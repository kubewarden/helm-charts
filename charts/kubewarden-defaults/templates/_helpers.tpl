{{- define "allow-privileged-escalation-policy-spec" -}}
spec:
  policyServer: {{ .Values.policyServer.name }}
  mode: {{ .Values.bestPracticePolicies.defaultPolicyMode }}
  module: {{ .Values.bestPracticePolicies.allowPrivilegeEscalationPolicy.module }}
  rules:
  - apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["pods"]
    operations:
    - CREATE
    - UPDATE
  mutating: false
  settings:
    default_allow_privilege_escalation: false
{{- end -}}
{{- define "host-namespace-policy-spec" -}}
spec:
  policyServer: {{ .Values.policyServer.name }}
  mode: {{ .Values.bestPracticePolicies.defaultPolicyMode }}
  module: {{ .Values.bestPracticePolicies.hostNamespacePolicy.module }}
  rules:
  - apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["pods"]
    operations:
    - CREATE
    - UPDATE
  mutating: false
  settings:
    allow_host_ipc: false
    allow_host_network: false
    allow_host_pid: false
{{- end -}}
{{- define "pod-privileged-policy-spec" -}}
spec:
  policyServer: {{ .Values.policyServer.name }}
  mode: {{ .Values.bestPracticePolicies.defaultPolicyMode }}
  module: {{ .Values.bestPracticePolicies.podPrivilegedPolicy.module }}
  rules:
  - apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["pods"]
    operations:
    - CREATE
    - UPDATE
  mutating: false
{{- end -}}
{{- define "user-group-policy-spec" -}}
spec:
  policyServer: {{ .Values.policyServer.name }}
  mode: {{ .Values.bestPracticePolicies.defaultPolicyMode }}
  module: {{ .Values.bestPracticePolicies.userGroupPolicy.module }}
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
      rule: "MustRunAsNonRoot"
    run_as_group:
      rule: "RunAsAny"
    supplemental_groups:
      rule: "RunAsAny"
{{- end -}}
