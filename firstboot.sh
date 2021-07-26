#!/bin/ash

#Get the admin JWT token
jwt=`http POST :9000/api/auth Username="portainer" Password="portainer1234" | jq '.jwt' | sed 's/^.//' | sed 's/.$//'`

#Add local Docker endpoint
#http --form POST :9000/api/endpoints "Authorization: Bearer $jwt" Name="docker" EndpointCreationType=1

#Add docker in docker
docker volume create standalone-certs-ca
docker volume create standalone-certs-ca-client
docker run --privileged --name standalone -d \
-e DOCKER_TLS_CERTDIR=/certs \
-v standalone-certs-ca:/certs/ca \
-v standalone-certs-ca-client:/certs/client \
docker:dind
sleep 2

#Add docker endpoint
docker exec -it standalone /sbin/ip a show eth0 | grep inet | awk '{ print $2 }' | sed 's/.\{3\}$//' > /root/.standalone_ip
standalone_ip=`cat .standalone_ip`
http --form POST :9000/api/endpoints "Authorization: Bearer $jwt" Name="docker" URL="tcp://$standalone_ip:9001" EndpointCreationType=2  TLS="true" TLSSkipVerify="true" TLSSkipClientVerify="true"
docker exec standalone /usr/local/bin/docker run -d -p 9001:9001 --name portainer_agent --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker/volumes:/var/lib/docker/volumes portainer/agent
http --form POST :9000/api/endpoints "Authorization: Bearer $jwt" Name="docker" URL="tcp://$standalone_ip:9001" EndpointCreationType=2  TLS="true" TLSSkipVerify="true" TLSSkipClientVerify="true"

#Add docker swarm in docker
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

docker exec swarm1 /sbin/apk add curl
sleep 1

docker exec swarm1 /usr/bin/curl -L https://downloads.portainer.io/agent-stack.yml -o /tmp/agent-stack.yml
docker exec swarm1 /usr/local/bin/docker stack deploy --compose-file=/tmp/agent-stack.yml portainer-agent
sleep 20

docker exec -it swarm1 /sbin/ip a show eth0 | grep inet | awk '{ print $2 }' | sed 's/.\{3\}$//' > /root/.swarm_ip
swarm_ip=`cat .swarm_ip`

jwt=`http POST :9000/api/auth Username="portainer" Password="portainer1234" | jq '.jwt' | sed 's/^.//' | sed 's/.$//'`
http --form POST :9000/api/endpoints "Authorization: Bearer $jwt" Name="docker swarm" URL="tcp://$swarm_ip:9001" EndpointCreationType=2  TLS="true" TLSSkipVerify="true" TLSSkipClientVerify="true"

#Start minikube
sudo -u portainer minikube start --driver=docker --ports=":30778" --ports=":9001"

#Add the metrics server to the minikube cluster
sudo -u portainer minikube addons enable metrics-server

#Add Portainer Agent to the local kind Kubernetes cluster
sudo -u portainer curl -qL https://downloads.portainer.io/portainer-agent-k8s-nodeport.yaml -o /home/portainer/portainer-agent-k8s.yaml
sudo -u portainer kubectl apply -f /home/portainer/portainer-agent-k8s.yaml --validate=false
sudo -u portainer rm /home/portainer/portainer-agent-k8s.yaml
sleep 30

#Get mapped 30778 port from control-plane
jwt=`http POST :9000/api/auth Username="portainer" Password="portainer1234" | jq '.jwt' | sed 's/^.//' | sed 's/.$//'`
port=`docker port minikube | grep 30778 | head -1 | awk '$1=$1' FS=":" OFS=" " |  awk '{ print $4 }'`
ip=`ip a show eth0 | grep inet | head -1 | awk '{ print $2 }' | sed 's/.\{3\}$//'`

#Add local Kubernetes endpoint
sudo -u portainer http --form POST :9000/api/endpoints "Authorization: Bearer $jwt" Name="kubernetes" URL="tcp://$ip:$port" EndpointCreationType=2 TLS="true" TLSSkipVerify="true" TLSSkipClientVerify="true"

#Housekeeping
echo '/root/rebuild.sh > /dev/tty1' > /root/.profile
echo 'exec startx' >> /root/.profile
clear
echo "Portainer Sandbox installed. Open your browser on http://$ip:9000"
echo "Username: portainer"
echo "Password: portainer1234"
sleep 5
startx
