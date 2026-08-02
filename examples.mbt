///|
pub fn demo_observations() -> Array[Observation] {
  [
    { timestamp: 0.0, distance: 0.0, elapsed: 0.0 },
    { timestamp: 60.0, distance: 620.0, elapsed: 60.0 },
    { timestamp: 120.0, distance: 1190.0, elapsed: 120.0 },
    { timestamp: 180.0, distance: 1690.0, elapsed: 180.0 },
    { timestamp: 240.0, distance: 2180.0, elapsed: 240.0 },
    { timestamp: 300.0, distance: 2760.0, elapsed: 300.0 },
    { timestamp: 360.0, distance: 3290.0, elapsed: 360.0 },
    { timestamp: 420.0, distance: 3810.0, elapsed: 420.0 },
    { timestamp: 480.0, distance: 4330.0, elapsed: 480.0 },
  ]
}

///|
pub fn run_demo() -> Array[EtaResult] {
  forecast_route(demo_observations(), demo_route())
}
