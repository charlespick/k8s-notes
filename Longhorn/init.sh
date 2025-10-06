#!/bin/bash

microk8s helm repo add longhorn https://charts.longhorn.io
microk8s helm repo update
microk8s helm install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace
