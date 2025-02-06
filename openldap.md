
# Install and configure openLDAP for Tanzu Platform SM

## Challenges
  * dockerhub reports error 429 even when trying to configure a proxycache in Harbor
  * Unable to authenticate to docker hub due to 429

## Workaround - download the image tarball elsewhere and transfer it to harbor

* On laptop with sheepctl - outside of Broadcom's network, download the openldap image and save it to tar:
  ```
  imgpkg copy --image docker.io/bitnami/openldap:latest --to-tar openldap.tar
  ```
* On same laptop, scp the tar file and install manifest to the jumpbox:
  ```
  scp openldap.tar kubo@$JUMPERIP:/home/kubo
  scp resources/openldap.yaml kubo@$JUMPERIP:/home/kubo
  ```

* On jumpbox, import the tar to the library project on Harbor:
  ```
  imgpkg copy --tar openldap.tar --to-repo harbor.platform.io:8443/library/openldap --repo-based-tags --registry-verify-certs=false --registry-username admin --registry-password Harbor12345
  ```

## Install OpenLDAP Server

**Note:**  The cluster config must have the self-signed harbor cert added to its trust, see [Install harbor on jumpbox](harbor.md)

* Create imagePullSecret:
  ```
  kubectl create secret -n openldap docker-registry harbor --docker-username=admin --docker-password=Harbor12345 --docker-server=https://harbor.platform.io:8443
  ```

* Apply objects
  ```
  kubectl apply -f openldap.yaml
  ```
