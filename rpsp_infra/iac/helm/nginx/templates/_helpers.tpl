{{/*
Expand the chart name.
*/}}
{{- define "dda-nginx-ingress.name" -}}
{{- printf "dda-ingress-%s" .Values.environment }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "dda-nginx-ingress.labels" -}}
app.kubernetes.io/name: dda-nginx-ingress
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
environment: {{ .Values.environment }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}

{{/*
Computed fully qualified domain for the environment.
*/}}
{{- define "dda-nginx-ingress.fqdn" -}}
{{- printf "%s.%s" .Values.subdomain .Values.domain }}
{{- end }}
