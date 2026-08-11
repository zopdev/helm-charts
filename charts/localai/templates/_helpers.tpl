{{/*
Expand the name of the chart.
*/}}
{{- define "localai.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Fully qualified app name, used for the API service and workload names.
*/}}
{{- define "localai.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-localai" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "localai.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "localai.labels" -}}
helm.sh/chart: {{ include "localai.chart" . }}
{{ include "localai.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "localai.selectorLabels" -}}
app.kubernetes.io/name: {{ include "localai.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Selector labels for the pods that serve the API. The standalone pod and
the distributed frontends both carry these, so one Service fronts either
topology. Workers deliberately do not, so API traffic never lands on a
pod that has no API server.
*/}}
{{- define "localai.serverSelectorLabels" -}}
{{ include "localai.selectorLabels" . }}
app.kubernetes.io/component: server
{{- end }}

{{- define "localai.workerSelectorLabels" -}}
{{ include "localai.selectorLabels" . }}
app.kubernetes.io/component: worker
{{- end }}

{{/*
Name of the Secret holding the worker registration token.
*/}}
{{- define "localai.registrationSecretName" -}}
{{- printf "%s-registration" (include "localai.fullname" .) }}
{{- end }}

{{/*
The postgres subchart provisions one database per entry in
`postgres.services`, and writes its generated credentials to a Secret
named after the release, the database, and the service. Recompute that
name here so the frontends can read the credentials it generated.
*/}}
{{- define "localai.postgresSecretName" -}}
{{- $svc := first .Values.postgres.services -}}
{{- printf "%s-%s-%s-postgres-database-secret" .Release.Name (replace "_" "-" $svc.database) $svc.name -}}
{{- end }}

{{/*
NATS endpoint: the subchart's service, or an operator-supplied server.
*/}}
{{- define "localai.natsUrl" -}}
{{- if .Values.externalNats.url -}}
{{- .Values.externalNats.url -}}
{{- else -}}
{{- printf "nats://%s-nats:4222" .Release.Name -}}
{{- end -}}
{{- end }}

{{/*
Environment for the PostgreSQL connection.

With the subchart, the username and password are read from the Secret it
generated and interpolated into the URL by kubelet, so the credentials
never appear in this chart's rendered manifests. sslmode is pinned to
disable because that Secret's own DATABASE_URL carries no sslmode, and a
driver defaulting to `require` would fail against the subchart's server,
which does not serve TLS.
*/}}
{{- define "localai.databaseEnv" -}}
{{- if .Values.externalDatabase.url }}
- name: LOCALAI_AUTH_DATABASE_URL
  value: {{ .Values.externalDatabase.url | quote }}
{{- else }}
{{- $svc := first .Values.postgres.services }}
- name: LOCALAI_DB_USER
  valueFrom:
    secretKeyRef:
      name: {{ include "localai.postgresSecretName" . }}
      key: DB_USER
- name: LOCALAI_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "localai.postgresSecretName" . }}
      key: DB_PASSWORD
- name: LOCALAI_AUTH_DATABASE_URL
  value: "postgresql://$(LOCALAI_DB_USER):$(LOCALAI_DB_PASSWORD)@{{ .Release.Name }}-postgres:5432/{{ $svc.database }}?sslmode=disable"
{{- end }}
{{- end }}
