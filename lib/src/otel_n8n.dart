// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_n8n_suppression.dart';

const _tracerName = 'dartastic_otel_libs_n8n';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Wraps an n8n webhook trigger POST in a PRODUCER span. [path]
/// is the webhook path (e.g. `customer-signup`).
Future<T> tracedN8nWebhook<T>({
  required String path,
  required Future<T> Function() invoke,
  String? workflowName,
  int? payloadSize,
}) async {
  if (n8nInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'messaging.system': 'n8n_webhook',
    'messaging.operation': 'publish',
    'messaging.destination.name': path,
    'n8n.webhook.path': path,
  };
  if (workflowName != null) m['n8n.workflow.name'] = workflowName;
  if (payloadSize != null) m['messaging.message.body.size'] = payloadSize;

  final span = _tracer().startSpan(
    'n8n webhook $path',
    kind: SpanKind.producer,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}

/// Wraps an n8n REST API call (workflows.activate, executions.list,
/// etc.) in a CLIENT span.
Future<T> tracedN8nApi<T>({
  required String resource,
  required String action,
  required Future<T> Function() invoke,
  String? workflowId,
  String? executionId,
}) async {
  if (n8nInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'n8n.resource': resource,
    'n8n.action': action,
    'n8n.operation': '$resource.$action',
  };
  if (workflowId != null) m['n8n.workflow.id'] = workflowId;
  if (executionId != null) m['n8n.execution.id'] = executionId;

  final span = _tracer().startSpan(
    'n8n $resource.$action',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
