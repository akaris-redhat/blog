#!/bin/bash

Make sure that you're running xorgs and not wayland:
https://docs.fedoraproject.org/en-US/quick-docs/configuring-xorg-as-default-gnome-session/
~~~
Procedure

    Open /etc/gdm/custom.conf and uncomment WaylandEnable=false.

    Add the following line to the [daemon] section:

    DefaultSession=gnome-xorg.desktop

    Save the custom.conf file.
~~~

Build container with buildah:
~~~
buildah from --name java-container fedora:26
buildah run java-container -- yum install xclock icedtea-web -y
buildah commit java-container java-image
~~~

Disable selinux:
~~~
sudo setenforce 0
~~~

Test container:
~~~
podman run -ti -e DISPLAY --rm -v /run/user/1000/gdm/Xauthority:/run/user/0/gdm/Xauthority:Z --net=host localhost/java-image xclock
~~~
