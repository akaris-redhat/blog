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
data:
  run-apache.sh: |
    #!/bin/bash

    /usr/sbin/httpd $OPTIONS -DFOREGROUND
kind: ConfigMap
metadata:
  creationTimestamp: null
  name: run-apache
  selfLink: /api/v1/namespaces/default/configmaps/run-apache
---
apiVersion: v1
kind: BuildConfig
metadata:
  name: fh-build
spec:
  source:
    configMaps:
      - configMap:
          name: run-apache
    dockerfile: |
       FROM fedora
       EXPOSE 80
       RUN yum install httpd -y
       RUN yum install tcpdump -y
       RUN yum install iproute -y
       RUN echo "Apache" >> /var/www/html/index.html
       ADD run-apache.sh /run-apache.sh
       RUN chmod -v +x /run-apache.sh
       CMD ["/run-apache.sh"]
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
[root@master-2 ~]# oc apply -f buildconfig.yaml 
imagestream.image.openshift.io/fh created
configmap/run-apache created
buildconfig.build.openshift.io/fh-build created
[root@master-2 ~]# oc get configmap
NAME         DATA      AGE
run-apache   1         5s
[root@master-2 ~]# oc get bc
ocNAME       TYPE      FROM         LATEST
fh-build   Docker    Dockerfile   0
[root@master-2 ~]# oc get is
NAME      DOCKER REPO                                   TAGS      UPDATED
fh        docker-registry.default.svc:5000/default/fh   
~~~

Now, start the build:
~~~
[root@master-2 ~]# oc start-build fh-build --follow
build.build.openshift.io/fh-build-1 started
Step 1/11 : FROM fedora
 ---> 536f3995adeb
Step 2/11 : EXPOSE 80
 ---> Running in 336e05de1176
 ---> cc328bfa1609
Removing intermediate container 336e05de1176
Step 3/11 : RUN yum install httpd -y
 ---> Running in 9ed7b439d71e

Fedora Modular 31 - x86_64                      880 kB/s | 5.2 MB     00:06    
Fedora Modular 31 - x86_64 - Updates            565 kB/s | 4.0 MB     00:07    
Fedora 31 - x86_64 - Updates                    2.4 MB/s |  22 MB     00:09    
Fedora 31 - x86_64                              5.0 MB/s |  71 MB     00:14    
Last metadata expiration check: 0:00:01 ago on Tue Mar 10 17:35:21 2020.



Dependencies resolved.
================================================================================
 Package                  Architecture Version              Repository     Size
================================================================================
Installing:
 httpd                    x86_64       2.4.41-12.fc31       updates       1.4 M
Installing dependencies:
 apr                      x86_64       1.7.0-2.fc31         fedora        124 k
 apr-util                 x86_64       1.6.1-11.fc31        fedora         98 k
 fedora-logos-httpd       noarch       30.0.2-3.fc31        fedora         16 k
 httpd-filesystem         noarch       2.4.41-12.fc31       updates        15 k
 httpd-tools              x86_64       2.4.41-12.fc31       updates        84 k
 mailcap                  noarch       2.1.48-6.fc31        fedora         31 k
 mod_http2                x86_64       1.15.3-2.fc31        fedora        158 k
Installing weak dependencies:
 apr-util-bdb             x86_64       1.6.1-11.fc31        fedora         13 k
 apr-util-openssl         x86_64       1.6.1-11.fc31        fedora         16 k

Transaction Summary
================================================================================
Install  10 Packages

