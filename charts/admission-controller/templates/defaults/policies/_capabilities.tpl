{{- define "kubewarden.defaults.capabilities" -}}
apiVersion: {{ $.Values.crdVersion }}
kind: ClusterAdmissionPolicy
metadata:
  name: {{ .Values.recommendedPolicies.capabilitiesPolicy.name }}
  labels:
    {{- include "admission-controller.policyLabels" . | nindent 4 }}
  annotations:
    io.kubewarden.policy.severity: medium
    io.kubewarden.policy.category: PSP
    {{- include "admission-controller.defaults.annotations" . | nindent 4 }}
spec:
  mode: {{ .Values.recommendedPolicies.defaultPolicyMode | default "monitor" }}
  failurePolicy: {{ include "policy_failure_policy" . | trim }}
  module: {{ template "policy_default_registry" . }}{{ .Values.recommendedPolicies.capabilitiesPolicy.module.repository }}:{{ .Values.recommendedPolicies.capabilitiesPolicy.module.tag }}
  mutating: true
  backgroundAudit: true
  rules:
    - apiGroups: [""]
      apiVersions: ["v1"]
      resources: ["pods"]
      operations: ["CREATE", "UPDATE"]
  {{- include "policy-namespace-selector" . | nindent 2 }}
  settings: {{ .Values.recommendedPolicies.capabilitiesPolicy.settings | toYaml | nindent 4 }}
{{- end -}}
