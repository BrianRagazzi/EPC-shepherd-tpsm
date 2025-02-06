# Install harbor on jumpbox

* Download Harbor bits
  ```
  curl -L https://github.com/goharbor/harbor/releases/download/v2.12.2/harbor-offline-installer-v2.12.2.tgz --output harbor-offline-installer-v2.12.2.tgz
  ```

* Extract tar
  ```
  tar -xvf harbor-offline-installer-v2.12.2.tgz
  ```
  * this will place relevant files into the ./harbor directory

* make folders
  ```
  sudo mkdir -p /harbor/{cert,data}
  ```

* Create self-signed cert
  ```
  sudo openssl req -x509 -nodes -days 365 -subj "/CN=harbor.platform.io/C=US/ST=CA/L=Palo Alto/O=Broadcom/OU=Tanzu" -addext "subjectAltName=DNS:harbor.platform.io" -newkey rsa:2048 -keyout /harbor/cert/selfsigned.key -out /harbor/cert/selfsigned.crt
  ```

* Create/edit/copy harbor.yml
  ```
  cd ./harbor
  cp harbor.yml.tmpl harbor.yml
  sed -i ' 5 s|hostname: reg.mydomain.com|hostname: harbor.platform.io|' harbor.yml
  sed -i ' 10 s|  port: 80|  port: 8080|' harbor.yml
  sed -i ' 15 s|  port: 443|  port: 8443|' harbor.yml
  sed -i ' 17 s|  certificate: /your/certificate/path|  certificate: /harbor/cert/selfsigned.crt|' harbor.yml
  sed -i ' 18 s|  private_key: /your/private/key/path|  private_key: /harbor/cert/selfsigned.key|' harbor.yml
  sed -i ' 66 s|data_volume: /data|data_volume: /harbor/data|' harbor.yml
  ```

* install
  ```
  sudo ./install.sh --with-trivy
  ```

* Add/update DNS record in dnsmasq
  ```
  echo 'address=/harbor.platform.io/192.168.116.1' | sudo tee -a /etc/dnsmasq.d/vlan-dhcp-dns.conf
  sudo systemctl restart dnsmasq
  ```

* Connect!
  * Use Firefox with proxy to browse to https://harbor.platform.io


## Update TanzuServiceConfiguration to trust Harbor cert
* Switch context to Supervisor cluster
  ```
  kubectl config use-context kubernetes-admin@kubernetes
  ```
* Create TanzuServiceConfiguration:
  ```
  harborcert=$(cat /harbor/cert/selfsigned.crt |base64 -w 0) bash -c "cat > TanzuServiceConfiguration.yaml" <<EOF
  apiVersion: run.tanzu.vmware.com/v1alpha1
  kind: TkgServiceConfiguration
  metadata:
    name: tkg-service-configuration
  spec:
    defaultCNI: antrea
    trust:
      additionalTrustedCAs:
        - name: harborcert
          data: $harborcert
  EOF
  ```
* Apply TanzuServiceConfiguration:
  ```
  kubetl apply -f TanzuServiceConfiguration.yaml
  ```
