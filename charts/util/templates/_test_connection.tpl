{{- define "util.testConnectionHost" -}}
{{- if .Values.route.enabled -}}
{{- .Values.route.host | required "route.host is required because route.enabled=true" -}}
{{- else if .Values.ingress.enabled -}}
{{- (first .Values.ingress.hosts).host | required "ingress.hosts[0].host is required because ingress.enabled=true" -}}
{{- else -}}
{{- include "util.fullname" . }}:{{ .Values.service.port }}
{{- end -}}
{{- end -}}
{{- define "util.testConnectionScheme" -}}
{{- if (or (and .Values.ingress.enabled .Values.ingress.tls)
           (and .Values.route.enabled   .Values.route.tls)) -}}
https
{{- else -}}
http
{{- end -}}
{{- end -}}

{{- define "util.testServiceConnectionTpl" }}
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "util.fullname" . }}-test-connection"
  labels:
    {{- include "util.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": test
spec:
  containers:
    - name: wget
      image: quay.io/prometheus/busybox:latest
      command: ['wget']
      args:
        - --spider
        - {{ include "util.testConnectionScheme" . }}://{{ include "util.testConnectionHost" . }}{{ (.Values.test).path }}
  restartPolicy: Never
{{- end }}
