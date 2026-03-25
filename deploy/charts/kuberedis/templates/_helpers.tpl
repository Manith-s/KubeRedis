{{/*
Expand the name of the chart.
*/}}
{{- define "kuberedis.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Fully qualified app name (release-chart, or override).
*/}}
{{- define "kuberedis.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Chart label value (name-version).
*/}}
{{- define "kuberedis.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* ── Common labels ──────────────────────────────────── */}}
{{- define "kuberedis.labels" -}}
helm.sh/chart: {{ include "kuberedis.chart" . }}
{{ include "kuberedis.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "kuberedis.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kuberedis.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* ── KVStore helpers ────────────────────────────────── */}}
{{- define "kuberedis.kvstore.name" -}}
{{- printf "%s-kvstore" (include "kuberedis.fullname" .) }}
{{- end }}

{{- define "kuberedis.kvstore.labels" -}}
{{ include "kuberedis.labels" . }}
app.kubernetes.io/component: kvstore
{{- end }}

{{- define "kuberedis.kvstore.selectorLabels" -}}
{{ include "kuberedis.selectorLabels" . }}
app.kubernetes.io/component: kvstore
{{- end }}

{{/* ── Redis helpers ──────────────────────────────────── */}}
{{- define "kuberedis.redis.name" -}}
{{- printf "%s-redis" (include "kuberedis.fullname" .) }}
{{- end }}

{{- define "kuberedis.redis.headlessServiceName" -}}
{{- printf "%s-redis-headless" (include "kuberedis.fullname" .) }}
{{- end }}

{{- define "kuberedis.redis.labels" -}}
{{ include "kuberedis.labels" . }}
app.kubernetes.io/component: redis
{{- end }}

{{- define "kuberedis.redis.selectorLabels" -}}
{{ include "kuberedis.selectorLabels" . }}
app.kubernetes.io/component: redis
{{- end }}

{{/*
Address of the Redis primary pod for kvstore to connect to.
Format: <statefulset>-0.<headless-svc>.<namespace>.svc.cluster.local:<port>
*/}}
{{- define "kuberedis.redis.primaryAddr" -}}
{{- printf "%s-0.%s.%s.svc.cluster.local:%d" (include "kuberedis.redis.name" .) (include "kuberedis.redis.headlessServiceName" .) .Release.Namespace (int .Values.redis.port) }}
{{- end }}
