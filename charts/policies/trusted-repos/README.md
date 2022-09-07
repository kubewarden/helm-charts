Kubewarden policy that allows to restrict what repositories, tags and
images pods in your cluster can refer to.

# What the policy allows to restrict

The policy configuration allows to mix and match several filters:
`registries`, `tags`, and `images`.

When both an allow list and a reject list is supported, only one can
be provided at the same time for that specific filter.

* Registries
  * Allow list
  * Reject list

* Tags
  * Reject list

* Images
  * Allow list
  * Reject list

## Examples

* Only allow images coming from `registry.my-corp.com`:

```yaml
registries:
  allow:
  - registry.my-corp.com
```

* Only reject one host, in this case the Docker Hub:

```yaml
registries:
  reject:
  - docker.io
```

* Reject the latest tag for all images:

```yaml
tags:
  reject:
  - latest
```

* Only reject one specific image, allow the rest:

```yaml
images:
  reject:
  - quay.io/etcd/etcd:v3.4.12
```

* Only accept a well known set of images, reject the rest:

```yaml
images:
  accept:
  - quay.io/coreos/etcd:v3.4.12@sha256:7ed2739c96eb16de3d7169e2a0aa4ccf3a1f44af24f2bb6cad826935a51bcb3d
  - quay.io/bitnami/redis:6.0@sha256:82dfd9ac433eacb5f89e5bf2601659bbc78893c1a9e3e830c5ef4eb489fde079
```
