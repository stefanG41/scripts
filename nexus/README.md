kubectl apply -f nexus-deployment.yaml
kubectl apply -f nexus-pvc.yaml
kubectl apply -f nexus-service.yaml


kubectl delete -f nexus-deployment.yaml
kubectl delete -f nexus-pvc.yaml
kubectl delete -f nexus-service.yaml

kubectl apply -f https://raw.githubusercontent.com/stefanG41/scripts/main/nexus-deployment.yaml
kubectl apply -f https://raw.githubusercontent.com/stefanG41/scripts/main/nexus-pvc.yaml
kubectl apply -f https://raw.githubusercontent.com/stefanG41/scripts/main/scripts.git/nexus-service.yaml
