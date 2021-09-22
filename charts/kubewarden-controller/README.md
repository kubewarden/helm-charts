Kubewarden is a Kubernetes Dynamic Admission Controller that uses policies written
in WebAssembly.

For more information refer to the [official Kubewarden website](https://kubewarden.io/).

# kubewarden-controller

`kubewarden-controller` is a Kubernetes controller that allows you to
dynamically register Kubewarden admission policies.

The `kubewarden-controller` will reconcile the admission policies you
have registered against the Kubernetes webhooks of the cluster where
it is deployed.

## Installation

The kubewarden-controller can be deployed using a helm chart.
To install the kubewarden-controller in an existing cluster, make sure you have
[`cert-manager` installed](https://cert-manager.io/docs/installation/) and then
install the kubewarden-controller.

For example:
```console
$ kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.5.3/cert-manager.yaml
$ helm repo add kubewarden https://charts.kubewarden.io
$ helm install --wait --create-namespace -n kubewarden kubewarden-controller kubewarden/kubewarden-controller
```

This will install cert-manager, and kubewarden-controller on the Kubernetes
cluster in the default configuration (which includes self-signed TLS certs).

The default configuration values should be good enough for the
majority of deployments, all the options are documented
[here](https://charts.kubewarden.io/#configuration).

## Usage

Once the kubewarden-controller is up and running, Kubewarden policies can be defined
via the `ClusterAdmissionPolicy` resource.

The documentation of this Custom Resource can be found
[here](https://github.com/kubewarden/kubewarden-controller/blob/main/docs/crds/README.asciidoc)
or on [docs.crds.dev](https://doc.crds.dev/github.com/kubewarden/kubewarden-controller).

**Note well:** `ClusterAdmissionPolicy` resources are cluster-wide.

### Deploy your first admission policy

The following snippet defines a Kubewarden Policy based on the
[pod-privileged](https://github.com/kubewarden/pod-privileged-policy)
policy:

```yaml
apiVersion: policies.kubewarden.io/v1alpha1
kind: ClusterAdmissionPolicy
metadata:
  name: privileged-pods
spec:
  module: registry://ghcr.io/kubewarden/policies/pod-privileged:v0.1.5
  resources:
  - pods
  operations:
  - CREATE
  - UPDATE
  mutating: false
```

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

```
$ kubectl delete clusteradmissionpolicy privileged-pods
```
