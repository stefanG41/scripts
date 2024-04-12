git clone https://github.com/stefanG41/scripts.git

Build takes around 5min

kubectl apply -f nexus-namespace.yaml
kubectl apply -f nexus-secret.yaml
kubectl apply -f nexus-deployment.yaml
kubectl apply -f nexus-pvc.yaml
kubectl apply -f nexus-service.yaml


kubectl delete -f nexus-deployment.yaml
kubectl delete -f nexus-pvc.yaml
kubectl delete -f nexus-service.yaml
kubectl delete -f nexus-namespace.yaml
kubectl delete -f nexus-secret.yaml

Your admin user password is located in
/nexus-data/admin.password on the server.

kubectl create secret generic nexus-admin-password --from-literal=password='XXXXxxxxXXXX' --namespace=nexus-namespace

# Zuerst speichern wir den Namen des ersten gefundenen laufenden Pods, der mit "nexus" beginnt, in einer Variable
POD_NAME=$(kubectl get pods --field-selector=status.phase=Running | grep ^nexus | awk '{print $1}' | head -n 1)

# Dann führen wir den kubectl exec Befehl mit dieser Variablen aus, um die Datei 'admin.password' zu lesen
kubectl exec $POD_NAME -- cat /nexus-data/admin.password
