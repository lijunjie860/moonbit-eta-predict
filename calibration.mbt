///|
pub fn default_calibration_config() -> CalibrationConfig {
  { min_congestion: 0.0, max_congestion: 1.0, steps: 10 }
}

///|
fn score_congestion(
  route : RouteProfile,
  observations : Array[Observation],
  actuals : Array[Double],
  congestion : Double,
) -> ErrorSummary {
  let results : Array[EtaResult] = []
  let mut engine = EtaEngine::new(route, initial_speed=8.0)
  for obs in observations {
    let (next, result) = engine.observe(obs, congestion~)
    engine = next
    results.push(result)
  }
  summarize_errors(eta_results_to_points(results, actuals))
}

///|
pub fn calibrate_congestion(
  route : RouteProfile,
  observations : Array[Observation],
  actuals : Array[Double],
  config? : CalibrationConfig = default_calibration_config(),
) -> CalibrationResult {
  let candidates : Array[ForecastPoint] = []
  let steps = if config.steps <= 0 { 1 } else { config.steps }
  let mut best_congestion = config.min_congestion
  let mut best_error = score_congestion(
    route,
    observations,
    actuals,
    config.min_congestion,
  )
  for i in 0..<=steps {
    let ratio = i.to_double() / steps.to_double()
    let congestion = config.min_congestion +
      (config.max_congestion - config.min_congestion) * ratio
    let summary = score_congestion(route, observations, actuals, congestion)
    candidates.push({ predicted: congestion, actual: summary.mae })
    if i == 0 || summary.mae < best_error.mae {
      best_congestion = congestion
      best_error = summary
    }
  }
  { best_congestion, best_error, candidates }
}

///|
pub fn calibrate_demo() -> CalibrationResult {
  let trace = noisy_demo_trace()
  calibrate_congestion(demo_route(), trace.observations, trace.actual_remaining)
}
