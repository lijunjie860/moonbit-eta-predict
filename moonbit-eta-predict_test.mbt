///|
test "kalman smooths abrupt measurement noise" {
  let cfg = default_kalman_config()
  let values = [10.0, 10.5, 42.0, 10.8, 11.0]
  let smoothed = smooth_values(values, initial=10.0, config=cfg)
  assert_true(smoothed[2] < 25.0)
  assert_true(smoothed[4] < 15.0)
}

///|
test "adaptive window expands under stable samples" {
  let mut window = WindowState::new(default_window_config())
  for value in [8.0, 8.1, 8.0, 8.2, 8.1, 8.0, 8.1] {
    window = window.push(value)
  }
  assert_true(window.target_size > default_window_config().min_size)
  assert_true(window.stability() > 0.8)
}

///|
test "route profile produces plausible historical eta" {
  let route = demo_route()
  assert_true(route.total_distance() > 5000.0)
  let quiet = route.historical_eta(congestion=0.1)
  let rush = route.historical_eta(congestion=0.9)
  assert_true(rush > quiet)
}

///|
test "eta engine emits decreasing remaining distance" {
  let results = run_demo()
  assert_true(results.length() > 4)
  assert_true(
    results[0].remaining_distance >
    results[results.length() - 1].remaining_distance,
  )
  assert_true(results[results.length() - 1].eta_seconds > 0.0)
}

///|
test "metrics summarize forecast errors" {
  let summary = summarize_errors([
    { predicted: 10.0, actual: 12.0 },
    { predicted: 20.0, actual: 18.0 },
    { predicted: 30.0, actual: 33.0 },
  ])
  assert_eq(summary.count, 3)
  assert_true(summary.mae > 2.0)
  assert_true(summary.max_error == 3.0)
}

///|
test "scenario generator creates aligned observations and actuals" {
  let trace = noisy_demo_trace()
  assert_eq(trace.observations.length(), trace.actual_remaining.length())
  assert_true(trace.observations.length() == default_scenario_config().steps)
}

///|
test "calibration scans congestion candidates" {
  let result = calibrate_demo()
  assert_true(result.candidates.length() > 5)
  assert_true(result.best_congestion >= 0.0)
  assert_true(result.best_congestion <= 1.0)
}

///|
test "demo report includes eta and calibration sections" {
  let report = demo_report()
  assert_true(report.contains("MoonBit ETA report"))
  assert_true(report.contains("best_congestion"))
}

///|
test "validation reports temporal and distance defects" {
  let report = validate_observations([
    { timestamp: 20.0, distance: 3.0, elapsed: 20.0 },
    { timestamp: 10.0, distance: -1.0, elapsed: 10.0 },
  ])
  assert_true(report.issues.length() >= 2)
  assert_true(!report.valid)
}

///|
test "statistics handle median quantile and robust spread" {
  let values = [1.0, 2.0, 3.0, 100.0]
  assert_true(median(values) == 2.5)
  assert_true(quantile(values, probability=0.75) > 3.0)
  assert_true(mad(values) > 0.0)
  assert_true(percentile_rank(values, value=2.0) > 0.0)
}

///|
test "normalization sorts and removes duplicate timestamps" {
  let normalized = normalize_observations([
    { timestamp: 20.0, distance: 20.0, elapsed: 20.0 },
    { timestamp: 10.0, distance: 10.0, elapsed: 10.0 },
    { timestamp: 10.0, distance: 11.0, elapsed: 10.0 },
  ])
  assert_eq(normalized.length(), 2)
  assert_true(normalized[0].timestamp < normalized[1].timestamp)
}

///|
test "calendar selects boundary buckets deterministically" {
  let calendar = demo_calendar()
  assert_true(calendar.congestion_at(1, 7.0 * 3600.0) > 0.0)
  assert_true(calendar.congestion_at(6, 2.0 * 3600.0) < 0.5)
}

