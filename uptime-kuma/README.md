helm repo add uptime-kuma https://helm.irsigler.cloud
helm repo update
helm upgrade my-uptime-kuma uptime-kuma/uptime-kuma --install --namespace uptime-kuma --create-namespace --set service.type=LoadBalancer
export POD_NAME=$(kubectl get pods --namespace uptime-kuma -l "app.kubernetes.io/name=uptime-kuma,app.kubernetes.io/instance=my-uptime-kuma" -o jsonpath="{.items[0].metadata.name}")
    export CONTAINER_PORT=$(kubectl get pod --namespace uptime-kuma $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
    echo "Visit http://127.0.0.1:3001 to use your application"
    kubectl --namespace uptime-kuma port-forward $POD_NAME 3001:$CONTAINER_PORT


kubectl create secret generic ssh-key-secret --from-file=id_rsa=/home/ubuntu/id_rsa -n uptime-kuma

scp -i /root/.ssh/id_rsa sshkey-uptime-kuma-setup/id_rsa* root@192.168.1.204:/srv/nfs/sshkey-uptime-kuma-setup/.

scp -i /root/.ssh/id_rsa root@192.168.1.204:/srv/nfs/sshkey-uptime-kuma-setup/id_rsa /home/ubuntu/id_rsa
cp ~/id_rsa ~/.ssh/.
chmod 600 ~/.ssh/id_rsa
