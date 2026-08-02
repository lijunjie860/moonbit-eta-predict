///|
pub fn KalmanState::new(initial : Double, config : KalmanConfig) -> KalmanState {
  {
    estimate: initial,
    covariance: config.initial_error,
    process_noise: config.process_noise,
    measurement_noise: config.measurement_noise,
    min_variance: config.min_variance,
    gate_sigma: config.gate_sigma,
  }
}

///|
pub fn KalmanState::predict(
  self : KalmanState,
  delta_seconds? : Double = 1.0,
) -> KalmanState {
  let dt = if delta_seconds < 0.0 { 0.0 } else { delta_seconds }
  { ..self, covariance: self.covariance + self.process_noise * (1.0 + dt) }
}

///|
pub fn KalmanState::innovation(
  self : KalmanState,
  measurement : Double,
) -> Double {
  measurement - self.estimate
}

///|
pub fn KalmanState::is_outlier(
  self : KalmanState,
  measurement : Double,
) -> Bool {
  let spread = self.covariance + self.measurement_noise
  abs_double(self.innovation(measurement)) > self.gate_sigma * spread
}

///|
pub fn KalmanState::update(
  self : KalmanState,
  measurement : Double,
) -> KalmanState {
  let predicted = self.predict()
  if predicted.is_outlier(measurement) {
    { ..predicted, covariance: predicted.covariance + predicted.process_noise }
  } else {
    let gain = predicted.covariance /
      (predicted.covariance + predicted.measurement_noise)
    let estimate = predicted.estimate +
      gain * (measurement - predicted.estimate)
    let covariance = (1.0 - gain) * predicted.covariance
    {
      ..predicted,
      estimate,
      covariance: clamp(covariance, predicted.min_variance, covariance),
    }
  }
}

///|
pub fn smooth_values(
  values : Array[Double],
  initial~ : Double,
  config~ : KalmanConfig,
) -> Array[Double] {
  let out : Array[Double] = []
  let mut state = KalmanState::new(initial, config)
  for value in values {
    state = state.update(value)
    out.push(state.estimate)
  }
  out
}

///|
pub fn velocity_from_observation(
  prev : Observation,
  next : Observation,
) -> VelocitySample {
  let dt = next.timestamp - prev.timestamp
  let distance_delta = next.distance - prev.distance
  let elapsed_delta = next.elapsed - prev.elapsed
  let speed = if dt <= 0.0 { 0.0 } else { distance_delta / dt }
  let confidence = if elapsed_delta < 0.0 || speed <= 0.0 {
    0.0
  } else {
    clamp(dt / (dt + abs_double(elapsed_delta - dt)), 0.0, 1.0)
  }
  { timestamp: next.timestamp, speed, confidence }
}
