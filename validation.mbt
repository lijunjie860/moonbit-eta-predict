///|
/// Compare doubles without relying on a total-order implementation.
pub fn compare_double(left : Double, right : Double) -> Int {
  if left < right {
    -1
  } else if left > right {
    1
  } else {
    0
  }
}

///|
/// Report whether a floating-point value is a usable finite input.
pub fn is_finite_value(value : Double) -> Bool {
  value == value && value.abs() < 1.7976931348623157e308
}

///|
fn issue(
  issues : Array[ValidationIssue],
  code : ValidationCode,
  index : Int,
  message : String,
) -> Unit {
  issues.push({ code, index, message })
}

///|
/// Validate observations without changing caller-owned data.
pub fn validate_observations(
  observations : Array[Observation],
) -> ValidationReport {
  let issues : Array[ValidationIssue] = []
  if observations.length() == 0 {
    issue(issues, EmptyInput, 0, "observation input is empty")
  }
  let mut previous_timestamp = -1.0
  let mut previous_distance = -1.0
  for index, observation in observations {
    if !is_finite_value(observation.timestamp) ||
      !is_finite_value(observation.distance) ||
      !is_finite_value(observation.elapsed) {
      issue(
        issues,
        NonFiniteValue,
        index,
        "observation contains a non-finite value",
      )
    }
    if observation.timestamp < 0.0 {
      issue(issues, NegativeTimestamp, index, "timestamp must not be negative")
    }
    if observation.distance < 0.0 {
      issue(issues, NegativeDistance, index, "distance must not be negative")
    }
    if index > 0 && observation.timestamp < previous_timestamp {
      issue(
        issues,
        NonMonotonicTime,
        index,
        "timestamps must be non-decreasing",
      )
    }
    if index > 0 && observation.distance < previous_distance {
      issue(
        issues,
        NonMonotonicDistance,
        index,
        "distance must be non-decreasing",
      )
    }
    previous_timestamp = observation.timestamp
    previous_distance = observation.distance
  }
  { valid: issues.length() == 0, checked: observations.length(), issues }
}

///|
/// Validate a route profile and its segment parameter ranges.
pub fn validate_route(route : RouteProfile) -> ValidationReport {
  let issues : Array[ValidationIssue] = []
  if route.segments.length() == 0 {
    issue(issues, EmptyInput, 0, "route must contain at least one segment")
  }
  for index, segment in route.segments {
    if segment.distance <= 0.0 || !is_finite_value(segment.distance) {
      issue(issues, InvalidRange, index, "segment distance must be positive")
    }
    if segment.free_flow_speed <= 0.0 ||
      segment.typical_speed <= 0.0 ||
      segment.rush_hour_speed <= 0.0 {
      issue(issues, InvalidRange, index, "segment speeds must be positive")
    }
    if segment.reliability < 0.0 || segment.reliability > 1.0 {
      issue(issues, InvalidRange, index, "reliability must be within [0, 1]")
    }
    if segment.segment_id.trim().is_empty() {
      issue(issues, InvalidConfiguration, index, "segment id must not be blank")
    }
  }
  { valid: issues.length() == 0, checked: route.segments.length(), issues }
}

///|
/// Clamp a configuration to safe operational limits.
pub fn sanitize_kalman_config(config : KalmanConfig) -> KalmanConfig {
  {
    process_noise: if config.process_noise < 0.0 {
      0.0
    } else {
      config.process_noise
    },
    measurement_noise: if config.measurement_noise < 0.000001 {
      0.000001
    } else {
      config.measurement_noise
    },
    initial_error: if config.initial_error < 0.000001 {
      0.000001
    } else {
      config.initial_error
    },
    min_variance: if config.min_variance < 0.0000001 {
      0.0000001
    } else {
      config.min_variance
    },
    gate_sigma: if config.gate_sigma < 0.1 {
      0.1
    } else {
      config.gate_sigma
    },
  }
}

///|
/// Clamp a window configuration while preserving its ordering invariants.
pub fn sanitize_window_config(config : WindowConfig) -> WindowConfig {
  let min_size = if config.min_size < 1 { 1 } else { config.min_size }
  let max_size = if config.max_size < min_size {
    min_size
  } else {
    config.max_size
  }
  {
    min_size,
    max_size,
    low_variance: if config.low_variance < 0.0 {
      0.0
    } else {
      config.low_variance
    },
    high_variance: if config.high_variance < config.low_variance {
      config.low_variance
    } else {
      config.high_variance
    },
    expansion_step: if config.expansion_step < 1 {
      1
    } else {
      config.expansion_step
    },
    shrink_step: if config.shrink_step < 1 {
      1
    } else {
      config.shrink_step
    },
  }
}

///|
/// Sort observations and keep the last value for a duplicate timestamp.
pub fn normalize_observations(
  observations : Array[Observation],
) -> Array[Observation] {
  let sorted = observations.copy()
  sorted.sort_by((left, right) => {
    let time_order = compare_double(left.timestamp, right.timestamp)
    if time_order == 0 {
      compare_double(left.elapsed, right.elapsed)
    } else {
      time_order
    }
  })
  let normalized : Array[Observation] = []
  for observation in sorted {
    if normalized.length() > 0 &&
      normalized[normalized.length() - 1].timestamp == observation.timestamp {
      normalized[normalized.length() - 1] = observation
    } else {
      normalized.push(observation)
    }
  }
  normalized
}

///|
/// Build a normalized batch and count rows discarded by basic validity checks.
pub fn build_observation_batch(
  observations : Array[Observation],
  source? : String = "memory",
) -> ObservationBatch {
  let valid : Array[Observation] = []
  let mut dropped = 0
  for observation in observations {
    if is_finite_value(observation.timestamp) &&
      is_finite_value(observation.distance) &&
      is_finite_value(observation.elapsed) &&
      observation.timestamp >= 0.0 &&
      observation.distance >= 0.0 {
      valid.push(observation)
    } else {
      dropped += 1
    }
  }
  { observations: normalize_observations(valid), source, dropped }
}

///|
/// Validate a calendar bucket range.
pub fn validate_calendar_bucket(bucket : CalendarBucket) -> Bool {
  bucket.start_second >= 0.0 &&
  bucket.end_second <= 86400.0 &&
  bucket.end_second > bucket.start_second &&
  bucket.congestion >= 0.0 &&
  bucket.congestion <= 1.0
}

///|
/// Validate a complete ETA configuration.
pub fn validate_eta_config(config : EtaConfig) -> ValidationReport {
  let issues : Array[ValidationIssue] = []
  if config.min_speed <= 0.0 || config.max_speed < config.min_speed {
    issue(issues, InvalidConfiguration, 0, "speed bounds are invalid")
  }
  if config.history_weight < 0.0 || config.live_weight < 0.0 {
    issue(issues, InvalidConfiguration, 0, "weights must be non-negative")
  }
  if config.reliability_floor < 0.0 || config.reliability_floor > 1.0 {
    issue(
      issues,
      InvalidConfiguration,
      0,
      "reliability floor is outside [0, 1]",
    )
  }
  { valid: issues.length() == 0, checked: 1, issues }
}
