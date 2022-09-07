Continuous integration | License
 -----------------------|--------
![Continuous integration](https://github.com/kubewarden/psp-capabilities/workflows/Continuous%20integration/badge.svg) | [![License: Apache 2.0](https://img.shields.io/badge/License-Apache2.0-brightgreen.svg)](https://opensource.org/licenses/Apache-2.0)


This Kubewarden Policy is a replacement for the Kubernetes Pod Security Policy
that controls the usage of Containers capabilities:

  * [Deprecated PSP](https://kubernetes.io/docs/concepts/policy/pod-security-policy/#capabilities)
  * [Kubernetes container capabilities feature](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-capabilities-for-a-container)

# How the policy works

The following fields take a list of capabilities, specified as the capability
name in `ALL_CAPS` without the `CAP_` prefix.

* `allowed_capabilities`: provides a list of capabilities that are allowed to be
  added to a container. The default set of capabilities are implicitly allowed.
  The empty set means that no additional capabilities may be added beyond the
  default set. `*` can be used to allow all capabilities.
* `required_drop_capabilities`: the capabilities which must be dropped from
  containers. These capabilities are removed from the default set, and must not
  be added. Capabilities listed in `required_drop_capabilities` must not be
  included in `allowed_capabilities` or `default_add_capabilities`.
* `default_add_capabilities`: the capabilities which are added to containers by
  default, in addition to the runtime defaults. See the documentation of your
  Container Runtime for the default list of capabilities.

The policy validates Pods at creation time and can also mutate them when either the
`required_drop_capabilities` or the `default_add_capabilities` values are specified.

**Note well:** Kubernetes does not allow to change container capabilities after Pod creation
time, hence this policy is interested only in `CREATE` operatoins.

# Configuration

The policy can be configured with the following data structure:

```yml
allowed_capabilities:
- CHOWN

required_drop_capabilities:
- NET_ADMIN

default_add_capabilities:
- KILL
```

# Examples

## Allow only Container Runtime's default capabilities

Each Container Runtime (docker, containerD, CRI-O,...) has a default list of
allowed capabilities.

Deploying the policy with an **empty** configuration ensures no capability can
be added to containers.

For example, the following Pod would be rejected by the policy:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hello
spec:
  containers:
  - name: hello
    image: busybox
    command: [ "sh", "-c", "echo 'Hello!' && sleep 1h" ]
    securityContext:
      capabilities:
        add:
        - NET_ADMIN
```

## Allow only approved capabilities to be added

This configuration allows only approved capabilities to be
added to containers:

```yaml
allowed_capabilities:
- CHOWN
- KILL
```

This configuration would allow these Pods:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hello
spec:
  containers:
  - name: hello
    image: busybox
    command: [ "sh", "-c", "echo 'Hello!' && sleep 1h" ]
    securityContext:
      capabilities:
        add:
        - CHOWN
---
apiVersion: v1
kind: Pod
metadata:
  name: hello2
spec:
  containers:
  - name: hello
    image: busybox
    command: [ "sh", "-c", "echo 'Hello!' && sleep 1h" ]
```

While these Pods would be rejected:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: rejected
spec:
  containers:
  - name: hello
    image: busybox
    command: [ "sh", "-c", "echo 'Hello!' && sleep 1h" ]
    securityContext:
      capabilities:
        add:
        - BPF
---
apiVersion: v1
kind: Pod
metadata:
  name: init-violation
spec:
  containers:
  - name: hello
    image: busybox
    command: [ "sh", "-c", "echo 'Hello!' && sleep 1h" ]
  initContainers:
  - name: init1
    image: busybox
    command: [ "sh", "-c", "echo 'Hello from initContainer" ]
    securityContext:
      capabilities:
        add:
        - MKNOD
```

## Mutate Pods

The policy can mutate Pods at creation time.

Let's take the following configuration:

```yml
allowed_capabilities:
- CHOWN,KILL

required_drop_capabilities:
- NET_ADMIN

default_add_capabilities:
- CHOWN
```

And then try to create this Pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hello
spec:
  containers:
  - name: hello
    image: busybox
    command: [ "sh", "-c", "echo 'Hello!' && sleep 1h" ]
    securityContext:
      capabilities:
        add:
        - KILL
```

The policy would be changed the Pod specification, leading to the creation
of this Pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hello
spec:
  containers:
  - name: hello
    image: busybox
    command: [ "sh", "-c", "echo 'Hello!' && sleep 1h" ]
    securityContext:
      capabilities:
        add:
        - KILL
        - CHOWN
        drop:
        - NET_ADMIN
```

# Obtain policy

The policy is automatically published as an OCI artifact inside of
[this](https://github.com/orgs/kubewarden/packages/container/package/policies%2Fpsp-capabilities)
container registry.

# Using the policy

The easiest way to use this policy is through the [kubewarden-controller](https://github.com/kubewarden/kubewarden-controller).
