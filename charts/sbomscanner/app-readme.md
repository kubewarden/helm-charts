# SBOMscanner

SBOMscanner is a SBOM-centric security scanner for Kubernetes. It provides native Kubernetes resources and integrates seamlessly with Rancher and other SUSE tooling.

## Key Features

### 1. Kubernetes-Native, Event-Driven Architecture
- Generates SBOM CRs (Software Bill of Materials)
- Generates Vulnerability Report CRs

### 2. SBOM-Centric Design
- Image contents change less frequently than vulnerability definitions
- Scanning an image is more expensive compared to generating an SBOM

## Use Cases

- Visualize results in the Rancher UI
- Feed data into Kubewarden for policy enforcement
- Export metrics to SUSE Observability for centralized monitoring

## Learn More

- [Source Code](https://github.com/kubewarden/sbomscanner)
