// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'dart:async';

const Symbol _suppressKey = #dartastic_otel_libs_n8n_suppress;

/// Whether instrumentation is suppressed in the current zone.
bool n8nInstrumentationSuppressed() {
  return Zone.current[_suppressKey] == true;
}

/// Runs [body] without creating spans for calls made inside it.
T runWithoutN8nInstrumentation<T>(T Function() body) {
  return runZoned(body, zoneValues: {_suppressKey: true});
}

/// Runs [body] without creating spans for calls made inside it.
Future<T> runWithoutN8nInstrumentationAsync<T>(
  Future<T> Function() body,
) {
  return runZoned(body, zoneValues: {_suppressKey: true});
}
