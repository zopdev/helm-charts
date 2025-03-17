{{- define "jupyterhub.userNodeAffinityRequired" -}}
- matchExpressions:
  - key: hub.jupyter.org/node-purpose
    operator: In
    values: [user]
{{- end }}

{{- define "jupyterhub.userNodeAffinityPreferred" -}}
- weight: 100
  preference:
    matchExpressions:
      - key: hub.jupyter.org/node-purpose
        operator: In
        values: [user]
{{- end }}

{{- define "jupyterhub.userPodAffinityRequired" -}}
{{- end }}

{{- define "jupyterhub.userPodAffinityPreferred" -}}
{{- end }}

{{- define "jupyterhub.userPodAntiAffinityRequired" -}}
{{- end }}

{{- define "jupyterhub.userPodAntiAffinityPreferred" -}}
{{- end }}



{{- /*
  jupyterhub.userAffinity:
    It is used by user-placeholder to set the same affinity on them as the
    spawned user pods spawned by kubespawner.
*/}}
{{- define "jupyterhub.userAffinity" -}}

{{- $dummy := set . "nodeAffinityRequired" (include "jupyterhub.userNodeAffinityRequired" .) -}}
{{- $dummy := set . "podAffinityRequired" (include "jupyterhub.userPodAffinityRequired" .) -}}
{{- $dummy := set . "podAntiAffinityRequired" (include "jupyterhub.userPodAntiAffinityRequired" .) -}}
{{- $dummy := set . "nodeAffinityPreferred" (include "jupyterhub.userNodeAffinityPreferred" .) -}}
{{- $dummy := set . "podAffinityPreferred" (include "jupyterhub.userPodAffinityPreferred" .) -}}
{{- $dummy := set . "podAntiAffinityPreferred" (include "jupyterhub.userPodAntiAffinityPreferred" .) -}}
{{- $dummy := set . "hasNodeAffinity" (or .nodeAffinityRequired .nodeAffinityPreferred) -}}
{{- $dummy := set . "hasPodAffinity" (or .podAffinityRequired .podAffinityPreferred) -}}
{{- $dummy := set . "hasPodAntiAffinity" (or .podAntiAffinityRequired .podAntiAffinityPreferred) -}}

{{- if .hasNodeAffinity -}}
nodeAffinity:
  {{- if .nodeAffinityRequired }}
  requiredDuringSchedulingIgnoredDuringExecution:
    nodeSelectorTerms:
      {{- .nodeAffinityRequired | nindent 6 }}
  {{- end }}

  {{- if .nodeAffinityPreferred }}
  preferredDuringSchedulingIgnoredDuringExecution:
    {{- .nodeAffinityPreferred | nindent 4 }}
  {{- end }}
{{- end }}

{{- if .hasPodAffinity }}
podAffinity:
  {{- if .podAffinityRequired }}
  requiredDuringSchedulingIgnoredDuringExecution:
    {{- .podAffinityRequired | nindent 4 }}
  {{- end }}

  {{- if .podAffinityPreferred }}
  preferredDuringSchedulingIgnoredDuringExecution:
    {{- .podAffinityPreferred | nindent 4 }}
  {{- end }}
{{- end }}

{{- if .hasPodAntiAffinity }}
podAntiAffinity:
  {{- if .podAntiAffinityRequired }}
  requiredDuringSchedulingIgnoredDuringExecution:
    {{- .podAntiAffinityRequired | nindent 4 }}
  {{- end }}

  {{- if .podAntiAffinityPreferred }}
  preferredDuringSchedulingIgnoredDuringExecution:
    {{- .podAntiAffinityPreferred | nindent 4 }}
  {{- end }}
{{- end }}

{{- end }}



{{- define "jupyterhub.coreAffinity" -}}
affinity:
  nodeAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        preference:
          matchExpressions:
            - key: hub.jupyter.org/node-purpose
              operator: In
              values: [core]
{{- end }}

