~~~
(overcloud) [stack@undercloud-0 clouds]$ oc describe machine -n openshift-machine-api osc-c5r5c-worker-bgt9b
Name:         osc-c5r5c-worker-bgt9b
Namespace:    openshift-machine-api
Labels:       machine.openshift.io/cluster-api-cluster=osc-c5r5c
              machine.openshift.io/cluster-api-machine-role=worker
              machine.openshift.io/cluster-api-machine-type=worker
              machine.openshift.io/cluster-api-machineset=osc-c5r5c-worker
Annotations:  <none>
API Version:  machine.openshift.io/v1beta1
Kind:         Machine
Metadata:
  Creation Timestamp:  2019-12-20T10:23:14Z
  Finalizers:
    machine.machine.openshift.io
  Generate Name:  osc-c5r5c-worker-
  Generation:     1
  Owner References:
    API Version:           machine.openshift.io/v1beta1
    Block Owner Deletion:  true
    Controller:            true
    Kind:                  MachineSet
    Name:                  osc-c5r5c-worker
    UID:                   9077b6df-2312-11ea-9b6c-fa163e431263
  Resource Version:        3455
  Self Link:               /apis/machine.openshift.io/v1beta1/namespaces/openshift-machine-api/machines/osc-c5r5c-worker-bgt9b
  UID:                     bb0af782-2312-11ea-9b6c-fa163e431263
Spec:
  Metadata:
    Creation Timestamp:  <nil>
  Provider Spec:
    Value:
      API Version:  openstackproviderconfig.openshift.io/v1alpha1
      Cloud Name:   openstack
      Clouds Secret:
        Name:       openstack-cloud-credentials
        Namespace:  openshift-machine-api
      Flavor:       m1.openshift
      Image:        rhcos
      Kind:         OpenstackProviderSpec
      Metadata:
        Creation Timestamp:  <nil>
      Networks:
        Filter:
        Subnets:
          Filter:
            Name:  osc-c5r5c-nodes
            Tags:  openshiftClusterID=osc-c5r5c
      Security Groups:
        Filter:
        Name:  osc-c5r5c-worker
      Server Metadata:
        Name:                  osc-c5r5c-worker
        Openshift Cluster ID:  osc-c5r5c
      Tags:
        openshiftClusterID=osc-c5r5c
      Trunk:  true
      User Data Secret:
        Name:  worker-user-data
Events:        <none>
(overcloud) [stack@undercloud-0 clouds]$ oc get machine -n openshift-machine-api 
NAME                     STATE   TYPE   REGION   ZONE   AGE
osc-c5r5c-master-0                                      4h52m
osc-c5r5c-master-1                                      4h52m
osc-c5r5c-master-2                                      4h52m
osc-c5r5c-worker-bgt9b                                  4h51m
osc-c5r5c-worker-qphk7                                  4h51m
osc-c5r5c-worker-vs85h                                  4h51m
(overcloud) [stack@undercloud-0 clouds]$ oc get machineset -n openshift-machine-api 
NAME               DESIRED   CURRENT   READY   AVAILABLE   AGE
osc-c5r5c-worker   3         3                             4h54m
(overcloud) [stack@undercloud-0 clouds]$ 
~~~

~~~
(overcloud) [stack@undercloud-0 clouds]$ kubectl get machineset -n openshift-machine-api osc-c5r5c-worker -o yaml
apiVersion: machine.openshift.io/v1beta1
kind: MachineSet
metadata:
  creationTimestamp: "2019-12-20T10:22:02Z"
  generation: 1
  labels:
    machine.openshift.io/cluster-api-cluster: osc-c5r5c
    machine.openshift.io/cluster-api-machine-role: worker
    machine.openshift.io/cluster-api-machine-type: worker
  name: osc-c5r5c-worker
  namespace: openshift-machine-api
  resourceVersion: "3448"
  selfLink: /apis/machine.openshift.io/v1beta1/namespaces/openshift-machine-api/machinesets/osc-c5r5c-worker
  uid: 9077b6df-2312-11ea-9b6c-fa163e431263
