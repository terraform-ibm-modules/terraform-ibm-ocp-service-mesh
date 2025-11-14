# Secure OpenShift cluster with 3 zones and 3 subnets

This sample deploys OpenShift cluster in a VPC designed with 3 zones and 3 subnets (default, private, edge) per each zone, resulting in 9 workers, one per zone/subnet combination. After the initial cluster deployment the example deploys the RedHat Service Mesh operators, and a Service Mesh / istio control plane, two customised ingresses (one deploying an IBM Cloud VPC Application Load Balancer and one an IBM Cloud VPC Network Load balancer) and a customised egress gateways in the same namespace
