#!/bin/ash
setup-xorg-base
sed -i 's/\#http/http/' /etc/apk/repositories
apk update
apk add curl jq httpie util-linux-misc xf86-video-vboxvideo virtualbox-guest-additions firefox ratpoison docker nano dialog ttf-opensans kubectl ffmpeg
apk add py3-setuptools
echo vboxpci >> /etc/modules
echo vboxdrv >> /etc/modules
echo vboxnetflt >> /etc/modules
rc-update add docker boot
rc-update add virtualbox-guest-additions boot
service docker start
sleep 5
docker volume create portainer_data
sleep 5
docker run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always -v portainer_data:/data portainer/portainer-ce
sleep 5
http POST http://localhost:9000/api/users/admin/init Username="portainer" Password="portainer1234"
curl -sfL https://get.k3s.io | sh -
