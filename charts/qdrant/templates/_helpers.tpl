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
Selector labels. This feeds the StatefulSet's immutable spec.selector, so it is
kept to the single flat `app` label the repo's datastore charts use — no
app.kubernetes.io/* keys mixed in.
*/}}
{{- define "qdrant.selectorLabels" -}}
app: {{ .Release.Name }}-qdrant
{{- end -}}