Total download size: 1.9 M
Installed size: 5.9 M
Downloading Packages:
(1/10): httpd-filesystem-2.4.41-12.fc31.noarch.  19 kB/s |  15 kB     00:00    
(2/10): httpd-tools-2.4.41-12.fc31.x86_64.rpm    80 kB/s |  84 kB     00:01    
(3/10): httpd-2.4.41-12.fc31.x86_64.rpm         693 kB/s | 1.4 MB     00:02    
(4/10): apr-util-1.6.1-11.fc31.x86_64.rpm        77 kB/s |  98 kB     00:01    
(5/10): apr-1.7.0-2.fc31.x86_64.rpm              73 kB/s | 124 kB     00:01    
(6/10): apr-util-bdb-1.6.1-11.fc31.x86_64.rpm    30 kB/s |  13 kB     00:00    
(7/10): apr-util-openssl-1.6.1-11.fc31.x86_64.r  69 kB/s |  16 kB     00:00    
(8/10): fedora-logos-httpd-30.0.2-3.fc31.noarch  77 kB/s |  16 kB     00:00    
(9/10): mailcap-2.1.48-6.fc31.noarch.rpm         75 kB/s |  31 kB     00:00    
(10/10): mod_http2-1.15.3-2.fc31.x86_64.rpm     373 kB/s | 158 kB     00:00    
--------------------------------------------------------------------------------
Total                                           382 kB/s | 1.9 MB     00:05     
Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
  Preparing        :                                                        1/1 
  Installing       : apr-1.7.0-2.fc31.x86_64                               1/10 
  Installing       : apr-util-bdb-1.6.1-11.fc31.x86_64                     2/10 
  Installing       : apr-util-openssl-1.6.1-11.fc31.x86_64                 3/10 
  Installing       : apr-util-1.6.1-11.fc31.x86_64                         4/10 
  Installing       : httpd-tools-2.4.41-12.fc31.x86_64                     5/10 
  Installing       : mailcap-2.1.48-6.fc31.noarch                          6/10 
  Installing       : fedora-logos-httpd-30.0.2-3.fc31.noarch               7/10 
  Running scriptlet: httpd-filesystem-2.4.41-12.fc31.noarch                8/10 
  Installing       : httpd-filesystem-2.4.41-12.fc31.noarch                8/10 
  Installing       : mod_http2-1.15.3-2.fc31.x86_64                        9/10 
  Installing       : httpd-2.4.41-12.fc31.x86_64                          10/10 
  Running scriptlet: httpd-2.4.41-12.fc31.x86_64                          10/10 
  Verifying        : httpd-2.4.41-12.fc31.x86_64                           1/10 
  Verifying        : httpd-filesystem-2.4.41-12.fc31.noarch                2/10 
  Verifying        : httpd-tools-2.4.41-12.fc31.x86_64                     3/10 
  Verifying        : apr-1.7.0-2.fc31.x86_64                               4/10 
  Verifying        : apr-util-1.6.1-11.fc31.x86_64                         5/10 
  Verifying        : apr-util-bdb-1.6.1-11.fc31.x86_64                     6/10 
  Verifying        : apr-util-openssl-1.6.1-11.fc31.x86_64                 7/10 
  Verifying        : fedora-logos-httpd-30.0.2-3.fc31.noarch               8/10 
  Verifying        : mailcap-2.1.48-6.fc31.noarch                          9/10 
  Verifying        : mod_http2-1.15.3-2.fc31.x86_64                       10/10 

Installed:
  apr-1.7.0-2.fc31.x86_64                 apr-util-1.6.1-11.fc31.x86_64        
  apr-util-bdb-1.6.1-11.fc31.x86_64       apr-util-openssl-1.6.1-11.fc31.x86_64
  fedora-logos-httpd-30.0.2-3.fc31.noarch httpd-2.4.41-12.fc31.x86_64          
  httpd-filesystem-2.4.41-12.fc31.noarch  httpd-tools-2.4.41-12.fc31.x86_64    
  mailcap-2.1.48-6.fc31.noarch            mod_http2-1.15.3-2.fc31.x86_64       

Complete!
 ---> 98d98c94a387
Removing intermediate container 9ed7b439d71e
Step 4/11 : RUN yum install tcpdump -y
 ---> Running in b634945ebf71

Last metadata expiration check: 0:01:34 ago on Tue Mar 10 17:35:21 2020.
Dependencies resolved.
================================================================================
 Package         Architecture   Version                   Repository       Size
================================================================================
Installing:
 tcpdump         x86_64         14:4.9.3-1.fc31           updates         446 k

Transaction Summary
================================================================================
Install  1 Package

