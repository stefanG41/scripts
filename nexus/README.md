kubectl apply -f nexus-deployment.yaml
kubectl apply -f nexus-pvc.yaml
kubectl apply -f nexus-service.yaml


kubectl delete -f nexus-deployment.yaml
kubectl delete -f nexus-pvc.yaml
kubectl delete -f nexus-service.yaml
