{{- define "scylladb.serviceAccountName" -}}
{{ default (include "scylla.names.fullname" .) }}
{{- end -}}

{{- define "scylladb.seeds" -}}
{{- $seeds := list }}
{{- $fullname := include "scylla.names.fullname" .  }}
{{- $releaseNamespace := include "scylla.names.namespace" . }}
{{- $clusterDomain := "cluster.local" }}
{{- $seedCount := 1 }}
{{- range $e, $i := until $seedCount }}
{{- $seeds = append $seeds (printf "%s-%d.%s-headless.%s.svc.%s" $fullname $i $fullname $releaseNamespace $clusterDomain) }}
{{- end }}
{{- join "," $seeds }}
{{- end -}}


