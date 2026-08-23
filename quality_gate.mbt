///|
/// Default quality thresholds for the deterministic package fixtures.
pub fn default_quality_gate() -> QualityGateConfig {
  {
    max_mae: 1000000.0,
    max_rmse: 1000000.0,
    min_confidence: 0.0,
    min_points: 1,
    require_monotonic_distance: true,
  }
}

///|
/// Return a gate with non-negative limits and sensible cardinality.
pub fn sanitize_quality_gate(config : QualityGateConfig) -> QualityGateConfig {
  {
    max_mae: if config.max_mae < 0.0 {
      0.0
    } else {
      config.max_mae
    },
    max_rmse: if config.max_rmse < 0.0 {
      0.0
    } else {
      config.max_rmse
    },
    min_confidence: clamp(config.min_confidence, 0.0, 1.0),
    min_points: if config.min_points < 0 {
      0
    } else {
      config.min_points
    },
    require_monotonic_distance: config.require_monotonic_distance,
  }
}

///|
fn gate_reason(reasons : Array[String], message : String) -> Unit {
  reasons.push(message)
}

///|
/// Evaluate forecast metrics and confidence thresholds.
pub fn evaluate_quality_gate(
  results : Array[EtaResult],
  points : Array[ForecastPoint],
  config : QualityGateConfig,
) -> QualityGateResult {
  let safe = sanitize_quality_gate(config)
  let reasons : Array[String] = []
  let summary = summarize_errors(points)
  if points.length() < safe.min_points {
    gate_reason(reasons, "not enough evaluation points")
  }
  if summary.mae > safe.max_mae {
    gate_reason(reasons, "MAE exceeds threshold")
  }
  if summary.rmse > safe.max_rmse {
    gate_reason(reasons, "RMSE exceeds threshold")
  }
  for result in results {
    if result.confidence < safe.min_confidence {
      gate_reason(reasons, "confidence below threshold")
    }
  }
  {
    passed: reasons.length() == 0,
    reasons,
    checked_points: points.length(),
    summary,
  }
}

///|
/// Check monotonic distance progression in a trace.
pub fn monotonic_distance(observations : Array[Observation]) -> Bool {
  let mut previous = -1.0
  let mut valid = true
  for observation in observations {
    if observation.distance < previous {
      valid = false
    }
    previous = observation.distance
  }
  valid
}

///|
/// Evaluate a batch with input progression and metric checks.
pub fn evaluate_batch_quality(
  observations : Array[Observation],
  batch : BatchForecast,
  config : QualityGateConfig,
) -> QualityGateResult {
  let base = evaluate_quality_gate(batch.results, batch.points, config)
  if config.require_monotonic_distance && !monotonic_distance(observations) {
    let reasons = base.reasons.copy()
    reasons.push("distance is not monotonic")
    { ..base, passed: false, reasons }
  } else {
    base
  }
}

///|
/// Render a gate result for CI output.
pub fn format_quality_gate(result : QualityGateResult) -> String {
  let builder = StringBuilder()
  builder.write_string("passed={result.passed} points={result.checked_points} ")
  builder.write_string(format_error_summary(result.summary))
  if result.reasons.length() > 0 {
    builder.write_string(" reasons=")
    builder.write_string(result.reasons.join(";"))
  }
  builder.to_string()
}

///|
/// Return a strict gate suitable for a production caller.
pub fn strict_quality_gate() -> QualityGateConfig {
  {
    max_mae: 120.0,
    max_rmse: 180.0,
    min_confidence: 0.05,
    min_points: 3,
    require_monotonic_distance: true,
  }
}

///|
/// Return whether a report contains no gate failures.
pub fn quality_gate_passed(result : QualityGateResult) -> Bool {
  result.passed
}
