git clone https://github.com/stefanG41/scripts.git

kubectl apply -f pihole-namespace.yaml
kubectl apply -f helm-pihole-install.yaml
kubectl get jobs -n pihole
helm list -n pihole
kubectl get services -n pihole


kubectl apply -f pihole-namespace.yaml

helm repo add mojo2600 https://mojo2600.github.io/pihole-kubernetes/
helm repo update

helm install my-pihole mojo2600/pihole --version 2.23.0 --namespace pihole --values values.yaml
