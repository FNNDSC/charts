{{- define "util.knativeOrDeployment" -}}
{{- include "util.serviceAccountTpl" . }}
---
{{- include "util.testServiceConnectionTpl" . }}
---
{{- if (eq .Values.kind "Service") }}
  {{- include "util.knativeServiceTpl" . }}
{{- else if (eq .Values.kind "Deployment") }}
  {{- include "util.deploymentEverythingTpl" . }}
{{- else }}
  {{- fail (printf "Unsupported kind: %s" .kind) }}
{{- end -}}
{{- end -}}

{{- define "util.deploymentEverythingTpl" }}
{{- include "util.deploymentTpl" . }}
---
{{- include "util.hpaTpl" . }}
---
{{- include "util.ingressTpl" . }}
---
{{- include "util.serviceTpl" . }}
---
{{- include "util.openshiftRouteTpl" . }}
{{- end }}
