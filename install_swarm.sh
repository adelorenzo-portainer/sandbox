#!/bin/ash

(
docker volume create swarm1-certs-ca
docker volume create swarm1-certs-ca-client
docker run --privileged --name swarm1 \
--restart=always -d \
-e DOCKER_TLS_CERTDIR=/certs \
-v swarm1-certs-ca:/certs/ca \
-v swarm1-certs-ca-client:/certs/client \
docker:dind
sleep 2

docker volume create swarm2-certs-ca
docker volume create swarm2-certs-ca-client
docker run --privileged --name swarm2 \
--restart=always -d \
-e DOCKER_TLS_CERTDIR=/certs \
-v swarm2-certs-ca:/certs/ca \
-v swarm2-certs-ca-client:/certs/client \
docker:dind
sleep 2

docker exec swarm1 /usr/local/bin/docker swarm init
sleep 1

docker exec swarm1 /usr/local/bin/docker swarm join-token worker | head -3 | sed '1d' | tail -1 | cut -c5- > /tmp/.swarm_token
sleep 1

sed 's/^/docker exec swarm2 \/usr\/local\/bin\//' /tmp/.swarm_token > /tmp/.com
sleep 1

chmod +x /tmp/.com
/tmp/.com
rm /tmp/.com

docker exec swarm1 /sbin/apk add curl
sleep 1

#Install Portainer Agent
docker exec swarm1 /usr/bin/curl -L https://downloads.portainer.io/agent-stack.yml -o /tmp/agent-stack.yml
docker exec swarm1 /usr/local/bin/docker stack deploy --compose-file=/tmp/agent-stack.yml portainer-agent

/usr/local/bin/.endpoint_swarm.sh

) | zenity --text "Installing Docker Swarm" --progress --auto-close --pulsate
