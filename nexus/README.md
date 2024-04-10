git clone https://github.com/stefanG41/scripts.git

Build takes around 5min

kubectl apply -f nexus-deployment.yaml
kubectl apply -f nexus-pvc.yaml
kubectl apply -f nexus-service.yaml


kubectl delete -f nexus-deployment.yaml
kubectl delete -f nexus-pvc.yaml
kubectl delete -f nexus-service.yaml


Your admin user password is located in
/nexus-data/admin.password on the server.
