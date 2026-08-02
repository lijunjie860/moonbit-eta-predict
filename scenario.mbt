///|
pub fn default_scenario_config() -> ScenarioConfig {
  {
    steps: 12,
    interval_seconds: 45.0,
    base_speed: 10.0,
    congestion: 0.35,
    noise_stride: 4,
    noise_magnitude: 65.0,
  }
}

///|
fn scenario_speed(config : ScenarioConfig, index : Int) -> Double {
  let wave = if index % 3 == 0 {
    0.92
  } else if index % 3 == 1 {
    1.08
  } else {
    1.0
  }
  let congestion_factor = 1.0 - clamp(config.congestion, 0.0, 0.9) * 0.55
  clamp(config.base_speed * wave * congestion_factor, 0.5, 60.0)
}

///|
fn scenario_noise(config : ScenarioConfig, index : Int) -> Double {
  if config.noise_stride <= 0 {
    0.0
  } else if index % config.noise_stride == 0 {
    config.noise_magnitude
  } else if index % config.noise_stride == config.noise_stride - 1 {
    0.0 - config.noise_magnitude * 0.45
  } else {
    0.0
  }
}

///|
pub fn generate_scenario(
  route : RouteProfile,
  config : ScenarioConfig,
) -> ScenarioTrace {
  let observations : Array[Observation] = []
  let actual_remaining : Array[Double] = []
  let route_distance = route.total_distance()
  let mut distance = 0.0
  let mut elapsed = 0.0
  for i in 0..<config.steps {
    let speed = scenario_speed(config, i)
    elapsed += config.interval_seconds
    distance = clamp(
      distance + speed * config.interval_seconds + scenario_noise(config, i),
      0.0,
      route_distance,
    )
    observations.push({ timestamp: elapsed, distance, elapsed })
    actual_remaining.push(safe_div(route_distance - distance, speed, 0.0))
  }
  { observations, actual_remaining }
}

///|
pub fn noisy_demo_trace() -> ScenarioTrace {
  generate_scenario(demo_route(), default_scenario_config())
}
