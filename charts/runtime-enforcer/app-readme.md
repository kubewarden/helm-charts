# Kubewarden Runtime Enforcer

Kubewarden Runtime Enforcer is a Kubernetes security tool that uses eBPF
(Extended Berkeley Packet Filter) to observe process executions in your
workloads and to enforce allow-list based security policies at the kernel
level.

It operates in three phases:

- **Learn** — observe process executions and generate a `WorkloadPolicyProposal`
  per workload.
- **Monitor** — report violations of an approved `WorkloadPolicy` without
  blocking them.
- **Protect** — block executions that violate the policy allow-list.

For more information refer to the
[documentation](https://docs.kubewarden.io/runtime-enforcer/latest/en/introduction.html).
