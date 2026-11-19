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

The project is in Beta. The design documents are in the
[RFCs](https://github.com/kubewarden/runtime-enforcer/tree/main/docs/rfc).

## Documentation

The full documentation is available at
[docs.kubewarden.io/runtime-enforcer](https://docs.kubewarden.io/runtime-enforcer/latest/en/introduction.html).

- [Kubewarden Runtime Enforcer Quick Start](https://docs.kubewarden.io/runtime-enforcer/latest/en/installation/quickstart.html)
  — deploy Runtime Enforcer and walk through the learn/monitor/protect workflow.
- [Compatibility](https://docs.kubewarden.io/runtime-enforcer/latest/en/compatibility.html)
  — kernel, architecture and platform requirements.
- [Kubewarden Runtime Enforcer phases: learn, monitor, protect](https://docs.kubewarden.io/runtime-enforcer/latest/en/phases.html)
  — understand the learn, monitor and protect phases in detail.

This repository also documents two command-line tools:

- [kubectl runtime-enforcer](docs/kubectl_plugin.adoc)
  — manage `WorkloadPolicyProposal` and `WorkloadPolicy` resources in a cluster.
- [wpgen](docs/wpgen.adoc)
  — draft a `WorkloadPolicy` from container images, without a cluster.

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

The chart does not deploy an OpenTelemetry collector. The controller and the
agent export metrics and violation events to a collector that you deploy. To
turn on the export, set `global.otel.endpoint`.

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

The top-level keys of [`values.yaml`](https://github.com/kubewarden/runtime-enforcer/blob/main/charts/runtime-enforcer/values.yaml):

| Key                 | Description                                                                                                  |
| ------------------- | ------------------------------------------------------------------------------------------------------------ |
| `namespaceOverride` | The namespace of the chart resources. If it is empty, the chart uses the release namespace.                  |
| `global`            | The values for all workloads: registry, pull secrets, log level, labels, scheduling, extra env, `otel`.      |
| `otel`              | The telemetry export of this chart. A key that is set here wins over the workload `otel` and `global.otel`.  |
| `controller`        | The controller Deployment: image, replicas, resources, security context, PodDisruptionBudget.                |
| `agent`             | The agent DaemonSet that loads the eBPF programs on each node: image, capabilities, NRI socket path.         |
| `debugger`          | An optional debugger Deployment. Disabled by default.                                                        |
| `learning`          | The `namespaceSelector` that limits the namespaces where learning mode is active.                            |
| `priorityClass`     | The PriorityClass shared by the controller and agent pods. A `priorityClassName` overrides it.               |

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
identity of the shared `container-release.yml` reusable workflow in the
`kubewarden/github-actions` repository. The `@<ref>` part of that identity is
the commit of the reusable workflow, not the Runtime Enforcer tag, so the
commands match it with `--certificate-identity-regexp`. That identity alone names the
builder, not the release. The commands also pin the caller repository and the
release tag with `--certificate-github-workflow-repository` and
`--certificate-github-workflow-ref`, so a signed file from another repository
or another release does not pass. The flags do not bind the component. Every
component of one release shares these certificate values, so a blob and its
bundle from one component verify under another component's filename. To check
which image a file describes, read the `subject` field inside the file.

The same workflow runs `actions/attest` on each multi-architecture image. That
attestation gives the images SLSA Build L3. To verify it, run:

```shell
gh attestation verify oci://ghcr.io/kubewarden/runtime-enforcer/controller:<TAG TO VERIFY> \
    --repo kubewarden/runtime-enforcer \
    --signer-workflow kubewarden/github-actions/.github/workflows/container-release.yml
```

To verify the cosign signature of an image, run:

```shell
cosign verify --certificate-oidc-issuer=https://token.actions.githubusercontent.com  \
    --certificate-identity-regexp='^https://github\.com/kubewarden/github-actions/\.github/workflows/container-release\.yml@' \
    --certificate-github-workflow-repository=kubewarden/runtime-enforcer \
    --certificate-github-workflow-ref='refs/tags/<TAG TO VERIFY>' \
    ghcr.io/kubewarden/runtime-enforcer/controller:<TAG TO VERIFY>
```

The command works with a tag and with a digest. The release signs the
multi-architecture image and each single-architecture image.

To verify the provenance file from the release assets, run:

```shell
cosign verify-blob --certificate-oidc-issuer=https://token.actions.githubusercontent.com  \
    --certificate-identity-regexp='^https://github\.com/kubewarden/github-actions/\.github/workflows/container-release\.yml@' \
    --certificate-github-workflow-repository=kubewarden/runtime-enforcer \
    --certificate-github-workflow-ref='refs/tags/<TAG TO VERIFY>' \
    --bundle RuntimeEnforcer-controller-attestation-amd64-provenance.intoto.jsonl.bundle.sigstore \
    RuntimeEnforcer-controller-attestation-amd64-provenance.intoto.jsonl
```

To verify the SBOM file, use the same command with the `sbom.json` files:

```shell
cosign verify-blob --certificate-oidc-issuer=https://token.actions.githubusercontent.com  \
    --certificate-identity-regexp='^https://github\.com/kubewarden/github-actions/\.github/workflows/container-release\.yml@' \
    --certificate-github-workflow-repository=kubewarden/runtime-enforcer \
    --certificate-github-workflow-ref='refs/tags/<TAG TO VERIFY>' \
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

## Provenance, SBOM and signatures of the kubectl plugin and wpgen binaries

The release assets include the `kubectl-runtime_enforcer` and `wpgen` binaries
for `linux` and `darwin`, on `amd64` and `arm64`. Each binary has SLSA Build L3
provenance, an SBOM, and a keyless cosign signature.

The release workflow calls the reusable workflow `go-binary-release.yml` in
this repository. That workflow builds the binaries and creates the SBOM files
in one job. A second job signs and attests them. The build job cannot sign,
because it has no OIDC token. The second job runs no code from the repository.

Each binary has these release assets, where `<binary>` is the name of the file,
for example `wpgen-linux-amd64`:

- `<binary>.sha256`: the checksum of the binary.
- `<binary>.bundle.sigstore`: the cosign signature of the binary.
- `<binary>-sbom.spdx.json`: the SBOM of the binary, in the SPDX format.
- `<binary>-sbom.spdx.json.bundle.sigstore`: the cosign signature of the SBOM.

To verify the provenance of a binary that you downloaded, run:

```shell
gh attestation verify kubectl-runtime_enforcer-linux-amd64 \
    --repo kubewarden/runtime-enforcer \
    --signer-workflow kubewarden/runtime-enforcer/.github/workflows/go-binary-release.yml
```

To verify the SBOM attestation of the same binary, add the SBOM predicate type:

```shell
gh attestation verify kubectl-runtime_enforcer-linux-amd64 \
    --repo kubewarden/runtime-enforcer \
    --signer-workflow kubewarden/runtime-enforcer/.github/workflows/go-binary-release.yml \
    --predicate-type https://spdx.dev/Document/v2.3
```

To verify the cosign signature of a binary, run:

```shell
cosign verify-blob --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
    --certificate-identity='https://github.com/kubewarden/runtime-enforcer/.github/workflows/go-binary-release.yml@refs/tags/<TAG TO VERIFY>' \
    --bundle kubectl-runtime_enforcer-linux-amd64.bundle.sigstore \
    kubectl-runtime_enforcer-linux-amd64
```

To verify the SBOM file, use the same command with the `-sbom.spdx.json` files.

> [!NOTE]
> The commands in this section use the `kubectl-runtime_enforcer-linux-amd64`
> binary. The same commands work for the other binaries and for `wpgen`.

The signer identity names a workflow file in this repository. A verifier that
pins this identity trusts every commit of that file. The same repository holds
the workflow and the source code that the workflow builds.

The `.sha256` files only help you to detect a corrupt download. They do not
prove where the binary came from. Use the provenance or the signature for that.

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
