# Kubewarden helm-charts

Welcome to the Kubewarden project.

Since the 1.36 release of Kubewarden Admission Controller the Kubewarden project
comprises two components, the Kubewarden Admission Controller and SBOMScanner.

Before that the Kubewarden project was a single component, the Kubewarden
Admission Controller, known simply as Kubewarden. Since 1.36, the Kubewarden
project is a collection of components, and the Kubewarden Admission Controller
and SBOMScanner are the first two of those components.

## Charts

- [`admission-controller`](./admission-controller): the Kubewarden Admission
  Controller, a Kubernetes Dynamic Admission Controller that uses policies
  written in WebAssembly. This chart installs the whole stack: the CRDs, the
  controller and a default PolicyServer.
- [`sbomscanner`](./sbomscanner): a SBOM-centric security scanner for Kubernetes.

### Deprecated charts

The Kubewarden Admission Controller used to be installed through three separate
charts, which are now deprecated in favor of the unified
[`admission-controller`](./admission-controller) chart:

- [`kubewarden-crds`](./kubewarden-crds)
- [`kubewarden-controller`](./kubewarden-controller)
- [`kubewarden-defaults`](./kubewarden-defaults)

For more information refer to the [official Kubewarden website](https://kubewarden.io/).
