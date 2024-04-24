helm repo add uptime-kuma https://helm.irsigler.cloud
helm repo update

helm upgrade my-uptime-kuma uptime-kuma/uptime-kuma --install --namespace uptime-kuma --create-namespace
