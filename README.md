# Kubewarden helm-charts

Welcome to the Kubewarden project.

The Kubewarden project comprises two components: Admission Controller and SBOMScanner.

The Kubewarden Admission Controller is a Kubernetes Dynamic Admission Controller
that uses policies written in WebAssembly.

SBOMScanner is a SBOM-centric security scanner for Kubernetes. It can scan container
registries, container images running inside of your cluster and even the nodes of
your Kubernetes cluster.

## Charts

- [`admission-controller`](https://github.com/kubewarden/helm-charts/tree/main/charts/admission-controller): the chart installing the
  Kubewarden Admission Controller.
- [`sbomscanner`](https://github.com/kubewarden/helm-charts/tree/main/charts/sbomscanner): the chart installing SBOMscanner.

### Deprecated charts

The Kubewarden Admission Controller used to be installed through three separate
charts, which are now deprecated in favor of the unified
[`admission-controller`](https://github.com/kubewarden/helm-charts/tree/main/charts/admission-controller) chart:

- [`kubewarden-crds`](https://github.com/kubewarden/helm-charts/tree/main/charts/kubewarden-crds)
- [`kubewarden-controller`](https://github.com/kubewarden/helm-charts/tree/main/charts/kubewarden-controller)
- [`kubewarden-defaults`](https://github.com/kubewarden/helm-charts/tree/main/charts/kubewarden-defaults)

For more information refer to the [official Kubewarden website](https://kubewarden.io/).
