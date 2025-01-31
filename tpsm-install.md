



# Run on local machine where sheepctl is:
* Set exports
```
export LOCKID=d3e4d358-131d-4426-885a-2d2eac25bea1
export ENVNAME=USFSI
```

* get lock details
```
sheepctl lock get ${LOCKID} > ${ENVNAME}.json
sheepctl lock get ${LOCKID} -j -o ${ENVNAME}-access.json
```
* Get kubeconfig for supervisor
```
sheepctl lock kubeconfig ${LOCKID} > ${ENVNAME}.kubeconfig
```
* User/pass for jumpbox
  - username = kubo
  - Password = sheepctl lock get ${LOCKID} -j |jq -r .outputs.vm.jumper.password

* Password for vCenter (not pretty)
  - Password = sheepctl lock get ${LOCKID}  | jq -r .vc[].password

* Get jumpbox IP, export to envvar
```
export JUMPERIP=$(sheepctl lock get ${LOCKID} -j |jq -r .outputs.vm.jumper.hostname)
```

* Create a $HOME/.kube directory on the jumpbox
```
ssh kubo@$JUMPERIP -t 'mkdir -p $HOME/.kube'
```

*  copy files from local to jumpbox - run on local machine where sheepctl is
```
scp -p resources/dnsmasq-install.sh kubo@$JUMPERIP:/home/kubo/
scp resources/storageclass-tpsm.yaml kubo@$JUMPERIP:/home/kubo/
scp resources/set-baseline.yaml kubo@$JUMPERIP:/home/kubo/
scp resources/cluster-tpsm.yaml kubo@$JUMPERIP:/home/kubo/
scp ${ENVNAME}.kubeconfig kubo@$JUMPERIP:/home/kubo/.kube/config
```

# On vCenter UI

* Create VMClass in testns namespace
  * name: tpsm
  * CPU: 8
  * RAM: 32GB
  * Reservation: none


# Login to Jumpbox
```
ssh kubo@$JUMPERIP
```
* install dnsmasq
```
~/dns-masq-install.sh
```
* add dns record for tanzu.platform.io
```
echo 'address=/tanzu.platform.io/192.168.0.4' | sudo tee /etc/dnsmasq.d/vlan-dhcp-dns.conf
sudo systemctl restart dnsmasq
sudo systemctl restart squid
```

* Install prereqs on jumpbox
  * Carvel Tools
  ```
  mkdir -p build/
  curl -kL https://carvel.dev/install.sh | K14SIO_INSTALL_BIN_DIR=build bash
  sudo cp -r ./build/* /usr/local/bin/
  ```
  * Tanzu CLI
  ```
  sudo apt install -y ca-certificates curl gpg
  ```
  ```
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://storage.googleapis.com/tanzu-cli-installer-packages/keys/TANZU-PACKAGING-GPG-RSA-KEY.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/tanzu-archive-keyring.gpg
  echo "deb [signed-by=/etc/apt/keyrings/tanzu-archive-keyring.gpg] https://storage.googleapis.com/tanzu-cli-installer-packages/apt tanzu-cli-jessie main" | sudo tee /etc/apt/sources.list.d/tanzu.list
  sudo apt update
  sudo apt install -y tanzu-cli
  ```
  * Crashd
  ```
  wget https://github.com/vmware-tanzu/crash-diagnostics/releases/download/v0.3.10/crashd_0.3.10_linux_amd64.tar.gz
  mkdir -p crashd_0.3.10_linux_amd64
  tar -xvf crashd_0.3.10_linux_amd64.tar.gz -C crashd_0.3.10_linux_amd64
  sudo mv crashd_0.3.10_linux_amd64/crashd  /usr/local/bin/crashd
  ```


# supervisor cluster - run on jumpbox
* confirm access to supervisor cluster
```
kubectl get ns testns
```

* Create Cluster & wait for ready
```
kubectl apply -n testns -f cluster-tpsm.yaml
```
  * wait for ready:
  ```
  watch -n 30 kubectl get tanzukubernetescluster -n testns tpsm -ojsonpath='{.status.phase}'
  ```

* get kubeconfig for tpsm cluster
```
kubectl get secret -n testns tpsm-kubeconfig -ojsonpath='{.data.value}' | base64 -d > tpsm-kubeconfig
```

* Merge kubeconfig
  * set KUBECONFIG env var:
  `export KUBECONFIG=~/.kube/config:~/tpsm-kubeconfig`

  * Flatten to new file:
  `kubectl config view --flatten > ~/combo.config`

  * Replace ~/.kube/config
  `cp combo.config ~/.kube/config`

* Change context to tpsm cluster
```
kubectl config use-context tpsm-admin@tpsm
```
# Prepare target cluster
Make sure your context is tpsm-admin@tpsm
* Install cert-manager
```
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.2/cert-manager.yaml
```
* Create tpsm storageClass
```
kubectl apply -f storageclass-tpsm.yaml
```
* install Kapp controller
  * check to see if kapp controller exists:
  `kubectl get po -A -l app=kapp-controller`
  * if it does not, install it
  ```
  kapp deploy -a kc -f <(ytt -f https://github.com/carvel-dev/kapp-controller/releases/download/v0.50.0/release.yml -f set-baseline.yaml -v namespace=kapp-controller)
  ```

