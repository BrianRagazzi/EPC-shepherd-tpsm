



# Get jumpbox details:
## exports
```
export LOCKID=d3e4d358-131d-4426-885a-2d2eac25bea1
export ENVNAME=USFSI
```

## get lock details
```
sheepctl lock get ${LOCKID} > ${ENVNAME}.json
sheepctl lock get ${LOCKID} -j -o ${ENVNAME}-access.json
```
### kubeconfig for supervisor
```
sheepctl lock kubeconfig ${LOCKID} > ${ENVNAME}.kubeconfig
```
## User/pass
username = kubo
Password = sheepctl lock get ${LOCKID} -j |jq -r .outputs.vm.jumper.password

## Get jumpbox IP
```
export JUMPERIP=$(sheepctl lock get ${LOCKID} -j |jq -r .outputs.vm.jumper.hostname)
```

# Login to jumpbox
```
ssh kubo@$JUMPERIP
```

## Update DNSMasq
/etc/dnsmasq.d/vlan-dhcp-dns.conf

## Create .kube folder
```
mkdir -p ~/.kube
```

## copy files from local to jumpbox - run on local machine where sheepctl is
```
scp dnsmasq-install.sh kubo@$JUMPERIP:/home/kubo/
scp ${ENVNAME}.kubeconfig kubo@$JUMPERIP:/home/kubo/.kube/config
```
