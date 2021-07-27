#Install minikube Kubernetes
#Check if the Portainer Agent is running
echo ""
echo ""
while true
do
agent_state=`sudo -u portainer kubectl get pod -n portainer | awk '{ print $3 }' | tail -1`
if [ "$agent_state" != "Running" ]; then
	echo -ne '⚡ Portainer Agent Not Running yet\r'
else
	break
fi
sleep 1
done

sleep 5
jwt=`http POST :9000/api/auth Username="portainer" Password="portainer1234" | jq '.jwt' | sed 's/^.//' | sed 's/.$//'`
port=`docker port minikube | grep 30778 | head -1 | awk '$1=$1' FS=":" OFS=" " |  awk '{ print $4 }'`
ip=`ip a show eth0 | grep inet | head -1 | awk '{ print $2 }' | sed 's/.\{3\}$//'`
sudo -u portainer http --form POST :9000/api/endpoints "Authorization: Bearer $jwt" Name="kubernetes" URL="tcp://$ip:$port" EndpointCreationType=2 TLS="true" TLSSkipVerify="true" TLSSkipClientVerify="true"

