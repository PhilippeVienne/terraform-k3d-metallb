# Local kubernetes cluster powered by k3d

This terraform module intend to create a local kubernetes cluster using k3d and provide with MetalLB a Layer 2 loadbalancer with the last 4th part of the created docker network.

## Requirements

* terraform 0.12+: 
* kubectl 1.15+: https://kubernetes.io/docs/tasks/tools/install-kubectl/
* jq: https://stedolan.github.io/jq/download/
* docker: https://docs.docker.com/install/
* k3d: https://github.com/rancher/k3d

## Note due to pending PR

This module depends on a future version of the terraform-provider-docker due to a fix.

Use and compile the plugin from: https://github.com/PhilippeVienne/terraform-provider-docker

PR Status: https://github.com/terraform-providers/terraform-provider-docker/pull/229
