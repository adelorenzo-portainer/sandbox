# sandbox first setup recipe with alpine linux

## sandbox base alpine setup script
---

```
setup-xorg-base
#echo 'http://dl-cdn.alpinelinux.org/alpine/latest-stable/community' >> /etc/apk/repositories
sed -i 's/\#http/http/' /etc/apk/repositories
apk update
apk add curl jq httpie util-linux-misc xf86-video-vboxvideo virtualbox-guest-additions firefox ratpoison docker nano dialog ttf-opensans
add apk py3-setuptools
add minikube kubectl docker
echo vboxpci >> /etc/modules
echo vboxdrv >> /etc/modules
echo vboxnetflt >> /etc/modules
rc-update add docker boot
rc-update add virtualbox-guest-additions default
service docker start
docker volume create portainer_data
docker run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
```
