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

{{/*
Service/StatefulSet names, truncated to fit a DNS-1035 label (max 63
chars) after their suffix -- "immich.fullname" is already truncated at
63 on its own, but appending "-server"/"-ml"/"-postgres" on top of that
can still overflow past 63, which "helm lint"/"helm template" never
catch (Service creation only fails server-side, on install).
*/}}
{{- define "immich.serverFullname" -}}
{{- printf "%s-server" (include "immich.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "immich.mlFullname" -}}
{{- printf "%s-ml" (include "immich.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "immich.postgresFullname" -}}
{{- printf "%s-postgres" (include "immich.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Headless Service names, computed once here so a StatefulSet's
`serviceName` and its headless Service's `metadata.name` can never
drift apart -- both derive from the same truncated call site instead of
concatenating "-headless" independently in each template.
*/}}
{{- define "immich.serverHeadlessFullname" -}}
{{- printf "%s-headless" (include "immich.serverFullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "immich.mlHeadlessFullname" -}}
{{- printf "%s-headless" (include "immich.mlFullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "immich.postgresHeadlessFullname" -}}
{{- printf "%s-headless" (include "immich.postgresFullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "immich.postgresSecretName" -}}
{{- if .Values.postgres.existingSecret }}
{{- .Values.postgres.existingSecret }}
{{- else }}
{{- printf "%s-postgres-secret" (include "immich.fullname" .) }}
{{- end }}
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
