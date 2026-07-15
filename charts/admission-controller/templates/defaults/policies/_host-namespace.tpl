{{- define "kubewarden.defaults.hostNamespace" -}}
apiVersion: {{ $.Values.crdVersion }}
kind: ClusterAdmissionPolicy
metadata:
  name: {{ .Values.recommendedPolicies.hostNamespacePolicy.name }}
  labels:
    {{- include "admission-controller.policyLabels" . | nindent 4 }}
  annotations:
    io.kubewarden.policy.severity: medium
    io.kubewarden.policy.category: PSP
    {{- include "admission-controller.defaults.annotations" . | nindent 4 }}
spec:
  mode: {{ .Values.recommendedPolicies.defaultPolicyMode | default "monitor" }}
  failurePolicy: {{ include "policy_failure_policy" . | trim }}
  module: {{ template "policy_default_registry" . }}{{ .Values.recommendedPolicies.hostNamespacePolicy.module.repository }}:{{ .Values.recommendedPolicies.hostNamespacePolicy.module.tag }}
  mutating: false
  backgroundAudit: true
  rules:
    - apiGroups: [""]
      apiVersions: ["v1"]
      resources: ["pods"]
      operations: ["CREATE", "UPDATE"]
  {{- include "policy-namespace-selector" . | nindent 2 }}
  settings: {{ .Values.recommendedPolicies.hostNamespacePolicy.settings | toYaml | nindent 4 }}
{{- end -}}
