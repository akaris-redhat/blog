### Building custom images with OpenShift ###

Create the following file

`buildconfig.yaml`:
~~~
apiVersion: image.openshift.io/v1
kind: ImageStream
metadata:
  creationTimestamp: null
  generation: 1
  name: fh
  selfLink: /apis/image.openshift.io/v1/namespaces/default/imagestreams/fh
spec:
  lookupPolicy:
    local: false
status:
  dockerImageRepository: docker-registry.default.svc:5000/fh
---
apiVersion: v1
kind: BuildConfig
metadata:
  name: fh-build
spec:
  source:
    dockerfile: '
       FROM fedora\n
       EXPOSE 80\n
       RUN yum install httpd -y\n
       RUN yum install tcpdump -y\n
       RUN yum install iproute -y\n
       RUN echo "Apache" >> /var/www/html/index.html\n
       ADD run-apache.sh /run-apache.sh\n
       RUN chmod -v +x /run-apache.sh\n
       CMD ["/run-apache.sh"]'
  strategy:
    dockerStrategy:
      noCache: true
  output:
    to:
      kind: ImageStreamTag
      name: fh:latest
~~~

And apply it:
~~~

~~~

### Resources ###

* https://docs.openshift.com/container-platform/3.11/dev_guide/builds/build_inputs.html#dockerfile-source
* https://docs.openshift.com/container-platform/3.11/dev_guide/builds/basic_build_operations.html
* https://lists.openshift.redhat.com/openshift-archives/users/2017-September/msg00031.html
* https://docs.openshift.com/container-platform/3.11/dev_guide/builds/basic_build_operations.html
* https://kb.novaordis.com/index.php/OpenShift_Image_and_ImageStream_Operations
