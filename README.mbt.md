# moonbit-eta-predict

`moonbit-eta-predict` is a MoonBit library for streaming estimated-time-of-arrival prediction. It combines scalar Kalman smoothing, robust outlier handling, adaptive moving windows, route segment profiles, and evaluation helpers so a MoonBit application can turn noisy progress observations into stable ETA updates.

The project was created for the MoonBit August Hackathon. Before selecting the topic, I checked mooncakes.io for overlapping packages around ETA, Kalman filtering, and time-series forecasting. Existing packages did not show a mature MoonBit ETA engine with route profiles and streaming correction, so this project focuses on that gap instead of duplicating a general utility library.

## Features

- One-dimensional Kalman filter for online speed smoothing.
- Innovation gate for noisy GPS or delayed telemetry measurements.
- Adaptive window that grows on stable traffic and shrinks during variance spikes.
- Route profiles with free-flow, typical, rush-hour, and reliability parameters.
- ETA engine that blends live observations with historical segment expectations.
- Metrics helpers for MAE, RMSE, MAPE, and max error.
- Runnable demo and black-box tests.

## Quick Start

```bash
moon update
moon check --deny-warn
moon test --deny-warn
moon fmt
moon info
git diff --exit-code
moon run cmd/main
```

## Example

```mbt check
///|
test {
  let route = demo_route()
  let observations = demo_observations()
  let results = forecast_route(observations, route)
  assert_true(results.length() > 0)
}
```

## Repository Structure

```text
.
|-- types.mbt                  # Public domain records
|-- defaults.mbt               # Defaults and numeric helpers
|-- kalman.mbt                 # Kalman prediction and measurement update
|-- window.mbt                 # Adaptive moving window
|-- profile.mbt                # Route and segment historical model
|-- eta.mbt                    # ETA engine facade
|-- metrics.mbt                # Forecast evaluation helpers
|-- examples.mbt               # Built-in demo route and observations
|-- cmd/main                   # CLI demo
|-- .github/workflows/test.yml # CI for MoonBit checks and tests
```

## Scope

The first release targets deterministic ETA estimation primitives that are easy to test and reuse. It does not depend on an external map provider, online traffic API, or native database. Future versions can add CSV ingestion, richer segment calendars, batch calibration, and bindings for web or edge deployments.

## Source Statement

All MoonBit source code in this repository is original implementation work for the hackathon. The algorithms are standard public-domain engineering techniques: scalar Kalman filtering, moving-window statistics, and weighted ETA blending. No third-party source code was copied into the implementation.

## License

Apache-2.0.
