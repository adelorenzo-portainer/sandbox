#!/bin/ash

#Delete previous setup
sudo -u portainer minikube delete
minikube delete
docker stop portainer
docker rm portainer
docker volume rm portainer_data
docker container kill $(docker ps -q)
docker container rm $(docker ps -a -q)

#Install Portainer
docker volume create portainer_data
docker run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce

#Define Admin user and Password
http POST http://localhost:9000/api/users/admin/init Username="portainer" Password="portainer1234"

#Get the admin JWT token
jwt=`http POST :9000/api/auth Username="portainer" Password="portainer1234" | jq '.jwt' | sed 's/^.//' | sed 's/.$//'`

#Add local Docker endpoint
http --form POST :9000/api/endpoints "Authorization: Bearer $jwt" Name="docker" EndpointCreationType=1

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

