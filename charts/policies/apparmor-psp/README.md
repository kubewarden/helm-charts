Continuous integration | License
 -----------------------|--------
![Continuous integration](https://github.com/kubewarden/apparmor-psp-policy/workflows/Continuous%20integration/badge.svg) | [![License: Apache 2.0](https://img.shields.io/badge/License-Apache2.0-brightgreen.svg)](https://opensource.org/licenses/Apache-2.0)


This Kubewarden Policy is a replacement for the Kubernetes Pod Security Policy
that controls the usage of [AppArmor profiles](https://kubernetes.io/docs/tutorials/clusters/apparmor/).

# How the policy works

This policy works by defining a whitelist of allowed AppArmor profiles. Pods
are then inspected at creation and update time, to ensure only approved
profiles are used.

When no AppArmor profile is defined, Kubernetes will leave the final choice to
the underlying container runtime. This will result in using the default
AppArmor profile provided by Container Runtime. Because of that, the default
behaviour of this policy is to accept workloads that do not have an AppArmor
profile specified.

# Configuration

The policy can be configured with the following data structure:

```yml
# list of allowed profiles
allowed_profiles:
- runtime/default
- localhost/my-special-workload
```

# Examples

## Do not allow `unconfined` workloads

Running a container with the `unconfined` profile is considered a bad
security practice.

This can be prevented by using this setting values:

```yaml
allowed_profiles:
- runtime/default
```

This configuration would allow these Pods:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hello-apparmor
  annotations:
    container.apparmor.security.beta.kubernetes.io/hello: runtime/default
spec:
  containers:
  - name: hello
    image: busybox
    command: [ "sh", "-c", "echo 'Hello AppArmor!' && sleep 1h" ]
---
apiVersion: v1
kind: Pod
metadata:
  name: hello-apparmor-default-profile
spec:
  containers:
  - name: hello
    image: busybox
    command: [ "sh", "-c", "echo 'Hello AppArmor!' && sleep 1h" ]
```

While these Pods would not be allowed on the cluster:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hello-unconfined
  annotations:
    container.apparmor.security.beta.kubernetes.io/hello: unconfined
spec:
  containers:
  - name: hello
    image: busybox
    command: [ "sh", "-c", "echo 'Hello AppArmor!' && sleep 1h" ]
---
apiVersion: v1
kind: Pod
metadata:
  name: hello-custom-profile
  annotations:
    container.apparmor.security.beta.kubernetes.io/hello: localhost/my-custom-profile
spec:
  containers:
  - name: hello
    image: busybox
    command: [ "sh", "-c", "echo 'Hello AppArmor!' && sleep 1h" ]
```

## Limit the AppArmor profiles that can be used

The following profile would force all the workloads to either not specify
an AppArmor profile (and hence use the default one provided by the Container
Runtime) or use one of the approved profiles:

```yaml
allowed_profiles:
- runtime/default
- localhost/my-custom-profile
```

This configuration would allow these Pods:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hello-apparmor
  annotations:
    container.apparmor.security.beta.kubernetes.io/hello: runtime/default
spec:
  containers:
  - name: hello
    image: busybox
    command: [ "sh", "-c", "echo 'Hello AppArmor!' && sleep 1h" ]
---
apiVersion: v1
kind: Pod
metadata:
  name: hello-apparmor-default-profile
spec:
  containers:
  - name: hello
    image: busybox
    command: [ "sh", "-c", "echo 'Hello AppArmor!' && sleep 1h" ]
---
apiVersion: v1
kind: Pod
metadata:
  name: hello-apparmor-custom-profile
  annotations:
    container.apparmor.security.beta.kubernetes.io/hello: localhost/my-custom-profile
spec:
  containers:
  - name: hello
    image: busybox
    command: [ "sh", "-c", "echo 'Hello AppArmor!' && sleep 1h" ]
```

While these Pods would not be allowed on the cluster:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hello-unconfined
  annotations:
    container.apparmor.security.beta.kubernetes.io/hello: unconfined
spec:
  containers:
  - name: hello
    image: busybox
    command: [ "sh", "-c", "echo 'Hello AppArmor!' && sleep 1h" ]
---
apiVersion: v1
kind: Pod
metadata:
  name: hello-unknown-profile
  annotations:
    container.apparmor.security.beta.kubernetes.io/hello: localhost/unknown-profile
spec:
  containers:
  - name: hello
    image: busybox
    command: [ "sh", "-c", "echo 'Hello AppArmor!' && sleep 1h" ]
```

# Obtain policy

The policy is automatically published as an OCI artifact inside of
[this](https://github.com/orgs/kubewarden/packages/container/package/policies%2Fpsp-apparmor)
container registry.

# Using the policy

The easiest way to use this policy is through the [kubewarden-controller](https://github.com/kubewarden/kubewarden-controller).
