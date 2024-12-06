{{- define "pfdcm.name" -}}
{{- default .Values.pfdcm.nameOverride "chris-pfdcm" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pfdcm.fullname" -}}
{{- mustMerge (dict
  "Values" (dict
    "nameOverride" (include "pfdcm.name" .)
    "fullnameOverride" .Values.pfdcm.fullnameOverride
  )
) (omit . "Values") | include "util.fullname" -}}
{{- end -}}

{{- define "pfdcm.volumes" -}}
- name: data
  emptyDir:
    sizeLimit: {{ .Values.pfdcm.dataSizeLimit | default "1Gi" }}
- name: config
  secret:
    secretName: {{ include "pfdcm.fullname" . }}
    optional: false
{{- end -}}

{{- define "pfdcm.volumeMounts" -}}
- mountPath: /home/dicom
  name: data
- mountPath: /home/dicom/services
  name: config
{{- end -}}

{{- define "pfdcm.labels" -}}
{{- include "chris.labels" . }}
app.kubernetes.io/name: {{ include "pfdcm.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: backend
{{- end -}}

{{- define "pfdcm.listenerVersion" -}}
{{- .Values.pfdcm.listener.image.tag -}}
{{- end -}}

{{- define "pfdcm.listenerLabels" -}}
{{ include "chris.labels" . }}
app.kubernetes.io/name: oxidicom
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ include "pfdcm.listenerVersion" . | quote }}
app.kubernetes.io/component: backend
{{- end }}

{{- define "pfdcm.listenerService" -}}
{{ .Release.Name }}-oxidicom
{{- end -}}

