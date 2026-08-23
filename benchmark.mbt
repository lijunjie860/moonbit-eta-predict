///|
fn combine_error_summaries(summaries : Array[ErrorSummary]) -> ErrorSummary {
  let mut count = 0
  let mut mae_total = 0.0
  let mut squared_total = 0.0
  let mut mape_total = 0.0
  let mut maximum = 0.0
  for summary in summaries {
    count += summary.count
    mae_total += summary.mae * summary.count.to_double()
    squared_total += square(summary.rmse) * summary.count.to_double()
    mape_total += summary.mape * summary.count.to_double()
    if summary.max_error > maximum {
      maximum = summary.max_error
    }
  }
  if count == 0 {
    { count: 0, mae: 0.0, rmse: 0.0, mape: 0.0, max_error: 0.0 }
  } else {
    let total = count.to_double()
    {
      count,
      mae: mae_total / total,
      rmse: (squared_total / total).sqrt(),
      mape: mape_total / total,
      max_error: maximum,
    }
  }
}

///|
fn mean_result_confidence(results : Array[EtaResult]) -> Double {
  let values : Array[Double] = []
  for result in results {
    values.push(result.confidence)
  }
  robust_mean(values)
}

///|
fn benchmark_case_from_config(
  name : String,
  notes : String,
  config : ScenarioConfig,
  route : RouteProfile,
) -> BenchmarkCase {
  let trace = generate_scenario(route, config)
  let results = forecast_route(trace.observations, route)
  let points = eta_results_to_points(results, trace.actual_remaining)
  {
    name,
    points: points.length(),
    summary: summarize_errors(points),
    mean_confidence: mean_result_confidence(results),
    notes,
  }
}

///|
/// Build the deterministic benchmark matrix used in CI and README output.
pub fn benchmark_cases() -> Array[BenchmarkCase] {
  let route = demo_route()
  [
    benchmark_case_from_config(
      "stable",
      "low congestion with no injected measurement spike",
      { ..default_scenario_config(), congestion: 0.12, noise_magnitude: 0.0 },
      route,
    ),
    benchmark_case_from_config(
      "noisy",
      "moderate congestion with periodic positive and negative spikes",
      { ..default_scenario_config(), congestion: 0.35, noise_magnitude: 72.0 },
      route,
    ),
    benchmark_case_from_config(
      "delayed",
      "longer observation interval and lower base speed",
      {
        ..default_scenario_config(),
        steps: 10,
        interval_seconds: 75.0,
        base_speed: 8.0,
        noise_magnitude: 34.0,
      },
      route,
    ),
    benchmark_case_from_config(
      "congested",
      "high congestion route trace with short local speed envelope",
      {
        ..default_scenario_config(),
        congestion: 0.82,
        base_speed: 7.0,
        noise_magnitude: 48.0,
      },
      route,
    ),
  ]
}

///|
/// Render one benchmark case as a stable text row.
pub fn format_benchmark_case(case : BenchmarkCase) -> String {
  "\{case.name} points=\{case.points} mae=\{case.summary.mae} rmse=\{case.summary.rmse} mape=\{case.summary.mape} confidence=\{case.mean_confidence}"
}

///|
/// Render the full benchmark report as Markdown-compatible text.
pub fn render_benchmark_report(
  cases : Array[BenchmarkCase],
  aggregate : ErrorSummary,
) -> String {
  let builder = StringBuilder()
  builder.write_string("ETA benchmark\n")
  builder.write_string("case | points | MAE | RMSE | MAPE | confidence\n")
  builder.write_string("--- | ---: | ---: | ---: | ---: | ---:\n")
  for case in cases {
    builder.write_string(format_benchmark_case(case))
    builder.write_char('\n')
  }
  builder.write_string("aggregate ")
  builder.write_string(format_error_summary(aggregate))
  builder.to_string()
}

///|
/// Run all benchmark cases and return aggregate metrics.
pub fn run_benchmark_suite() -> BenchmarkReport {
  let cases = benchmark_cases()
  let summaries : Array[ErrorSummary] = []
  let mut total_points = 0
  for case in cases {
    summaries.push(case.summary)
    total_points += case.points
  }
  let aggregate = combine_error_summaries(summaries)
  {
    cases,
    aggregate,
    total_points,
    rendered: render_benchmark_report(cases, aggregate),
  }
}

///|
/// Return the benchmark case with the lowest MAE.
pub fn best_benchmark_case(report : BenchmarkReport) -> BenchmarkCase? {
  if report.cases.length() == 0 {
    None
  } else {
    let mut best = report.cases[0]
    for case in report.cases[1:] {
      if case.summary.mae < best.summary.mae {
        best = case
      }
    }
    Some(best)
  }
}

///|
/// Return the benchmark case with the highest MAE.
pub fn worst_benchmark_case(report : BenchmarkReport) -> BenchmarkCase? {
  if report.cases.length() == 0 {
    None
  } else {
    let mut worst = report.cases[0]
    for case in report.cases[1:] {
      if case.summary.mae > worst.summary.mae {
        worst = case
      }
    }
    Some(worst)
  }
}

///|
/// Check whether all cases meet a deterministic quality threshold.
pub fn benchmark_passes(report : BenchmarkReport, max_mae~ : Double) -> Bool {
  report.cases.all(case => case.summary.mae <= max_mae)
}

///|
/// Return all case names in report order.
pub fn benchmark_case_names(report : BenchmarkReport) -> Array[String] {
  let names : Array[String] = []
  for case in report.cases {
    names.push(case.name)
  }
  names
}

///|
/// Calculate the relative MAE spread between best and worst cases.
pub fn benchmark_mae_spread(report : BenchmarkReport) -> Double {
  match (best_benchmark_case(report), worst_benchmark_case(report)) {
    (Some(best), Some(worst)) =>
      safe_div(worst.summary.mae - best.summary.mae, best.summary.mae, 0.0)
    _ => 0.0
  }
}

///|
/// Create a benchmark report from an arbitrary route and scenario matrix.
pub fn benchmark_route(
  route : RouteProfile,
  scenarios : Array[(String, ScenarioConfig)],
) -> BenchmarkReport {
  let cases : Array[BenchmarkCase] = []
  for pair in scenarios {
    let name = pair.0
    let config = pair.1
    cases.push(
      benchmark_case_from_config(
        name, "caller supplied scenario", config, route,
      ),
    )
  }
  let summaries : Array[ErrorSummary] = []
  let mut total_points = 0
  for case in cases {
    summaries.push(case.summary)
    total_points += case.points
  }
  let aggregate = combine_error_summaries(summaries)
  {
    cases,
    aggregate,
    total_points,
    rendered: render_benchmark_report(cases, aggregate),
  }
}

///|
/// Return a benchmark summary suitable for a single-line CI annotation.
pub fn benchmark_annotation(report : BenchmarkReport) -> String {
  "cases=\{report.cases.length()} points=\{report.total_points} mae=\{report.aggregate.mae} rmse=\{report.aggregate.rmse}"
}
