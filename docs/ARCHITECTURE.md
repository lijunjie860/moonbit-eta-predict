# Architecture

The package is organized around a deterministic data flow:

```text
Observation[]
    -> validation.mbt / guardrails.mbt
    -> csv_codec.mbt / json_codec.mbt / dataset.mbt
    -> kalman.mbt + window.mbt + profile.mbt + calendar.mbt
    -> eta.mbt / stream.mbt / route_forecast.mbt
    -> metrics.mbt / advanced_metrics.mbt / quality_gate.mbt
    -> calibration / benchmark / report / CLI
```

The root package owns public records and enums. Files are implementation boundaries rather than separate modules, so the public API remains importable as `@lijunjie860/moonbit-eta-predict`. The executable under `cmd/main` only obtains command-line arguments and delegates to `run_cli`.

## Runtime principles

1. Inputs are validated and normalized before entering a streaming engine.
2. Historical route profiles provide a bounded fallback when live evidence is weak.
3. All benchmark fixtures are deterministic and checked into source code.
4. Parsing failures return typed outcomes rather than panicking.
5. Contract and quality-gate helpers make assumptions visible to host applications.

The package intentionally avoids network calls and service-specific integrations. This keeps the core suitable for WebAssembly, native edge programs, and server-side embedding.