spec:
  replicas: 3
  selector:
    matchLabels:
      machine.openshift.io/cluster-api-cluster: osc-c5r5c
      machine.openshift.io/cluster-api-machineset: osc-c5r5c-worker
  template:
    metadata:
      creationTimestamp: null
      labels:
        machine.openshift.io/cluster-api-cluster: osc-c5r5c
        machine.openshift.io/cluster-api-machine-role: worker
        machine.openshift.io/cluster-api-machine-type: worker
        machine.openshift.io/cluster-api-machineset: osc-c5r5c-worker
    spec:
      metadata:
        creationTimestamp: null
      providerSpec:
        value:
          apiVersion: openstackproviderconfig.openshift.io/v1alpha1
          cloudName: openstack
          cloudsSecret:
            name: openstack-cloud-credentials
            namespace: openshift-machine-api
          flavor: m1.openshift
          image: rhcos
          kind: OpenstackProviderSpec
          metadata:
            creationTimestamp: null
          networks:
          - filter: {}
            subnets:
            - filter:
                name: osc-c5r5c-nodes
                tags: openshiftClusterID=osc-c5r5c
          securityGroups:
          - filter: {}
            name: osc-c5r5c-worker
          serverMetadata:
            Name: osc-c5r5c-worker
            openshiftClusterID: osc-c5r5c
          tags:
          - openshiftClusterID=osc-c5r5c
          trunk: true
          userDataSecret:
            name: worker-user-data
status:
  fullyLabeledReplicas: 3
  observedGeneration: 1
  replicas: 3
~~~

~~~
/var/log/pods/openshift-machine-api_machine-api-controllers-f64b7f7b8-tm7qc_b1f05af2-2312-11ea-9b6c-fa163e431263/machine-controller/0.log
(...)
2019-12-20T10:23:14.635223358+00:00 stderr F E1220 10:23:14.635191       1 controller.go:239] Failed to check if machine "osc-c5r5c-worker-bgt9b" exists: Error checking if instance exists (machine/actuator.go 346): 
2019-12-20T10:23:14.635223358+00:00 stderr F Error getting a new instance service from the machine (machine/actuator.go 467): Create providerClient err: You must provide exactly one of DomainID or DomainName in a Scope with ProjectName
2019-12-20T10:23:15.636135623+00:00 stderr F I1220 10:23:15.635874       1 controller.go:133] Reconciling Machine "osc-c5r5c-master-0"
2019-12-20T10:23:15.636215058+00:00 stderr F I1220 10:23:15.636192       1 controller.go:304] Machine "osc-c5r5c-master-0" in namespace "openshift-machine-api" doesn't specify "cluster.k8s.io/cluster-name" label, assuming nil cluster
2019-12-20T10:23:15.641348382+00:00 stderr F E1220 10:23:15.641317       1 controller.go:239] Failed to check if machine "osc-c5r5c-master-0" exists: Error checking if instance exists (machine/actuator.go 346): 
2019-12-20T10:23:15.641348382+00:00 stderr F Error getting a new instance service from the machine (machine/actuator.go 467): Create providerClient err: You must provide exactly one of DomainID or DomainName in a Scope with ProjectName
2019-12-20T10:23:16.641614350+00:00 stderr F I1220 10:23:16.641562       1 controller.go:133] Reconciling Machine "osc-c5r5c-master-1"
2019-12-20T10:23:16.641614350+00:00 stderr F I1220 10:23:16.641591       1 controller.go:304] Machine "osc-c5r5c-master-1" in namespace "openshift-machine-api" doesn't specify "cluster.k8s.io/cluster-name" label, assuming nil cluster
2019-12-20T10:23:16.647323379+00:00 stderr F E1220 10:23:16.647295       1 controller.go:239] Failed to check if machine "osc-c5r5c-master-1" exists: Error checking if instance exists (machine/actuator.go 346): 
2019-12-20T10:23:16.647323379+00:00 stderr F Error getting a new instance service from the machine (machine/actuator.go 467): Create providerClient err: You must provide exactly one of DomainID or DomainName in a Scope with ProjectName
2019-12-20T10:23:17.647630531+00:00 stderr F I1220 10:23:17.647587       1 controller.go:133] Reconciling Machine "osc-c5r5c-master-2"
2019-12-20T10:23:17.647695173+00:00 stderr F I1220 10:23:17.647677       1 controller.go:304] Machine "osc-c5r5c-master-2" in namespace "openshift-machine-api" doesn't specify "cluster.k8s.io/cluster-name" label, assuming nil cluster
2019-12-20T10:23:17.652613228+00:00 stderr F E1220 10:23:17.652551       1 controller.go:239] Failed to check if machine "osc-c5r5c-master-2" exists: Error checking if instance exists (machine/actuator.go 346): 
2019-12-20T10:23:17.652613228+00:00 stderr F Error getting a new instance service from the machine (machine/actuator.go 467): Create providerClient err: You must provide exactly one of DomainID or DomainName in a Scope with ProjectName
2019-12-20T10:23:18.652945792+00:00 stderr F I1220 10:23:18.652884       1 controller.go:133] Reconciling Machine "osc-c5r5c-worker-qphk7"
~~~