* Install SecretGen Controller
```
kapp deploy -a sg -f https://github.com/carvel-dev/secretgen-controller/releases/latest/download/release.yml
```


# Install TPSM - run on jumpbox

## Download non-airgapped bits from artifactory to jumpbox
```
export ARTIFACTORY_USER=jd123456 //broadcom user ID
export ARTIFACTORY_API_TOKEN=abc123 // Identity token from https://usw1.packages.broadcom.com/ui/user_profile
export TANZU_SM_VERSION=10.0.0-oct-2024-rc.533-vc0bb325
export DOCKER_REGISTRY=tis-tanzuhub-sm-docker-dev-local.usw1.packages.broadcom.com

curl -u ${ARTIFACTORY_USER}:${ARTIFACTORY_API_TOKEN} https://usw1.packages.broadcom.com/artifactory/tis-tanzuhub-sm-docker-dev-local/hub-self-managed/${TANZU_SM_VERSION}/releases/non-airgapped/tanzu-self-managed-${TANZU_SM_VERSION}-linux-amd64.tar.gz --output tanzu-self-managed-${TANZU_SM_VERSION}.tar.gz
```

## Extract to ~/tpsm
```
mkdir ./tpsm
tar -xzvf tanzu-self-managed-${TANZU_SM_VERSION}.tar.gz -C ./tpsm
```
## Update config.yaml
```
sed -i 's|profile: foundation|profile: evaluation|' tpsm/config.yaml
sed -i 's|loadBalancerIP: ""|loadBalancerIP: "192.168.116.206"|' tpsm/config.yaml
sed -i 's|host: ""|host: "tanzu.platform.io"|' tpsm/config.yaml
sed -i 's|storageClass: ""|storageClass: "tpsm"|g' tpsm/config.yaml
sed -i ' 80 s|password: ""|password: "admin123"|' tpsm/config.yaml
sed -i ' 153 s|name: ""|name: "tanzu-sales"|' tpsm/config.yaml
sed -i 's|#  oauthProviders:|  oauthProviders:|g' tpsm/config.yaml
sed -i ' 92 s|#    - name: ""|    - name: "okta.test"|' tpsm/config.yaml
sed -i ' 97 s|#      configUrl: ""|      configUrl: "https://dev-70846880.okta.com/.well-known/openid-configuration"|'  tpsm/config.yaml
sed -i ' 99 s|#      issuerUrl: ""|      issuerUrl: "https://dev-70846880.okta.com"|' tpsm/config.yaml
sed -i ' 101 s|#      scopes: \["openid"]|      scopes: \["openid", "email", "groups"]|' tpsm/config.yaml
sed -i ' 103 s|#      loginPageLinkText: ""|      loginPageLinkText: "Login with Dev Okta"|'  tpsm/config.yaml
sed -i ' 105 s|#      clientId: ""|      clientId: "0oaggqbiqdlnTtfFY5d7"|'  tpsm/config.yaml
sed -i ' 107 s|#      secret: ""|      secret: "UMdEVboJTSfHAQEbuIlj1j2zticsxBRiEuRLYsfJk6dbeR9Nh47qH_7E_7q7MVT1"|' tpsm/config.yaml
sed -i ' 109 s|#      attributeMappings:|      attributeMappings:|' tpsm/config.yaml
sed -i ' 111 s|#        username: ""|        username: "email"|' tpsm/config.yaml
sed -i ' 113 s|#        groups: ""|        groups: "groups"|' tpsm/config.yaml
```

## verify
```
cd ./tpsm
./tanzu-sm-installer verify -f config.yaml -u "${ARTIFACTORY_USER}:${ARTIFACTORY_API_TOKEN}" -r ${DOCKER_REGISTRY}/hub-self-managed/${TANZU_SM_VERSION}/repo --install-version ${TANZU_SM_VERSION}
```
Watch the verification for [x] lines and resolve any that arise.
Looking to see **Success: The hostname 'tanzu.platform.io' resolves to 192.168.116.206** and **Completed pre-check(s) validation**


## Install!!
```
./tanzu-sm-installer install -f config.yaml -u "${ARTIFACTORY_USER}:${ARTIFACTORY_API_TOKEN}" -r ${DOCKER_REGISTRY}/hub-self-managed/${TANZU_SM_VERSION}/repo --install-version ${TANZU_SM_VERSION}
```
* once the install starts, you can break out of it to check the status:
  * `tanzu package installed list -n tanzusm`
  * `kubectl get pkgi -n tanzusm`


## Connect
Use firefox on local machine: Set Network Settings as follows:

* Select Manual proxy configuration
  * HTTP Proxy:  $JUMPERIP
  * port: 443
  * Also use this proxy for HTTPS
* No proxy for ".mozilla.org, mozilla.com, google.com,127.0.0.1/8"
* Proxy DNS when using SOCKS v4

**Browse to https://tanzu.platform.io in Firefox**






# tear down
* Remove TPSM
```
./tanzu-sm-installer reset --kubeconfig ~/.kube/config --include-pv-deletion
```
