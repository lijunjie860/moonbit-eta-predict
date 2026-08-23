///|
/// Construct a stable benchmark scenario.
pub fn stable_scenario() -> ScenarioConfig {
  {
    ..default_scenario_config(),
    steps: 18,
    congestion: 0.1,
    noise_magnitude: 0.0,
  }
}

///|
/// Construct a high-variance benchmark scenario.
pub fn noisy_scenario() -> ScenarioConfig {
  {
    ..default_scenario_config(),
    steps: 18,
    congestion: 0.45,
    noise_stride: 3,
    noise_magnitude: 95.0,
  }
}

///|
/// Construct a slow-route benchmark scenario.
pub fn delayed_scenario() -> ScenarioConfig {
  {
    ..default_scenario_config(),
    steps: 14,
    interval_seconds: 90.0,
    base_speed: 6.5,
    congestion: 0.55,
    noise_magnitude: 28.0,
  }
}

///|
/// Construct a severe congestion benchmark scenario.
pub fn congested_scenario() -> ScenarioConfig {
  {
    ..default_scenario_config(),
    steps: 20,
    base_speed: 5.5,
    congestion: 0.9,
    noise_magnitude: 66.0,
  }
}

///|
/// Return named scenarios for external benchmark runners.
pub fn standard_scenarios() -> Array[(String, ScenarioConfig)] {
  [
    ("stable", stable_scenario()),
    ("noisy", noisy_scenario()),
    ("delayed", delayed_scenario()),
    ("congested", congested_scenario()),
  ]
}

///|
/// Return a scenario with a single observation, useful for smoke tests.
pub fn singleton_scenario() -> ScenarioConfig {
  {
    ..default_scenario_config(),
    steps: 1,
    interval_seconds: 1.0,
    noise_magnitude: 0.0,
  }
}

///|
/// Return a scenario that reaches the route end quickly.
pub fn completion_scenario() -> ScenarioConfig {
  {
    ..default_scenario_config(),
    steps: 3,
    interval_seconds: 600.0,
    base_speed: 40.0,
    congestion: 0.0,
    noise_magnitude: 0.0,
  }
}

///|
/// Generate a trace for a named standard scenario.
pub fn named_scenario(name : String) -> ScenarioTrace {
  let config = if name == "stable" {
    stable_scenario()
  } else if name == "noisy" {
    noisy_scenario()
  } else if name == "delayed" {
    delayed_scenario()
  } else if name == "congested" {
    congested_scenario()
  } else {
    default_scenario_config()
  }
  generate_scenario(demo_route(), config)
}

///|
/// Check that a scenario remains within route and time bounds.
pub fn scenario_is_well_formed(
  trace : ScenarioTrace,
  route : RouteProfile,
) -> Bool {
  if trace.observations.length() != trace.actual_remaining.length() {
    false
  } else {
    let mut valid = true
    let distance = route.total_distance()
    let mut previous_time = -1.0
    for observation in trace.observations {
      if observation.timestamp < previous_time ||
        observation.distance < 0.0 ||
        observation.distance > distance {
        valid = false
      }
      previous_time = observation.timestamp
    }
    valid
  }
}

///|
/// Compare benchmark output cardinality for two scenarios.
pub fn scenario_size_delta(left : ScenarioTrace, right : ScenarioTrace) -> Int {
  left.observations.length() - right.observations.length()
}
