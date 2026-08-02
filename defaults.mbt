///|
pub fn default_kalman_config() -> KalmanConfig {
  {
    process_noise: 0.35,
    measurement_noise: 4.0,
    initial_error: 16.0,
    min_variance: 0.000001,
    gate_sigma: 3.0,
  }
}

///|
pub fn default_window_config() -> WindowConfig {
  {
    min_size: 4,
    max_size: 24,
    low_variance: 0.8,
    high_variance: 9.0,
    expansion_step: 2,
    shrink_step: 3,
  }
}

///|
pub fn default_eta_config() -> EtaConfig {
  {
    min_speed: 0.5,
    max_speed: 55.0,
    history_weight: 0.45,
    live_weight: 0.55,
    reliability_floor: 0.15,
  }
}

///|
pub fn clamp(value : Double, low : Double, high : Double) -> Double {
  if value < low {
    low
  } else if value > high {
    high
  } else {
    value
  }
}

///|
pub fn abs_double(value : Double) -> Double {
  if value < 0.0 {
    0.0 - value
  } else {
    value
  }
}

///|
pub fn square(value : Double) -> Double {
  value * value
}

///|
pub fn safe_div(
  numerator : Double,
  denominator : Double,
  fallback : Double,
) -> Double {
  if abs_double(denominator) <= 0.0000001 {
    fallback
  } else {
    numerator / denominator
  }
}
