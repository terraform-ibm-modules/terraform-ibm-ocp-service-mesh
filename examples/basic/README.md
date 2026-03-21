# Basic OCP cluster single zone and single subnet with RedHat ServiceMesh v3

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<p>
  <a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=ocp-service-mesh-basic-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-ocp-service-mesh/tree/main/examples/basic">
    <img src="https://img.shields.io/badge/Deploy%20with%20IBM%20Cloud%20Schematics-0f62fe?style=flat&logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics">
  </a><br>
  ℹ️ Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab.
</p>
<!-- END SCHEMATICS DEPLOY HOOK -->

This sample deploys a VPC and its infrastructure resources and an OpenShift Cluster on IBM Cloud, then deploys on the cluster the RedHat Service Mesh v3 operator, a Service Mesh / istio control plane, a basic ingress and a basic egress in different namespaces, and a sample app serving the httpbin microservice for testing purposes.
