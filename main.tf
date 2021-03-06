variable "k3d_cluster_name" {
  default = "k3s-default"
  type = string
}

variable "k3d_cluster_port" {
  default = 6443
  type = number
}

variable "k3d_cluster_ip" {
  default = "0.0.0.0"
  type = string
}

provider "docker" {
  version = ">2.6.0"
}

variable "workers_count" {
  default = 0
  type = number
}

resource "null_resource" "cluster" {
  triggers = {
    name = var.k3d_cluster_name
    workers_count = var.workers_count
    ip = var.k3d_cluster_ip
    port = var.k3d_cluster_port
  }
  provisioner "local-exec" {
    interpreter = [
      "/bin/bash",
      "-c"
    ]
    command = <<TERM
k3d create --name ${var.k3d_cluster_name} --workers ${var.workers_count} --auto-restart --api-port ${var.k3d_cluster_ip}:${var.k3d_cluster_port}
until k3d get-kubeconfig --name='${var.k3d_cluster_name}'; do
  sleep 1;
done
TERM
  }
  provisioner "local-exec" {
    command = "k3d delete --name ${var.k3d_cluster_name}"
    when = destroy
  }
}

data external kubeconfig {
  depends_on = [
    null_resource.cluster
  ]
  program = [
    "/bin/bash",
    "-c",
<<BASH
k3d get-kubeconfig --name='${var.k3d_cluster_name}' | jq -R "{kubeconfig:.}"
BASH
  ]
}

data docker_network k3d {
  depends_on = [
    null_resource.cluster
  ]
  name = "k3d-${var.k3d_cluster_name}"
}

resource "null_resource" "metallb" {
  depends_on = [
    null_resource.cluster
  ]
  provisioner "local-exec" {
    environment = {
      KUBECONFIG = data.external.kubeconfig.result["kubeconfig"]
    }
    command = "kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.3/manifests/metallb.yaml"
  }
  provisioner "local-exec" {
    command = "kubectl delete -f https://raw.githubusercontent.com/google/metallb/v0.8.3/manifests/metallb.yaml --kubeconfig=$(k3d get-kubeconfig --name='${var.k3d_cluster_name}')"
    when = destroy
  }
}

resource "local_file" "metallb_config" {
  depends_on = [
    null_resource.cluster,
    data.docker_network.k3d
  ]
  filename = "${path.module}/metallb_config.yaml"
  content = <<YAML
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      avoid-buggy-ips: true
      addresses:
      %{ for subnet in data.docker_network.k3d.ipam_config.*.subnet }
      - ${cidrsubnet(subnet, 4, 3)}
      %{ endfor }
YAML
  }

resource "null_resource" "metallb_config" {
  depends_on = [
    null_resource.cluster,
    null_resource.metallb
  ]
  triggers = {
    kubeconfig = data.external.kubeconfig.result["kubeconfig"]
    metallb_config = md5(local_file.metallb_config.content)
  }
  provisioner "local-exec" {
    environment = {
      KUBECONFIG = data.external.kubeconfig.result["kubeconfig"]
    }
    command = "kubectl apply -f ${local_file.metallb_config.filename}"
  }
  provisioner "local-exec" {
    command = "kubectl delete -n metallb-system configmap config --kubeconfig=$(k3d get-kubeconfig --name='${var.k3d_cluster_name}')"
    when = destroy
  }
}

output "kubeconfig" {
  value = file(data.external.kubeconfig.result["kubeconfig"])
  sensitive = true
}
