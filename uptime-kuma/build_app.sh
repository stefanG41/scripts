#!/bin/bash

# Add the Helm repository
helm repo add uptime-kuma https://helm.irsigler.cloud
helm repo update

# Install or upgrade Uptime Kuma using Helm
helm upgrade my-uptime-kuma uptime-kuma/uptime-kuma --install --namespace uptime-kuma --create-namespace --set service.type=LoadBalancer

# Wait until the pod is in the Running state
echo "Waiting for the Uptime Kuma pod to be running..."
while [[ $(kubectl get pods --namespace uptime-kuma -l "app.kubernetes.io/name=uptime-kuma,app.kubernetes.io/instance=my-uptime-kuma" -o jsonpath="{.items[0].status.phase}") != "Running" ]]; do
  sleep 5
done

# Get the pod name and container port
export POD_NAME=$(kubectl get pods --namespace uptime-kuma -l "app.kubernetes.io/name=uptime-kuma,app.kubernetes.io/instance=my-uptime-kuma" -o jsonpath="{.items[0].metadata.name}")
export CONTAINER_PORT=$(kubectl get pod --namespace uptime-kuma $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")

# Wait for a few seconds to ensure the pod is fully ready
sleep 10

# Provide the user with the information on how to access the application
echo http://$SERVICE_IP:3001

