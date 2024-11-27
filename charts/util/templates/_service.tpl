{{- define "util.serviceTpl" }}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "util.fullname" . }}
  labels:
    {{- include "util.labels" . | nindent 4 }}
  {{- with .Values.service.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: http
      protocol: TCP
      name: http
      {{- if .Values.service.nodePort }}
      nodePort: {{ .Values.service.nodePort }}
      {{- end }}
  selector:
    {{- include "util.selectorLabels" . | nindent 4 }}
{{- end }}
