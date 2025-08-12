{{- define "karpenter.name" -}}
{{- default .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "karpenter.fullname" -}}
    {{- printf "%s-karpenter-gcp" .Release.Name | trunc 63 | trimSuffix "-"}}
{{- end }}

{{- define "karpenter.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "karpenter.labels" -}}
helm.sh/chart: {{ include "karpenter.chart" . }}
{{ include "karpenter.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "karpenter.selectorLabels" -}}
app.kubernetes.io/name: {{ include "karpenter.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "karpenter.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "karpenter.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "karpenter.pdb.apiVersion" -}}
{{- if and (.Capabilities.APIVersions.Has "policy/v1") (semverCompare ">= 1.21-0" .Capabilities.KubeVersion.Version) -}}
{{- print "policy/v1" -}}
{{- else -}}
{{- print "policy/v1beta1" -}}
{{- end -}}
{{- end -}}
