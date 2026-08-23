///|
/// Conservative input guard defaults for embedded applications.
pub fn default_input_guard(route : RouteProfile) -> InputGuardConfig {
  {
    maximum_distance: route.total_distance() * 1.05,
    maximum_timestamp: 7.776e6,
    reject_backwards_time: true,
    reject_backwards_distance: true,
  }
}

///|
/// Return a guard with non-negative finite limits.
pub fn sanitize_input_guard(config : InputGuardConfig) -> InputGuardConfig {
  {
    maximum_distance: if !is_finite_value(config.maximum_distance) ||
      config.maximum_distance < 0.0 {
      0.0
    } else {
      config.maximum_distance
    },
    maximum_timestamp: if !is_finite_value(config.maximum_timestamp) ||
      config.maximum_timestamp < 0.0 {
      0.0
    } else {
      config.maximum_timestamp
    },
    reject_backwards_time: config.reject_backwards_time,
    reject_backwards_distance: config.reject_backwards_distance,
  }
}

///|
/// Guard one observation against finite, range, and monotonicity constraints.
pub fn guard_observation(
  previous : Observation?,
  observation : Observation,
  config : InputGuardConfig,
) -> GuardResult {
  let safe = sanitize_input_guard(config)
  let reasons : Array[String] = []
  if !is_finite_value(observation.timestamp) {
    reasons.push("timestamp is not finite")
  }
  if !is_finite_value(observation.distance) {
    reasons.push("distance is not finite")
  }
  if !is_finite_value(observation.elapsed) {
    reasons.push("elapsed is not finite")
  }
  if observation.timestamp < 0.0 {
    reasons.push("timestamp is negative")
  }
  if observation.distance < 0.0 {
    reasons.push("distance is negative")
  }
  if observation.timestamp > safe.maximum_timestamp {
    reasons.push("timestamp exceeds configured bound")
  }
  if observation.distance > safe.maximum_distance {
    reasons.push("distance exceeds configured bound")
  }
  match previous {
    None => ()
    Some(last) => {
      if safe.reject_backwards_time && observation.timestamp < last.timestamp {
        reasons.push("timestamp moves backwards")
      }
      if safe.reject_backwards_distance && observation.distance < last.distance {
        reasons.push("distance moves backwards")
      }
    }
  }
  { accepted: reasons.length() == 0, observation, reasons }
}

///|
/// Clamp a valid observation to a route distance ceiling.
pub fn clamp_observation_distance(
  observation : Observation,
  maximum_distance : Double,
) -> Observation {
  {
    ..observation,
    distance: clamp(observation.distance, 0.0, maximum_distance),
  }
}

///|
/// Filter a trace through an input guard while retaining reason counts.
pub fn guard_trace(
  observations : Array[Observation],
  config : InputGuardConfig,
) -> (Array[Observation], Array[String]) {
  let accepted : Array[Observation] = []
  let reasons : Array[String] = []
  let mut previous : Observation? = None
  for observation in observations {
    let result = guard_observation(previous, observation, config)
    if result.accepted {
      accepted.push(observation)
      previous = Some(observation)
    } else {
      for reason in result.reasons {
        reasons.push(reason)
      }
    }
  }
  (accepted, reasons)
}

///|
/// Check that an ETA result respects its public numeric contract.
pub fn check_eta_result(result : EtaResult) -> Bool {
  result.eta_seconds >= 0.0 &&
  result.remaining_distance >= 0.0 &&
  result.smoothed_speed >= 0.0 &&
  result.raw_speed >= 0.0 &&
  result.confidence >= 0.0 &&
  result.confidence <= 1.0 &&
  is_finite_value(result.eta_seconds) &&
  is_finite_value(result.smidence())
}

///|
/// Keep the result contract check independent of optional host integrations.
fn EtaResult::smidence(self : EtaResult) -> Double {
  self.confidence
}

///|
/// Check a whole forecast output for finite and bounded values.
pub fn check_eta_results(results : Array[EtaResult]) -> ContractReport {
  let failures : Array[String] = []
  for index, result in results {
    if !check_eta_result(result) {
      failures.push("result \{index} violates ETA contract")
    }
  }
  { valid: failures.length() == 0, checks: results.length(), failures }
}

///|
/// Check that remaining distance never increases over a result trace.
pub fn check_remaining_distance(results : Array[EtaResult]) -> Bool {
  let mut previous = 1.7976931348623157e308
  let mut valid = true
  for result in results {
    if result.remaining_distance > previous {
      valid = false
    }
    previous = result.remaining_distance
  }
  valid
}

///|
/// Run the standard route forecast contract checks.
pub fn forecast_contract(
  observations : Array[Observation],
  results : Array[EtaResult],
) -> ContractReport {
  let failures : Array[String] = []
  let input_report = validate_observations(observations)
  if input_report.issues.length() > 0 {
    failures.push("input validation failed")
  }
  if !check_remaining_distance(results) {
    failures.push("remaining distance increased")
  }
  let result_report = check_eta_results(results)
  for failure in result_report.failures {
    failures.push(failure)
  }
  {
    valid: failures.length() == 0,
    checks: observations.length() + results.length(),
    failures,
  }
}

///|
/// Render contract failures for an embedding log.
pub fn format_contract(report : ContractReport) -> String {
  let builder = StringBuilder()
  builder.write_string(
    "valid={report.valid} checks={report.checks} failures={report.failures.length()}\n",
  )
  for failure in report.failures {
    builder.write_string(failure)
    builder.write_char('\n')
  }
  builder.to_string()
}

///|
/// Return whether all rows in a dataset can enter the engine.
pub fn dataset_is_guarded(
  dataset : ObservationDataset,
  config : InputGuardConfig,
) -> Bool {
  let (_, reasons) = guard_trace(dataset.observations(), config)
  reasons.length() == 0
}
