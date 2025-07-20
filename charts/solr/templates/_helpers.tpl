{{- define "solr.hashPassword" -}}
{{- $password := .rootPassword }}

{{- $magicNum := 101559956668416 }}

{{- /* Generate salt components */}}
{{- $rand1 := randInt 0 $magicNum }}
{{- $num1 := sub $magicNum $rand1 }}
{{- $rand2 := randInt 0 $magicNum }}
{{- $num2 := sub $magicNum $rand2 }}

{{- /* Convert numbers to base36-like encoding */}}
{{- $base36num1 := toString $num1 | b64enc }}
{{- $base36num2 := toString $num2 | b64enc }}

{{- /* Create salt */}}
{{- $salt := print (substr 1 -1 $base36num1) (substr 1 -1 $base36num2) }}

{{- /* Hash operations */}}
{{- $saltedInput := print $salt $password }}
{{- $firstHash := $saltedInput | sha256sum }}
{{- $secondHash := $firstHash | sha256sum }}

{{- /* Final encoding */}}
{{- $finalHash := $secondHash | b64enc }}
{{- $encodedSalt := $salt | b64enc }}

{{- printf "%s %s" $finalHash $encodedSalt }}
{{- end }}