Total download size: 446 k
Installed size: 1.2 M
Downloading Packages:
tcpdump-4.9.3-1.fc31.x86_64.rpm                 285 kB/s | 446 kB     00:01    
--------------------------------------------------------------------------------
Total                                           232 kB/s | 446 kB     00:01     
Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
  Preparing        :                                                        1/1 
  Running scriptlet: tcpdump-14:4.9.3-1.fc31.x86_64                         1/1 
  Installing       : tcpdump-14:4.9.3-1.fc31.x86_64                         1/1 
  Running scriptlet: tcpdump-14:4.9.3-1.fc31.x86_64                         1/1 
  Verifying        : tcpdump-14:4.9.3-1.fc31.x86_64                         1/1 

Installed:
  tcpdump-14:4.9.3-1.fc31.x86_64                                                

Complete!
 ---> 0e6d31818699
Removing intermediate container b634945ebf71
Step 5/11 : RUN yum install iproute -y
 ---> Running in 8a97b178492e

Last metadata expiration check: 0:02:10 ago on Tue Mar 10 17:35:21 2020.
Dependencies resolved.
================================================================================
 Package               Architecture  Version               Repository      Size
================================================================================
Installing:
 iproute               x86_64        5.4.0-1.fc31          updates        640 k
Installing dependencies:
 libmnl                x86_64        1.0.4-10.fc31         fedora          28 k
 linux-atm-libs        x86_64        2.5.1-25.fc31         fedora          38 k
 psmisc                x86_64        23.3-2.fc31           updates        160 k
Installing weak dependencies:
 iproute-tc            x86_64        5.4.0-1.fc31          updates        408 k

Transaction Summary
================================================================================
Install  5 Packages

Total download size: 1.2 M
Installed size: 3.4 M
Downloading Packages:
(1/5): psmisc-23.3-2.fc31.x86_64.rpm             93 kB/s | 160 kB     00:01    
(2/5): iproute-tc-5.4.0-1.fc31.x86_64.rpm       199 kB/s | 408 kB     00:02    
(3/5): iproute-5.4.0-1.fc31.x86_64.rpm          305 kB/s | 640 kB     00:02    
(4/5): libmnl-1.0.4-10.fc31.x86_64.rpm           40 kB/s |  28 kB     00:00    
(5/5): linux-atm-libs-2.5.1-25.fc31.x86_64.rpm   53 kB/s |  38 kB     00:00    
--------------------------------------------------------------------------------
Total                                           266 kB/s | 1.2 MB     00:04     
Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
  Preparing        :                                                        1/1 
  Installing       : libmnl-1.0.4-10.fc31.x86_64                            1/5 
  Installing       : linux-atm-libs-2.5.1-25.fc31.x86_64                    2/5 
  Installing       : psmisc-23.3-2.fc31.x86_64                              3/5 
  Installing       : iproute-tc-5.4.0-1.fc31.x86_64                         4/5 
  Installing       : iproute-5.4.0-1.fc31.x86_64                            5/5 
  Running scriptlet: iproute-5.4.0-1.fc31.x86_64                            5/5 
  Verifying        : iproute-5.4.0-1.fc31.x86_64                            1/5 
  Verifying        : iproute-tc-5.4.0-1.fc31.x86_64                         2/5 
  Verifying        : psmisc-23.3-2.fc31.x86_64                              3/5 
  Verifying        : libmnl-1.0.4-10.fc31.x86_64                            4/5 
  Verifying        : linux-atm-libs-2.5.1-25.fc31.x86_64                    5/5 

Installed:
  iproute-5.4.0-1.fc31.x86_64        iproute-tc-5.4.0-1.fc31.x86_64            
  libmnl-1.0.4-10.fc31.x86_64        linux-atm-libs-2.5.1-25.fc31.x86_64       
  psmisc-23.3-2.fc31.x86_64         

Complete!
 ---> 25dbab5462e9
Removing intermediate container 8a97b178492e
Step 6/11 : RUN echo "Apache" >> /var/www/html/index.html
 ---> Running in d0b07909b473

 ---> 30eb534c9b8f
