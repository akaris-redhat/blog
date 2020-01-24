### Documentation ###

* [https://docs.openshift.com/container-platform/4.2/registry/securing-exposing-registry.html](https://docs.openshift.com/container-platform/4.2/registry/securing-exposing-registry.html)
* [https://docs.openshift.com/container-platform/4.2/registry/accessing-the-registry.html](https://docs.openshift.com/container-platform/4.2/registry/accessing-the-registry.html)

### Accessing the registry ###

Exposing with default routes:
~~~
oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge
HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
~~~

If in a lab environment and not using DNS servers, modify `/etc/hosts` on the client and push:
~~~
x.x.x.x default-route-openshift-image-registry.apps.<cluster URL>
~~~

When using the kubeadmin user, login as follows:
~~~
podman login -u kubeadmin -p $(oc whoami -t) --tls-verify=false $HOST 
~~~

Otherwise:
~~~
podman login -u $(oc whoami) -p $(oc whoami -t) --tls-verify=false $HOST 
~~~

### Pushing images to the registry ###

Build a custom image, e.g.:
~~~
mkdir custom-image
cd custom-image
cat<<'EOF'>Dockerfile
FROM fedora
RUN yum install tcpdump iproute iputils -y
EOF
buildah bud -t fedora-custom:1.0 .
~~~
