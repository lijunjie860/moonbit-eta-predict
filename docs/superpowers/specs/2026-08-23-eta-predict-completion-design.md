# ETA Prediction Completion Design

**Goal:** Turn `moonbit-eta-predict` into a reusable, documented, tested MoonBit ETA toolkit with more than 6,000 lines of meaningful production `.mbt` source.

**Scope:** Extend the existing deterministic streaming estimator in the directions already described by the proposal: structured observations, CSV/JSON interchange, calendar-aware route profiles, batch calibration, reproducible benchmarks, and a usable CLI. The proposal file remains read-only.

## Architecture

The public root package remains the compatibility facade. New implementation files are organized by responsibility: validation and normalization, robust statistics, route calendars, dataset parsing, batch forecasting, calibration, benchmarking, and reporting. Public records live in the root package; private parsing and scoring helpers stay private to their files. Existing constructors and functions remain available.

The data flow is:

```text
raw observations -> parser -> validation/normalization -> scenario/dataset
                                             |
                                             v
                    route calendar + streaming ETA engine
                                             |
                       results -> metrics -> benchmark/report
```

All algorithms are deterministic and use only the MoonBit standard library. No network service, map provider, database, or generated data is required at runtime.

## Deliverables

- Typed observation batches with validation, sorting, deduplication, and safe normalization.
- CSV and JSON line codecs with explicit parse errors and round-trip tests.
- Calendar-aware route profiles and multi-segment ETA breakdowns.
- Batch forecasting, rolling evaluation, calibration, and reproducible benchmark reports.
- CLI commands that exercise demo, benchmark, and calibration flows.
- Boundary tests for empty, malformed, non-monotonic, degenerate, noisy, and extreme inputs.
- README sections for positioning, capabilities, quick start, CLI, architecture, benchmarks, testing, CI, and license.
- CI for formatting, warnings, all targets, coverage, API interface stability, and packaging checks.

## Non-goals

- Editing the proposal or adding internal submission/authoring commentary to the public README.
- Claiming external production accuracy or real-world traffic data that is not present in the repository.
- Adding a network client or a third-party runtime dependency just to increase source size.

## Verification

The completion gate is a fresh local run of `moon fmt --check`, `moon check --deny-warn --target all`, `moon test --deny-warn --target all`, coverage reporting, `moon info`, CLI execution, benchmark execution, repository inspection, and a production-only `.mbt` line count excluding tests and generated `.mbti` files.
