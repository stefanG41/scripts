
git clone https://github.com/stefanG41/scripts.git

Build takes around 5min

kubectl apply -f nextcloud-namespace.yaml
kubectl apply -f nextcloud-secret.yaml
kubectl apply -f nextcloud-deployment.yaml
kubectl apply -f nextcloud-pvc.yaml
kubectl apply -f nextcloud-service.yaml


kubectl delete -f nextcloud-deployment.yaml
kubectl delete -f nextcloud-pvc.yaml
kubectl delete -f nextcloud-service.yaml
kubectl delete -f nextcloud-namespace.yaml
kubectl delete -f nextcloud-secret.yaml
