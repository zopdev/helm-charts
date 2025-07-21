{{- define "chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "scylla.names.fullname" -}}
{{- printf "%s-scylladb" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "scylla.names.namespace" -}}
{{- default .Release.Namespace .Values.namespaceOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

