# Private ingress and egress ingress LB on transit

Profile with:
1. One private INGRESS gateway deployment deploying the ingress pods on the transit
    - Ingress gateway pods located on transit worker pool and HA anti-affinity configured to spread pods on the expected nodes. These can be customised by setting var.transit_ingress_pods_affinity and var.transit_ingress_tolerations properly
    - Auto-scaling can be customised through var.transit_ingress_autoscale_configuration
    - Ingress gateway by default opening ports TCP 443/8443 (https workload), TCP 15021/15021 (health check port), TCP 15443/15443 (TLS for transit LB)
    - Ingress customisation is available through var.variables input parameters for the `transit ingress`
1. One transit EGRESS gateway deployment
    - Egress gateway pods located on transit worker pool and HA anti-affinity configured to spread pods on the expected nodes. These can be customised by setting var.transit_egress_pods_affinity and var.transit_egress_tolerations properly
    - Auto-scaling can be customised through var.transit_egress_autoscale_configuration
    - Egress gateway by default opening port TCP 443/8443 (https)
    - Egress customisation is available through var.variables input parameters for the `transit egress`
