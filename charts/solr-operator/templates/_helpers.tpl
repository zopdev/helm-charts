{{- define "solr-operator.name" -}}
{{ .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "solr-operator.fullname" -}}
{{ printf "%s-solr-operator" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "solr-operator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "solr-operator.serviceAccountName" -}}
{{ printf "%s-sa" (include "solr-operator.fullname" .) }}
{{- end }}

{{- define "solr-operator.watchNamespaces" -}}
{{ .Release.Namespace }}
{{- end -}}

{{- define "solr-operator.mTLS.clientCertDirectory" -}}
/etc/ssl/solr/client-cert
{{- end -}}

{{- define "solr-operator.mTLS.caCertDirectory" -}}
/etc/ssl/solr/ca-cert
{{- end -}}
{{- define "solr-operator.mTLS.caCertName" -}}
rootSolrCert.pem
{{- end -}}

{{- define "solr-operator.mTLS.volumeMounts" -}}
{{- if .Values.mTLS.clientCertSecret -}}
- name: tls-client-cert
  mountPath: {{ include "solr-operator.mTLS.clientCertDirectory" . }}
  readOnly: true
{{- end -}}
{{ if .Values.mTLS.caCertSecret }}
- name: tls-ca-cert
  mountPath: {{ include "solr-operator.mTLS.caCertDirectory" . }}
  readOnly: true
{{ end }}
{{- end -}}

{{- define "solr-operator.mTLS.volumes" -}}
{{- if .Values.mTLS.clientCertSecret -}}
- name: tls-client-cert
  secret:
    secretName: {{ .Values.mTLS.clientCertSecret }}
    optional: false
{{- end -}}
{{ if .Values.mTLS.caCertSecret }}
- name: tls-ca-cert
  secret:
    secretName: {{ .Values.mTLS.caCertSecret }}
    items:
      - key: {{ .Values.mTLS.caCertSecretKey }}
        path: {{ include "solr-operator.mTLS.caCertName" . }}
    optional: false
{{- end -}}
{{- end -}}