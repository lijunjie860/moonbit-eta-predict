# moonbit-eta-predict

Deterministic, streaming estimated-time-of-arrival primitives for MoonBit applications. The library turns noisy progress observations into stable ETA updates for logistics, campus transit, delivery, warehouse robots, and other bounded-route workflows.

## Project positioning

`moonbit-eta-predict` is a reusable algorithm and data layer. It does not depend on a map provider, online traffic API, database, or network service. Applications provide route segments and observations; the library handles smoothing, validation, historical profiles, calendar-aware congestion, evaluation, and reproducible reports.

## Core capabilities

- Scalar Kalman smoothing with innovation gating for noisy telemetry.
- Adaptive moving windows with stability and confidence estimates.
- Route profiles, multi-segment ETA breakdowns, bottleneck detection, and route ranking.
- Weekly congestion calendars and free-flow, typical, rush-hour, and live speed policies.
- CSV and JSON Lines codecs with schema validation and non-panicking parse outcomes.
- Batch forecasting, rolling evaluation, congestion grid calibration, holdout evaluation, and cross-validation.
- MAE, RMSE, MAPE, sMAPE, bias, median absolute error, coverage, calibration bins, and quality gates.
- Deterministic synthetic traces and benchmark cases for stable, noisy, delayed, and congested conditions.
- A small CLI for demos, benchmark tables, calibration, validation, and version information.

## Quick start

Requires the current stable MoonBit toolchain.

```bash
moon update
moon check --deny-warn --target all
moon test --deny-warn --target all
moon run cmd/main -- demo
```

Library usage:

```moonbit
let route = @eta.demo_route()
let observations = @eta.demo_observations()
let batch = @eta.forecast_batch(observations, route, congestion=0.3)
println(@eta.format_batch_forecast(batch))
```

## CLI

```text
moon run cmd/main -- demo
moon run cmd/main -- benchmark
moon run cmd/main -- benchmark table
moon run cmd/main -- calibrate
moon run cmd/main -- validate
moon run cmd/main -- version
```

The CLI is deterministic and has no network or external data requirement.

## Architecture

```text
observations -> validation/normalization -> codecs/dataset
                                           |
                    route calendar + streaming ETA engine
                                           |
             batch results -> metrics -> calibration/benchmark/report
```

The root package owns the public domain types. Focused implementation files cover filtering, windows, profiles, calendars, codecs, datasets, batch workflows, calibration, metrics, contracts, alerts, route selection, and reports. `cmd/main` is a thin executable wrapper over the public CLI dispatcher.

## Benchmarks

Run:

```bash
moon run cmd/main -- benchmark table
```

Measured locally with the checked-in deterministic suite on 2026-08-23:

| Case | Points | MAE (s) | RMSE (s) | Mean confidence |
| --- | ---: | ---: | ---: | ---: |
| stable | 12 | 48.0563 | 61.5689 | 0.6096 |
| noisy | 12 | 100.2907 | 115.7411 | 0.4610 |
| delayed | 10 | 175.2661 | 205.0600 | 0.3943 |
| congested | 12 | 691.5240 | 709.8941 | 0.3608 |
| aggregate | 46 | 257.1981 | 380.9066 | — |

These are reproducible synthetic scenario measurements for regression detection, not claims about an external traffic dataset.

## Testing

```bash
moon fmt --check
moon check --deny-warn --target all
moon test --deny-warn --target all
moon test --deny-warn --enable-coverage
moon coverage report -f summary
moon info
```

The test suite covers ordinary flows and boundaries including empty input, malformed CSV/JSON, duplicate timestamps, non-monotonic observations, zero denominators, degenerate routes, extreme congestion, short cross-validation folds, invalid stream updates, and quality-gate failures.

## CI

GitHub Actions runs on Ubuntu, macOS, and Windows. It installs the stable MoonBit toolchain, updates dependencies, checks every backend, runs tests with coverage, verifies formatting and generated public interfaces, and keeps the working tree clean. Package publishing is a separate manual workflow with prepublish checks.

## License

Apache License 2.0. See [LICENSE](LICENSE).
