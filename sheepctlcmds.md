# Commands for sheepctl


## Connect
```
sheepctl target set -u https://epc-shepherd.lvn.broadcom.net -n Tanzu-Sales
```
## Get a lock
```
sheepctl pool lock TKGS-3.0.0-VC-8u3-Non-Airgap -n Tanzu-Sales --lifetime 5d --description 'Team (Person)'
```

## List Locks
```
sheepctl lock list -n Tanzu-Sales
```
### Export Lock data to files (do both to get all the data):
```
sheepctl lock get -n Tanzu-Sales 0e450633-978c-4704-9432-f047731afbf5 > USEAST.json
sheepctl lock get d3e4d358-131d-4426-885a-2d2eac25bea1 -j -o USFSI-access.json
```

## list pools
```
sheepctl pool list -n Tanzu-Sales
```
## Extend lock
```
sheepctl lock extend 9596f88d-0681-4e8d-a4b9-5c47b35ab4d6 -t 5d
```