Looking at the secret:
~~~
(overcloud) [stack@undercloud-0 clouds]$ kubectl get secrets -n openshift-machine-api openstack-cloud-credentials -o yaml
apiVersion: v1
data:
  clouds.yaml: Y2xvdWRzOgogIG9wZW5zdGFjazoKICAgIGF1dGg6CiAgICAgIGFwcGxpY2F0aW9uX2NyZWRlbnRpYWxfaWQ6ICIiCiAgICAgIGFwcGxpY2F0aW9uX2NyZWRlbnRpYWxfbmFtZTogIiIKICAgICAgYXBwbGljYXRpb25fY3JlZGVudGlhbF9zZWNyZXQ6ICIiCiAgICAgIGF1dGhfdXJsOiBodHRwOi8vMTcyLjE2LjAuMTMwOjUwMDAvL3YzCiAgICAgIGRlZmF1bHRfZG9tYWluOiAiIgogICAgICBkb21haW5faWQ6ICIiCiAgICAgIGRvbWFpbl9uYW1lOiAiIgogICAgICBwYXNzd29yZDogelA0YmUydWtocENrajR6cVJmVWs4WGpRYgogICAgICBwcm9qZWN0X2RvbWFpbl9pZDogIiIKICAgICAgcHJvamVjdF9kb21haW5fbmFtZTogIiIKICAgICAgcHJvamVjdF9pZDogIiIKICAgICAgcHJvamVjdF9uYW1lOiBhZG1pbgogICAgICB0b2tlbjogIiIKICAgICAgdXNlcl9kb21haW5faWQ6ICIiCiAgICAgIHVzZXJfZG9tYWluX25hbWU6IERlZmF1bHQKICAgICAgdXNlcl9pZDogIiIKICAgICAgdXNlcm5hbWU6IGFkbWluCiAgICBhdXRoX3R5cGU6ICIiCiAgICBjYWNlcnQ6ICIiCiAgICBjZXJ0OiAiIgogICAgY2xvdWQ6ICIiCiAgICBpZGVudGl0eV9hcGlfdmVyc2lvbjogIjMiCiAgICBrZXk6ICIiCiAgICBwcm9maWxlOiAiIgogICAgcmVnaW9uX25hbWU6IHJlZ2lvbk9uZQogICAgcmVnaW9uczogbnVsbAogICAgdmVyaWZ5OiB0cnVlCiAgICB2b2x1bWVfYXBpX3ZlcnNpb246ICIiCg==
kind: Secret
metadata:
  annotations:
    cloudcredential.openshift.io/credentials-request: openshift-cloud-credential-operator/openshift-machine-api-openstack
  creationTimestamp: "2019-12-20T10:23:00Z"
  name: openstack-cloud-credentials
  namespace: openshift-machine-api
  resourceVersion: "2525"
  selfLink: /api/v1/namespaces/openshift-machine-api/secrets/openstack-cloud-credentials
  uid: b2bded52-2312-11ea-9b6c-fa163e431263
type: Opaque
~~~

