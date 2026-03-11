# Profile with public ingress and egress, transit with egress and ingress enabling support for CSE proxy

Profile with:
1. One public INGRESS gateway deployment (consuming from public VPC LB)
    - Ingress gateway pods located on edge worker pool and HA anti-affinity configured to spread pods on the expected nodes. These can be customised by setting var.public_ingress_pods_affinity and var.public_ingress_tolerations properly
    - Auto-scaling can be customised through var.public_ingress_autoscale_configuration
    - Ingress gateway by default opening ports TCP 443/8443 (https workload) and TCP 15021/15021 (health check port)
    - Ingress customisation is available through var.variables input parameters for the `public ingress`
1. One INGRESS gateway deployment with specific custom annotations deployed on cluster `transit` labeled nodes.
    - Ingress Gateway pods located on transit worker pool and HA anti-affinity configured to spread pods on the expected nodes. These can be customised by setting var.transit_ingress_pods_affinity and var.transit_ingress_tolerations properly
    - Auto-scaling can be customised through var.transit_ingress_autoscale_configuration
    - Ingress gateway by default opening ports TCP 443/8443 (https workload), TCP 15021/15021 (health check port), TCP 15443/15443 (TLS for transit LB)
    - Ingress customisation is available through var.variables input parameters for the `transit ingress`
1. One public EGRESS gateway deployment
    - Egress gateway pods located on edge worker pool (with public internet access through the public gateway) and HA anti-affinity configured to spread pods on the expected nodes. These can be customised by setting var.public_egress_pods_affinity and var.public_egress_tolerations properly
    - Auto-scaling can be customised through var.public_egress_autoscale_configuration
    - Egress gateway by default opening ports TCP 443/443 (https)
    - Egress customisation is available through var.variables input parameters for the `public egress`
1. One transit EGRESS gateway deployment
    - Egress gateway pods located on trait worker pool and HA anti-affinity configured to spread pods on the expected nodes. These can be customised by setting var.transit_egress_pods_affinity and var.transit_egress_tolerations properly
    - Auto-scaling can be customised through var.transit_egress_autoscale_configuration
    - Egress gateway by default opening ports TCP 443/443 (https)
    - Egress customisation is available through var.variables input parameters for the `transit egress`
1. Configures CSE Proxy Envoy Filter
