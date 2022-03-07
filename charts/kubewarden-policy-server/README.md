# kubewarden-policy-server

`kubewarden-policy-server` is the Helm chart that installs a default Policy Server
required by the Kubewarden to run `ClusterAdmissionPolicy` or `AdmissionPolicy`. It should be installed
before installing any policies.

## Installing

For example:
```console
$ helm repo add kubewarden https://charts.kubewarden.io
$ helm install --create-namespace -n kubewarden kubewarden-policy-server kubewarden/kubewarden-policy-server
```

For a more comprehensive documentation about how to install the whole Kubewarden
stack, check the `kubewarden-controller` chart documentation out.

## Upgrading the charts

Please refer to the release notes of each version of the helm charts.
These can be found [here](https://github.com/kubewarden/helm-charts/releases).

## Uninstalling the charts

To uninstall/delete kubewarden-policy-server use the following command:

```console
$ helm uninstall -n kubewarden kubewarden-policy-server
```

The commands remove all the Kubernetes components associated with the chart.
Keep in mind that the chart is required by the `kubewarden-controller` chart.

If you want to keep the history use `--keep-history` flag.

## Configuration

The following tables list the configurable parameters of the kubewarden-policy-server
chart and their default values.

| Parameter                               | Description                                                                                                              | Default             |
| --------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ | ------------------- |
| `policyServer.replicaCount`             | Replica size for the `policy-server` deployment                                                                          | `1`                 |
| `policyServer.image.repository`         | The `policy-server` container image to be used                                                                           | `ghcr.io/kubewarden/policy-server` |
| `policyServer.image.tag`                | The tag of the `policy-server` container image to be used                                                                | ``                  |
| `policyServer.telemetry.enabled`        | Enable OpenTelemetry configuration                                                                                       | `False`             |
