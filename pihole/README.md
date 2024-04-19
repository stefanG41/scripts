git clone https://github.com/stefanG41/scripts.git

kubectl apply -f pihole-namespace.yaml
kubectl apply -f helm-pihole-install.yaml
kubectl get jobs -n pihole
helm list -n pihole
kubectl get services -n pihole
