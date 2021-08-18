#!/bin/ash

(
docker volume create standalone-certs-ca
docker volume create standalone-certs-ca-client
docker run --privileged --name standalone \
--restart=always -d \
-e DOCKER_TLS_CERTDIR=/certs \
-v standalone-certs-ca:/certs/ca \
-v standalone-certs-ca-client:/certs/client \
docker:dind
sleep 3

#Install Portainer Agent
docker exec standalone /usr/local/bin/docker run -d -p 9001:9001 --name portainer_agent --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker/volumes:/var/lib/docker/volumes portainer/agent

/usr/local/bin/.endpoint_standalone.sh

) | zenity --text "Installing Docker" --progress --auto-close --pulsate
