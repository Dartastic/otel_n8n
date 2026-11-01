// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_n8n/otel_n8n.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_n8n-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('webhook records PRODUCER span', () async {
    await tracedN8nWebhook<String>(
      path: 'customer-signup',
      workflowName: 'Onboarding',
      payloadSize: 200,
      invoke: () async => 'ok',
    );
    final span = spans.findSpanByName('n8n webhook customer-signup');
    expect(span!.kind, SpanKind.producer);
    final a = attrsOf(span);
    expect(a['n8n.webhook.path'], 'customer-signup');
    expect(a['n8n.workflow.name'], 'Onboarding');
  });

  test('API call records CLIENT span', () async {
    await tracedN8nApi<String>(
      resource: 'workflows',
      action: 'activate',
      workflowId: 'w-1',
      invoke: () async => 'ok',
    );
    final a = attrsOf(spans.findSpanByName('n8n workflows.activate')!);
    expect(a['n8n.resource'], 'workflows');
    expect(a['n8n.workflow.id'], 'w-1');
  });

  test('suppression skips spans', () async {
    await runWithoutN8nInstrumentationAsync(() async {
      await tracedN8nWebhook<String>(
        path: 'p',
        invoke: () async => 'ok',
      );
    });
    expect(spans.findSpansStartingWith('n8n '), isEmpty);
  });
}
