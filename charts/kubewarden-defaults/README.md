# kubewarden-defaults

`kubewarden-defaults` is the Helm chart that installs a default PolicyServer
required by the Kubewarden to run `ClusterAdmissionPolicy` and  `AdmissionPolicy`. It should be installed
before installing any policies.


## Enable recommended policies

The chart allows the user to install some recommended policies to enforce some
best practice security checks. By the default, the policies are disabled and the
user must enables this feature. The recommended policies are:

- [allow privilege escalation policy](https://github.com/kubewarden/allow-privilege-escalation-psp-policy): prevents process to gain more privileges.
- [host namespaces policy](https://github.com/kubewarden/host-namespaces-psp-policy): blocks pods trying to share host's IPC, networks and PID namespaces
- [pod privileged policy](https://github.com/kubewarden/pod-privileged-policy): does not allow pod running in privileged mode
- [user-group policy](https://github.com/kubewarden/user-group-psp-policy): prevents pod running with root user

All the policies are installed cluster wide. But they are configured to ignore
namespaces important to run the control plane and Rancher components, like
`kube-system` and `rancher-operator-system` namespaces.

Furthermore, all the policies are installed in "monitor" mode by default. This
means that the policies will **not** block requests. They will report the requests
which violates the policies rules. To change the default policy mode to "protect" mode,
the user can change the default policy mode using the Helm chart value.

For example, if the user wants to install the policies in "protect" mode and ignore the
resources from the "kube-system" and "devel" namespaces, the following command can be used:

```
helm install --set recommendedPolicies.enabled=True --set recommendedPolicies.skipNamespaces=\{kube-system,devel\} --set recommendedPolicies.defaultPolicyMode=protect kubewarden-defaults kubewarden/kubewarden-defaults
```

**WARNING**
Enforcing the policies to the `kube-system` namespace could break your cluster.
Be aware that some pods could need break this rules. Therefore, the user must be
sure which namespaces the policies will be applied. Remember that when you
define the `--set` command line flag the default values are overwritten. So, the
user must define the `kube-system` namespace manually.

Check out the configuration section to see all the configuration options.
The user can also change the policies mode after the installation. See the
Kubewarden documentation to learn more.


## Installing

For example:
```console
$ helm repo add kubewarden https://charts.kubewarden.io
$ helm install --create-namespace -n kubewarden kubewarden-defaults kubewarden/kubewarden-defaults
```

For a more comprehensive documentation about how to install the whole Kubewarden
stack, check the `kubewarden-controller` chart documentation out.

## Upgrading the charts

Please refer to the release notes of each version of the helm charts.
These can be found [here](https://github.com/kubewarden/helm-charts/releases).

## Uninstalling the charts

To uninstall/delete kubewarden-crds use the following command:

```console
$ helm uninstall -n kubewarden kubewarden-defaults
```

The commands remove all the Kubernetes components associated with the chart.
**WARNING!** Keep in mind that the removal of the chart will remove all the
policies running on the `default` Policy Server.

If you want to keep the history use `--keep-history` flag.

## Configuration

The following tables list the configurable parameters of the `kubewarden-defaults`
chart and their default values.

| Parameter                                | Description                                                                                                              | Default             |
| ---------------------------------------  | ------------------------------------------------------------------------------------------------------------------------ | ------------------- |
| `policyServer.replicaCount`              | Replica size for the `policy-server` deployment                                                                          | `1`                 |
| `policyServer.image.repository`          | The `policy-server` container image to be used                                                                           | `ghcr.io/kubewarden/policy-server` |
| `policyServer.image.tag`                 | The tag of the `policy-server` container image to be used                                                                | ``                  |
| `policyServer.telemetry.enabled`         | Enable OpenTelemetry configuration                                                                                       | `False`             |
| `recommendedPolicies.enabled`            | Install the recommended policies                                                                                         | `False`             |
| `recommendedPolicies.skipNamespaces`     | Recommended policies should ignore resources from these namespaces                                                       | `[calico-system, cattle-alerting, cattle-fleet-local-system, cattle-fleet-system, cattle-global-data, cattle-global-nt, cattle-impersonation-system, cattle-istio, cattle-logging, cattle-pipeline, cattle-prometheus, cattle-system, cert-manager, ingress-nginx, kube-node-lease, kube-public, kube-system, rancher-operator-system, security-scan, tigera-operator]` |
| `recommendedPolicies.defaultPolicyMode`  | The policy mode used in all default policies                                                                             | `monitor`           |

