{{- define "litellm.name" -}}
  {{- default .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "litellm.fullname" -}}
  {{- printf "%s-litellm" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "litellm.chart" -}}
  {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "litellm.labels" -}}
app: {{ include "litellm.name" . }}
chart: {{ include "litellm.chart" . }}
release: {{ .Release.Name }}
{{- end -}}

{{- define "litellm.selectorLabels" -}}
app: {{ include "litellm.name" . }}
release: {{ .Release.Name }}
{{- end -}}

{{/*
Name of the secret holding PROXY_MASTER_KEY. Uses masterkey.existingSecret when
set, otherwise the auto-generated <fullname>-masterkey secret.
*/}}
{{- define "litellm.masterkeySecretName" -}}
  {{- if .Values.masterkey.existingSecret -}}
    {{- .Values.masterkey.existingSecret -}}
  {{- else -}}
    {{- printf "%s-masterkey" (include "litellm.fullname" .) -}}
  {{- end -}}
{{- end -}}

{{/*
Name of the chart-owned secret holding the provider API keys given in .Values.apiKeys.
*/}}
{{- define "litellm.apiKeysSecretName" -}}
  {{- printf "%s-apikeys" (include "litellm.fullname" .) -}}
{{- end -}}

{{/*
Name of the postgres subchart's per-database secret (carries DATABASE_URL).
Derived from the first postgres.services entry so it stays in sync with the
zopdev/postgres init-script-config-map naming convention.
*/}}
{{- define "litellm.postgresSecretName" -}}
  {{- $svc := index .Values.postgres.services 0 -}}
  {{- printf "%s-%s-%s-postgres-database-secret" .Release.Name (replace "_" "-" $svc.database) $svc.name -}}
{{- end -}}
