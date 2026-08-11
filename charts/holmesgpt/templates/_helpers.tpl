{{- define "holmesgpt.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "holmesgpt.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-holmesgpt" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "holmesgpt.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "holmesgpt.labels" -}}
helm.sh/chart: {{ include "holmesgpt.chart" . }}
{{ include "holmesgpt.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "holmesgpt.selectorLabels" -}}
app.kubernetes.io/name: {{ include "holmesgpt.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "holmesgpt.serviceAccountName" -}}
{{- if .Values.rbac.create }}
{{- default (include "holmesgpt.fullname" .) .Values.rbac.serviceAccountName }}
{{- else }}
{{- default "default" .Values.rbac.serviceAccountName }}
{{- end }}
{{- end }}

{{/*
Rewrites `envRef:VAR` into the runtime templating Holmes resolves from
its environment, so a credential is named in values but its value only
ever exists in the pod.

The variable name is checked against POSIX rules first. Kubernetes
silently drops keys that are not valid env var names from an
envFrom.secretRef mount, so a hyphenated key like `AZURE-API-KEY` would
never reach the pod and the failure would surface as an authentication
error rather than as a naming one.
*/}}
{{- define "holmesgpt.renderModelValue" -}}
{{- $value := .value -}}
{{- if and (kindIs "string" $value) (hasPrefix "envRef:" $value) -}}
{{- $envVar := trimPrefix "envRef:" $value -}}
{{- if not (regexMatch "^[A-Za-z_][A-Za-z0-9_]*$" $envVar) -}}
{{- fail (printf "modelList.%s.%s: %q is not a usable environment variable name. It must match [A-Za-z_][A-Za-z0-9_]* -- Kubernetes drops keys with hyphens or dots from an envFrom.secretRef mount, so the value would never reach the pod. Rename the Secret key." .model .field $envVar) -}}
{{- end -}}
{{- printf "{{ env.%s }}" $envVar -}}
{{- else -}}
{{- $value -}}
{{- end -}}
{{- end }}
