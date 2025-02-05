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
sudo openssl req -x509 -nodes -days 365 -subj "/CN=harbor.platform.io/C=US/ST=CA/L=Palo Alto/O=Broadcom/OU=Tanzu" -newkey rsa:2048 -keyout /harbor/cert/selfsigned.key -out /harbor/cert/selfsigned.crt
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
