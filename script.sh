#!/bin/bash

for i in {1..40}; do
  helm install svc-$i charts/service \
    --namespace helmtest \
    --set minCPU=20m \
    --set minMemory=16M \
    --set maxCPU=25m \
    --set maxMemory=20M \
    --set minReplicas=1 \
    --set maxReplicas=1 \
    --set name=svc-$i
done