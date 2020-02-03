Running a container registry without hostname (only IP address) and self-signed certificate. 

Follow the OpenShift documentation:
* https://access.redhat.com/documentation/en-us/openshift_container_platform/4.3/html/installing/installation-configuration#installing-restricted-networks-preparations

But generate the self-signed certificate with:
~~~
cat<<'EOF'> config
[req]
default_bits = 4096
prompt = no
default_md = sha256
x509_extensions = v3_req
distinguished_name = dn

[dn]
C = "OZ"
ST = "State of Oz"
L = "City of Oz"
O = "ACME, Inc."
emailAddress = "akaris@example.com"
CN = "192.168.123.10"

[v3_req]
basicConstraints = CA:FALSE
subjectAltName = @alt_names

[alt_names]
DNS.1 = 192.168.123.10
IP.1 = 192.168.123.10
EOF
openssl req -newkey rsa:4096 -nodes -sha256 -keyout domain.key -x509 -days 365 -out domain.crt -config config
~~~

Then, trust the certificate. Follow:
* https://stackoverflow.com/questions/22509271/import-self-signed-certificate-in-redhat/22619328

~~~
cd /etc/pki/tls/certs
cp /root/domain.crt .
ln -sv domain.crt $(openssl x509 -in domain.crt -noout -hash).0
~~~

Run the containter with:
~~~
podman run --name mirror-registry -p 5000:5000 -v /opt/registry/data:/var/lib/registry:z      -v /opt/registry/auth:/auth:z      -e "REGISTRY_AUTH=htpasswd"      -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm"      -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd      -v /opt/registry/certs:/certs:z      -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt      -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key      -d docker.io/library/registry:2
~~~

Then, verify:
~~~
[root@mirror ~]# openssl s_client -connect 10.10.181.198:5000
CONNECTED(00000003)
depth=0 C = OZ, ST = State of Oz, L = City of Oz, O = "ACME, Inc.", emailAddress = akaris@example.com, CN = 192.168.123.10
verify return:1
(...)
    Verify return code: 0 (ok)
---
~~~

Curl might report an issue:
~~~
[root@mirror ~]# curl https://10.10.181.198:5000 
curl: (60) Issuer certificate is invalid.
(...)
[root@mirror ~]# curl -V
curl 7.29.0 (x86_64-redhat-linux-gnu) libcurl/7.29.0 NSS/3.44 zlib/1.2.7 libidn/1.28 libssh2/1.4.3
~~~

Just follow the rest of the documentation. Get `$OCP_RELEASE` from https://quay.io/repository/openshift-release-dev/ocp-release?tag=latest&tab=tags. 

The following command ...
~~~
oc adm -a ${LOCAL_SECRET_JSON} release mirror \
     --from=quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE} \
     --to=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} \
     --to-release-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}
~~~

... should still download the images:
~~~
[root@mirror ~]# oc adm -a ${LOCAL_SECRET_JSON} release mirror      --from=quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}      --to=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}      --to-release-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}
info: Mirroring 101 images to 192.168.123.10:5000/ocp4/openshift4 ...
10.10.181.198:5000/
  ocp4/openshift4
    blobs:
      quay.io/openshift-release-dev/ocp-v4.0-art-dev sha256:94eeef1238d5121c25ec4f2c77f44646910e36253dc08da798c6babf65ed9531 479B
      quay.io/openshift-release-dev/ocp-v4.0-art-dev sha256:0e8ea260d0262eac3725175d3d499ead6fd77cb1fa8272b3e665e8f64044fb89 1.499KiB
      quay.io/openshift-release-dev/ocp-v4.0-art-dev sha256:4fbc3bafa3d4400bb97a733c1fe12f2f99bf38b9d5b913d5034f29798739654d 1.585KiB
      quay.io/openshift-release-dev/ocp-v4.0-art-dev sha256:c4e552011c627e79a47d52ca6f0d0685f747f29f97b9a8f40f9c2b58b695f30a 1.608KiB
(...)
~~~
