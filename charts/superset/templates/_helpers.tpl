{{- define "generateBase64Key" -}}
{{ randAlphaNum 32 | b64enc }}
{{- end -}}

{{- define "superset.name" -}}
  {{- default .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "superset.fullname" -}}
  {{- printf "%s-superset" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "superset.chart" -}}
  {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "superset.image" -}}
  {{- printf "%s:%s" .Values.image.repository (.Values.image.tag | default .Chart.AppVersion) -}}
{{- end -}}

{{- /*
  The Secret holding the env every Superset pod reads. Declared once so the
  SECRET_KEY lookup below and the Secret that stores it cannot disagree.
*/ -}}
{{- define "superset.env-secret.fullname" -}}
  {{- printf "%s-env" (include "superset.fullname" .) -}}
{{- end -}}

{{- /*
  Superset's Flask SECRET_KEY.

  It signs session cookies AND encrypts the database-connection passwords that
  Superset stores in its own metadata DB, so it has to survive an upgrade: a
  fresh key logs every user out and leaves every saved database connection
  undecryptable. It used to be minted by `randAlphaNum` inside superset_config.py
  on every render, so EVERY `helm upgrade` rotated it (and churned the config
  Secret's checksum, rolling all the pods for no reason). It is now generated
  once and read back out of the env Secret on later renders, the same shape as
  charts/jupyterhub/templates/hub/_helpers-passwords.tpl.
*/ -}}
{{- define "superset.secretKey" -}}
  {{- if .Values.supersetNode.secretKey -}}
    {{- .Values.supersetNode.secretKey -}}
  {{- else -}}
    {{- $k8s_state := lookup "v1" "Secret" .Release.Namespace (include "superset.env-secret.fullname" .) | default (dict "data" (dict)) -}}
    {{- $data := $k8s_state.data | default (dict) -}}
    {{- if hasKey $data "SUPERSET_SECRET_KEY" -}}
      {{- index $data "SUPERSET_SECRET_KEY" | b64dec -}}
    {{- else -}}
      {{- include "generateBase64Key" . | trim -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- /*
  DB_USER / DB_PASS for every Superset pod.

  With the bundled postgres subchart these come from the root Secret it creates,
  which is the only credential that exists: postgres v0.0.12 generates both the
  root password and each `services[]` user/password at random and ignores
  `postgresRootPassword` and `services[].password` entirely.

  With `postgres.enabled: false` that Secret is never created, so the pods read a
  Secret that does not exist and the toggle could only ever produce a broken
  release. Pointing the chart at an external Postgres now uses
  `supersetNode.connections.db_user` / `.db_pass`, which were previously dead
  values (an explicit `env` entry always overrode what `envFrom` supplied).
*/ -}}
{{- define "superset.dbEnv" -}}
{{- if .Values.postgres.enabled -}}
- name: "DB_PASS"
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-postgres-root-secret
      key: postgres-password
- name: "DB_USER"
  value: postgres
{{- else -}}
- name: "DB_PASS"
  value: {{ .Values.supersetNode.connections.db_pass | quote }}
- name: "DB_USER"
  value: {{ .Values.supersetNode.connections.db_user | quote }}
{{- end -}}
{{- end -}}

{{- /*
  Render a values entry as a Python literal for superset_config.py.
  A YAML boolean has to become True/False - Go templates print `true`, which Python
  reads as an undefined name and every Superset pod then fails to boot.
  A string that already looks like a dict/list, or that spells True/False, is passed
  through unquoted so callers can still hand in raw Python.
*/ -}}
{{- define "superset.pyValue" -}}
  {{- $v := . -}}
  {{- if kindIs "bool" $v -}}
    {{- ternary "True" "False" $v -}}
  {{- else if kindIs "string" $v -}}
    {{- if or (hasPrefix "{" $v) (hasPrefix "[" $v) (eq $v "True") (eq $v "False") (eq $v "None") -}}
      {{- $v -}}
    {{- else -}}
      {{- $v | quote -}}
    {{- end -}}
  {{- else -}}
    {{- $v -}}
  {{- end -}}
{{- end -}}

{{- define "superset-config" }}
import os
from flask_caching.backends.rediscache import RedisCache

def env(key, default=None):
    return os.getenv(key, default)

