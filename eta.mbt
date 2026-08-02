///|
pub(all) struct EtaEngine {
  kalman : KalmanState
  window : WindowState
  route : RouteProfile
  config : EtaConfig
  last_observation : Observation?
} derive(Debug, Eq)

///|
pub fn EtaEngine::new(
  route : RouteProfile,
  initial_speed~ : Double,
  config? : EtaConfig = default_eta_config(),
) -> EtaEngine {
  {
    kalman: KalmanState::new(initial_speed, default_kalman_config()),
    window: WindowState::new(default_window_config()),
    route,
    config,
    last_observation: None,
  }
}

///|
fn blend_speed(
  live : Double,
  historical : Double,
  config : EtaConfig,
  reliability : Double,
) -> Double {
  let r = clamp(reliability, config.reliability_floor, 1.0)
  let live_weight = config.live_weight * r
  let history_weight = config.history_weight * (2.0 - r)
  let total = live_weight + history_weight
  clamp(
    (live * live_weight + historical * history_weight) / total,
    config.min_speed,
    config.max_speed,
  )
}

///|
pub fn EtaEngine::observe(
  self : EtaEngine,
  observation : Observation,
  congestion? : Double = 0.3,
) -> (EtaEngine, EtaResult) {
  let route_distance = self.route.total_distance()
  let remaining = clamp(
    route_distance - observation.distance,
    0.0,
    route_distance,
  )
  let historical_eta = self.route.historical_eta(congestion~)
  let historical_speed = safe_div(
    route_distance,
    historical_eta,
    self.config.min_speed,
  )
  let (raw_speed, raw_confidence) = match self.last_observation {
    None => (historical_speed, self.route.average_reliability())
    Some(prev) => {
      let sample = velocity_from_observation(prev, observation)
      (sample.speed, sample.confidence)
    }
  }
  let bounded_raw = clamp(
    raw_speed,
    self.config.min_speed,
    self.config.max_speed,
  )
  let kalman = self.kalman.update(bounded_raw)
  let window = self.window.push(kalman.estimate)
  let live_speed = window.average()
  let reliability = self.route.average_reliability() *
    window.stability() *
    clamp(raw_confidence, 0.0, 1.0)
  let smoothed_speed = blend_speed(
    live_speed,
    historical_speed,
    self.config,
    reliability,
  )
  let eta_seconds = safe_div(remaining, smoothed_speed, 0.0)
  let confidence = clamp(reliability, 0.0, 1.0)
  (
    { ..self, kalman, window, last_observation: Some(observation) },
    {
      eta_seconds,
      smoothed_speed,
      raw_speed: bounded_raw,
      confidence,
      remaining_distance: remaining,
    },
  )
}

///|
pub fn forecast_route(
  observations : Array[Observation],
  route : RouteProfile,
) -> Array[EtaResult] {
  let out : Array[EtaResult] = []
  let mut engine = EtaEngine::new(route, initial_speed=8.0)
  for obs in observations {
    let (next, result) = engine.observe(obs)
    engine = next
    out.push(result)
  }
  out
}
