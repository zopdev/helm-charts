{{- define "libredb-studio.name" -}}
  {{- default .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "libredb-studio.fullname" -}}
  {{- printf "%s-libredb-studio" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "libredb-studio.chart" -}}
  {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "libredb-studio.labels" -}}
app: {{ include "libredb-studio.name" . }}
chart: {{ include "libredb-studio.chart" . }}
release: {{ .Release.Name }}
{{- end -}}

{{- define "libredb-studio.selectorLabels" -}}
app: {{ include "libredb-studio.name" . }}
release: {{ .Release.Name }}
{{- end -}}

{{- define "libredb-studio.secretName" -}}
  {{- .Values.auth.existingSecret | default (include "libredb-studio.fullname" .) -}}
{{- end -}}

{{- define "libredb-studio.claimName" -}}
  {{- .Values.persistence.existingClaim | default (include "libredb-studio.fullname" .) -}}
{{- end -}}

{{/*
Variables the chart sets. validate.yaml rejects them in `env`.
*/}}
{{- define "libredb-studio.ownedEnv" -}}
PORT,HOSTNAME,STORAGE_PROVIDER,STORAGE_SQLITE_PATH,AUTH_BOOTSTRAP,AUTH_COOKIE_SECURE,ADMIN_EMAIL,ADMIN_PASSWORD,JWT_SECRET
{{- end -}}
