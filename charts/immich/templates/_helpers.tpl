{{- define "immich.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "immich.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-immich" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "immich.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "immich.labels" -}}
helm.sh/chart: {{ include "immich.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Per-component selector labels. Three components share one release, so
the component name discriminates their Services/selectors from each
other. Takes a dict of {context, component} since it needs both the
root context (for .Chart/.Values/.Release) and which component this is.
*/}}
{{- define "immich.selectorLabels" -}}
app.kubernetes.io/name: {{ include "immich.name" .context }}
app.kubernetes.io/instance: {{ .context.Release.Name }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{- define "immich.serverFullname" -}}
{{- printf "%s-server" (include "immich.fullname" .) }}
{{- end }}

{{- define "immich.mlFullname" -}}
{{- printf "%s-ml" (include "immich.fullname" .) }}
{{- end }}

{{- define "immich.postgresFullname" -}}
{{- printf "%s-postgres" (include "immich.fullname" .) }}
{{- end }}

{{- define "immich.postgresSecretName" -}}
{{- printf "%s-postgres-secret" (include "immich.fullname" .) }}
{{- end }}

{{/*
Redis dependency's Service name. The redis chart's only client-facing
Service is its headless one -- there is no separate ClusterIP Service --
and it publishes this same hostname in its own
{{ .Release.Name }}-redis-service-configmap as REDIS_HOST.
*/}}
{{- define "immich.redisHost" -}}
{{- printf "%s-redis-headless-service" .Release.Name }}
{{- end }}
