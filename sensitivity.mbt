///|
fn sensitivity_point(
  route : RouteProfile,
  congestion : Double,
  baseline_eta : Double,
  input : Double,
) -> SensitivityPoint {
  let breakdown = forecast_breakdown(route, speed=input, congestion~)
  {
    input,
    eta_seconds: breakdown.total_eta_seconds,
    speed: safe_div(route.total_distance(), breakdown.total_eta_seconds, 0.0),
    confidence: breakdown.confidence,
    delta_from_baseline: breakdown.total_eta_seconds - baseline_eta,
  }
}

///|
fn monotonic_eta(points : Array[SensitivityPoint]) -> Bool {
  if points.length() <= 1 {
    true
  } else {
    let mut valid = true
    let mut previous = points[0].eta_seconds
    for point in points[1:] {
      if point.eta_seconds > previous {
        valid = false
      }
      previous = point.eta_seconds
    }
    valid
  }
}

///|
/// Evaluate ETA sensitivity to live speed.
pub fn speed_sensitivity(
  route : RouteProfile,
  congestion~ : Double,
  baseline_speed? : Double = 8.0,
  minimum_speed? : Double = 2.0,
  maximum_speed? : Double = 20.0,
  steps? : Int = 8,
) -> SensitivityReport {
  let baseline = forecast_breakdown(route, speed=baseline_speed, congestion~)
  let values : Array[SensitivityPoint] = []
  let count = if steps < 1 { 1 } else { steps }
  for index in 0..<=count {
    let input = minimum_speed +
      (maximum_speed - minimum_speed) * index.to_double() / count.to_double()
    values.push(
      sensitivity_point(route, congestion, baseline.total_eta_seconds, input),
    )
  }
  let slope = safe_div(
    values[values.length() - 1].eta_seconds - values[0].eta_seconds,
    values[values.length() - 1].input - values[0].input,
    0.0,
  )
  {
    parameter: "live_speed",
    baseline: sensitivity_point(
      route,
      congestion,
      baseline.total_eta_seconds,
      baseline_speed,
    ),
    points: values,
    monotonic: monotonic_eta(values),
    elasticity: slope,
  }
}

///|
/// Evaluate ETA sensitivity to congestion.
pub fn congestion_sensitivity(
  route : RouteProfile,
  speed? : Double = 8.0,
  steps? : Int = 10,
) -> SensitivityReport {
  let baseline = forecast_breakdown(route, speed~, congestion=0.3)
  let values : Array[SensitivityPoint] = []
  let count = if steps < 1 { 1 } else { steps }
  for index in 0..<=count {
    let input = index.to_double() / count.to_double()
    let breakdown = forecast_breakdown(route, speed~, congestion=input)
    values.push({
      input,
      eta_seconds: breakdown.total_eta_seconds,
      speed: safe_div(route.total_distance(), breakdown.total_eta_seconds, 0.0),
      confidence: breakdown.confidence,
      delta_from_baseline: breakdown.total_eta_seconds -
      baseline.total_eta_seconds,
    })
  }
  let slope = safe_div(
    values[values.length() - 1].eta_seconds - values[0].eta_seconds,
    values[values.length() - 1].input - values[0].input,
    0.0,
  )
  {
    parameter: "congestion",
    baseline: {
      input: 0.3,
      eta_seconds: baseline.total_eta_seconds,
      speed: safe_div(route.total_distance(), baseline.total_eta_seconds, 0.0),
      confidence: baseline.confidence,
      delta_from_baseline: 0.0,
    },
    points: values,
    monotonic: values.length() <= 1 || !monotonic_eta(values),
    elasticity: slope,
  }
}

///|
/// Return the largest absolute ETA change in a sensitivity report.
pub fn maximum_sensitivity_delta(report : SensitivityReport) -> Double {
  let values : Array[Double] = []
  for point in report.points {
    values.push(abs_double(point.delta_from_baseline))
  }
  if values.length() == 0 {
    0.0
  } else {
    quantile(values, probability=1.0)
  }
}

///|
/// Return the point closest to a requested input.
pub fn nearest_sensitivity_point(
  report : SensitivityReport,
  input : Double,
) -> SensitivityPoint? {
  if report.points.length() == 0 {
    None
  } else {
    let mut best = report.points[0]
    let mut distance = abs_double(best.input - input)
    for point in report.points[1:] {
      let next_distance = abs_double(point.input - input)
      if next_distance < distance {
        best = point
        distance = next_distance
      }
    }
    Some(best)
  }
}

///|
/// Render a sensitivity curve for chart ingestion.
pub fn format_sensitivity(report : SensitivityReport) -> String {
  let builder = StringBuilder()
  builder.write_string(
    "parameter=\{report.parameter} monotonic=\{report.monotonic} elasticity=\{report.elasticity}\n",
  )
  for point in report.points {
    builder.write_string(
      "\{point.input},\{point.eta_seconds},\{point.speed},\{point.confidence}\n",
    )
  }
  builder.to_string()
}
