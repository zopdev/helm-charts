#!/bin/bash

for rev in {1..20}; do
  for i in {1..100}; do
    helm upgrade svc-$i charts/service \
      --namespace helmtest \
      --history-max 999999 \
      --set minCPU=20m \
      --set minMemory=16M \
      --set maxCPU=25m \
      --set maxMemory=20M \
      --set minReplicas=1 \
      --set maxReplicas=1 \
      --set name=svc-$i \
      --set timestamp=$(date +%s%N)
  done
done
