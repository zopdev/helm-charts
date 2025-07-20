{{- define "solr.custom-kube-options.pod.filler" -}}
{{- if .Values.resources -}}
resources:
  {{- toYaml .Values.resources | nindent 2 }}
{{ end }}
{{- end -}}

{{- define "solr.custom-kube-options.stateful-set.filler" }}
{{- end -}}

{{- define "solr.custom-kube-options.filler" -}}
{{- with (include "solr.custom-kube-options.pod.filler" .) -}}
{{- if . -}}
podOptions:
  {{- . | nindent 2 -}}
{{ end }}
{{ end }}
{{- with (include "solr.custom-kube-options.stateful-set.filler" .) -}}
{{- if . -}}
statefulSetOptions:
  {{- . | nindent 2 -}}
{{ end }}
{{ end }}
{{- end -}}

{{- define "solr.custom-kube-options" -}}
{{- with (include "solr.custom-kube-options.filler" .) -}}
{{- if . -}}
customSolrKubeOptions:
  {{- . | nindent 2 -}}
{{ end }}
{{ end }}
{{- end -}}