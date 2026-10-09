# Kubewarden Network Enforcer

> [!WARNING]
> This project is experimental and under active development. It is not yet
> a production-ready solution.

Kubewarden Network Enforcer is a Kubernetes security tool that observes real
network flows from running workloads and produces `WorkloadNetworkPolicyProposal`
resources with suggested ingress and egress rules.

It operates in three phases:

- **Learn** — observe network flows and generate a `WorkloadNetworkPolicyProposal`
  per workload.
- **Monitor** — report flows that violate an approved `WorkloadNetworkPolicy`
  without blocking them.
- **Protect** — enforce the approved policy and block flows that violate it.

The controller reads flow telemetry from the configured data-plane provider:
Istio ambient (ztunnel and fluent-bit), Calico Goldmane, or Cilium Hubble Relay.

For more information refer to the
[documentation](https://docs.kubewarden.io/network-enforcer/latest/en/introduction.html).
