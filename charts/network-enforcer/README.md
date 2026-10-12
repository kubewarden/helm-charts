[![Kubewarden Core Repository](https://github.com/kubewarden/community/blob/main/badges/kubewarden-core.svg)](https://github.com/kubewarden/community/blob/main/REPOSITORIES.md#core-scope)
[![Sandbox](https://img.shields.io/badge/status-sandbox-red?style=for-the-badge)](https://github.com/kubewarden/community/blob/main/REPOSITORIES.md#sandbox)
[![Artifact HUB](https://img.shields.io/badge/ArtifactHub-Helm_Charts-blue?style=flat&logo=artifacthub&link=https%3A%2F%2Fartifacthub.io%2Fpackages%2Fsearch%3Frepo%3Dkubewarden%26kind%3D0%26verified_publisher%3Dtrue%26official%3Dtrue%26cncf%3Dtrue%26sort%3Drelevance%26page%3D1)](https://artifacthub.io/packages/search?repo=kubewarden&kind=0&verified_publisher=true&official=true&cncf=true&sort=relevance&page=1)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/kubewarden/network-enforcer/badge)](https://scorecard.dev/viewer/?uri=github.com/kubewarden/network-enforcer)
[![CLOMonitor](https://img.shields.io/endpoint?url=https://clomonitor.io/api/projects/cncf/kubewarden/badge)](https://clomonitor.io/projects/cncf/kubewarden)

# Kubewarden Network Enforcer

> [!WARNING]
> This project is experimental and under active development. It is not yet
> a production-ready solution.

Kubewarden Network Enforcer is a Kubernetes security tool that helps teams
move from permissive networking to policy-driven cluster security.

It observes real network flows from running workloads, correlates traffic
patterns, and produces `WorkloadNetworkPolicyProposal` resources that describe
suggested ingress and egress rules. Teams review and approve these proposals
before they are enforced, so they keep control while reducing trial-and-error.

It operates in three phases:

- **Learn** — observe network flows and generate a `WorkloadNetworkPolicyProposal`
  per workload.
- **Monitor** — report flows that violate an approved `WorkloadNetworkPolicy`
  without blocking them.
- **Protect** — enforce the approved policy and block flows that violate it.

The project is built around a Kubernetes controller that manages the proposal
and policy lifecycle. The controller reads flow telemetry from the configured
data-plane provider: Istio ambient (ztunnel and fluent-bit), Calico Goldmane,
or Cilium Hubble Relay.

The design documents are in the
[RFCs](https://github.com/kubewarden/network-enforcer/tree/main/docs/rfc).

## Documentation

The full documentation is available at
[docs.kubewarden.io/network-enforcer](https://docs.kubewarden.io/network-enforcer/latest/en/introduction.html).

- [Quick Start](https://docs.kubewarden.io/network-enforcer/latest/en/installation/quickstart.html)
  — deploy Network Enforcer and walk through the learn/monitor/protect workflow.
- [Compatibility](https://docs.kubewarden.io/network-enforcer/latest/en/compatibility.html)
  — provider and platform requirements.
- [Phases: learn, monitor, protect](https://docs.kubewarden.io/network-enforcer/latest/en/phases.html)
  — understand the learn, monitor and protect phases in detail.

## Installation

Network Enforcer is deployed with a Helm chart. The chart is published at
https://charts.kubewarden.io.

The chart needs Kubernetes 1.31 or later. The cluster must run one of the
supported data-plane providers: Istio ambient, Calico with Goldmane, or Cilium
with Hubble Relay. See
[Compatibility](https://docs.kubewarden.io/network-enforcer/latest/en/compatibility.html)
for the provider requirements.

The chart needs [cert-manager](https://cert-manager.io/) and the
[cert-manager-csi-driver](https://cert-manager.io/docs/usage/csi-driver/)
in the cluster. The
[Quick Start](https://docs.kubewarden.io/network-enforcer/latest/en/installation/quickstart.html)
shows how to install them.

Network Enforcer ships with a standalone OTEL collector Deployment that handles
violation metrics and events forwarding. No external OpenTelemetry Collector is
needed for a basic setup.

```sh
helm repo add kubewarden https://charts.kubewarden.io
helm repo update
helm install network-enforcer kubewarden/network-enforcer \
  --namespace network-enforcer \
  --create-namespace \
  --set controller.provider.name=istio \
  --wait
```

Set `controller.provider.name` to `istio`, `cilium`, or `calico` to match the
data-plane provider running in your cluster.

After installation, ensure all pods are running:

```sh
kubectl get pods -n network-enforcer
```

## Configuration

The top-level keys of
[`values.yaml`](https://github.com/kubewarden/network-enforcer/blob/main/charts/network-enforcer/values.yaml):

| Key                   | Description                                                                                |
| --------------------- | ------------------------------------------------------------------------------------------ |
| `controller`          | The controller Deployment: image, resources, security context, scheduling, log level.      |
| `controller.provider` | The data-plane provider (`istio`, `cilium`, `calico`), and per-provider endpoint/TLS settings. |
| `telemetry`           | The OTEL collector strategy: `none`, `default` (bundled collector), or `external`.         |
| `imagePullSecrets`    | Secrets with private registry credentials.                                                 |
| `nameOverride`        | Replaces the chart name in the generated resource names.                                   |
| `fullnameOverride`    | Replaces the whole `<release>-<chart>` prefix in the generated resource names.             |

### Provider endpoint and TLS

`controller.provider.name` selects which provider is active. Endpoint, TLS, and
other provider-specific settings live under that provider's own tree
(`controller.provider.istio`, `.cilium`, `.calico`). Only the active tree is
applied; values under inactive providers are ignored.

| Provider | Default endpoint | Default TLS mode | Default material |
| -------- | ---------------- | ---------------- | ---------------- |
| `istio` | `4317` | `issuer` | chart CA Issuer |
| `cilium` | `hubble-relay.kube-system.svc:443` | `existingSecret` | `kube-system/hubble-relay-client-certs`, server name `ui.hubble-relay.cilium.io` |
| `calico` | `goldmane.calico-system.svc:7443` | `existingSecret` | `calico-system/goldmane-key-pair` + `goldmane-ca-bundle` (CA key `tigera-ca-bundle.crt`) |

Calico does not support `insecure`: Goldmane requires mTLS. Cilium `insecure` is
plaintext to Relay port 80: set `tls.mode=insecure` and clear `tls.serverName`.
If `endpoint` is still the default `:443`, the chart rewrites it to `:80`.

Override examples:

```yaml
controller:
  provider:
    name: cilium
    cilium:
      tls:
        mode: insecure
        serverName: ""   # clear the Relay SAN override for plaintext
```

The controller binary stays provider-neutral: the chart renders `--provider-tls-*`
flags (including `--provider-tls-ca-bundle-key` when a CA ConfigMap is used).

See the comments in `values.yaml` for the full list of options.

### CRDs

CRDs are installed with the `helm.sh/resource-policy: keep` annotation:

- `helm upgrade` updates CRDs normally
- `helm uninstall` does not delete CRDs, which prevents cascade-deletion of all
  WorkloadNetworkPolicies and WorkloadNetworkPolicyProposals in the cluster

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
helm uninstall network-enforcer --namespace network-enforcer
```

Note that this command won't delete the existing WorkloadNetworkPolicy and
WorkloadNetworkPolicyProposal resources.

To remove them, you can run the following commands:

```sh
kubectl delete crd workloadnetworkpolicies.networkenforcer.kubewarden.io
kubectl delete crd workloadnetworkpolicyproposals.networkenforcer.kubewarden.io
```

Finally, delete the namespace where Network Enforcer was deployed:

```sh
kubectl delete ns network-enforcer
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
assets](https://github.com/kubewarden/network-enforcer/releases), and
attached to the image as JSON-encoded documents following the [in-toto SPDX
predicate](https://github.com/in-toto/attestation/blob/main/spec/predicates/spdx.md)
format. You can obtain them with
[`crane`](https://github.com/google/go-containerregistry/blob/main/cmd/crane/README.md)
or [`docker buildx imagetools
inspect`](https://docs.docker.com/reference/cli/docker/buildx/imagetools/inspect).

Network Enforcer publishes one image: `controller`. The release assets follow
the pattern
`NetworkEnforcer-controller-attestation-<arch>-<provenance|sbom>.<ext>`.

Network Enforcer signs the container image and the SBOM and provenance
files. The signatures use keyless signing with the GitHub Actions OIDC
identity of the release workflow.

To verify the signature of the image, run:

```shell
cosign verify --certificate-oidc-issuer=https://token.actions.githubusercontent.com  \
    --certificate-identity="https://github.com/kubewarden/network-enforcer/.github/workflows/release.yml@refs/tags/<TAG TO VERIFY>" \
    ghcr.io/kubewarden/network-enforcer/controller:<TAG TO VERIFY>
```

The command works with a tag and with a digest. The release signs the
multi-architecture image and each single-architecture image.

To verify the provenance file from the release assets, run:

```shell
cosign verify-blob --certificate-oidc-issuer=https://token.actions.githubusercontent.com  \
    --certificate-identity="https://github.com/kubewarden/network-enforcer/.github/workflows/release.yml@refs/tags/<TAG TO VERIFY>" \
    --bundle NetworkEnforcer-controller-attestation-amd64-provenance.intoto.jsonl.bundle.sigstore \
    NetworkEnforcer-controller-attestation-amd64-provenance.intoto.jsonl
```

To verify the SBOM file, use the same command with the `sbom.json` files:

```shell
cosign verify-blob --certificate-oidc-issuer=https://token.actions.githubusercontent.com  \
    --certificate-identity="https://github.com/kubewarden/network-enforcer/.github/workflows/release.yml@refs/tags/<TAG TO VERIFY>" \
    --bundle NetworkEnforcer-controller-attestation-amd64-sbom.json.bundle.sigstore \
    NetworkEnforcer-controller-attestation-amd64-sbom.json
```

The SBOM and provenance files are also attached to the image in the registry.
Docker Buildx stores them in one attestation manifest per architecture. The
registry copy is not signed. The signed copies are the release assets.

To list the attestation manifests of a tag, run:

```shell
crane manifest ghcr.io/kubewarden/network-enforcer/controller:<TAG TO VERIFY> | jq '.manifests[] | select(.annotations["vnd.docker.reference.type"]=="attestation-manifest")'
```

Each attestation manifest has one layer per SBOM or provenance file. To list
the layers, run:

```shell
crane manifest ghcr.io/kubewarden/network-enforcer/controller@sha256:<ATTESTATION MANIFEST DIGEST>
```

To download one file, use the digest of its layer:

```shell
crane blob ghcr.io/kubewarden/network-enforcer/controller@sha256:<LAYER DIGEST>
```

## Security disclosure

See the [Kubewarden security policy](https://github.com/kubewarden/community/security/policy).

## Build with the community

Network Enforcer is part of [Kubewarden](https://www.kubewarden.io/), a CNCF
Sandbox project. Rancher by SUSE developed it first.

Get help, share an idea, or improve these docs.

- [Join us on Slack](https://kubernetes.slack.com/?redir=%2Fmessages%2Fkubewarden)
- [Community meetings](https://www.kubewarden.io/#get-in-touch)
- [Contribute to the docs](https://github.com/kubewarden/docs)

# Changelog

See [GitHub Releases content](https://github.com/kubewarden/network-enforcer/releases).