///|
test "route breakdown sums segment eta" {
  let result = forecast_breakdown(demo_route(), speed=8.0, congestion=0.4)
  assert_eq(result.segments.length(), demo_route().segments.length())
  assert_true(result.total_eta_seconds > 0.0)
  assert_true(result.total_eta_seconds == sum_segment_eta(result.segments))
}

///|
test "csv codec accepts headers and rejects malformed rows" {
  let csv = "timestamp,distance,elapsed\n0,0,0\n60,600,60\n"
  let parsed = parse_csv_observations(csv)
  assert_eq(parsed.observations.length(), 2)
  let bad = parse_csv_observations("timestamp,distance\n0,0\n")
  assert_true(bad.is_error())
}

///|
test "json line codec round trips observations" {
  let source : Array[Observation] = [
    { timestamp: 0.0, distance: 0.0, elapsed: 0.0 },
    { timestamp: 30.0, distance: 240.0, elapsed: 30.0 },
  ]
  let encoded = encode_json_lines(source)
  let decoded = parse_json_lines(encoded)
  assert_eq(decoded.observations.length(), source.length())
  assert_true(decoded.observations[1].distance == 240.0)
}

///|
test "batch forecasting preserves input cardinality" {
  let batch = forecast_batch(demo_observations(), demo_route(), congestion=0.3)
  assert_eq(batch.results.length(), demo_observations().length())
  assert_true(batch.summary.count == batch.results.length())
}

///|
test "rolling evaluation handles short windows" {
  let evaluation = rolling_evaluate(
    run_demo(),
    noisy_demo_trace().actual_remaining,
    window_size=3,
  )
  assert_true(evaluation.windows.length() > 0)
  assert_true(evaluation.overall.count > 0)
}

///|
test "benchmark suite is deterministic and non-empty" {
  let report = run_benchmark_suite()
  assert_true(report.cases.length() >= 4)
  assert_true(report.total_points > 0)
  assert_true(report.aggregate.mae >= 0.0)
  assert_true(report.rendered.contains("stable"))
}

///|
test "cli dispatch exposes help and benchmark" {
  assert_true(run_cli(["help"]).contains("benchmark"))
  assert_true(run_cli(["benchmark"]).contains("cases="))
  assert_true(run_cli(["version"]).contains("0.2.1"))
  assert_true(run_cli(["unknown"]).contains("unknown command"))
}

///|
test "empty and invalid inputs are safe" {
  assert_true(!validate_observations([]).valid)
  assert_true(validate_route({ segments: [] }).issues.length() > 0)
  assert_true(parse_csv_observations("").is_error())
  assert_true(parse_json_lines("not-json").is_error())
  assert_true(root_mean_square([]) == 0.0)
}

///|
test "statistics clamp probability and preserve robust ordering" {
  assert_true(quantile([1.0, 2.0, 3.0], probability=-2.0) == 1.0)
  assert_true(quantile([1.0, 2.0, 3.0], probability=3.0) == 3.0)
  assert_true(trimmed_mean([1.0, 2.0, 3.0, 100.0], proportion=0.25) < 30.0)
  assert_true(winsorize([1.0, 2.0, 3.0, 100.0])[3] < 100.0)
}

///|
test "schema and dataset summaries expose missing targets" {
  let schema = observation_schema()
  assert_true(validate_schema_metadata(schema))
  assert_true(
    validate_schema_header(schema, ["timestamp", "distance", "elapsed"]).valid,
  )
  assert_true(!validate_schema_header(schema, ["timestamp", "distance"]).valid)
  let dataset = dataset_from_observations(demo_observations())
  assert_true(
    summarize_dataset(dataset).missing_targets == dataset.rows.length(),
  )
  assert_true(target_coverage(dataset) == 0.0)
}

///|
test "dataset normalization and slicing are deterministic" {
  let dataset = dataset_from_targets(
    [
      { timestamp: 20.0, distance: 20.0, elapsed: 20.0 },
      { timestamp: 0.0, distance: 0.0, elapsed: 0.0 },
    ],
    [10.0, 20.0],
  )
  let normalized = dataset.normalize()
  assert_true(normalized.observations()[0].timestamp == 0.0)
  assert_true(normalized.between(start=0.0, end=10.0).rows.length() == 1)
  assert_true(stride_dataset(normalized, 2).rows.length() == 1)
}