Removing intermediate container d0b07909b473
Step 7/11 : ADD run-apache.sh /run-apache.sh
 ---> 3f8d68d6b8c9
Removing intermediate container 791595daf279
Step 8/11 : RUN chmod -v +x /run-apache.sh
 ---> Running in cf3b9509db44

mode of '/run-apache.sh' changed from 0600 (rw-------) to 0711 (rwx--x--x)
 ---> e53b23f01893
Removing intermediate container cf3b9509db44
Step 9/11 : CMD /run-apache.sh
 ---> Running in d79684be9eca
 ---> ea019a162b55
Removing intermediate container d79684be9eca
Step 10/11 : ENV "OPENSHIFT_BUILD_NAME" "fh-build-1" "OPENSHIFT_BUILD_NAMESPACE" "default"
 ---> Running in 71fe9b0c5d6b
 ---> b4740adc0ab9
Removing intermediate container 71fe9b0c5d6b
Step 11/11 : LABEL "io.openshift.build.name" "fh-build-1" "io.openshift.build.namespace" "default"
 ---> Running in 4f205c797d63
 ---> 274538a43e0a
Removing intermediate container 4f205c797d63
Successfully built 274538a43e0a

Pushing image docker-registry.default.svc:5000/default/fh:latest ...
Pushed 0/7 layers, 4% complete
Pushed 1/7 layers, 59% complete
Pushed 2/7 layers, 66% complete
Pushed 3/7 layers, 70% complete
Pushed 4/7 layers, 59% complete
Pushed 5/7 layers, 72% complete
Pushed 5/7 layers, 94% complete
Pushed 6/7 layers, 96% complete
Pushed 7/7 layers, 100% complete
Push successful    
~~~

Verify the build and imagestream:
~~~
[root@master-2 ~]# oc get is
oNAME      DOCKER REPO                                   TAGS      UPDATED
fh        docker-registry.default.svc:5000/default/fh   latest    About a minute ago
[root@master-2 ~]# oc get bc
oNAME       TYPE      FROM         LATEST
fh-build   Docker    Dockerfile   1
[root@master-2 ~]# oc get builds
NAME         TYPE      FROM         STATUS     STARTED         DURATION
fh-build-1   Docker    Dockerfile   Complete   7 minutes ago   5m55s
[root@master-2 ~]# oc describe is fh
Name:			fh
Namespace:		default
Created:		7 minutes ago
Labels:			<none>
Annotations:		kubectl.kubernetes.io/last-applied-configuration={"apiVersion":"image.openshift.io/v1","kind":"ImageStream","metadata":{"annotations":{},"creationTimestamp":null,"generation":1,"name":"fh","namespace":"default","selfLink":"/apis/image.openshift.io/v1/namespaces/default/imagestreams/fh"},"spec":{"lookupPolicy":{"local":false}},"status":{"dockerImageRepository":"docker-registry.default.svc:5000/fh"}}
			
Docker Pull Spec:	docker-registry.default.svc:5000/default/fh
Image Lookup:		local=false
Unique Images:		1
Tags:			1

latest
  no spec tag

  * docker-registry.default.svc:5000/default/fh@sha256:770559f9e958c6c1d0dd91f8ff64f10f2e1fc8538c337682b95f855f8a5a123e
      About a minute ago
~~~

Now, use the imagestream in a deployment:
~~~

~~~

### Resources ###

* https://docs.openshift.com/container-platform/3.11/dev_guide/builds/build_inputs.html#dockerfile-source
* https://docs.openshift.com/container-platform/3.11/dev_guide/builds/basic_build_operations.html
* https://lists.openshift.redhat.com/openshift-archives/users/2017-September/msg00031.html
* https://docs.openshift.com/container-platform/3.11/dev_guide/builds/basic_build_operations.html
* https://kb.novaordis.com/index.php/OpenShift_Image_and_ImageStream_Operations
* https://docs.openshift.com/dedicated/3/dev_guide/builds/build_inputs.html#using-secrets-during-build
