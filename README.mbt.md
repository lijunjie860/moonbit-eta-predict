# moonbit-eta-predict

`moonbit-eta-predict` provides deterministic streaming ETA prediction primitives for MoonBit applications. It combines scalar Kalman smoothing, adaptive windows, route profiles, calendar-aware congestion, typed CSV/JSON Lines codecs, batch calibration, quality gates, and reproducible benchmark reports.

## Quick start

```bash
moon update
moon check --deny-warn --target all
moon test --deny-warn --target all
moon run cmd/main -- demo
```

```mbt check
///|
test "README forecast example" {
  let route = demo_route()
  let batch = forecast_batch(demo_observations(), route, congestion=0.3)
  assert_true(batch.results.length() > 0)
  assert_true(batch.summary.count == batch.results.length())
}
```

## Capabilities

- Kalman smoothing and innovation gating.
- Adaptive windows and confidence estimation.
- Multi-segment route ETA and weekly congestion calendars.
- CSV and JSON Lines observation codecs with schema validation.
- Batch forecasting, rolling evaluation, calibration, and cross-validation.
- Error metrics, quality gates, alerts, route selection, and explanations.
- Deterministic CLI demos and benchmark cases.

## CLI

```text
moon run cmd/main -- demo
moon run cmd/main -- benchmark table
moon run cmd/main -- calibrate
moon run cmd/main -- validate
```

## Testing and CI

```bash
moon fmt --check
moon check --deny-warn --target all
moon test --deny-warn --target all
moon info
```

The repository CI repeats these checks on Ubuntu, macOS, and Windows and publishes coverage summaries.

## License

Apache-2.0. See [LICENSE](LICENSE).
