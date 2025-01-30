



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
# supervisor cluster - run on jumpbox
  - confirm access to supervisor cluster
  ```kubectl get no```
