///|
test "kalman smooths abrupt measurement noise" {
  let cfg = default_kalman_config()
  let values = [10.0, 10.5, 42.0, 10.8, 11.0]
  let smoothed = smooth_values(values, initial=10.0, config=cfg)
  assert_true(smoothed[2] < 25.0)
  assert_true(smoothed[4] < 15.0)
}

///|
test "adaptive window expands under stable samples" {
  let mut window = WindowState::new(default_window_config())
  for value in [8.0, 8.1, 8.0, 8.2, 8.1, 8.0, 8.1] {
    window = window.push(value)
  }
  assert_true(window.target_size > default_window_config().min_size)
  assert_true(window.stability() > 0.8)
}

///|
test "route profile produces plausible historical eta" {
  let route = demo_route()
  assert_true(route.total_distance() > 5000.0)
  let quiet = route.historical_eta(congestion=0.1)
  let rush = route.historical_eta(congestion=0.9)
  assert_true(rush > quiet)
}

///|
test "eta engine emits decreasing remaining distance" {
  let results = run_demo()
  assert_true(results.length() > 4)
  assert_true(
    results[0].remaining_distance >
    results[results.length() - 1].remaining_distance,
  )
  assert_true(results[results.length() - 1].eta_seconds > 0.0)
}

///|
test "metrics summarize forecast errors" {
  let summary = summarize_errors([
    { predicted: 10.0, actual: 12.0 },
    { predicted: 20.0, actual: 18.0 },
    { predicted: 30.0, actual: 33.0 },
  ])
  assert_eq(summary.count, 3)
  assert_true(summary.mae > 2.0)
  assert_true(summary.max_error == 3.0)
}
