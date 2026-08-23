# Source and attribution

This repository contains original MoonBit implementation code for a reusable
streaming ETA prediction library. The implementation is organized around
public domain algorithms and does not copy source files from another project.

The project uses well-known algorithms and engineering ideas:

- scalar Kalman filtering for online state estimation;
- adaptive moving-window statistics for local stability;
- weighted blending of live and historical route speed;
- standard regression metrics such as MAE, RMSE, and MAPE.

The package has no vendored third-party source files, generated source from
external projects, private code, commercial data, or non-redistributable test
fixtures. Its only runtime dependency is `moonbitlang/core/json`, which is
used for JSON Lines interchange.

The public API is designed for applications that need deterministic route
forecasting, observation validation, route profiles, calibration, evaluation,
and reproducible reports without requiring a map provider or network service.
