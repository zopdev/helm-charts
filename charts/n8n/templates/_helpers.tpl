{{- define "n8n.name" -}}
  {{- default .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "n8n.fullname" -}}
  {{- printf "%s-n8n" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "n8n.chart" -}}
  {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "n8n.labels" -}}
app: {{ include "n8n.name" . }}
chart: {{ include "n8n.chart" . }}
release: {{ .Release.Name }}
{{- end -}}

{{- define "n8n.selectorLabels" -}}
app: {{ include "n8n.name" . }}
release: {{ .Release.Name }}
{{- end -}}

{{/*
Name of the postgres subchart's per-database secret, which carries DB_USER and
DB_PASSWORD. The subchart composes this name from the services[] entry rather
than exposing it, so the format is reproduced here and has to stay in step with
its init-script-config-map template.
*/}}
{{- define "n8n.postgresSecretName" -}}
  {{- if not .Values.postgres.services -}}
    {{- fail "postgres.services must list one entry (name and database); it is what provisions the n8n database, its role, and the Secret holding those credentials." -}}
  {{- end -}}
  {{- $svc := index .Values.postgres.services 0 -}}
  {{- printf "%s-%s-%s-postgres-database-secret" .Release.Name (replace "_" "-" $svc.database) $svc.name -}}
{{- end -}}

{{/*
Name of the secret holding N8N_ENCRYPTION_KEY: the pre-created one when given,
otherwise the generated <fullname>-encryption.
*/}}
{{- define "n8n.encryptionSecretName" -}}
  {{- if .Values.encryptionKey.existingSecret -}}
    {{- .Values.encryptionKey.existingSecret -}}
  {{- else -}}
    {{- printf "%s-encryption" (include "n8n.fullname" .) -}}
  {{- end -}}
{{- end -}}

{{/*
Database connection details, resolved once so the deployment and the wait-for-db
init container cannot disagree about where the database is. Returns a dict with
host, port, database and user; the password is always a secret reference and is
handled separately.
*/}}
{{- define "n8n.db" -}}
  {{- if .Values.postgres.enabled -}}
    {{- if not .Values.postgres.services -}}
      {{- fail "postgres.services must list one entry (name and database); it is what provisions the n8n database, its role, and the Secret holding those credentials." -}}
    {{- end -}}
    {{- $svc := index .Values.postgres.services 0 -}}
    {{- dict "host" (printf "%s-postgres" .Release.Name) "port" "5432" "database" $svc.database | toYaml -}}
  {{- else -}}
    {{- dict "host" .Values.externalDatabase.host "port" (toString .Values.externalDatabase.port) "database" .Values.externalDatabase.database | toYaml -}}
  {{- end -}}
{{- end -}}

{{/*
The claim the n8n data volume binds to: the user's existing claim when named,
otherwise the one this chart creates.
*/}}
{{- define "n8n.claimName" -}}
  {{- if .Values.persistence.existingClaim -}}
    {{- .Values.persistence.existingClaim -}}
  {{- else -}}
    {{- include "n8n.fullname" . -}}
  {{- end -}}
{{- end -}}

{{/*
n8n bakes its public URL into every webhook it registers and into OAuth callback
URLs, so this has to be the address a caller outside the cluster would use, not
the service address. An explicit webhookUrl wins; otherwise it is derived from
the ingress host, which is the only externally reachable name the chart knows.
Empty when there is neither, which leaves n8n on its own localhost default.
*/}}
{{- define "n8n.webhookUrl" -}}
  {{- if .Values.webhookUrl -}}
    {{- printf "%s/" (.Values.webhookUrl | trimSuffix "/") -}}
  {{- else if and .Values.ingress.enabled .Values.ingress.host -}}
    {{- $scheme := ternary "https" "http" (ne (toString .Values.ingress.tlsSecretName) "") -}}
    {{- printf "%s://%s/" $scheme .Values.ingress.host -}}
  {{- end -}}
{{- end -}}

{{/*
Host and protocol as n8n should advertise them, taken apart from the public URL
above so all three agree. Deriving N8N_PROTOCOL from ingress.tlsSecretName
instead would contradict an explicit https webhookUrl whenever TLS is terminated
somewhere ahead of the ingress. Returns an empty dict when no public URL is
configured, leaving n8n on its own defaults.
*/}}
{{- define "n8n.public" -}}
  {{- $url := include "n8n.webhookUrl" . -}}
  {{- if $url -}}
    {{- $scheme := ternary "https" "http" (hasPrefix "https://" $url) -}}
    {{- $authority := $url | trimPrefix "https://" | trimPrefix "http://" | trimSuffix "/" -}}
    {{/* Drop any path, then any port: N8N_HOST is the hostname alone. */}}
    {{- $host := $authority | splitList "/" | first | splitList ":" | first -}}
    {{- dict "url" $url "host" $host "protocol" $scheme | toYaml -}}
  {{- else -}}
    {{- dict | toYaml -}}
  {{- end -}}
{{- end -}}

{{/*
Every environment variable the chart derives from other values, as a comma
separated list. validate.yaml rejects `env` overrides of these, and configmap.yaml
skips them defensively - two consumers, one definition, so the guard cannot fall
behind the ConfigMap the way a hand-maintained list does.

Overriding any of them through `env` would not win cleanly anyway: the ConfigMap
would carry the key twice and last-one-wins, leaving n8n advertising one value
while a related variable still described the other.
*/}}
{{- define "n8n.ownedEnv" -}}
DB_TYPE,DB_POSTGRESDB_HOST,DB_POSTGRESDB_PORT,DB_POSTGRESDB_DATABASE,DB_POSTGRESDB_SCHEMA,DB_POSTGRESDB_USER,DB_POSTGRESDB_PASSWORD,EXECUTIONS_MODE,N8N_PORT,N8N_LISTEN_ADDRESS,N8N_DEFAULT_BINARY_DATA_MODE,N8N_DIAGNOSTICS_ENABLED,N8N_WEBHOOK_URL,WEBHOOK_URL,N8N_HOST,N8N_PROTOCOL,N8N_SECURE_COOKIE,N8N_METRICS,GENERIC_TIMEZONE,TZ,N8N_ENCRYPTION_KEY
{{- end -}}