///|
test "json and csv encoders produce parseable round trips" {
  let observations = demo_observations()[0:3].to_owned()
  let csv = encode_csv_observations(observations)
  let json = encode_json_lines(observations)
  assert_eq(
    parse_csv_observations(csv).observations.length(),
    observations.length(),
  )
  assert_eq(parse_json_lines(json).observations.length(), observations.length())
  assert_true(parse_double_token("bad") is None)
}

///|
test "grid calibration and cross validation handle small datasets" {
  let trace = noisy_demo_trace()
  let dataset = dataset_from_targets(trace.observations, trace.actual_remaining)
  let grid = grid_calibrate(demo_route(), dataset, steps=3)
  assert_true(grid.evaluated == 4)
  assert_true(refine_grid(demo_route(), dataset, grid).evaluated > 0)
  let cv = cross_validate_congestion(demo_route(), dataset, fold_count=3)
  assert_true(cv.folds.length() == 3)
  assert_true(cross_validation_is_complete(cv))
}

///|
test "quality gates explain failures" {
  let result = evaluate_quality_gate([], [], {
    max_mae: 1.0,
    max_rmse: 1.0,
    min_confidence: 0.9,
    min_points: 1,
    require_monotonic_distance: true,
  })
  assert_true(!result.passed)
  assert_true(result.reasons.length() > 0)
  assert_true(format_quality_gate(result).contains("passed="))
}

///|
test "streaming monitor drops invalid observations and emits alerts" {
  let (summary, alerts) = monitor_observations(
    [
      { timestamp: 0.0, distance: 0.0, elapsed: 0.0 },
      { timestamp: -1.0, distance: 10.0, elapsed: 1.0 },
      { timestamp: 30.0, distance: 20.0, elapsed: 30.0 },
    ],
    demo_route(),
  )
  assert_true(summary.snapshots.length() == 2)
  assert_true(summary.dropped == 1)
  assert_true(alerts.length() > 0)
  assert_true(stream_is_safe(summary))
}

///|
test "advanced metrics and bins remain finite" {
  let results = run_demo()
  let trace = noisy_demo_trace()
  let points = eta_results_to_points(results, trace.actual_remaining)
  let report = metric_report(results, points)
  assert_true(report.smape >= 0.0)
  assert_true(report.coverage >= 0.0 && report.coverage <= 1.0)
  assert_true(metric_vector(report).length() == 7)
  assert_true(calibration_gap(report) >= 0.0)
}

///|
test "route selection handles empty and ranked candidates" {
  assert_true(select_route([]).selected is None)
  let candidates = make_route_candidates(
    [("main", demo_route()), ("backup", demo_route())],
    speed=8.0,
    congestion=0.4,
  )
  let selection = select_route(candidates)
  assert_true(selection.selected is Some(_))
  assert_eq(route_ids(candidates).length(), 2)
  assert_true(pareto_routes(candidates).length() > 0)
}

///|
test "benchmark reports contain real deterministic case rows" {
  let report = run_benchmark_suite()
  assert_true(render_benchmark_table(report).contains("stable"))
  assert_true(benchmark_lines(report).length() == report.cases.length() + 1)
  assert_true(benchmark_interpretation(report).contains("cases="))
  assert_true(benchmark_mae_spread(report) >= 0.0)
}

///|
test "public diagnostics render values instead of interpolation markers" {
  assert_true(version_banner().contains("moonbit-eta-predict 0.2.1"))
  let contract = format_contract({
    valid: false,
    checks: 2,
    failures: ["bad input"],
  })
  assert_true(contract.contains("valid=false checks=2 failures=1"))
  let gate = format_quality_gate({
    passed: false,
    reasons: ["too few points"],
    checked_points: 0,
    summary: summarize_errors([]),
  })
  assert_true(gate.contains("passed=false points=0"))
}

