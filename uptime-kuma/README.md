helm repo add uptime-kuma https://helm.irsigler.cloud
helm repo update
helm upgrade my-uptime-kuma uptime-kuma/uptime-kuma --install --namespace uptime-kuma --create-namespace --set service.type=LoadBalancer
export POD_NAME=$(kubectl get pods --namespace uptime-kuma -l "app.kubernetes.io/name=uptime-kuma,app.kubernetes.io/instance=my-uptime-kuma" -o jsonpath="{.items[0].metadata.name}")
    export CONTAINER_PORT=$(kubectl get pod --namespace uptime-kuma $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
    echo "Visit http://127.0.0.1:3001 to use your application"
    kubectl --namespace uptime-kuma port-forward $POD_NAME 3001:$CONTAINER_PORT
