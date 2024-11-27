{{- define "util.serviceAccountTpl" }}
{{- if ((.Values).serviceAccount).create }}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "util.serviceAccountName" . }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- .Value.serviceAccount.labels | deepCopy | default (dict) | mustMergeOverwrite (include "util.labels" . | fromYaml) | toYaml | nindent 4 }}
  {{- with .Values.serviceAccount.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
automountServiceAccountToken: {{ .Values.serviceAccount.automount }}
{{- end }}
{{- end }}