~~~
(overcloud) [stack@undercloud-0 clouds]$ base64 -d <(echo 'Y2xvdWRzOgogIG9wZW5zdGFjazoKICAgIGF1dGg6CiAgICAgIGFwcGxpY2F0aW9uX2NyZWRlbnRpYWxfaWQ6ICIiCiAgICAgIGFwcGxpY2F0aW9uX2NyZWRlbnRpYWxfbmFtZTogIiIKICAgICAgYXBwbGljYXRpb25fY3JlZGVudGlhbF9zZWNyZXQ6ICIiCiAgICAgIGF1dGhfdXJsOiBodHRwOi8vMTcyLjE2LjAuMTMwOjUwMDAvL3YzCiAgICAgIGRlZmF1bHRfZG9tYWluOiAiIgogICAgICBkb21haW5faWQ6ICIiCiAgICAgIGRvbWFpbl9uYW1lOiAiIgogICAgICBwYXNzd29yZDogelA0YmUydWtocENrajR6cVJmVWs4WGpRYgogICAgICBwcm9qZWN0X2RvbWFpbl9pZDogIiIKICAgICAgcHJvamVjdF9kb21haW5fbmFtZTogIiIKICAgICAgcHJvamVjdF9pZDogIiIKICAgICAgcHJvamVjdF9uYW1lOiBhZG1pbgogICAgICB0b2tlbjogIiIKICAgICAgdXNlcl9kb21haW5faWQ6ICIiCiAgICAgIHVzZXJfZG9tYWluX25hbWU6IERlZmF1bHQKICAgICAgdXNlcl9pZDogIiIKICAgICAgdXNlcm5hbWU6IGFkbWluCiAgICBhdXRoX3R5cGU6ICIiCiAgICBjYWNlcnQ6ICIiCiAgICBjZXJ0OiAiIgogICAgY2xvdWQ6ICIiCiAgICBpZGVudGl0eV9hcGlfdmVyc2lvbjogIjMiCiAgICBrZXk6ICIiCiAgICBwcm9maWxlOiAiIgogICAgcmVnaW9uX25hbWU6IHJlZ2lvbk9uZQogICAgcmVnaW9uczogbnVsbAogICAgdmVyaWZ5OiB0cnVlCiAgICB2b2x1bWVfYXBpX3ZlcnNpb246ICIiCg==')
clouds:
  openstack:
    auth:
      application_credential_id: ""
      application_credential_name: ""
      application_credential_secret: ""
      auth_url: http://172.16.0.130:5000//v3
      default_domain: ""
      domain_id: ""
      domain_name: ""
      password: zP4be2ukhpCkj4zqRfUk8XjQb
      project_domain_id: ""
      project_domain_name: ""
      project_id: ""
      project_name: admin
      token: ""
      user_domain_id: ""
      user_domain_name: Default
      user_id: ""
      username: admin
    auth_type: ""
    cacert: ""
    cert: ""
    cloud: ""
    identity_api_version: "3"
    key: ""
    profile: ""
    region_name: regionOne
    regions: null
    verify: true
    volume_api_version: ""
~~~


~~~
(overcloud) [stack@undercloud-0 clouds]$ cat clouds.yaml 
clouds:
  overcloud:
    auth:
      auth_url: http://172.16.0.130:5000//v3
      username: "admin"
      password: zP4be2ukhpCkj4zqRfUk8XjQb
      project_name: "admin"
      user_domain_name: "Default"
    region_name: "regionOne"
    interface: "public"
    identity_api_version: 3
~~~




The problem is in the generated secret:
~~~
Error getting a new instance service from the machine (machine/actuator.go 467): Create providerClient err: You must provide exactly one of DomainID or DomainName in a Scope with ProjectName
~~~

https://github.com/terraform-providers/terraform-provider-openstack/issues/267


Whereas when I check here: https://egallen.com/openshift-42-on-openstack-13-gpu/  This blog article uses project_id, too.
~~~

clouds:
  openstack:
    auth:
      auth_url: http://192.168.168.54:5000/v3
      username: "admin"
      password: XXXXXXXXXXXXXX
      project_id: XXXXXXXXX
      project_name: "admin"
      user_domain_name: "Default"
    region_name: "regionOne"
    interface: "public"
    identity_api_version: 3
~~~

However, my clouds.yaml file is actually completely correct:
~~~
[stack@undercloud-0 clouds]$ openstack --os-cloud overcloud token issue
+------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Field      | Value                                                                                                                                                                                   |
+------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| expires    | 2019-12-20T16:24:40+0000                                                                                                                                                                |
| id         | gAAAAABd_Oe4sLSSjwQiCPFhVK9PUFBehqVXbj-r96GdFvRieT51YZQUdm5lc5ic5VKYRFPg4jhPat4ZIdyow1QL-vZnxSK8MUAqUMQnc6xjs80JD-ibCNIg1Gac14Idp1CGIutsaUMS-Ms33LDgEw32S2qomv7LRUCLVcEBwrqwYLHXYE2ohyk |
| project_id | 1bb14f515f0945a4891fe3fa2372a795                                                                                                                                                        |
| user_id    | 0d3f5ab158c64c11b57d58c76d9675f0                                                                                                                                                        |
+------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
~~~

I'm now trying with:
~~~
clouds:
  openstack:
    auth:
      auth_url: http://172.16.0.130:5000//v3
      username: "admin"
      password: zP4be2ukhpCkj4zqRfUk8XjQb
      project_id: 1bb14f515f0945a4891fe3fa2372a795
      project_name: "admin"
      user_domain_name: "Default"
    region_name: "regionOne"
    interface: "public"
    identity_api_version: 3
~~~
