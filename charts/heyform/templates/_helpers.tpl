{{- define "heyform.name" -}}
  {{- default .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
A release named after the chart keeps its name, so the three workloads are
not called heyform-heyform-*.
*/}}
{{- define "heyform.fullname" -}}
  {{- if contains .Chart.Name .Release.Name -}}
    {{- .Release.Name | trunc 50 | trimSuffix "-" -}}
  {{- else -}}
    {{- printf "%s-%s" .Release.Name .Chart.Name | trunc 50 | trimSuffix "-" -}}
  {{- end -}}
{{- end -}}

{{- define "heyform.mongodb.fullname" -}}
  {{- printf "%s-mongodb" (include "heyform.fullname" .) -}}
{{- end -}}

{{- define "heyform.redis.fullname" -}}
  {{- printf "%s-redis" (include "heyform.fullname" .) -}}
{{- end -}}

{{- define "heyform.chart" -}}
  {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Labels take the component as a second argument: (list . "app").
*/}}
{{- define "heyform.labels" -}}
{{ include "heyform.selectorLabels" . }}
chart: {{ include "heyform.chart" (index . 0) }}
{{- end -}}

{{- define "heyform.selectorLabels" -}}
app: {{ include "heyform.name" (index . 0) }}
release: {{ (index . 0).Release.Name }}
component: {{ index . 1 }}
{{- end -}}

{{- define "heyform.scheduling" -}}
{{- with .Values.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end -}}

{{- define "heyform.secretName" -}}
  {{- .Values.secrets.existingSecret | default (include "heyform.fullname" .) -}}
{{- end -}}

{{- define "heyform.publicUrl" -}}
  {{- if .Values.publicUrl -}}
    {{- .Values.publicUrl | trimSuffix "/" -}}
  {{- else if .Values.ingress.enabled -}}
    {{- printf "https://%s" .Values.ingress.host -}}
  {{- else -}}
    http://localhost:9157
  {{- end -}}
{{- end -}}

{{- define "heyform.trustProxy" -}}
  {{- if .Values.trustProxy -}}
    {{- .Values.trustProxy -}}
  {{- else if .Values.ingress.enabled -}}
    1
  {{- else -}}
    false
  {{- end -}}
{{- end -}}

{{/*
authSource=admin: the bundled MongoDB creates its one user in the admin
database, while the data lives in heyform.
*/}}
{{- define "heyform.mongoUri" -}}
  {{- if .Values.mongodb.enabled -}}
    {{- printf "mongodb://%s:27017/heyform?authSource=admin" (include "heyform.mongodb.fullname" .) -}}
  {{- else -}}
    {{- .Values.externalMongodb.uri -}}
  {{- end -}}
{{- end -}}

{{- define "heyform.redisHost" -}}
  {{- if .Values.redis.enabled -}}
    {{- include "heyform.redis.fullname" . -}}
  {{- else -}}
    {{- .Values.externalRedis.host -}}
  {{- end -}}
{{- end -}}

{{/*
Variables the chart sets. validate.yaml rejects them in `env`.
*/}}
{{- define "heyform.ownedEnv" -}}
NODE_ENV,APP_LISTEN_PORT,APP_LISTEN_HOSTNAME,APP_HOMEPAGE_URL,TRUST_PROXY,SESSION_KEY,FORM_ENCRYPTION_KEY,MONGO_URI,REDIS_HOST,REDIS_PORT
{{- end -}}

{{/*
Set by the chart only while the bundled store is on, so an external store
can take them from `env` or extraEnvFrom.
*/}}
{{- define "heyform.ownedMongoEnv" -}}
MONGO_USER,MONGO_PASSWORD
{{- end -}}

{{- define "heyform.ownedRedisEnv" -}}
REDIS_PASSWORD
{{- end -}}
