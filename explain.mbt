///|
/// Explain the factors used to produce an ETA result.
pub fn explain_eta(
  result : EtaResult,
  route : RouteProfile,
  congestion~ : Double,
  config? : EtaConfig = default_eta_config(),
) -> EtaExplanation {
  let historical_speed = safe_div(
    route.total_distance(),
    route.historical_eta(congestion~),
    config.min_speed,
  )
  let live_weight = config.live_weight * result.confidence
  let history_weight = config.history_weight * (2.0 - result.confidence)
  let factors : Array[String] = []
  if result.confidence < 0.3 {
    factors.push("low confidence increases historical influence")
  }
  if result.raw_speed <= config.min_speed {
    factors.push("raw speed is at the configured floor")
  }
  if congestion > 0.65 {
    factors.push("congestion selects rush-hour profile")
  }
  if result.remaining_distance <= 0.0 {
    factors.push("route has no remaining distance")
  }
  {
    remaining_distance: result.remaining_distance,
    raw_speed: result.raw_speed,
    smoothed_speed: result.smoothed_speed,
    historical_speed,
    live_weight,
    history_weight,
    confidence: result.confidence,
    factors,
  }
}

///|
/// Return a concise explanation suitable for a tooltip.
pub fn format_eta_explanation(explanation : EtaExplanation) -> String {
  let builder = StringBuilder()
  builder.write_string(
    "remaining={explanation.remaining_distance} raw={explanation.raw_speed} smooth={explanation.smoothed_speed} history={explanation.historical_speed} confidence={explanation.confidence}\n",
  )
  for factor in explanation.factors {
    builder.write_string("- ")
    builder.write_string(factor)
    builder.write_char('\n')
  }
  builder.to_string()
}

///|
/// Explain every result in a batch.
pub fn explain_batch(
  batch : BatchForecast,
  route : RouteProfile,
  congestion~ : Double,
) -> Array[EtaExplanation] {
  let explanations : Array[EtaExplanation] = []
  for result in batch.results {
    explanations.push(explain_eta(result, route, congestion~))
  }
  explanations
}

///|
/// Return the dominant explanation factor, if any.
pub fn dominant_eta_factor(explanation : EtaExplanation) -> String? {
  if explanation.factors.length() == 0 {
    None
  } else {
    Some(explanation.factors[0])
  }
}

///|
/// Explain how a result differs from a historical-only baseline.
pub fn baseline_delta(
  result : EtaResult,
  route : RouteProfile,
  congestion~ : Double,
) -> Double {
  let baseline = safe_div(
    result.remaining_distance,
    safe_div(route.total_distance(), route.historical_eta(congestion~), 0.5),
    0.0,
  )
  result.eta_seconds - baseline
}
