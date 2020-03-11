### OpenShift httpbin with tshark sidecar ###

The following allows us to see any incoming requests to httpbin but to filter out httpbin's answers.

Prerequisites:
~~~
[root@master-2 ~]# oc adm policy add-scc-to-user anyuid -z default
scc "anyuid" added to: ["system:serviceaccount:default:default"]
~~~

Create file `httpbin.yaml`:
~~~
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  labels:
    app: httpbin-deploymentconfig
  name: httpbin-service
spec:
  host: httpbin.apps.akaris2.lab.pnq2.cee.redhat.com
  port:
    targetPort: 80
  to:
    kind: Service
    name: httpbin-service
    weight: 100
  wildcardPolicy: None
---
apiVersion: v1
kind: Service
metadata:
  name: httpbin-service
  labels:
    app: httpbin-deploymentconfig
spec:
  selector:
    app: httpbin-pod
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
---
apiVersion: v1
kind: DeploymentConfig
metadata:
  name: httpbin-deploymentconfig
  labels:
    app: httpbin-deploymentconfig
spec:
  replicas: 1
  selector:
    app: httpbin-pod
  template:
    metadata:
      labels:
        app: httpbin-pod
    spec:
      containers:
      - name: tshark
        image: danielguerra/alpine-tshark 
        command:
          - "tshark" 
          - "-i" 
          - "eth0" 
          - "-Y" 
          - "http" 
          - "-V"  
          - "dst" 
          - "port"
          - "80"
      - name: httpbin
        image: kennethreitz/httpbin
        imagePullPolicy: Always
        command:
        - "gunicorn"
        - "-b"
        - "0.0.0.0:80"
        - "httpbin:app"
        - "-k"
        - "gevent"
        - "--capture-output"
        - "--error-logfile"
        - "-"
        - "--access-logfile"
        - "-"
        - "--access-logformat"
        - "'%(h)s %(t)s %(r)s %(s)s Host: %({Host}i)s} Header-i: %({Header}i)s Header-o: %({Header}o)s'"
~~~

Apply config:
~~~
oc apply -f httpbin.yaml 
~~~

Get the pod name and loolk at the pod's logs for container `tshark`:
~~~
[root@master-0 ~]# oc get pods -l app=httpbin-pod
NAME                               READY     STATUS    RESTARTS   AGE
httpbin-deploymentconfig-8-tgmvn   2/2       Running   0          3m
[root@master-0 ~]# oc logs httpbin-deploymentconfig-8-tgmvn -c tshark  -f
Capturing on 'eth0'
Frame 4: 535 bytes on wire (4280 bits), 535 bytes captured (4280 bits) on interface 0
    Interface id: 0 (eth0)
        Interface name: eth0
    Encapsulation type: Ethernet (1)
    Arrival Time: Mar 11, 2020 12:17:13.290037158 UTC
    [Time shift for this packet: 0.000000000 seconds]
    Epoch Time: 1583929033.290037158 seconds
    [Time delta from previous captured frame: 0.000002253 seconds]
    [Time delta from previous displayed frame: 0.000000000 seconds]
    [Time since reference or first frame: 36.739477011 seconds]
    Frame Number: 4
    Frame Length: 535 bytes (4280 bits)
    Capture Length: 535 bytes (4280 bits)
    [Frame is marked: False]
    [Frame is ignored: False]
    [Protocols in frame: eth:ethertype:ip:tcp:http:urlencoded-form]
Ethernet II, Src: 7a:9c:fa:d2:07:d8 (7a:9c:fa:d2:07:d8), Dst: 0a:58:0a:80:00:0c (0a:58:0a:80:00:0c)
    Destination: 0a:58:0a:80:00:0c (0a:58:0a:80:00:0c)
        Address: 0a:58:0a:80:00:0c (0a:58:0a:80:00:0c)
        .... ..1. .... .... .... .... = LG bit: Locally administered address (this is NOT the factory default)
        .... ...0 .... .... .... .... = IG bit: Individual address (unicast)
    Source: 7a:9c:fa:d2:07:d8 (7a:9c:fa:d2:07:d8)
        Address: 7a:9c:fa:d2:07:d8 (7a:9c:fa:d2:07:d8)
        .... ..1. .... .... .... .... = LG bit: Locally administered address (this is NOT the factory default)
        .... ...0 .... .... .... .... = IG bit: Individual address (unicast)
    Type: IPv4 (0x0800)
Internet Protocol Version 4, Src: 10.130.0.1, Dst: 10.128.0.12
    0100 .... = Version: 4
    .... 0101 = Header Length: 20 bytes (5)
    Differentiated Services Field: 0x00 (DSCP: CS0, ECN: Not-ECT)
        0000 00.. = Differentiated Services Codepoint: Default (0)
        .... ..00 = Explicit Congestion Notification: Not ECN-Capable Transport (0)
    Total Length: 521
    Identification: 0xdfdf (57311)
    Flags: 0x02 (Don't Fragment)
        0... .... = Reserved bit: Not set
        .1.. .... = Don't fragment: Set
        ..0. .... = More fragments: Not set
    Fragment offset: 0
    Time to live: 64
    Protocol: TCP (6)
    Header checksum: 0x4401 [validation disabled]
    [Header checksum status: Unverified]
    Source: 10.130.0.1
    Destination: 10.128.0.12
Transmission Control Protocol, Src Port: 38288, Dst Port: 80, Seq: 1, Ack: 1, Len: 469
    Source Port: 38288
    Destination Port: 80
    [Stream index: 1]
    [TCP Segment Len: 469]
    Sequence number: 1    (relative sequence number)
    [Next sequence number: 470    (relative sequence number)]
    Acknowledgment number: 1    (relative ack number)
    1000 .... = Header Length: 32 bytes (8)
    Flags: 0x018 (PSH, ACK)
        000. .... .... = Reserved: Not set
        ...0 .... .... = Nonce: Not set
        .... 0... .... = Congestion Window Reduced (CWR): Not set
        .... .0.. .... = ECN-Echo: Not set
        .... ..0. .... = Urgent: Not set
        .... ...1 .... = Acknowledgment: Set
        .... .... 1... = Push: Set
        .... .... .0.. = Reset: Not set
        .... .... ..0. = Syn: Not set
        .... .... ...0 = Fin: Not set
        [TCP Flags: ·······AP···]
    Window size value: 221
    [Calculated window size: 28288]
    [Window size scaling factor: 128]
    Checksum: 0xd9c6 [unverified]
    [Checksum Status: Unverified]
    Urgent pointer: 0
    Options: (12 bytes), No-Operation (NOP), No-Operation (NOP), Timestamps
        TCP Option - No-Operation (NOP)
            Kind: No-Operation (1)
        TCP Option - No-Operation (NOP)
            Kind: No-Operation (1)
        TCP Option - Timestamps: TSval 44637623, TSecr 44644920
            Kind: Time Stamp Option (8)
            Length: 10
            Timestamp value: 44637623
            Timestamp echo reply: 44644920
    [SEQ/ACK analysis]
        [iRTT: 0.001410475 seconds]
        [Bytes in flight: 470]
        [Bytes sent since last PSH flag: 469]
    TCP payload (469 bytes)
Hypertext Transfer Protocol
    POST /post HTTP/1.1\r\n
        [Expert Info (Chat/Sequence): POST /post HTTP/1.1\r\n]
            [POST /post HTTP/1.1\r\n]
            [Severity level: Chat]
            [Group: Sequence]
        Request Method: POST
        Request URI: /post
        Request Version: HTTP/1.1
~~~
