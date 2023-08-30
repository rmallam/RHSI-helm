{{- define "selfsignedcerts" -}}
{{- $secret := lookup "v1" "Secret" .Release.Namespace "skupper-helm-certs" -}}
{{- if $secret -}}
tls.crt:  {{ index $secret.data "tls.crt" }}
ca.crt:  {{ index $secret.data "ca.crt" }}
tls.key:  {{ index $secret.data "tls.key" }}
{{- else }}
{{- $altNames := list ( printf "%s-%s.%s" .Values.common.ingress.host .Values.common.ingress.domain ) ( printf "%s.%s.svc.cluster.local" "skupper-router-local" .Release.Namespace ) -}}
{{- $ca := genCA "skupper-ca" 365 -}}
{{- $cert := genSignedCert .Release.Name nil $altNames 365 $ca -}}
tls.crt: {{ $cert.Cert | b64enc }}
tls.key: {{ $cert.Key | b64enc }}
ca.crt: {{ $ca.Cert | b64enc }}
{{- end -}}
{{- end -}}

{{- define "consolesecret" -}}
{{- $secret := lookup "v1" "Secret" .Release.Namespace "skupper-console-users" -}}
{{- if $secret -}}
admin:  {{ index $secret.data "admin" }}
{{- else -}}
admin: "YWRtaW4K"
{{- end -}}
{{- end -}}

{{- define "skupper.siteuid" -}}
{{- $uid := lookup "v1" "ConfigMap" .Release.Namespace "skupper-site" -}}
{{- if $uid -}}
{{- printf "%s" (lookup "v1" "ConfigMap" .Release.Namespace "skupper-site").metadata.uid }}
{{- end -}}
{{- end -}}

{{/*
skupper token labels and annotations for the link secret
*/}}
{{- define "token.metadata" -}}
labels:
  skupper.io/type: connection-token
annotations:
  edge-port: "443"
  inter-router-port: "443"
{{- end -}}

{{/*
skupper router Annotations
*/}}
{{- define "router.annotations" -}}
{{- if .Values.router.annotations }}
{{- toYaml .Values.router.annotations }}
{{- end -}}
{{- end -}}

{{/*
skupper router labels
*/}}
{{- define "router.labels" -}}
{{- if .Values.router.labels }}
{{- toYaml .Values.router.labels }}
{{- end -}}
{{- end -}}

{{/*
skupper router affinity
*/}}
{{- define "router.affinity" -}}
{{- if .Values.router.affinity }}
{{- toYaml .Values.router.affinity }}
{{- end -}}
{{- end -}}
