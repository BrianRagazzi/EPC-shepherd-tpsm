



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

*  copy files from local to jumpbox - run on local machine where sheepctl is
```
scp resources/dnsmasq-install.sh kubo@$JUMPERIP:/home/kubo/
scp resources/vmclass-tpsm.yaml kubo@$JUMPERIP:/home/kubo/
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
* Create .kube folder - run on jumpbox
```
mkdir -p ~/.kube
```
* Install prereqs on jumpbox
  * Carvel Tools
  ```
  mkdir -p build/
  curl -kL https://carvel.dev/install.sh | K14SIO_INSTALL_BIN_DIR=build bash
  ```
  * Tanzu CLI
  ```
  sudo apt install -y ca-certificates curl gpg
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

* ~~Create vmclass~~ **Doesn't work as desired**
~~kubectl apply -n testns -f vmclass-tpsm.yaml~~


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
