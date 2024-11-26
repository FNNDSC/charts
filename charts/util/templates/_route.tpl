{{- define "util.openshiftRouteTpl" }}
{{- if .Values.route.enabled -}}
kind: Route
apiVersion: route.openshift.io/v1
metadata:
  name: {{ include "util.fullname" . }}
  labels:
    {{- include "util.labels" . | nindent 4 }}
  {{- with .Values.route.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  to:
    kind: Service
    name: {{ include "util.fullname" . }}
  {{- with .Values.route.tls }}
  tls:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  port:
    targetPort: http
  host: {{ required ".Values.route.host is required." .Values.route.host }}
{{- end }}
{{- end }}