///|
test "guardrails and route contracts reject unsafe traces" {
  let route = demo_route()
  let input_guard = default_input_guard(route)
  let observations : Array[Observation] = [
    { timestamp: 0.0, distance: 0.0, elapsed: 0.0 },
    { timestamp: 30.0, distance: 200.0, elapsed: 30.0 },
    { timestamp: 20.0, distance: 100.0, elapsed: 20.0 },
  ]
  let (accepted, reasons) = guard_trace(observations, input_guard)
  assert_eq(accepted.length(), 2)
  assert_true(reasons.length() > 0)
  assert_true(
    !guard_observation(Some(observations[1]), observations[2], input_guard).accepted,
  )
  assert_true(
    clamp_observation_distance(observations[1], 100.0).distance == 100.0,
  )
  let results = run_demo()
  assert_true(results_are_finite(results))
  assert_true(forecast_contract(demo_observations(), results).valid)
}

///|
test "alerts and explanations expose operational context" {
  let route = demo_route()
  let (summary, alerts) = monitor_observations(
    [
      { timestamp: 0.0, distance: 0.0, elapsed: 0.0 },
      { timestamp: 30.0, distance: 20.0, elapsed: 30.0 },
    ],
    route,
  )
  assert_true(summary.snapshots.length() == 2)
  assert_eq(alert_counts(alerts).length(), 5)
  assert_true(format_alerts(alerts).contains("update="))
  let explanations = explain_batch(
    forecast_batch(demo_observations(), route, congestion=0.8),
    route,
    congestion=0.8,
  )
  assert_true(explanations.length() > 0)
  assert_true(format_eta_explanation(explanations[0]).contains("remaining="))
}

///|
test "time series utilities cover empty and boundary series" {
  assert_eq(summarize_time_series([]).count, 0)
  assert_eq(first_differences([1.0, 3.0, 2.0]).length(), 2)
  assert_true(cumulative_sum([1.0, 2.0], initial=1.0)[1] == 4.0)
  assert_true(integrate_series([0.0, 2.0, 4.0]) == 4.0)
  assert_true(interpolate_series([0.0, 10.0], 0.5) == 5.0)
  assert_eq(resample_series([0.0, 10.0], 3).length(), 3)
  assert_eq(moving_average_series([1.0, 3.0, 5.0], 2).length(), 3)
  assert_eq(holt_level([]).length(), 0)
  assert_eq(extrapolate_series([2.0], 2).length(), 2)
}

///|
test "health metadata and sensitivity are stable for host integrations" {
  assert_true(demo_health().ready)
  assert_true(capabilities_are_named())
  assert_true(metadata_is_complete())
  assert_true(supports_target("wasm-gc"))
  assert_true(!supports_target("unknown"))
  let speed_report = speed_sensitivity(demo_route(), congestion=0.4, steps=2)
  assert_eq(speed_report.points.length(), 3)
  assert_true(maximum_sensitivity_delta(speed_report) >= 0.0)
  assert_true(nearest_sensitivity_point(speed_report, 8.0) is Some(_))
  assert_true(format_sensitivity(speed_report).contains("parameter=live_speed"))
  assert_true(regime_for_congestion(0.0) == FreeFlow)
  assert_true(regime_for_congestion(1.0) == RushHour)
}

///|
test "calendar route forecasts preserve segment contracts" {
  let detailed = forecast_breakdown_at(
    demo_route(),
    speed=8.0,
    demo_calendar(),
    weekday=1,
    second_of_day=8.0 * 3600.0,
  )
  assert_true(detailed_breakdown_is_consistent(detailed))
  assert_true(format_detailed_breakdown(detailed).contains("weekday=1"))
  assert_true(
    cumulative_segment_eta(detailed.total.segments).length() ==
    detailed.total.segments.length(),
  )
  assert_true(bottleneck_segment(detailed.total.segments) is Some(_))
  assert_true(reliable_distance_fraction(demo_route()) >= 0.0)
}
