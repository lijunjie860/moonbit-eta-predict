# Source Statement

This repository contains original MoonBit source code written for the MoonBit August Hackathon.

The project uses well-known public algorithms and engineering ideas:

- scalar Kalman filtering for online state estimation;
- adaptive moving-window statistics for local stability;
- weighted blending of live and historical route speed;
- standard regression metrics such as MAE, RMSE, and MAPE.

No mature MoonBit package with the same ETA prediction scope was found during the mooncakes.io keyword check for `eta`, `kalman`, and `time series`. The project is therefore positioned as a reusable ecosystem package rather than a clone of an existing MoonBit module.
