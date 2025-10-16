## SBOMscanner Storage

The `storage` Helm chart installs the SBOMscanner storage deployment, which should be installed alongside the SBOMscanner controller and worker components.

The storage component uses SQLite as its database backend. **Note that SQLite is intended for development and testing purposes only, and should not be used in production environments.**

To ensure data persistence, the storage component requires a PersistentVolumeClaim (PVC). You can provide your own PVC to control how and where data is stored.

There are two ways to satisfy this requirement:

1. Provide a pre-created PVC and reference it in your Helm values using `persistence.storageData.existingClaim`.
2. If no PVC is provided, and your cluster supports dynamic provisioning via a `StorageClass`, a new PVC and corresponding PV will be created automatically.
