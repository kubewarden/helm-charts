[![Kubewarden Core Repository](https://github.com/kubewarden/community/blob/main/badges/kubewarden-core.svg)](https://github.com/kubewarden/community/blob/main/REPOSITORIES.md#core-scope)
[![Incubating](https://img.shields.io/badge/status-incubating-orange?style=for-the-badge)](https://github.com/kubewarden/community/blob/main/REPOSITORIES.md#incubating)
[![Artifact HUB](https://img.shields.io/badge/ArtifactHub-Helm_Charts-blue?style=flat&logo=artifacthub&link=https%3A%2F%2Fartifacthub.io%2Fpackages%2Fsearch%3Frepo%3Dkubewarden%26kind%3D0%26verified_publisher%3Dtrue%26official%3Dtrue%26cncf%3Dtrue%26sort%3Drelevance%26page%3D1)](https://artifacthub.io/packages/search?repo=kubewarden&kind=0&verified_publisher=true&official=true&cncf=true&sort=relevance&page=1)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/kubewarden/runtime-enforcer/badge)](https://scorecard.dev/viewer/?uri=github.com/kubewarden/runtime-enforcer)
[![CLOMonitor](https://img.shields.io/endpoint?url=https://clomonitor.io/api/projects/cncf/kubewarden/badge)](https://clomonitor.io/projects/cncf/kubewarden)

# Kubewarden Runtime Enforcer

Kubewarden Runtime Enforcer is a Kubernetes security tool that uses eBPF
(Extended Berkeley Packet Filter) to observe process executions in your
workloads and to enforce allow-list based security policies at the kernel
level.

It operates in three phases:

- **Learn** — observe process executions and generate a `WorkloadPolicyProposal`
  per workload.
- **Monitor** — report violations of an approved `WorkloadPolicy` without
  blocking them.
- **Protect** — block executions that violate the policy allow-list.

The project is in Beta. The design documents are in the [RFCs](docs/rfc).

## Documentation

The full documentation is available at
[docs.kubewarden.io/runtime-enforcer](https://docs.kubewarden.io/runtime-enforcer/latest/en/introduction.html).

- [Kubewarden Runtime Enforcer Quick Start](https://docs.kubewarden.io/runtime-enforcer/latest/en/installation/quickstart.html)
  — deploy Runtime Enforcer and walk through the learn/monitor/protect workflow.
- [Compatibility](https://docs.kubewarden.io/runtime-enforcer/latest/en/compatibility.html)
  — kernel, architecture and platform requirements.
- [Kubewarden Runtime Enforcer phases: learn, monitor, protect](https://docs.kubewarden.io/runtime-enforcer/latest/en/phases.html)
  — understand the learn, monitor and protect phases in detail.

## Installation

Runtime Enforcer is deployed with a Helm chart. The chart is published at
https://charts.kubewarden.io.

The chart needs Kubernetes 1.31 or later. The nodes must run containerd or
CRI-O with NRI (Node Resource Interface) enabled. See
[Compatibility](https://docs.kubewarden.io/runtime-enforcer/latest/en/compatibility.html)
for the kernel and runtime requirements.

The chart needs [cert-manager](https://cert-manager.io/) and the
[cert-manager-csi-driver](https://cert-manager.io/docs/usage/csi-driver/)
in the cluster. The
[Quick Start](https://docs.kubewarden.io/runtime-enforcer/latest/en/installation/quickstart.html)
shows how to install them.

Runtime Enforcer ships with a standalone OTEL collector Deployment that handles
violation metrics and events forwarding. No external OpenTelemetry Collector is
needed for a basic setup.

```sh
helm repo add kubewarden https://charts.kubewarden.io
helm repo update
helm install runtime-enforcer kubewarden/runtime-enforcer \
  --namespace runtime-enforcer \
  --create-namespace \
  --wait
```

After installation, ensure all pods are running:

```sh
kubectl get pods -n runtime-enforcer
```

## Configuration

The top-level keys of [`values.yaml`](charts/runtime-enforcer/values.yaml):

| Key                | Description                                                                                          |
| ------------------ | ---------------------------------------------------------------------------------------------------- |
| `controller`       | The controller Deployment: image, resources, security context, scheduling, PodDisruptionBudget.      |
| `agent`            | The agent DaemonSet that loads the eBPF programs on each node: image, capabilities, NRI socket path. |
| `debugger`         | An optional debugger Deployment. Disabled by default.                                                |
| `learning`         | The `namespaceSelector` that limits the namespaces where learning mode is active.                    |
| `telemetry`        | The OTEL collector strategy: `none`, `default` (bundled collector), or `external`.                   |
| `priorityClass`    | The PriorityClass shared by the controller and agent pods.                                           |
| `imagePullSecrets` | Secrets with private registry credentials.                                                           |

See the comments in `values.yaml` for the full list of options.

### CRDs

CRDs are installed with the `helm.sh/resource-policy: keep` annotation:

- `helm upgrade` updates CRDs normally
- `helm uninstall` does not delete CRDs, which prevents cascade-deletion of all WorkloadPolicies and WorkloadPolicyProposals in the cluster

#### Reinstalling under a different release name or namespace

Because the CRDs are kept on uninstall, they survive with the Helm
ownership metadata of the release that created them
(`meta.helm.sh/release-name` and `meta.helm.sh/release-namespace`). Helm
checks this metadata on the next install:

- Same release name **and** namespace: Helm adopts the existing CRDs and
  the install succeeds.
- Different release name **or** namespace: Helm refuses to take over the
  CRDs and the install fails with:

  ```
  Error: ... invalid ownership metadata; annotation
  meta.helm.sh/release-name must equal "<new>": current value is "<old>"
  ```

This is expected: the CRDs still belong to the previous release. To adopt
them into the new release, install with `--take-ownership` (Helm 3.18+ or
Helm 4), which re-stamps the ownership metadata:

```sh
helm install <release> <chart> -n <namespace> --take-ownership
```

## Uninstall

```sh
helm uninstall runtime-enforcer --namespace runtime-enforcer
```

Note that this command won't delete the existing WorkloadPolicy and
WorkloadPolicyProposal.

To remove them, you can run the following commands:

```sh
kubectl delete crd workloadpolicies.runtimeenforcer.kubewarden.io
kubectl delete crd workloadpolicyproposals.runtimeenforcer.kubewarden.io
```

> [!NOTE]
> Deletion of a `WorkloadPolicy` will fail while at least one pod is still
> referencing it. Remove the pod(s) first, then delete the policy.

Finally, delete the namespace where Runtime Enforcer was deployed:

```sh
kubectl delete ns runtime-enforcer
```

# Software bill of materials & provenance

All Kubewarden components has its software bill of materials (SBOM) and build
[Provenance](https://slsa.dev/spec/v1.0/provenance) information published every
release. It follows the [SPDX](https://spdx.dev/) format and
[SLSA](https://slsa.dev/provenance/v0.2#schema) provenance schema.
Both of the files are generated by [Docker
buildx](https://docs.docker.com/build/metadata/attestations/) during the build
process and stored in the container registry together with the container image
as well as upload in the release page.

You can find them together with the signature and certificate used to sign it
in the [release
assets](https://github.com/kubewarden/runtime-enforcer/releases), and
attached to the image as JSON-encoded documents following the [in-toto SPDX
predicate](https://github.com/in-toto/attestation/blob/main/spec/predicates/spdx.md)
format. You can obtain them with
[`crane`](https://github.com/google/go-containerregistry/blob/main/cmd/crane/README.md)
or [`docker buildx imagetools
inspect`](https://docs.docker.com/reference/cli/docker/buildx/imagetools/inspect).

Runtime Enforcer publishes three images: `controller`, `agent` and `debugger`.
The release assets follow the pattern
`RuntimeEnforcer-<component>-attestation-<arch>-<provenance|sbom>.<ext>`.

Runtime Enforcer signs the container images and the SBOM and provenance
files. The signatures use keyless signing with the GitHub Actions OIDC
identity of the release workflow.

To verify the signature of an image, run:

```shell
cosign verify --certificate-oidc-issuer=https://token.actions.githubusercontent.com  \
    --certificate-identity="https://github.com/kubewarden/runtime-enforcer/.github/workflows/release.yml@<TAG TO VERIFY>" \
    ghcr.io/kubewarden/runtime-enforcer/controller:<TAG TO VERIFY>
```

The command works with a tag and with a digest. The release signs the
multi-architecture image and each single-architecture image.

To verify the provenance file from the release assets, run:

```shell
cosign verify-blob --certificate-oidc-issuer=https://token.actions.githubusercontent.com  \
    --certificate-identity="https://github.com/kubewarden/runtime-enforcer/.github/workflows/release.yml@<TAG TO VERIFY>" \
    --bundle RuntimeEnforcer-controller-attestation-amd64-provenance.intoto.jsonl.bundle.sigstore \
    RuntimeEnforcer-controller-attestation-amd64-provenance.intoto.jsonl
```

To verify the SBOM file, use the same command with the `sbom.json` files:

```shell
cosign verify-blob --certificate-oidc-issuer=https://token.actions.githubusercontent.com  \
    --certificate-identity="https://github.com/kubewarden/runtime-enforcer/.github/workflows/release.yml@<TAG TO VERIFY>" \
    --bundle RuntimeEnforcer-controller-attestation-amd64-sbom.json.bundle.sigstore \
    RuntimeEnforcer-controller-attestation-amd64-sbom.json
```

> [!NOTE]
> The commands in this section use the `controller` image. The same commands
> work for the `agent` and `debugger` images.

The SBOM and provenance files are also attached to the image in the registry.
Docker Buildx stores them in one attestation manifest per architecture. The
registry copy is not signed. The signed copies are the release assets.

To list the attestation manifests of a tag, run:

```shell
crane manifest ghcr.io/kubewarden/runtime-enforcer/controller:<TAG TO VERIFY> | jq '.manifests[] | select(.annotations["vnd.docker.reference.type"]=="attestation-manifest")'
```

Each attestation manifest has one layer per SBOM or provenance file. To list
the layers, run:

```shell
crane manifest ghcr.io/kubewarden/runtime-enforcer/controller@sha256:<ATTESTATION MANIFEST DIGEST>
```

To download one file, use the digest of its layer:

```shell
crane blob ghcr.io/kubewarden/runtime-enforcer/controller@sha256:<LAYER DIGEST>
```

## Security disclosure

See the [Kubewarden security policy](https://github.com/kubewarden/community/security/policy).

## Build with the community

Runtime Enforcer is part of [Kubewarden](https://www.kubewarden.io/), a CNCF
Sandbox project. Rancher by SUSE developed it first.

Get help, share an idea, or improve these docs.

- [Join us on Slack](https://kubernetes.slack.com/?redir=%2Fmessages%2Fkubewarden)
- [Community meetings](https://www.kubewarden.io/#get-in-touch)
- [Contribute to the docs](https://github.com/kubewarden/docs)

# Changelog

See [GitHub Releases content](https://github.com/kubewarden/runtime-enforcer/releases).
