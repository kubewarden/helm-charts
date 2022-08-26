# kubewarden-defaults

`kubewarden-defaults` is the Helm chart that installs a default PolicyServer
required by the Kubewarden to run `ClusterAdmissionPolicy` and  `AdmissionPolicy`. It should be installed
before installing any policies.


## Enable recommended policies

The chart allows the user to install some recommended policies to enforce some
best practice security checks. ***By the default, the policies are disabled and the
user must enable this feature.*** The recommended policies are:

- [`allow-privilege-escalation-psp` policy](https://github.com/kubewarden/allow-privilege-escalation-psp-policy): prevents process to gain more privileges.
- [`host-namespaces-psp` policy](https://github.com/kubewarden/host-namespaces-psp-policy): blocks pods trying to share host's IPC, networks and PID namespaces
- [`pod-privileged` policy](https://github.com/kubewarden/pod-privileged-policy): does not allow pod running in privileged mode
- [`user-group-psp` policy](https://github.com/kubewarden/user-group-psp-policy): prevents pod running with root user
- [`hostpaths-psp` policy](https://github.com/kubewarden/hostpaths-psp-policy): prevents containers from accessing host paths when  hosthPath volumes are defined
- [`capabilities-psp` policy](https://github.com/kubewarden/capabilities-psp-policy): prevents containers from adding Linux capabilities

All the policies are installed cluster wide. But they are configured to ignore
namespaces important to run the control plane and Rancher components, like
`kube-system` and `rancher-operator-system` namespaces.

Furthermore, all the policies are installed in "monitor" mode by default. This
means that the policies will **not** block requests. They will report the requests
which violates the policies rules. To change the default policy mode to "protect" mode,
the user can change the default policy mode using the Helm chart value.

For example, if the user wants to install the policies in "protect" mode and ignore the
resources from the "kube-system" and "devel" namespaces, the following command can be used:

```bash
helm install \
    --set recommendedPolicies.enabled=True \
    --set recommendedPolicies.skipNamespaces=\{kube-system,devel\} \
    --set recommendedPolicies.defaultPolicyMode=protect \
  kubewarden-defaults kubewarden/kubewarden-defaults
```

**WARNING**
Enforcing the policies to the `kube-system` namespace could break your cluster.
Be aware that some pods could need break this rules. Therefore, the user must be
sure which namespaces the policies will be applied. Remember that when you define the `--set` command line flag the default values are overwritten. So, the
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

| Parameter                                                          | Description                                                                                                              | Default             |
| ------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------ | ------------------- |
| `policyServer.replicaCount`                                        | Replica size for the `policy-server` deployment                                                                          | `1`                 |
| `policyServer.image.repository`                                    | The `policy-server` container image to be used                                                                           | `ghcr.io/kubewarden/policy-server` |
| `policyServer.image.tag`                                           | The tag of the `policy-server` container image to be used                                                                | ``                  |
| `policyServer.telemetry.enabled`                                   | Enable OpenTelemetry configuration                                                                                       | `False`             |
| `policyServer.imagePullSecret`                                     | Name of ImagePullSecret secret in the same namespace, used both for pulling the container images and the policies from OCI repositories. | `` |
| `policyServer.insecureSources`                                     | List of insecure URIs to policy repositories.                                                                            | `[]`                |
| `policyServer.sourceAuthorities`                                   | Registry URIs endpoints to a list of their associated PEM encoded certificate authorities that have to be used to verify the certificate used by the endpoint. | `{}` |
| `recommendedPolicies.enabled`                                      | Install the recommended policies                                                                                         | `False`             |
| `recommendedPolicies.skipNamespaces`                               | Recommended policies should ignore resources from these namespaces                                                       | `[calico-system, cattle-alerting, cattle-fleet-local-system, cattle-fleet-system, cattle-global-data, cattle-global-nt, cattle-impersonation-system, cattle-istio, cattle-logging, cattle-pipeline, cattle-prometheus, cattle-system, cert-manager, ingress-nginx, kube-node-lease, kube-public, kube-system, rancher-operator-system, security-scan, tigera-operator]` |
| `recommendedPolicies.defaultPolicyMode`                            | The policy mode used in all default policies                                                                             | `monitor`           |
| `recommendedPolicies.allowPrivilegeEscalationPolicy.module`        | Module used to deploy the `allow-privilege-escalation-psp` policy                                                        | `ghcr.io/kubewarden/policies/allow-privilege-escalation-psp:v0.1.11` |
| `recommendedPolicies.allowPrivilegeEscalationPolicy.name`          | Name of the `allow-privilege-escalation-psp` policy                                                                      | `no-privilege-escalation` |
| `recommendedPolicies.hostNamespacePolicy.module`                   | Module used to deploy the `host-namespaces-psp` policy                                                                   | `ghcr.io/kubewarden/policies/host-namespaces-psp:v0.1.2` |
| `recommendedPolicies.hostNamespacePolicy.name`                     | Name of the `host-namespaces-psp-policy` policy                                                                          | `no-host-namespaces-sharing` |
| `recommendedPolicies.podPrivilegedPolicy.module`                   | Module user to deploy the `pod-privileged` policy                                                                        | `ghcr.io/kubewarden/policies/pod-privileged:v0.2.1` |
| `recommendedPolicies.podPrivilegedPolicy.name`                     | Name of the `pod-privileged` policy                                                                                      | `no-privileged-pod` |
| `recommendedPolicies.userGroupPolicy.module`                       | Module used to deploy the `user-group-psp` policy                                                                        | `ghcr.io/kubewarden/policies/user-group-psp-policy:v0.2.0` |
| `recommendedPolicies.userGroupPolicy.name`                         | Name of the `user-group-psp` policy                                                                                      | `do-not-run-as-root` |
| `recommendedPolicies.hostPathsPolicy.module`                       | Module used to deploy `hostpaths-psp` policy                                                                             | `ghcr.io/kubewarden/policies/hostpaths-psp:v0.1.5` |
| `recommendedPolicies.hostPathsPolicy.name`                         | Name of the `hostpaths-psp` policy                                                                                       | `do-not-share-hostpaths` |
| `recommendedPolicies.hostPathsPolicy.paths`                        | Paths allowed to be accessed by containers                                                                               | `[{ pathPrefix: "/tmp", readOnly: true }]` |
| `recommendedPolicies.capabilitiesPolicy.module`                    | Module used to deploy the `capabilities-psp` policy                                                                      | `ghcr.io/kubewarden/policies/capabilities-psp:v0.1.9`|
| `recommendedPolicies.capabilitiesPolicy.name`                      | Name of the `capabilities-psp` policy                                                                                    | `"drop-capabilities"`|
| `recommendedPolicies.capabilitiesPolicy.allowed_capabilities`      | Capabilities allowed to be added to a container                                                                          | `[]` |
| `recommendedPolicies.capabilitiesPolicy.required_drop_capabilities`| Capabilities that must be dropped from containers                                                                        | `[ALL]`|
| `recommendedPolicies.capabilitiesPolicy.default_add_capabilities`  | Capabilities added to containers by default                                                                              | `[]`|
