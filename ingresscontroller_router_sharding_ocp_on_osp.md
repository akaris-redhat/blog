How to configure IngressController router sharding with OpenShift 4.x on top of OpenStack Platform 13 and Octavia and default HostNetwork endpointPublishingStrategy

### Preface ###

The official documentation describes how to configure router sharding:
[https://docs.openshift.com/container-platform/4.3/networking/configuring_ingress_cluster_traffic/configuring-ingress-cluster-traffic-ingress-controller.html#nw-ingress-sharding-namespace-labels_configuring-ingress-cluster-traffic-ingress-controller](https://docs.openshift.com/container-platform/4.3/networking/configuring_ingress_cluster_traffic/configuring-ingress-cluster-traffic-ingress-controller.html#nw-ingress-sharding-namespace-labels_configuring-ingress-cluster-traffic-ingress-controller)

However, the default `endpointPublishingStrategy` is `HostNetwork` and by default, OpenShift configures only a single VIP for installations in OpenStack. It is possible to configure Kuryr (supported) or Octavia loadbalancers (unsupported, see [https://access.redhat.com/solutions/4722521](https://access.redhat.com/solutions/4722521)). In that case, the IngressController's endpoint publishing strategy needs to be set to `LoadBalancerService`:
~~~
spec:
  endpointPublishingStrategy:
    type: LoadBalancerService
~~~

But it is also possible to keep the default `endpointPublishingStrategy`as `HostNetwork` and configure additional load balancers. This is a similar approach as chosen for vSphere deployments: [https://docs.openshift.com/container-platform/4.3/installing/installing_vsphere/installing-vsphere.html](https://docs.openshift.com/container-platform/4.3/installing/installing_vsphere/installing-vsphere.html)

The following examples use 3 namespaces, `default`, `test1`, `test2`. Each namespace will be served by one IngressController. The environment hosts 3 worker nodes. Due to limitations of the `HostNetwork` strategy, each worker node can host exactly one IngressController's router instance. Meaning that the replica count for each controller needs to be set to 1 in an environment with 3 worker nodes.

### Prerequisites ###

Make sure that the environment was configured with Octavia.

### Configuring test projects and the default project IngressControllers ###

Create 2 new projects and label them:
~~~
# Each ingresscontroller runs 1 replica = this works with 3 workers

# default ingress will match ns:
#     oc get ns -l type!=test1,type!=test2
# test1 ingress will match
#     oc get ns -l type=test1
# test2 ingress will match
#     oc get ns -l type=test2

oc new-project test1
oc new-project test2
oc label namespace test1 "type=test1"
oc label namespace test2 "type=test2"
~~~

Create a label on each worker node to pin IngressController routers to a particular node:
~~~
oc label node cluster-7n7w9-worker-zpq85 "ingressoperator=default"
oc label node cluster-7n7w9-worker-zpq84 "ingressoperator=test1"
oc label node cluster-7n7w9-worker-zpq83 "ingressoperator=test2"
~~~

### Configuring IngressControllers ###

Now, patch the default IngressController to force node selection and to make sure that it will not serve namespaces test1 and test2:

`operator-default-patch.yaml`
~~~
spec:
  replicas: 1
  namespaceSelector:
    matchExpressions:
    - key: type
      operator: NotIn
      values:
      - test1
      - test2
  nodePlacement:
    nodeSelector:
      matchLabels:
        ingressoperator: default
~~~

~~~
oc project default
oc patch -n openshift-ingress-operator ingresscontroller default --type="merge" -p "$(cat operator-default-patch.yaml)"
~~~

Now, create IngressOperators for namespaces test1 and test2:

`operator-test1.yaml`
~~~
apiVersion: v1
items:
- apiVersion: operator.openshift.io/v1
  kind: IngressController
  metadata:
    name: test1-ingress-controller
    namespace: openshift-ingress-operator
  spec:
    replicas: 1
    domain: test1.cluster.example.com
    nodePlacement:
      nodeSelector:
        matchLabels:
          node-role.kubernetes.io/worker: ""
          ingressoperator: "test1"
    namespaceSelector:
      matchLabels:
        type: test1
    endpointPublishingStrategy:
      type: HostNetwork
      #type: LoadBalancerService
  status: {}
kind: List
metadata:
  resourceVersion: ""
  selfLink: ""
~~~

`operator-test2.yaml`
~~~
apiVersion: v1
items:
- apiVersion: operator.openshift.io/v1
  kind: IngressController
  metadata:
    name: test2-ingress-controller
    namespace: openshift-ingress-operator
  spec:
    replicas: 1
    domain: test2.cluster.example.com
    nodePlacement:
      nodeSelector:
        matchLabels:
          node-role.kubernetes.io/worker: ""
          ingressoperator: test2
    namespaceSelector:
      matchLabels:
        type: test2
  status: {}
kind: List
metadata:
  resourceVersion: ""
  selfLink: ""
~~~

~~~
oc project test1
oc apply -f operator-test1.yaml
~~~

~~~
oc project test2
oc apply -f operator-test2.yaml
~~~

Note that at this point, the default IngressController routing will be broken. OCP on OSP runs a keepalived service which can be on either of the worker nodes.
Only one of the 3 IngressControllers will be served at this moment. We will change this in a moment.

### Creating test builds and services ###

~~~
oc project default
oc apply -f fh-build.yaml
oc start-build fh-build --follow
oc apply -f fh-ingress.yaml

oc project test1
oc adm policy add-scc-to-user anyuid -z default
oc apply -f fh-test1-build.yaml
oc start-build fh-test1-build --follow
oc apply -f fh-test1-ingress.yaml

oc project test2
oc adm policy add-scc-to-user anyuid -z default
oc apply -f fh-test2-build.yaml
oc start-build fh-test2-build --follow
oc apply -f fh-test2-ingress.yaml
~~~

`fh-build.yaml`
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
       EXPOSE 8080
       RUN yum install httpd -y
       RUN yum install tcpdump -y
       RUN yum install iproute -y
       RUN yum install procps-ng -y
       RUN echo "Apache default" >> /var/www/html/index.html
       ADD run-apache.sh /usr/share/httpd/run-apache.sh
       RUN chown apache. /run/httpd/ -R
       RUN chmod -v +rx /usr/share/httpd/run-apache.sh
       RUN chown apache.  /usr/share/httpd/run-apache.sh
       RUN usermod apache -s /bin/bash
       RUN sed -i 's/Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf
       RUN chown apache. /etc/httpd/logs/ -R
       USER apache
       CMD ["/usr/share/httpd/run-apache.sh"]
  strategy:
    dockerStrategy:
      noCache: true
  output:
    to:
      kind: ImageStreamTag
      name: fh:latest

~~~

`fh-ingress.yaml`
~~~
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: fhingress-ingress
  annotations:
    kubernetes.io/ingress.allow-http: "true"
spec:
  rules:
  - host: fh.apps.cluster.example.com
    http:
      paths:
      - path: /
        backend:
          serviceName: fhingress-service
          servicePort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: fhingress-service
  labels:
    app: fhingress-deploymentconfig
spec:
  selector:
    app: fhingress-pod
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fhingress-deployment
  labels:
    app: fhingress-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: fhingress-pod
  template:
    metadata:
      labels:
        app: fhingress-pod
    spec:
      containers:
      - name: fhingress
        image: image-registry.openshift-image-registry.svc:5000/default/fh
        imagePullPolicy: Always
~~~

`fh-test1-build.yaml`
~~~
apiVersion: image.openshift.io/v1
kind: ImageStream
metadata:
  creationTimestamp: null
  generation: 1
  name: fh-test1
  selfLink: /apis/image.openshift.io/v1/namespaces/default/imagestreams/fh-test1
spec:
  lookupPolicy:
    local: false
status:
  dockerImageRepository: docker-registry.default.svc:5000/fh-test1
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
  name: fh-test1-build
spec:
  source:
    configMaps:
      - configMap:
          name: run-apache
    dockerfile: |
       FROM fedora
       EXPOSE 8080
       RUN yum install httpd -y
       RUN yum install tcpdump -y
       RUN yum install iproute -y
       RUN yum install procps-ng -y
       RUN echo "Apache test1" >> /var/www/html/index.html
       ADD run-apache.sh /usr/share/httpd/run-apache.sh
       RUN chown apache. /run/httpd/ -R
       RUN chmod -v +rx /usr/share/httpd/run-apache.sh
       RUN chown apache.  /usr/share/httpd/run-apache.sh
       RUN usermod apache -s /bin/bash
       RUN sed -i 's/Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf
       RUN chown apache. /etc/httpd/logs/ -R
       USER apache
       CMD ["/usr/share/httpd/run-apache.sh"]
  strategy:
    dockerStrategy:
      noCache: true
  output:
    to:
      kind: ImageStreamTag
      name: fh-test1:latest

~~~

`fh-test1-ingress.yaml`
~~~
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: fh-test1ingress-ingress
  annotations:
    kubernetes.io/ingress.allow-http: "true"
spec:
  rules:
  - host: fh.test1.cluster.example.com
    http:
      paths:
      - path: /
        backend:
          serviceName: fh-test1ingress-service
          servicePort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: fh-test1ingress-service
  labels:
    app: fh-test1ingress-deploymentconfig
spec:
  selector:
    app: fh-test1ingress-pod
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fh-test1ingress-deployment
  labels:
    app: fh-test1ingress-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: fh-test1ingress-pod
  template:
    metadata:
      labels:
        app: fh-test1ingress-pod
    spec:
      containers:
      - name: fh-test1ingress
        image: image-registry.openshift-image-registry.svc:5000/test1/fh-test1
        imagePullPolicy: Always
~~~

`fh-test2-build.yaml`
~~~
apiVersion: image.openshift.io/v1
kind: ImageStream
metadata:
  creationTimestamp: null
  generation: 1
  name: fh-test2
  selfLink: /apis/image.openshift.io/v1/namespaces/default/imagestreams/fh-test2
spec:
  lookupPolicy:
    local: false
status:
  dockerImageRepository: docker-registry.default.svc:5000/fh-test2
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
  name: fh-test2-build
spec:
  source:
    configMaps:
      - configMap:
          name: run-apache
    dockerfile: |
       FROM fedora
       EXPOSE 8080
       RUN yum install httpd -y
       RUN yum install tcpdump -y
       RUN yum install iproute -y
       RUN yum install procps-ng -y
       RUN echo "Apache test2" >> /var/www/html/index.html
       ADD run-apache.sh /usr/share/httpd/run-apache.sh
       RUN chown apache. /run/httpd/ -R
       RUN chmod -v +rx /usr/share/httpd/run-apache.sh
       RUN chown apache.  /usr/share/httpd/run-apache.sh
       RUN usermod apache -s /bin/bash
       RUN sed -i 's/Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf
       RUN chown apache. /etc/httpd/logs/ -R
       USER apache
       CMD ["/usr/share/httpd/run-apache.sh"]
  strategy:
    dockerStrategy:
      noCache: true
  output:
    to:
      kind: ImageStreamTag
      name: fh-test2:latest

~~~

`fh-test2-ingress.yaml`
~~~
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: fh-test2ingress-ingress
  annotations:
    kubernetes.io/ingress.allow-http: "true"
spec:
  rules:
  - host: fh.test2.cluster.example.com
    http:
      paths:
      - path: /
        backend:
          serviceName: fh-test2ingress-service
          servicePort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: fh-test2ingress-service
  labels:
    app: fh-test2ingress-deploymentconfig
spec:
  selector:
    app: fh-test2ingress-pod
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fh-test2ingress-deployment
  labels:
    app: fh-test2ingress-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: fh-test2ingress-pod
  template:
    metadata:
      labels:
        app: fh-test2ingress-pod
    spec:
      containers:
      - name: fh-test2ingress
        image: image-registry.openshift-image-registry.svc:5000/test2/fh-test2
        imagePullPolicy: Always
~~~

### Configuring Octavia loadbalancers for server IngressControllers ###

Instead of using the default keepalived VIP, we are going to create one Octavia loadbalancer per IngressController:
~~~
(overcloud) [stack@undercloud-0 ~]$ openstack server list
+--------------------------------------+----------------------------+--------+--------------------------------------------------------------------------+---------------------+--------------+
| ID                                   | Name                       | Status | Networks                                                                 | Image               | Flavor       |
+--------------------------------------+----------------------------+--------+--------------------------------------------------------------------------+---------------------+--------------+
| 2e5bc035-e6da-4807-8c96-268c2587c759 | cluster-7n7w9-worker-fkv5p | ACTIVE | cluster-7n7w9-openshift=172.31.0.45                                      | cluster-7n7w9-rhcos | m1.openshift |
| 14406e18-74bd-4723-81b1-ea38080d3e72 | cluster-7n7w9-worker-ggxds | ACTIVE | cluster-7n7w9-openshift=172.31.0.13                                      | cluster-7n7w9-rhcos | m1.openshift |
| 7ad9432b-bb4f-4cc1-b842-1e63a323a3b5 | cluster-7n7w9-worker-zpq85 | ACTIVE | cluster-7n7w9-openshift=172.31.0.14                                      | cluster-7n7w9-rhcos | m1.openshift |
| dc4db4f7-d410-4404-9166-66204931538c | cluster-7n7w9-master-1     | ACTIVE | cluster-7n7w9-openshift=172.31.0.15                                      | cluster-7n7w9-rhcos | m1.openshift |
| e0e3a4cd-4d1e-4496-9e59-ba8c0d62b54a | cluster-7n7w9-master-2     | ACTIVE | cluster-7n7w9-openshift=172.31.0.23                                      | cluster-7n7w9-rhcos | m1.openshift |
| 1b76ade6-ad53-43c8-9f15-fd3d550e0a17 | cluster-7n7w9-master-0     | ACTIVE | cluster-7n7w9-openshift=172.31.0.39                                      | cluster-7n7w9-rhcos | m1.openshift |
| 43810d22-74ce-4f5a-a615-d77d1628dde7 | rhel-test1                 | ACTIVE | private1=2000:192:168:0:f816:3eff:fea4:39e1, 192.168.0.108, 172.16.0.208 | rhel                | m1.small     |
+--------------------------------------+----------------------------+--------+--------------------------------------------------------------------------+---------------------+--------------+
(overcloud) [stack@undercloud-0 ~]$ openstack server list --all
+--------------------------------------+----------------------------------------------+--------+--------------------------------------------------------------------------+----------------------------------------+--------------+
| ID                                   | Name                                         | Status | Networks                                                                 | Image                                  | Flavor       |
+--------------------------------------+----------------------------------------------+--------+--------------------------------------------------------------------------+----------------------------------------+--------------+
| 2bdd7c68-2b00-4824-9ebe-6cc3babdfe77 | amphora-da1a5888-1052-4a6b-a05d-fc21c22a5cf5 | ACTIVE | lb-mgmt-net=172.24.0.13; cluster-7n7w9-openshift=172.31.0.20             | octavia-amphora-13.0-20200323.2.x86_64 |              |
| 2e5bc035-e6da-4807-8c96-268c2587c759 | cluster-7n7w9-worker-fkv5p                   | ACTIVE | cluster-7n7w9-openshift=172.31.0.45                                      | cluster-7n7w9-rhcos                    | m1.openshift |
| 14406e18-74bd-4723-81b1-ea38080d3e72 | cluster-7n7w9-worker-ggxds                   | ACTIVE | cluster-7n7w9-openshift=172.31.0.13                                      | cluster-7n7w9-rhcos                    | m1.openshift |
| 7ad9432b-bb4f-4cc1-b842-1e63a323a3b5 | cluster-7n7w9-worker-zpq85                   | ACTIVE | cluster-7n7w9-openshift=172.31.0.14                                      | cluster-7n7w9-rhcos                    | m1.openshift |
| dc4db4f7-d410-4404-9166-66204931538c | cluster-7n7w9-master-1                       | ACTIVE | cluster-7n7w9-openshift=172.31.0.15                                      | cluster-7n7w9-rhcos                    | m1.openshift |
| e0e3a4cd-4d1e-4496-9e59-ba8c0d62b54a | cluster-7n7w9-master-2                       | ACTIVE | cluster-7n7w9-openshift=172.31.0.23                                      | cluster-7n7w9-rhcos                    | m1.openshift |
| 1b76ade6-ad53-43c8-9f15-fd3d550e0a17 | cluster-7n7w9-master-0                       | ACTIVE | cluster-7n7w9-openshift=172.31.0.39                                      | cluster-7n7w9-rhcos                    | m1.openshift |
| 43810d22-74ce-4f5a-a615-d77d1628dde7 | rhel-test1                                   | ACTIVE | private1=2000:192:168:0:f816:3eff:fea4:39e1, 192.168.0.108, 172.16.0.208 | rhel                                   | m1.small     |
+--------------------------------------+----------------------------------------------+--------+--------------------------------------------------------------------------+----------------------------------------+--------------+

(overcloud) [stack@undercloud-0 ~]$  # openstack loadbalancer create --name ingress-controller-default --vip-subnet-id 
(overcloud) [stack@undercloud-0 ~]$ openstack subnet list
+--------------------------------------+---------------------------------------------------+--------------------------------------+----------------------+
| ID                                   | Name                                              | Network                              | Subnet               |
+--------------------------------------+---------------------------------------------------+--------------------------------------+----------------------+
| 14a3bd37-7a3a-4f14-bd03-26d4860d91db | provider1-subnet                                  | d14c0815-22b5-4cdf-9db1-5da7951f1e0a | 172.16.0.0/24        |
| 5aef701a-c93f-4210-8722-3fdf8ef1ddf1 | provider1-ipv6-subnet                             | d14c0815-22b5-4cdf-9db1-5da7951f1e0a | 2000:10::/64         |
| 63950c5e-fc70-49ad-8d6b-092b8ba39016 | cluster-7n7w9-nodes                               | ac9c0bd9-3793-48d3-a12e-eaa06028a366 | 172.31.0.0/16        |
| 7f65d115-8077-4219-9ef8-3b0820ba8b52 | private1-ipv6-subnet                              | 0af094e6-1dac-4479-9ebc-88f8f7f0b254 | 2000:192:168::/64    |
| 9fa85591-718c-4fb9-88d8-0c2e5b0771ee | private1-subnet                                   | 0af094e6-1dac-4479-9ebc-88f8f7f0b254 | 192.168.0.0/24       |
| a0827588-7460-4f2f-9f29-12bb1be49c76 | lb-mgmt-subnet                                    | 85cd5be1-3d8b-4929-b9ac-2e770cb12ba9 | 172.24.0.0/16        |
| a5e9841d-38a7-47a0-8db2-f302a67a9845 | private2-subnet                                   | fdb07e70-7055-41a9-a8fa-10b2dce988b3 | 192.168.1.0/24       |
| af925c70-979e-4fa9-8704-72ec683a31f8 | private-mgmt-ipv6-subnet                          | 0d74f260-c3d6-4a77-8881-438c3bfaaa7b | 2000:192:168:10::/64 |
| c815a934-98ff-4daa-8b5e-5a0e5d91806f | private2-ipv6-subnet                              | fdb07e70-7055-41a9-a8fa-10b2dce988b3 | 2000:192:168:1::/64  |
| df05dd9e-6583-42a0-afee-e8f65d813e6f | private-mgmt-subnet                               | 0d74f260-c3d6-4a77-8881-438c3bfaaa7b | 192.168.10.0/24      |
| e1ebbac2-3d7c-4355-9624-f0920d705f76 | HA subnet tenant a416f556938f454f849da42faa317cd3 | 5079d963-7301-4218-855b-f7d33fce1081 | 169.254.192.0/18     |
+--------------------------------------+---------------------------------------------------+--------------------------------------+----------------------+
(overcloud) [stack@undercloud-0 ~]$ openstack loadbalancer create --name ingress-controller-default --vip-subnet-id cluster-7n7w9-nodes
+---------------------+--------------------------------------+
| Field               | Value                                |
+---------------------+--------------------------------------+
| admin_state_up      | True                                 |
| created_at          | 2020-04-08T10:27:46                  |
| description         |                                      |
| flavor              |                                      |
| id                  | e5feb42d-77e4-428b-9ad0-55fe6d30f3b3 |
| listeners           |                                      |
| name                | ingress-controller-default           |
| operating_status    | OFFLINE                              |
| pools               |                                      |
| project_id          | a416f556938f454f849da42faa317cd3     |
| provider            | octavia                              |
| provisioning_status | PENDING_CREATE                       |
| updated_at          | None                                 |
| vip_address         | 172.31.0.21                          |
| vip_network_id      | ac9c0bd9-3793-48d3-a12e-eaa06028a366 |
| vip_port_id         | f336d8c6-8f47-4d61-a865-19f34a671ffa |
| vip_qos_policy_id   | None                                 |
| vip_subnet_id       | 63950c5e-fc70-49ad-8d6b-092b8ba39016 |
+---------------------+--------------------------------------+
(overcloud) [stack@undercloud-0 ~]$ openstack loadbalancer create --name ingress-controller-test1 --vip-subnet-id cluster-7n7w9-nodes
+---------------------+--------------------------------------+
| Field               | Value                                |
+---------------------+--------------------------------------+
| admin_state_up      | True                                 |
| created_at          | 2020-04-08T10:28:33                  |
| description         |                                      |
| flavor              |                                      |
| id                  | a636c15a-92a2-4253-8945-8875c58aae96 |
| listeners           |                                      |
| name                | ingress-controller-test1             |
| operating_status    | OFFLINE                              |
| pools               |                                      |
| project_id          | a416f556938f454f849da42faa317cd3     |
| provider            | octavia                              |
| provisioning_status | PENDING_CREATE                       |
| updated_at          | None                                 |
| vip_address         | 172.31.0.24                          |
| vip_network_id      | ac9c0bd9-3793-48d3-a12e-eaa06028a366 |
| vip_port_id         | 7d85d059-65c2-47af-90a2-35337d4396f8 |
| vip_qos_policy_id   | None                                 |
| vip_subnet_id       | 63950c5e-fc70-49ad-8d6b-092b8ba39016 |
+---------------------+--------------------------------------+
(overcloud) [stack@undercloud-0 ~]$ openstack loadbalancer create --name ingress-controller-test2 --vip-subnet-id cluster-7n7w9-nodes
+---------------------+--------------------------------------+
| Field               | Value                                |
+---------------------+--------------------------------------+
| admin_state_up      | True                                 |
| created_at          | 2020-04-08T10:28:44                  |
| description         |                                      |
| flavor              |                                      |
| id                  | c2041396-66f5-4726-ad47-9ce7d2f7904f |
| listeners           |                                      |
| name                | ingress-controller-test2             |
| operating_status    | OFFLINE                              |
| pools               |                                      |
| project_id          | a416f556938f454f849da42faa317cd3     |
| provider            | octavia                              |
| provisioning_status | PENDING_CREATE                       |
| updated_at          | None                                 |
| vip_address         | 172.31.0.27                          |
| vip_network_id      | ac9c0bd9-3793-48d3-a12e-eaa06028a366 |
| vip_port_id         | ce0129ca-9b39-4ee1-8d12-bb0685967f65 |
| vip_qos_policy_id   | None                                 |
| vip_subnet_id       | 63950c5e-fc70-49ad-8d6b-092b8ba39016 |
+---------------------+--------------------------------------+

# wait until all loadbalancers are active

(overcloud) [stack@undercloud-0 ~]$ watch openstack loadbalancer list
(overcloud) [stack@undercloud-0 ~]$ openstack loadbalancer list
+--------------------------------------+----------------------------+----------------------------------+-------------+---------------------+----------+
| id                                   | name                       | project_id                       | vip_address | provisioning_status | provider |
+--------------------------------------+----------------------------+----------------------------------+-------------+---------------------+----------+
| e5feb42d-77e4-428b-9ad0-55fe6d30f3b3 | ingress-controller-default | a416f556938f454f849da42faa317cd3 | 172.31.0.21 | ACTIVE              | octavia  |
| a636c15a-92a2-4253-8945-8875c58aae96 | ingress-controller-test1   | a416f556938f454f849da42faa317cd3 | 172.31.0.24 | ACTIVE              | octavia  |
| c2041396-66f5-4726-ad47-9ce7d2f7904f | ingress-controller-test2   | a416f556938f454f849da42faa317cd3 | 172.31.0.27 | ACTIVE              | octavia  |
+--------------------------------------+----------------------------+----------------------------------+-------------+---------------------+----------+
(overcloud) [stack@undercloud-0 ~]$ openstack loadbalancer listener create --name ingress-controller-default-listener --protocol HTTP --protocol-port 80 ingress-controller-default
+---------------------------+--------------------------------------+
| Field                     | Value                                |
+---------------------------+--------------------------------------+
| admin_state_up            | True                                 |
| connection_limit          | -1                                   |
| created_at                | 2020-04-08T11:00:01                  |
| default_pool_id           | None                                 |
| default_tls_container_ref | None                                 |
| description               |                                      |
| id                        | be0d73e6-1162-4363-ad62-0d74e2c16f6b |
| insert_headers            | None                                 |
| l7policies                |                                      |
| loadbalancers             | e5feb42d-77e4-428b-9ad0-55fe6d30f3b3 |
| name                      | ingress-controller-default-listener  |
| operating_status          | OFFLINE                              |
| project_id                | a416f556938f454f849da42faa317cd3     |
| protocol                  | HTTP                                 |
| protocol_port             | 80                                   |
| provisioning_status       | PENDING_CREATE                       |
| sni_container_refs        | []                                   |
| updated_at                | None                                 |
+---------------------------+--------------------------------------+
(overcloud) [stack@undercloud-0 ~]$ openstack loadbalancer pool create --name ingress-controller-default-pool --lb-algorithm ROUND_ROBIN --listener ingress-controller-default-listener --protocol HTTP
+---------------------+--------------------------------------+
| Field               | Value                                |
+---------------------+--------------------------------------+
| admin_state_up      | True                                 |
| created_at          | 2020-04-08T11:00:13                  |
| description         |                                      |
| healthmonitor_id    |                                      |
| id                  | 47dc4567-f182-4c16-a2ec-aa306e40779d |
| lb_algorithm        | ROUND_ROBIN                          |
| listeners           | be0d73e6-1162-4363-ad62-0d74e2c16f6b |
| loadbalancers       | e5feb42d-77e4-428b-9ad0-55fe6d30f3b3 |
| members             |                                      |
| name                | ingress-controller-default-pool      |
| operating_status    | OFFLINE                              |
| project_id          | a416f556938f454f849da42faa317cd3     |
| protocol            | HTTP                                 |
| provisioning_status | PENDING_CREATE                       |
| session_persistence | None                                 |
| updated_at          | None                                 |
+---------------------+--------------------------------------+
(overcloud) [stack@undercloud-0 ~]$ openstack loadbalancer member create --subnet-id cluster-7n7w9-nodes --address 172.31.0.45 --protocol-port 80 ingress-controller-default-pool
+---------------------+--------------------------------------+
| Field               | Value                                |
+---------------------+--------------------------------------+
| address             | 172.31.0.45                          |
| admin_state_up      | True                                 |
| created_at          | 2020-04-08T11:02:06                  |
| id                  | 431aa74f-e98d-41fd-aab9-bf907f1e3993 |
| name                |                                      |
| operating_status    | NO_MONITOR                           |
| project_id          | a416f556938f454f849da42faa317cd3     |
| protocol_port       | 80                                   |
| provisioning_status | PENDING_CREATE                       |
| subnet_id           | 63950c5e-fc70-49ad-8d6b-092b8ba39016 |
| updated_at          | None                                 |
| weight              | 1                                    |
| monitor_port        | None                                 |
| monitor_address     | None                                 |
+---------------------+--------------------------------------+
(overcloud) [stack@undercloud-0 ~]$ openstack floating ip create provider1
+---------------------+--------------------------------------+
| Field               | Value                                |
+---------------------+--------------------------------------+
| created_at          | 2020-04-08T11:02:34Z                 |
| description         |                                      |
| fixed_ip_address    | None                                 |
| floating_ip_address | 172.16.0.211                         |
| floating_network_id | d14c0815-22b5-4cdf-9db1-5da7951f1e0a |
| id                  | 44720e51-dc95-453b-9993-1cac1fbf40b9 |
| name                | 172.16.0.211                         |
| port_id             | None                                 |
| project_id          | a416f556938f454f849da42faa317cd3     |
| qos_policy_id       | None                                 |
| revision_number     | 0                                    |
| router_id           | None                                 |
| status              | DOWN                                 |
| subnet_id           | None                                 |
| updated_at          | 2020-04-08T11:02:34Z                 |
+---------------------+--------------------------------------+
oad(overcloud) [stack@undercloud-0 ~]$ openstack loadbalancer list
+--------------------------------------+----------------------------+----------------------------------+-------------+---------------------+----------+
| id                                   | name                       | project_id                       | vip_address | provisioning_status | provider |
+--------------------------------------+----------------------------+----------------------------------+-------------+---------------------+----------+
| e5feb42d-77e4-428b-9ad0-55fe6d30f3b3 | ingress-controller-default | a416f556938f454f849da42faa317cd3 | 172.31.0.21 | ACTIVE              | octavia  |
| a636c15a-92a2-4253-8945-8875c58aae96 | ingress-controller-test1   | a416f556938f454f849da42faa317cd3 | 172.31.0.24 | ACTIVE              | octavia  |
| c2041396-66f5-4726-ad47-9ce7d2f7904f | ingress-controller-test2   | a416f556938f454f849da42faa317cd3 | 172.31.0.27 | ACTIVE              | octavia  |
+--------------------------------------+----------------------------+----------------------------------+-------------+---------------------+----------+
(overcloud) [stack@undercloud-0 ~]$ openstack loadbalancer listener create --name ingress-controller-test1-listener --protocol HTTP --protocol-port 80 ingress-controller-test1
+---------------------------+--------------------------------------+
| Field                     | Value                                |
+---------------------------+--------------------------------------+
| admin_state_up            | True                                 |
| connection_limit          | -1                                   |
| created_at                | 2020-04-08T11:03:33                  |
| default_pool_id           | None                                 |
| default_tls_container_ref | None                                 |
| description               |                                      |
| id                        | 9e7236f5-cb15-4c8c-8ffb-a00182c44871 |
| insert_headers            | None                                 |
| l7policies                |                                      |
| loadbalancers             | a636c15a-92a2-4253-8945-8875c58aae96 |
| name                      | ingress-controller-test1-listener    |
| operating_status          | OFFLINE                              |
| project_id                | a416f556938f454f849da42faa317cd3     |
| protocol                  | HTTP                                 |
| protocol_port             | 80                                   |
| provisioning_status       | PENDING_CREATE                       |
| sni_container_refs        | []                                   |
| updated_at                | None                                 |
+---------------------------+--------------------------------------+
(overcloud) [stack@undercloud-0 ~]$ openstack loadbalancer listener create --name ingress-controller-test2-listener --protocol HTTP --protocol-port 80 ingress-controller-test2
+---------------------------+--------------------------------------+
| Field                     | Value                                |
+---------------------------+--------------------------------------+
| admin_state_up            | True                                 |
| connection_limit          | -1                                   |
| created_at                | 2020-04-08T11:03:42                  |
| default_pool_id           | None                                 |
| default_tls_container_ref | None                                 |
| description               |                                      |
| id                        | 0cd99fe3-3750-4506-bafa-57cf4a15c7e8 |
| insert_headers            | None                                 |
| l7policies                |                                      |
| loadbalancers             | c2041396-66f5-4726-ad47-9ce7d2f7904f |
| name                      | ingress-controller-test2-listener    |
| operating_status          | OFFLINE                              |
| project_id                | a416f556938f454f849da42faa317cd3     |
| protocol                  | HTTP                                 |
| protocol_port             | 80                                   |
| provisioning_status       | PENDING_CREATE                       |
| sni_container_refs        | []                                   |
| updated_at                | None                                 |
+---------------------------+--------------------------------------+
(overcloud) [stack@undercloud-0 ~]$ openstack loadbalancer pool create --name ingress-controller-test1-pool --lb-algorithm ROUND_ROBIN --listener ingress-controller-test1-listener --protocol HTTP
+---------------------+--------------------------------------+
| Field               | Value                                |
+---------------------+--------------------------------------+
| admin_state_up      | True                                 |
| created_at          | 2020-04-08T11:04:00                  |
| description         |                                      |
| healthmonitor_id    |                                      |
| id                  | d7e93f06-3afd-467d-b43a-4018e59d6be1 |
| lb_algorithm        | ROUND_ROBIN                          |
| listeners           | 9e7236f5-cb15-4c8c-8ffb-a00182c44871 |
| loadbalancers       | a636c15a-92a2-4253-8945-8875c58aae96 |
| members             |                                      |
| name                | ingress-controller-test1-pool        |
| operating_status    | OFFLINE                              |
| project_id          | a416f556938f454f849da42faa317cd3     |
| protocol            | HTTP                                 |
| provisioning_status | PENDING_CREATE                       |
| session_persistence | None                                 |
| updated_at          | None                                 |
+---------------------+--------------------------------------+
(overcloud) [stack@undercloud-0 ~]$ openstack loadbalancer pool create --name ingress-controller-test2-pool --lb-algorithm ROUND_ROBIN --listener ingress-controller-test2-listener --protocol HTTP
+---------------------+--------------------------------------+
| Field               | Value                                |
+---------------------+--------------------------------------+
| admin_state_up      | True                                 |
| created_at          | 2020-04-08T11:04:10                  |
| description         |                                      |
| healthmonitor_id    |                                      |
| id                  | c6a4c5dd-836f-42fe-91bf-5a71d3109691 |
| lb_algorithm        | ROUND_ROBIN                          |
| listeners           | 0cd99fe3-3750-4506-bafa-57cf4a15c7e8 |
| loadbalancers       | c2041396-66f5-4726-ad47-9ce7d2f7904f |
| members             |                                      |
| name                | ingress-controller-test2-pool        |
| operating_status    | OFFLINE                              |
| project_id          | a416f556938f454f849da42faa317cd3     |
| protocol            | HTTP                                 |
| provisioning_status | PENDING_CREATE                       |
| session_persistence | None                                 |
| updated_at          | None                                 |
+---------------------+--------------------------------------+
(overcloud) [stack@undercloud-0 ~]$ openstack loadbalancer member create --subnet-id cluster-7n7w9-nodes --address 172.31.0.13 --protocol-port 80 ingress-controller-test1-pool
+---------------------+--------------------------------------+
| Field               | Value                                |
+---------------------+--------------------------------------+
| address             | 172.31.0.13                          |
| admin_state_up      | True                                 |
| created_at          | 2020-04-08T11:05:02                  |
| id                  | 584a9a8b-eb1c-41b4-9308-0a1cd9f91122 |
| name                |                                      |
| operating_status    | NO_MONITOR                           |
| project_id          | a416f556938f454f849da42faa317cd3     |
| protocol_port       | 80                                   |
| provisioning_status | PENDING_CREATE                       |
| subnet_id           | 63950c5e-fc70-49ad-8d6b-092b8ba39016 |
| updated_at          | None                                 |
| weight              | 1                                    |
| monitor_port        | None                                 |
| monitor_address     | None                                 |
+---------------------+--------------------------------------+
(overcloud) [stack@undercloud-0 ~]$ openstack loadbalancer member create --subnet-id cluster-7n7w9-nodes --address 172.31.0.14 --protocol-port 80 ingress-controller-test2-pool
openstack floating ip creat+---------------------+--------------------------------------+
| Field               | Value                                |
+---------------------+--------------------------------------+
| address             | 172.31.0.14                          |
| admin_state_up      | True                                 |
| created_at          | 2020-04-08T11:05:14                  |
| id                  | 8d859649-fcc1-4ffe-b9be-0ed6540346e1 |
| name                |                                      |
| operating_status    | NO_MONITOR                           |
| project_id          | a416f556938f454f849da42faa317cd3     |
| protocol_port       | 80                                   |
| provisioning_status | PENDING_CREATE                       |
| subnet_id           | 63950c5e-fc70-49ad-8d6b-092b8ba39016 |
| updated_at          | None                                 |
| weight              | 1                                    |
| monitor_port        | None                                 |
| monitor_address     | None                                 |
+---------------------+--------------------------------------+
(overcloud) [stack@undercloud-0 ~]$ openstack floating ip create provider1
o[+---------------------+--------------------------------------+
| Field               | Value                                |
+---------------------+--------------------------------------+
| created_at          | 2020-04-08T11:05:27Z                 |
| description         |                                      |
| fixed_ip_address    | None                                 |
| floating_ip_address | 172.16.0.204                         |
| floating_network_id | d14c0815-22b5-4cdf-9db1-5da7951f1e0a |
| id                  | 72181227-12f0-4790-bd7c-208785e05918 |
| name                | 172.16.0.204                         |
| port_id             | None                                 |
| project_id          | a416f556938f454f849da42faa317cd3     |
| qos_policy_id       | None                                 |
| revision_number     | 0                                    |
| router_id           | None                                 |
| status              | DOWN                                 |
| subnet_id           | None                                 |
| updated_at          | 2020-04-08T11:05:27Z                 |
+---------------------+--------------------------------------+
(overcloud) [stack@undercloud-0 ~]$ openstack loadbalancer list
openstack floating ip +--------------------------------------+----------------------------+----------------------------------+-------------+---------------------+----------+
| id                                   | name                       | project_id                       | vip_address | provisioning_status | provider |
+--------------------------------------+----------------------------+----------------------------------+-------------+---------------------+----------+
| e5feb42d-77e4-428b-9ad0-55fe6d30f3b3 | ingress-controller-default | a416f556938f454f849da42faa317cd3 | 172.31.0.21 | ACTIVE              | octavia  |
| a636c15a-92a2-4253-8945-8875c58aae96 | ingress-controller-test1   | a416f556938f454f849da42faa317cd3 | 172.31.0.24 | ACTIVE              | octavia  |
| c2041396-66f5-4726-ad47-9ce7d2f7904f | ingress-controller-test2   | a416f556938f454f849da42faa317cd3 | 172.31.0.27 | ACTIVE              | octavia  |
+--------------------------------------+----------------------------+----------------------------------+-------------+---------------------+----------+
l(overcloud) [stack@undercloud-0 ~]$ openstack floating ip list
+--------------------------------------+---------------------+------------------+--------------------------------------+--------------------------------------+----------------------------------+
| ID                                   | Floating IP Address | Fixed IP Address | Port                                 | Floating Network                     | Project                          |
+--------------------------------------+---------------------+------------------+--------------------------------------+--------------------------------------+----------------------------------+
| 0a3e9fa7-577c-47f9-b9e4-f583bd3ce180 | 172.16.0.208        | 192.168.0.108    | 03d91ec5-8de6-415b-9581-d00501bb40ed | d14c0815-22b5-4cdf-9db1-5da7951f1e0a | a416f556938f454f849da42faa317cd3 |
| 44720e51-dc95-453b-9993-1cac1fbf40b9 | 172.16.0.211        | None             | None                                 | d14c0815-22b5-4cdf-9db1-5da7951f1e0a | a416f556938f454f849da42faa317cd3 |
| 497c6667-22b3-4ed7-b6af-1c5091b14209 | 172.16.0.213        | 172.31.0.5       | 3bc4d5e1-90c9-4da1-86cd-d5e5d6fe985d | d14c0815-22b5-4cdf-9db1-5da7951f1e0a | a416f556938f454f849da42faa317cd3 |
| 4b9e9daf-4e7f-4338-ad70-6206e7e56367 | 172.16.0.214        | 172.31.0.7       | ee68b77c-95af-4bb2-ba62-c4d06d728c47 | d14c0815-22b5-4cdf-9db1-5da7951f1e0a | a416f556938f454f849da42faa317cd3 |
| 72181227-12f0-4790-bd7c-208785e05918 | 172.16.0.204        | None             | None                                 | d14c0815-22b5-4cdf-9db1-5da7951f1e0a | a416f556938f454f849da42faa317cd3 |
| a2693cfc-4379-4d9b-bb90-a86c3fcafd9c | 172.16.0.217        | None             | None                                 | d14c0815-22b5-4cdf-9db1-5da7951f1e0a | a416f556938f454f849da42faa317cd3 |
+--------------------------------------+---------------------+------------------+--------------------------------------+--------------------------------------+----------------------------------+
(overcloud) [stack@undercloud-0 ~]$ openstack port list | grep 172.31.0.21
| f336d8c6-8f47-4d61-a865-19f34a671ffa | octavia-lb-e5feb42d-77e4-428b-9ad0-55fe6d30f3b3                       | fa:16:3e:f1:04:50 | ip_address='172.31.0.21', subnet_id='63950c5e-fc70-49ad-8d6b-092b8ba39016'                         | DOWN   |
(overcloud) [stack@undercloud-0 ~]$ openstack port list | grep 172.31.0.24
| 7d85d059-65c2-47af-90a2-35337d4396f8 | octavia-lb-a636c15a-92a2-4253-8945-8875c58aae96                       | fa:16:3e:8c:32:69 | ip_address='172.31.0.24', subnet_id='63950c5e-fc70-49ad-8d6b-092b8ba39016'                         | DOWN   |
(overcloud) [stack@undercloud-0 ~]$ openstack port list | grep 172.31.0.27
| ce0129ca-9b39-4ee1-8d12-bb0685967f65 | octavia-lb-c2041396-66f5-4726-ad47-9ce7d2f7904f                       | fa:16:3e:e0:d7:bd | ip_address='172.31.0.27', subnet_id='63950c5e-fc70-49ad-8d6b-092b8ba39016'                         | DOWN   |
(overcloud) [stack@undercloud-0 ~]$ openstack floating ip set 172.16.0.211 --port octavia-lb-e5feb42d-77e4-428b-9ad0-55fe6d30f3b3
(overcloud) [stack@undercloud-0 ~]$ openstack floating ip set 172.16.0.204 --port octavia-lb-a636c15a-92a2-4253-8945-8875c58aae96
(overcloud) [stack@undercloud-0 ~]$ openstack floating ip set 172.16.0.217 --port octavia-lb-c2041396-66f5-4726-ad47-9ce7d2f7904f
(overcloud) [stack@undercloud-0 ~]$ openstack loadbalancer member list ingress-controller-default-pool
+--------------------------------------+------+----------------------------------+---------------------+-------------+---------------+------------------+--------+
| id                                   | name | project_id                       | provisioning_status | address     | protocol_port | operating_status | weight |
+--------------------------------------+------+----------------------------------+---------------------+-------------+---------------+------------------+--------+
| 431aa74f-e98d-41fd-aab9-bf907f1e3993 |      | a416f556938f454f849da42faa317cd3 | ACTIVE              | 172.31.0.45 |            80 | NO_MONITOR       |      1 |
+--------------------------------------+------+----------------------------------+---------------------+-------------+---------------+------------------+--------+
(overcloud) [stack@undercloud-0 ~]$ curl ^C
~~~

Once this is done, update your DNS entries. In this lab case, I'm simply changing `/etc/hosts`:
~~~
(overcloud) [stack@undercloud-0 ~]$ cat /etc/hosts
127.0.0.1   undercloud-0.redhat.local undercloud-0
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

# API cluster VIP
172.16.0.213 api.cluster.example.com

# original VIP
# 172.16.0.214 oauth-openshift.apps.cluster.example.com console-openshift-console.apps.cluster.example.com downloads-openshift-console.apps.cluster.example.com alertmanager-main-openshift-monitoring.apps.cluster.example.com grafana-openshift-monitoring.apps.cluster.example.com prometheus-k8s-openshift-monitoring.apps.cluster.example.com thanos-querier-openshift-monitoring.apps.cluster.example.com fh.apps.cluster.example.com fh.test2.cluster.example.com fh.test1.cluster.example.com

# new Octavia VIPs
172.16.0.211 oauth-openshift.apps.cluster.example.com console-openshift-console.apps.cluster.example.com downloads-openshift-console.apps.cluster.example.com alertmanager-main-openshift-monitoring.apps.cluster.example.com grafana-openshift-monitoring.apps.cluster.example.com prometheus-k8s-openshift-monitoring.apps.cluster.example.com thanos-querier-openshift-monitoring.apps.cluster.example.com fh.apps.cluster.example.com
172.16.0.204 fh.test1.cluster.example.com
172.16.0.217 fh.test2.cluster.example.com
~~~

### Testing ###

This should now work:
~~~
(overcloud) [stack@undercloud-0 ~]$ curl fh.apps.cluster.example.com
Apache default
(overcloud) [stack@undercloud-0 ~]$ curl fh.test1.cluster.example.com
Apache test1
(overcloud) [stack@undercloud-0 ~]$ curl fh.test2.cluster.example.com
Apache test2
~~~
