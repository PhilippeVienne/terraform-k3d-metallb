# Local kubernetes cluster powered by k3d

This terraform module intend to create a local kubernetes cluster using k3d and provide with MetalLB a Layer 2 loadbalancer with the last 4th part of the created docker network.

## Requirements

* terraform 0.12+: 
* kubectl 1.15+: https://kubernetes.io/docs/tasks/tools/install-kubectl/
* jq: https://stedolan.github.io/jq/download/
* docker: https://docs.docker.com/install/
* k3d: https://github.com/rancher/k3d
