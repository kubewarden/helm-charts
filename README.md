Kubewarden is a Kubernetes Dynamic Admission Controller that uses policies written
in WebAssembly.

For more details refer to the [official Kubewarden website](https://kubewarden.io/).

## Installing the chart

These are the steps needed to install kubewarden-controller using helm:

```shell
$ helm repo add kubewarden https://charts.kubewarden.io
$ helm install --create-namespace -n kubewarden kubewarden-controller kubewarden/kubewarden-controller
```

This will install kubewarden-controller on the Kubernetes cluster in the default
configuration.

The configuration section lists the parameters that can be configured
at installation time.

## Uninstalling the Chart

To uninstall/delete the `kubewarden-controller` release use the following
command:

```bash
$ helm uninstall -n kubewarden kubewarden-controller
```
The command removes all the Kubernetes components associated with the chart and
deletes the release along with the release history.

If you want to keep the history use `--keep-history` flag.

## Configuration

The following tables list the configurable parameters of the kubewarden-controller
chart and their default values.

| Parameter                                  | Description                                                                                                              | Default             |
| ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------ | ------------------- |
| `nameOverride`                             | Replaces the name of the chart in the `Chart.yaml` file when this is is used to construct Kubernetes object names         | ``                  |
| `fullnameOverride`                         | Completely replaces the generated name                                                                                   | ``                  |
| `imagePullSecrets`                         | Secrets to be used to pull container images from a Private Registry. Refer to [official Kubernetes documentation](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) | `[]` |
| `image.repository`                         | The `kubewarden-controller` container image to be used                                                                      | `ghcr.io/kubewarden/kubewarden-controller` |
| `image.tag`                                | The tag of the `kubewarden-controller` container image to be used. When left empty chart's `AppVersion` is going to be used | ``                  |
| `podAnnotations`                           | Extra annotations to add to the `kubewarden-controller` deployment                                                          | `{}`                |
| `nodeSelector`                             | `nodeSelector` for the `kubewarden-controller` deployment                                                                   | `{}`                |
| `tolerations`                              | `tolerations` for the `kubewarden-controller` deployment                                                                    | `{}`                |
| `affinity`                                 | `affinity` rules for the `kubewarden-controller` deployment                                                                 | `{}`                |
| `policyServer.replicaCount`                | Replica size for the `policy-server` deployment                                                                          | `1`                 |
| `policyServer.image.repository`            | The `policy-server` container image to be used                                                                           | `ghcr.io/kubewarden/policy-server` |
| `policyServer.image.tag`                   | The tag of the `policy-server` container image to be used                                                                | ``                  |
