{{/*
Generate service name from map key.
*/}}
{{- define "dda-apps.serviceName" -}}
{{- printf "%s-service" . }}
{{- end }}

{{/*
Common labels attached to every resource.
Usage: include "dda-apps.labels" (dict "svc" $name "root" $) | nindent 4
*/}}
{{- define "dda-apps.labels" -}}
app.kubernetes.io/name: {{ printf "%s-service" .svc }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/version: {{ .root.Values.global.imageTag | quote }}
app.kubernetes.io/managed-by: {{ .root.Release.Service }}
app.kubernetes.io/part-of: dda-microservices
environment: {{ .root.Values.global.environment }}
helm.sh/chart: {{ .root.Chart.Name }}-{{ .root.Chart.Version }}
{{- end }}
