///|
/// Forecast an observation array and score it against the route's historical baseline.
pub fn forecast_batch(
  observations : Array[Observation],
  route : RouteProfile,
  congestion~ : Double,
) -> BatchForecast {
  let results = forecast_route(observations, route)
  let points : Array[ForecastPoint] = []
  let historical_eta = route.historical_eta(congestion~)
  let route_distance = route.total_distance()
  for result in results {
    let baseline = safe_div(
      result.remaining_distance * historical_eta,
      route_distance,
      result.eta_seconds,
    )
    points.push({ predicted: result.eta_seconds, actual: baseline })
  }
  { results, points, summary: summarize_errors(points), skipped: 0 }
}

///|
/// Forecast only the rows with valid observations and retain skipped count.
pub fn forecast_dataset(
  dataset : ObservationDataset,
  route : RouteProfile,
  congestion~ : Double,
) -> BatchForecast {
  let observations : Array[Observation] = []
  let actuals : Array[Double] = []
  let mut skipped = 0
  for row in dataset.rows {
    if row.observation.timestamp < 0.0 || row.observation.distance < 0.0 {
      skipped += 1
    } else {
      observations.push(row.observation)
      match row.actual_remaining {
        Some(value) => actuals.push(value)
        None => actuals.push(0.0)
      }
    }
  }
  let results = forecast_route(observations, route)
  let points : Array[ForecastPoint] = []
  let historical_eta = route.historical_eta(congestion~)
  let route_distance = route.total_distance()
  for index, result in results {
    let actual = if index < actuals.length() && actuals[index] > 0.0 {
      actuals[index]
    } else {
      safe_div(
        result.remaining_distance * historical_eta,
        route_distance,
        result.eta_seconds,
      )
    }
    points.push({ predicted: result.eta_seconds, actual })
  }
  { results, points, summary: summarize_errors(points), skipped }
}

///|
/// Forecast multiple routes with one shared observation trace.
pub fn forecast_many(
  observations : Array[Observation],
  routes : Array[RouteProfile],
  congestion~ : Double,
) -> Array[BatchForecast] {
  let reports : Array[BatchForecast] = []
  for route in routes {
    reports.push(forecast_batch(observations, route, congestion~))
  }
  reports
}

///|
/// Return ETA values from a batch result.
pub fn batch_eta_values(batch : BatchForecast) -> Array[Double] {
  let values : Array[Double] = []
  for result in batch.results {
    values.push(result.eta_seconds)
  }
  values
}

///|
/// Return confidence values from a batch result.
pub fn batch_confidences(batch : BatchForecast) -> Array[Double] {
  let values : Array[Double] = []
  for result in batch.results {
    values.push(result.confidence)
  }
  values
}

///|
/// Re-score a batch against a caller-supplied actual target array.
pub fn rescore_batch(
  batch : BatchForecast,
  actuals : Array[Double],
) -> BatchForecast {
  let points = eta_results_to_points(batch.results, actuals)
  { ..batch, points, summary: summarize_errors(points) }
}

///|
/// Return the first and last ETA values as a compact trend summary.
pub fn eta_trend(batch : BatchForecast) -> (Double, Double, Double) {
  if batch.results.length() == 0 {
    (0.0, 0.0, 0.0)
  } else {
    let first = batch.results[0].eta_seconds
    let last = batch.results[batch.results.length() - 1].eta_seconds
    (first, last, last - first)
  }
}

///|
/// Apply a conservative confidence floor to a result batch.
pub fn apply_confidence_floor(
  batch : BatchForecast,
  floor~ : Double,
) -> BatchForecast {
  let safe_floor = clamp(floor, 0.0, 1.0)
  let results : Array[EtaResult] = []
  for result in batch.results {
    results.push({
      ..result,
      confidence: if result.confidence < safe_floor {
        safe_floor
      } else {
        result.confidence
      },
    })
  }
  { ..batch, results, }
}

///|
/// Partition results by whether their confidence meets a threshold.
pub fn split_by_confidence(
  results : Array[EtaResult],
  threshold~ : Double,
) -> (Array[EtaResult], Array[EtaResult]) {
  let accepted : Array[EtaResult] = []
  let rejected : Array[EtaResult] = []
  for result in results {
    if result.confidence >= threshold {
      accepted.push(result)
    } else {
      rejected.push(result)
    }
  }
  (accepted, rejected)
}
