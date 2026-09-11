# network-enforcer

> [!WARNING]
> This repo is still under active development.
> At the moment is more a research project than a production-ready solution.

Network Enforcer is a Kubernetes-focused project that helps teams move from permissive networking to policy-driven cluster security.

It observes real network flows from running workloads, correlates traffic patterns, and produces `WorkloadNetworkPolicyProposal` resources that describe suggested ingress/egress rules. These proposals can be reviewed and validated before they are enforced, so teams keep control while reducing trial-and-error.

The project is built around two core components: a Kubernetes controller that manages policy proposal lifecycle and reconciliation, and a CNI watcher that gathers network telemetry from the cluster data plane.

The goal is to reduce manual NetworkPolicy authoring effort while improving visibility, consistency, and confidence in workload-to-workload communication boundaries.

## Documentation

### Getting Started

- [Quick Start](https://github.com/kubewarden/network-enforcer/blob/main/docs/installation/quickstart.adoc)
- [Compatibility](https://github.com/kubewarden/network-enforcer/blob/main/docs/compatibility.adoc)
- [Uninstall](https://github.com/kubewarden/network-enforcer/blob/main/docs/installation/uninstall.adoc)

### Usage

- [Phases: Learn, Monitor, Protect](https://github.com/kubewarden/network-enforcer/blob/main/docs/phases.adoc)

## License

Copyright 2026.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
