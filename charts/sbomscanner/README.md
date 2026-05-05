# SBOMscanner

![License](https://img.shields.io/github/license/kubewarden/sbomscanner)
![GitHub branch check runs](https://img.shields.io/github/check-runs/kubewarden/sbomscanner/main)
![GitHub contributors](https://img.shields.io/github/contributors/kubewarden/sbomscanner)
[![Go Report Card](https://goreportcard.com/badge/github.com/kubewarden/sbomscanner)](https://goreportcard.com/report/github.com/kubewarden/sbomscanner)
[![Go Reference](https://pkg.go.dev/badge/github.com/kubewarden/sbomscanner.svg)](https://pkg.go.dev/github.com/kubewarden/sbomscanner)

A SBOM-centric security scanner for Kubernetes.

This is still being developed. For additional details, please refer to the [RFC](https://github.com/kubewarden/sbomscanner/tree/main/docs/rfc).

# Documentation

### Installation

- [Quickstart](https://github.com/kubewarden/sbomscanner/blob/main/docs/installation/quickstart.md)
- [Uninstall](https://github.com/kubewarden/sbomscanner/blob/main/docs/installation/uninstall.md)
- [Helm Chart Values Configuration](https://github.com/kubewarden/sbomscanner/blob/main/docs/installation/helm-values.md)

### Usage

- [Scanning Registries](https://github.com/kubewarden/sbomscanner/blob/main/docs/user-guide/scanning-registries.md)
- [Scanning Workloads](https://github.com/kubewarden/sbomscanner/blob/main/docs/user-guide/scanning-workloads.md)
- [Querying Reports](https://github.com/kubewarden/sbomscanner/blob/main/docs/user-guide/querying-reports.md)
- [Private Registries](https://github.com/kubewarden/sbomscanner/blob/main/docs/user-guide/private-registries.md)
- [VEX Support and VEXHub Integration](https://github.com/kubewarden/sbomscanner/blob/main/docs/user-guide/vex.md)
- [Air Gap Support](https://github.com/kubewarden/sbomscanner/blob/main/docs/user-guide/airgap-support.md)
- [MCP Server (Experimental)](https://github.com/kubewarden/sbomscanner/blob/main/docs/user-guide/mcp-server.md)

### Troubleshooting

- [Collecting logs](https://github.com/kubewarden/sbomscanner/blob/main/docs/troubleshooting/collecting-logs.md)

### Development

- [Contributing guidelines](https://github.com/kubewarden/sbomscanner/blob/main/CONTRIBUTING.md)

### Contact

Get in touch with us on Slack: join the [`kubewarden` channel](https://kubernetes.slack.com/?redir=%2Fmessages%2Fkubewarden) hosted by the official Kubernetes workspace 👨‍💻 💬 👩‍💻

# Credits

The storage API server is based on the [Kubernetes sample-apiserver](https://github.com/kubernetes/sample-apiserver) project.
