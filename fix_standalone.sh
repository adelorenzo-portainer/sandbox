jwt=`http POST :9000/api/auth Username="portainer" Password="portainer1234" | jq '.jwt' | sed 's/^.//' | sed 's/.$//'`

sleep 1
fix_standalone=`http GET :9000/api/endpoints "Authorization: Bearer $jwt" | jq -c '.[] | {Id, Name} | select(.Name == "docker")' | grep -o ':.*' | cut -f2- -d: | cut -f1 -d","`
http DELETE :9000/api/endpoints/$fix_standalone "Authorization: Bearer $jwt"
docker exec standalone /usr/local/bin/docker run -d -p 9001:9001 --name portainer_agent --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker/volumes:/var/lib/docker/volumes portainer/agent
docker exec -it standalone /sbin/ip a show eth0 | grep inet | awk '{ print $2 }' | sed 's/.\{3\}$//' > /root/.standalone_ip
standalone_ip=`cat .standalone_ip`
http --form POST :9000/api/endpoints "Authorization: Bearer $jwt" Name="docker" URL="tcp://$standalone_ip:9001" EndpointCreationType=2  TLS="true" TLSSkipVerify="true" TLSSkipClientVerify="true"


