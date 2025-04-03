{{- define "solr.hashPassword" -}}
{{- $password := "test" }}
{{- $magicNum := 101559956668416 }}
{{- /* Generate salt components */}}
{{- $rand1 := randInt 0 100000 }}
{{- $num1 := sub $magicNum $rand1 }}
{{- $rand2 := randInt 0 100000 }}
{{- $num2 := sub $magicNum $rand2 }}
{{- /* Create salt */}}
{{- $salt := print (toString $num1 | b64enc | substr 1 -1) (toString $num2 | b64enc | substr 1 -1) }}
{{- /* Hash operations */}}
{{- $saltedInput := print $salt $password }}
{{- $firstHash := $saltedInput | sha256sum }}
{{- $secondHash := $firstHash | sha256sum }}
{{- /* Final encoding */}}
{{- $finalHash := $secondHash | b64enc }}
{{- $encodedSalt := $salt | b64enc }}
{{- printf "%s %s" $finalHash $encodedSalt }}
{{- end }}