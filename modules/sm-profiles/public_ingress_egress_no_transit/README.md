# Public ingress and public egress profile

Profile with:
1. One public INGRESS gateway deployment (consuming from public VPC LB)
    - Ingress gateway pods located on edge worker pool and HA anti-affinity configured to spread pods on the expected nodes. These can be customised by setting var.public_ingress_pods_affinity and var.public_ingress_tolerations properly
    - Auto-scaling can be customised through var.public_ingress_autoscale_configuration
    - Ingress gateway by default opening ports TCP 443/8443 (https workload) and TCP 15021/15021 (health check port)
    - Ingress customisation is available through var.variables input parameters for the `public ingress`
2. One EGRESS gateway deployment
    - Egress gateway pods located on edge worker pool (with public internet access through the public gateway) and HA anti-affinity configured to spread pods on the expected nodes. These can be customised by setting var.public_egress_pods_affinity and var.public_egress_tolerations properly
    - Auto-scaling can be customised through var.public_egress_autoscale_configuration
    - Egress gateway by default opening ports TCP 443/443 (https)
    - Egress customisation is available through var.variables input parameters for the `public egress`
