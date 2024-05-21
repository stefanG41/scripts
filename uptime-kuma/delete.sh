#!/bin/bash


kubectl delete deployment my-uptime-kuma -n uptime-kuma
sleep 5
kubectl delete namespace uptime-kuma
sleep 5

echo "Deplyoment deleted successfully."
