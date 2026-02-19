# Basic OCP cluster single zone and single subnet with RedHat ServiceMesh v3

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=ocp-service-mesh-existing_cluster-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-ocp-service-mesh/tree/main/examples/existing_cluster"><img src="https://img.shields.io/badge/Deploy%20with IBM%20Cloud%20Schematics-0f62fe?logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics" style="height: 16px; vertical-align: text-bottom;"></a>
<!-- END SCHEMATICS DEPLOY HOOK -->


This sample deploys the RedHat Service Mesh operators, and a Service Mesh / istio control plane, a basic ingress and a basic egress in different namespaces, and a sample app serving the bookinfo microservice for testing purposes, on an existing cluster and VPC infrastructure.

<!-- BEGIN SCHEMATICS DEPLOY TIP HOOK -->
:information_source: Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab
<!-- END SCHEMATICS DEPLOY TIP HOOK -->
