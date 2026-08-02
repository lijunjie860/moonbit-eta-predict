///|
pub fn summarize_errors(points : Array[ForecastPoint]) -> ErrorSummary {
  if points.length() == 0 {
    { count: 0, mae: 0.0, rmse: 0.0, mape: 0.0, max_error: 0.0 }
  } else {
    let mut abs_total = 0.0
    let mut squared_total = 0.0
    let mut percentage_total = 0.0
    let mut max_error = 0.0
    for point in points {
      let error = abs_double(point.predicted - point.actual)
      abs_total += error
      squared_total += square(error)
      percentage_total += safe_div(error, point.actual, 0.0)
      if error > max_error {
        max_error = error
      }
    }
    let n = points.length().to_double()
    {
      count: points.length(),
      mae: abs_total / n,
      rmse: (squared_total / n).sqrt(),
      mape: percentage_total / n,
      max_error,
    }
  }
}

///|
pub fn eta_results_to_points(
  results : Array[EtaResult],
  actuals : Array[Double],
) -> Array[ForecastPoint] {
  let points : Array[ForecastPoint] = []
  let limit = if results.length() < actuals.length() {
    results.length()
  } else {
    actuals.length()
  }
  for i in 0..<limit {
    points.push({ predicted: results[i].eta_seconds, actual: actuals[i] })
  }
  points
}
