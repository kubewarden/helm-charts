# Kubewarden policy user-group-psp

This Kubewarden Policy is a replacement for the Kubernetes Pod Security
Policy that controls containers [user and groups](https://kubernetes.io/docs/concepts/policy/pod-security-policy/#users-and-groups).

This policy is used to control users and groups in containers.

## Installation

Once you have Kuberwarden installed in you Kubernetes cluster, you can install
the policy with the following command:

```bash
kubectl apply -f - <<EOF
apiVersion: policies.kubewarden.io/v1alpha2
kind: ClusterAdmissionPolicy
metadata:
  name: user-group-psp
spec:
  policyServer: default
  module: registry://ghcr.io/kubewarden/policies/user-group-psp:latest
  rules:
  - apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["pods"]
    operations:
    - CREATE
    - UPDATE
  mutating: true
  settings:
    run_as_user:
      rule: "MustRunAs"
      ranges:
        - min: 1000
          max: 2000
        - min: 4000
          max: 5000
    run_as_group:
      rule: "RunAsAny"
    supplemental_groups:
      rule: "RunAsAny"
EOF
```

You can see more information about the setting in the following section.

## Settings


The policy has three settings:

* `run_as_user`: Controls which user ID the containers are run with.
* `run_as_group`:  Controls which primary group ID the containers are run with.
* `supplemental_groups`: Controls which group IDs containers add.

All three settings have no defaults, just like the deprecated PSP (also, they would get used if `mutating` is `true`).

All three settings are JSON objects composed by two attributes: `rule` and `ranges`. The `rule` attribute defines
the strategy used by the policy to enforce users and groups used in containers. The available strategies are:

* `run_as_user`:
	* `MustRunAs` - Requires at least one range to be specified. Uses the minimum value of the first range as the default. Validates against all ranges.
	* `MustRunAsNonRoot` - Requires that the pod be submitted with a non-zero `runAsUser` or have the `USER` directive defined (using a numeric UID) in the image. Pods which have specified neither `runAsNonRoot` nor `runAsUser` settings will be mutated to set `runAsNonRoot=true`, thus requiring a defined non-zero numeric `USER` directive in the container. No default provided.
	* `RunAsAny` - No default provided. Allows any `runAsUser` to be specified.
* `run_as_group`:
	* `MustRunAs` - Requires at least one range to be specified. Uses the minimum value of the first range as the default. Validates against all ranges.
	* `MayRunAs` - Does not require that `RunAsGroup` be specified. However, when `RunAsGroup` is specified, they have to fall in the defined range.
	* `RunAsAny` - No default provided. Allows any `runAsGroup` to be specified.
* `supplemental_groups`:
	* `MustRunAs` - Requires at least one range to be specified. Uses the minimum value of the first range as the default. Validates against all ranges.
	* `MayRunAs` - Requires at least one range to be specified. Allows `supplementalGroups` to be left unset without providing a default. Validates against all ranges if `supplementalGroups` is set.
	* `RunAsAny` - No default provided. Allows any `supplementalGroups` to be specified

The `ranges` is a list of JSON objects with two attributes: `min` and `max`. Each range object define the user/group ID range used by the rule.

### Examples

To enforce that user and groups must be set and it should be in the defined ranges:

```json
{
  "run_as_user": {
    "rule": "MustRunAs",
    "ranges": [
      {
        "min": 1000,
        "max": 1999
      },
      {
        "min": 3000,
        "max": 3999
      }
    ]
  },
  "run_as_group": {
    "rule": "MustRunAs",
    "ranges": [
      {
        "min": 1000,
        "max": 1999
      },
      {
        "min": 3000,
        "max": 3999
      }
    ]
  },
  "supplemental_groups":{
    "rule": "MustRunAs",
    "ranges": [
      {
        "min": 1000,
        "max": 1999
      },
      {
        "min": 3000,
        "max": 3999
      }
    ]
  }
}
```

To allow any user and group:

```json
{
  "run_as_user": {
    "rule": "RunAsAny"
  },
  "run_as_group": {
    "rule": "RunAsAny"
  },
  "supplemental_groups":{
    "rule": "RunAsAny"
  }
}
```

To force running the container with non root user but any group:

```json
{
  "run_as_user": {
    "rule": "MustRunAsNonRoot"
  },
  "run_as_group": {
    "rule": "RunAsAny"
  },
  "supplemental_groups":{
    "rule": "RunAsAny"
  }
}
```

To enforce a group when the container has some group defined

```json
{
  "run_as_user": {
    "rule": "RunAsAny"
  },
  "run_as_group": {
    "rule": "MayRunAs",
    "ranges": [
      {
        "min": 1000,
        "max": 2000
      },
      {
        "min": 2001,
        "max": 3000
      }
    ]
  },
  "supplemental_groups":{
    "rule": "MayRunAs",
    "ranges": [
      {
        "min": 1000,
        "max": 2000
      },
      {
        "min": 2001,
        "max": 3000
      }
    ]
  }
}
```


## License

```
Copyright (C) 2021 José Guilherme Vanz <jguilhermevanz@suse.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
