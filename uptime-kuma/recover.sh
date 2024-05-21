#!/bin/bash

NAMESPACE=uptime-kuma
DEPLOYMENT_NAME=my-uptime-kuma
BACKUP_PFAD=/home/ubuntu/scripts/uptime-kuma
BACKUP_NAME=app-data.tar.gz

# Scale down the deployment
kubectl scale deployment/$DEPLOYMENT_NAME --replicas=0 -n $NAMESPACE

# Wait until the pods are terminated
while kubectl get pods -n $NAMESPACE | grep -q uptime-kuma; do
  echo "Waiting for pods to terminate..."
  sleep 5
done

# Scale up the deployment
kubectl scale deployment/$DEPLOYMENT_NAME --replicas=1 -n $NAMESPACE

# Wait until the new pod is running
while ! kubectl get pods -n $NAMESPACE | grep -q 'Running'; do
  echo "Waiting for new pod to be running..."
  sleep 5
done

# Get the new pod name
POD_NAME=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=uptime-kuma -o jsonpath="{.items[0].metadata.name}")

# Copy backup file to the pod
#kubectl cp /home/ubuntu/scripts/uptime-kuma/app-data-2024-05-21.tar.gz $NAMESPACE/$POD_NAME:/tmp/app-data-2024-05-21.tar.gz
kubectl cp $BACKUP_PFAD/$BACKUP_NAME $NAMESPACE/$POD_NAME:/tmp/$BACKUP_NAME

# Exec into the pod and restore the backup
#kubectl exec -it $POD_NAME -n $NAMESPACE -- /bin/sh -c "tar -xzvf /tmp/app-data-2024-05-21.tar.gz -C /app/data && chown -R root:root /app/data"
kubectl exec -it $POD_NAME -n $NAMESPACE -- /bin/sh -c "tar -xzvf /tmp/$BACKUP_NAME -C /app/data && chown -R root:root /app/data"


# Scale down the deployment
kubectl scale deployment/$DEPLOYMENT_NAME --replicas=0 -n $NAMESPACE

# Wait until the pods are terminated
while kubectl get pods -n $NAMESPACE | grep -q uptime-kuma; do
  echo "Waiting for pods to terminate..."
  sleep 5
done

# Scale up the deployment
kubectl scale deployment/$DEPLOYMENT_NAME --replicas=1 -n $NAMESPACE

# Wait until the new pod is running
while ! kubectl get pods -n $NAMESPACE | grep -q 'Running'; do
  echo "Waiting for new pod to be running..."
  sleep 5
done

# Get the new pod name
POD_NAME=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=uptime-kuma -o jsonpath="{.items[0].metadata.name}")

# Copy backup file to the pod
#kubectl cp /home/ubuntu/scripts/uptime-kuma/app-data-2024-05-21.tar.gz $NAMESPACE/$POD_NAME:/tmp/app-data-2024-05-21.tar.gz
kubectl cp $BACKUP_PFAD/$BACKUP_NAME $NAMESPACE/$POD_NAME:/tmp/$BACKUP_NAME

# Exec into the pod and restore the backup
#kubectl exec -it $POD_NAME -n $NAMESPACE -- /bin/sh -c "tar -xzvf /tmp/app-data-2024-05-21.tar.gz -C /app/data && chown -R root:root /app/data"
kubectl exec -it $POD_NAME -n $NAMESPACE -- /bin/sh -c "tar -xzvf /tmp/$BACKUP_NAME -C /app/data && chown -R root:root /app/data"

echo "Backup restored and pod restarted successfully."
