#!/bin/sh

kubectl create configmap lua-libs --from-file=JSON.lua --from-file=uuid.lua --from-file=envoy.yaml 
