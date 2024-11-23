{{- /*
Helper function to use a value. If the value is unset, try looking up the previous value
from a secret. If the secret does not exist, generate a random value with a specified length.
*/ -}}
{{- define "util.valueOrLookupOrRandom" -}}
{{- if .value -}}
  {{- .value | b64enc | quote -}}
{{- else -}}
  {{- $length := .length | default 32 -}}
  {{- $name := .name -}}
  {{- if (not $name) -}}
    {{- fail (printf "util.valueOrLookupOrRandom was not called with required parameter 'name'. Given parameters: %s" (keys .)) -}}
  {{- end -}}
  {{- with (lookup "v1" "Secret" .root.Release.Namespace .secret) -}}
    {{- if (hasKey .data $name) -}}
      {{- (index .data $name) | quote -}}
    {{- else -}}
      {{- randAlphaNum $length | b64enc | quote -}}
    {{- end -}}
  {{- else -}}
    {{- randAlphaNum $length | b64enc | quote -}}
  {{- end -}}
{{- end -}}
{{- end -}}

