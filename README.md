Kubewarden is a Kubernetes Dynamic Admission Controller that uses policies written
in WebAssembly.

You can combine all values from all charts on a single `values.yaml` file.

For more information refer to the [official Kubewarden website](https://kubewarden.io/).
# kubewarden-controller

`kubewarden-controller` is a Kubernetes controller that allows you to
dynamically register Kubewarden admission policies.

The `kubewarden-controller` will reconcile the admission policies you
have registered against the Kubernetes webhooks of the cluster where
it is deployed.

The kubewarden-controller can be deployed using a helm chart.

## Installing the charts

Make sure you have [`cert-manager` installed](https://cert-manager.io/docs/installation/)
and then install the kubewarden-controller chart.

If you want to enable telemetry, you also need to install [OpenTelemetry Operator](https://github.com/open-telemetry/opentelemetry-operator).

For example:
```console
$ kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.5.3/cert-manager.yaml
$ helm repo add kubewarden https://charts.kubewarden.io
$ helm install --create-namespace -n kubewarden kubewarden-crds kubewarden/kubewarden-crds
$ helm install --wait -n kubewarden kubewarden-controller kubewarden/kubewarden-controller
$ helm install --wait -n kubewarden kubewarden-defaults kubewarden/kubewarden-defaults
```

This will install cert-manager, kubewarden-crds, kubewarden-controller, and a
default PolicyServer on the Kubernetes cluster in the default configuration
(which includes self-signed TLS certs).

The default configuration values should be good enough for the majority of
deployments. All the options are documented in the configuration section.

## Upgrading the charts

Please refer to the release notes of each version of the helm charts.
These can be found [here](https://github.com/kubewarden/helm-charts/releases).

## Uninstalling the charts

To uninstall/delete kubewarden-controller and kubewarden-crds use the following
command:

```console
$ helm uninstall -n kubewarden kubewarden-defaults
$ helm uninstall -n kubewarden kubewarden-controller
$ helm uninstall -n kubewarden kubewarden-crds
```

The commands remove all the Kubernetes components associated with the chart, all
policy servers and their policies, and deletes the release along with the release
history.

If you want to keep the history use `--keep-history` flag.

## Configuration

See the `values.yaml` file of the chart for the configuration values.

For the default PolicyServer configuration, Check the `kubewarden-defaults`
chart and its documentation.

# Kubewarden usage

Once the kubewarden-controller is up and running, Kubewarden policies can be
defined via the `ClusterAdmissionPolicy` resource.

The documentation of this Custom Resource can be found
[here](https://github.com/kubewarden/kubewarden-controller/blob/main/docs/crds/README.asciidoc)
or on [docs.crds.dev](https://doc.crds.dev/github.com/kubewarden/kubewarden-controller).

**Note well:** `ClusterAdmissionPolicy` resources are cluster-wide.

### Deploy your first admission policy

The following snippet defines a Kubewarden Policy based on the
[pod-privileged](https://github.com/kubewarden/pod-privileged-policy)
policy:

```yaml
kubectl apply -f - <<EOF
---
apiVersion: policies.kubewarden.io/v1alpha2
kind: ClusterAdmissionPolicy
metadata:
  name: privileged-pods
spec:
  policyServer: default
  module: registry://ghcr.io/kubewarden/policies/pod-privileged:v0.1.9
  rules:
    - apiGroups: [""]
      apiVersions: ["v1"]
      resources: ["pods"]
      operations:
        - CREATE
        - UPDATE
  mutating: false
EOF
```

**Note well**: The `ClusterAdmissionPolicy` is deployed in the `default` PolicyServer.
Which is installed in the `kubewarden-defaults` chart. If you do not install
the chart, you should deploy a PolicyServer first. Check out the
[documentation](https://docs.kubewarden.io/quick-start.html#policy-server) for more details

Let's try to create a Pod with no privileged containers:

```shell
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: unprivileged-pod
spec:
  containers:
    - name: nginx
      image: nginx:latest
EOF
```

This will produce the following output, which means the Pod was successfully
created:

`pod/unprivileged-pod created`

Now, let's try to create a pod with at least one privileged container:

```shell
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: privileged-pod
spec:
  containers:
    - name: nginx
      image: nginx:latest
      securityContext:
        privileged: true
EOF
```

This time the creation of the Pod will be blocked, with the following message:

```
Error from server: error when creating "STDIN": admission webhook "privileged-pods.kubewarden.admission" denied the request: User 'minikube-user' cannot schedule privileged containers
```

### Remove your first admission policy

You can delete the admission policy you just created:

```console
$ kubectl delete clusteradmissionpolicy privileged-pods
```

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
`kube-system` and `rancher-operator-system` namespaces. This list of default
ignored namespaces is in the chart values under `recommendedPolicies.skipNamespaces`,
additional namespaces can be excluded using `recommendedPolicies.skipAdditionalNamespaces`.

Furthermore, all the policies are installed in "monitor" mode by default. This
means that the policies will **not** block requests. They will report the requests
which violates the policies rules. To change the default policy mode to "protect" mode,
the user can change the default policy mode using the Helm chart value.

For example, if the user wants to install the policies in "protect" mode and ignore the
resources from the "devel" namespaces, the following command can be used:

```bash
helm install \
    --set recommendedPolicies.enabled=True \
    --set recommendedPolicies.skipAdditionalNamespaces=\{devel\} \
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

See the `values.yaml` file of the chart for the configuration values.

# kubewarden-crds

`kubewarden-crds` is the Helm chart that installs the Custom Resources Definition
required by the Kubewarden stack. It should be installed before installing
`kubewarden-controller` and `kubewarden-defaults` charts.

## Contents

This chart installs Kubewarden CRDs:
  `admissionpolicies.policies.kubewarden.io`
  `clusteradmissionpolicies.policies.kubewarden.io`
  `policyservers.policies.kubewarden.io`

It also installs PolicyReports CRDs:
  `policyreports.wgpolicyk8s.io`
  `clusterpolicyreports.wgpolicyk8s.io`

To skip installing these (maybe because for example they are already installed
and owned by a different Helm Release), set the value `policyReports.enable` to
`false`.

## Installing

For example:
```console
$ helm repo add kubewarden https://charts.kubewarden.io
$ helm install --create-namespace -n kubewarden kubewarden-crds kubewarden/kubewarden-crds
```

For a more comprehensive documentation about how to install the whole Kubewarden
stack, check the `kubewarden-controller` chart documentation out.

## Upgrading the charts

Please refer to the release notes of each version of the helm charts.
These can be found [here](https://github.com/kubewarden/helm-charts/releases).

## Uninstalling the charts

To uninstall/delete kubewarden-crds use the following command:

```console
$ helm uninstall -n kubewarden kubewarden-crds
```

The commands remove all the Kubernetes components associated with the chart.
Keep in mind that the chart is required by the `kubewarden-controller` chart.

If you want to keep the history use `--keep-history` flag.
