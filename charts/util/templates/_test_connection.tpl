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
        - http://{{ include "util.fullname" . }}:{{ .Values.service.port }}{{ (.Values.test).path }}
  restartPolicy: Never
{{- end }}
