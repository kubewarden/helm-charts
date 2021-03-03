Chimera is a Kubernetes Dynamic Admission Controller that uses policies written
in WebAssembly.

For more details refer to the [official Chimera website](https://chimera-kube.github.io/).

## Installing the chart

These are the steps needed to install chimera-controller using helm:

```shell
$ helm repo add chimera-controller https://chimera-kube.github.io/chimera-controller/
$ helm install chimera-controller chimera-controller/chimera-controller
```

This will install chimera-controller on the Kubernetes cluster in the default
configuration.

The configuration section lists the parameters that can be configured
at installation time.

## Uninstalling the Chart

To uninstall/delete the `chimera-controller` release use the following
command:

```bash
$ helm uninstall chimera-controller
```
The command removes all the Kubernetes components associated with the chart and
deletes the release along with the release history.

If you want to keep the history use `--keep-history` flag.

## Configuration

The following tables list the configurable parameters of the chimera-controller
chart and their default values.

| Parameter                                  | Description                                                                                                              | Default             |
| ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------ | ------------------- |
| `nameOverride`                             | Replaces the name of the chart in the `Chart.yaml` file when this is is used to construct Kubernetes object names         | ``                  |
| `fullnameOverride`                         | Completely replaces the generated name                                                                                   | ``                  |
| `imagePullSecrets`                         | Secrets to be used to pull container images from a Private Registry. Refer to [official Kubernetes documentation](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) | `[]` |
| `image.repository`                         | The `chimera-controller` container image to be used                                                                      | `ghcr.io/chimera-kube/chimera-controller` |
| `image.tag`                                | The tag of the `chimera-controller` container image to be used. When left empty chart's `AppVersion` is going to be used | ``                  |
| `podAnnotations`                           | Extra annotations to add to the `chimera-controller` deployment                                                          | `{}`                |
| `nodeSelector`                             | `nodeSelector` for the `chimera-controller` deployment                                                                   | `{}`                |
| `tolerations`                              | `tolerations` for the `chimera-controller` deployment                                                                    | `{}`                |
| `affinity`                                 | `affinity` rules for the `chimera-controller` deployment                                                                 | `{}`                |
| `policyServer.replicaCount`                | Replica size for the `policy-server` deployment                                                                          | `1`                 |
| `policyServer.image.repository`            | The `policy-server` container image to be used                                                                           | `ghcr.io/chimera-kube/policy-server` |
| `policyServer.image.tag`                   | The tag of the `policy-server` container image to be used                                                                | ``                  |