# Redis Base URL
{{- if .Values.supersetNode.connections.redis_password }}
REDIS_BASE_URL=f"{env('REDIS_PROTO')}://{env('REDIS_USER', '')}:{env('REDIS_PASSWORD')}@{env('REDIS_HOST')}:{env('REDIS_PORT')}"
{{- else }}
REDIS_BASE_URL=f"{env('REDIS_PROTO')}://{env('REDIS_HOST')}:{env('REDIS_PORT')}"
{{- end }}

# Redis URL Params
{{- if .Values.supersetNode.connections.redis_ssl.enabled }}
REDIS_URL_PARAMS = f"?ssl_cert_reqs={env('REDIS_SSL_CERT_REQS')}"
{{- else }}
REDIS_URL_PARAMS = ""
{{- end}}

# Build Redis URLs
CACHE_REDIS_URL = f"{REDIS_BASE_URL}/{env('REDIS_DB', 1)}{REDIS_URL_PARAMS}"
CELERY_REDIS_URL = f"{REDIS_BASE_URL}/{env('REDIS_CELERY_DB', 0)}{REDIS_URL_PARAMS}"

MAPBOX_API_KEY = env('MAPBOX_API_KEY', '')
CACHE_CONFIG = {
      'CACHE_TYPE': 'RedisCache',
      'CACHE_DEFAULT_TIMEOUT': 300,
      'CACHE_KEY_PREFIX': 'superset_',
      'CACHE_REDIS_URL': CACHE_REDIS_URL,
}
DATA_CACHE_CONFIG = CACHE_CONFIG

SQLALCHEMY_DATABASE_URI = f"postgresql+psycopg2://{env('DB_USER')}:{env('DB_PASS')}@{env('DB_HOST')}:{env('DB_PORT')}/{env('DB_NAME')}"
SQLALCHEMY_TRACK_MODIFICATIONS = True

class CeleryConfig:
  imports  = ("superset.sql_lab", )
  broker_url = CELERY_REDIS_URL
  result_backend = CELERY_REDIS_URL

CELERY_CONFIG = CeleryConfig
RESULTS_BACKEND = RedisCache(
      host=env('REDIS_HOST'),
      {{- if .Values.supersetNode.connections.redis_password }}
      password=env('REDIS_PASSWORD'),
      {{- end }}
      port=env('REDIS_PORT'),
      key_prefix='superset_results',
      {{- if .Values.supersetNode.connections.redis_ssl.enabled }}
      ssl=True,
      ssl_cert_reqs=env('REDIS_SSL_CERT_REQS'),
      {{- end }}
)

# Feature Flags
FEATURE_FLAGS = {
    {{- if .Values.supersetNode.featureFlags }}
    {{- range $key, $value := .Values.supersetNode.featureFlags }}
    "{{ $key }}": {{ include "superset.pyValue" $value }},
    {{- end }}
    {{- end }}
}

# Additional Configurations
{{- if .Values.supersetNode.config }}
{{- range $key, $value := .Values.supersetNode.config }}
{{ $key }} = {{ include "superset.pyValue" $value }}
{{- end }}
{{- end }}

# Flask SECRET_KEY, taken from the env Secret (see superset.secretKey). Read at
# runtime rather than baked in, so this file is byte-identical across renders and
# an upgrade neither rotates the key nor needlessly rolls every pod.
SECRET_KEY = env('SUPERSET_SECRET_KEY')

{{- if .Values.configOverrides }}
# Overrides
{{- range $key, $value := .Values.configOverrides }}
{{ $key }} = '{{ tpl $value $ }}'
{{- end }}
{{- end }}
{{- end -}}

{{- define "supersetCeleryBeat.selectorLabels" -}}
app: {{ include "superset.name" . }}-celerybeat
release: {{ .Release.Name }}
{{- end -}}

{{- define "supersetCeleryFlower.selectorLabels" -}}
app: {{ include "superset.name" . }}-flower
release: {{ .Release.Name }}
{{- end -}}

{{- define "supersetNode.selectorLabels" -}}
app: {{ include "superset.name" . }}
release: {{ .Release.Name }}
{{- end -}}

{{- define "supersetWebsockets.selectorLabels" -}}
app: {{ include "superset.name" . }}-ws
release: {{ .Release.Name }}
{{- end -}}

{{- define "supersetWorker.selectorLabels" -}}
app: {{ include "superset.name" . }}-worker
release: {{ .Release.Name }}
{{- end -}}