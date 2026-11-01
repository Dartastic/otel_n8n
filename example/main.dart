// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_n8n/otel_n8n.dart';

/// Traces n8n calls with OpenTelemetry.
///
/// `otel_n8n` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each n8n call in
/// [tracedN8nWebhook]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'n8n-example');

  // Wraps an n8n webhook trigger POST in a PRODUCER span.
  final n8nWebhookId = await tracedN8nWebhook<String>(
    path: '/v1/orders',
    workflowName: 'example',
    payloadSize: 512,
    invoke: () async {
      // Make the n8n call here, then report what it returned.
      return 'n8n_8f3a2c';
    },
  );
  OTelLog.info('tracedN8nWebhook returned $n8nWebhookId');

  // Wraps an n8n REST API call (workflows.activate, executions.list, etc.) in a CLIENT span.
  final n8nApiId = await tracedN8nApi<String>(
    resource: 'Order',
    action: 'example',
    workflowId: 'workflow_8f3a2c',
    executionId: 'execution_8f3a2c',
    invoke: () async {
      // Make the n8n call here, then report what it returned.
      return 'n8n_8f3a2c';
    },
  );
  OTelLog.info('tracedN8nApi returned $n8nApiId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutN8nInstrumentationAsync.
  await runWithoutN8nInstrumentationAsync(
    () => tracedN8nWebhook<String>(
      path: '/v1/orders',
      workflowName: 'example',
      payloadSize: 512,
      invoke: () async {
        return 'n8n_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
