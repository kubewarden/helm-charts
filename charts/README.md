# Kubewarden helm-charts

Kubewarden is a Kubernetes Dynamic Admission Controller that uses policies written
in WebAssembly.

You can combine all values from all charts on a single `values.yaml` file.

_**Note:**_ [`kubewarden-crds`](./kubewarden-crds) is the Helm chart that installs the Custom Resources Definition required by the Kubewarden stack. It should be installed before installing [`kubewarden-controller`](./kubewarden-controller) and [`kubewarden-defaults`](./kubewarden-defaults) charts.

For more information refer to the [official Kubewarden website](https://kubewarden.io/).
