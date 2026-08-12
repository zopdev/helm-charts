{{/*
Fully qualified app name: <release>-qdrant, capped at 63 chars for DNS.
*/}}
{{- define "qdrant.fullname" -}}
{{- printf "%s-qdrant" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Name of the Secret holding the generated API key.
*/}}
{{- define "qdrant.secretName" -}}
{{- printf "%s-qdrant-apikey-secret" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Selector labels — used by the StatefulSet, Services and ServiceMonitor.
*/}}
{{- define "qdrant.selectorLabels" -}}
app.kubernetes.io/part-of: qdrant
app: {{ .Release.Name }}-qdrant
{{- end -}}
