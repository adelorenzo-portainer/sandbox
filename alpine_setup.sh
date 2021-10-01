setup-xorg-base
sed -i 's/\#http/http/' /etc/apk/repositories
apk update
apk add curl jq httpie util-linux-misc xf86-video-vboxvideo virtualbox-guest-additions firefox ratpoison docker nano dialog ttf-opensans kubectl
apk add py3-setuptools
wget -O /usr/local/bin/kind https://github.com/kubernetes-sigs/kind/releases/download/v0.11.1/kind-linux-amd64
chmod +x /usr/local/bin/kind
echo vboxpci >> /etc/modules
echo vboxdrv >> /etc/modules
echo vboxnetflt >> /etc/modules
rc-update add docker boot
rc-update add virtualbox-guest-additions default
service docker start
docker volume create portainer_data
docker run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always -v portainer_data:/data portainerci/portainer:develop
http POST http://localhost:9000/api/users/admin/init Username="portainer" Password="portainer1234"
