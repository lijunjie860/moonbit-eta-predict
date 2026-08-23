///|
fn calibration_score(
  route : RouteProfile,
  dataset : ObservationDataset,
  congestion : Double,
) -> ErrorSummary {
  let batch = forecast_dataset(dataset, route, congestion~)
  batch.summary
}

///|
fn candidate_compare(
  left : CalibrationCandidate,
  right : CalibrationCandidate,
) -> Int {
  let error_order = compare_double(left.error.mae, right.error.mae)
  if error_order == 0 {
    compare_double(left.congestion, right.congestion)
  } else {
    error_order
  }
}

///|
/// Build evenly spaced congestion candidates, including both endpoints.
pub fn congestion_grid(
  minimum~ : Double,
  maximum~ : Double,
  steps~ : Int,
) -> Array[Double] {
  let low = clamp(minimum, 0.0, 1.0)
  let high = clamp(maximum, low, 1.0)
  let count = if steps < 1 { 1 } else { steps }
  let values : Array[Double] = []
  for index in 0..<=count {
    values.push(low + (high - low) * index.to_double() / count.to_double())
  }
  values
}

///|
/// Evaluate a congestion grid over a labeled dataset.
pub fn grid_calibrate(
  route : RouteProfile,
  dataset : ObservationDataset,
  minimum? : Double = 0.0,
  maximum? : Double = 1.0,
  steps? : Int = 10,
) -> GridCalibration {
  let candidates : Array[CalibrationCandidate] = []
  for congestion in congestion_grid(minimum~, maximum~, steps~) {
    candidates.push({
      congestion,
      error: calibration_score(route, dataset, congestion),
      rank: 0,
    })
  }
  candidates.sort_by(candidate_compare)
  for index in 0..<candidates.length() {
    candidates[index] = { ..candidates[index], rank: index + 1 }
  }
  let best = if candidates.length() == 0 {
    { congestion: 0.0, error: summarize_errors([]), rank: 0 }
  } else {
    candidates[0]
  }
  { candidates, best, evaluated: candidates.length() }
}

///|
/// Refine a grid around its current best candidate.
pub fn refine_grid(
  route : RouteProfile,
  dataset : ObservationDataset,
  initial : GridCalibration,
  radius? : Double = 0.1,
  steps? : Int = 8,
) -> GridCalibration {
  let center = initial.best.congestion
  let refined = grid_calibrate(
    route,
    dataset,
    minimum=clamp(center - abs_double(radius), 0.0, 1.0),
    maximum=clamp(center + abs_double(radius), 0.0, 1.0),
    steps~,
  )
  if refined.best.error.mae <= initial.best.error.mae {
    refined
  } else {
    initial
  }
}

///|
/// Return the top k candidates after calibration.
pub fn top_candidates(
  calibration : GridCalibration,
  count : Int,
) -> Array[CalibrationCandidate] {
  let result : Array[CalibrationCandidate] = []
  let limit = if count < 0 {
    0
  } else if count > calibration.candidates.length() {
    calibration.candidates.length()
  } else {
    count
  }
  for index in 0..<limit {
    result.push(calibration.candidates[index])
  }
  result
}

///|
/// Compare candidate calibration against a baseline congestion value.
pub fn calibration_improvement(
  route : RouteProfile,
  dataset : ObservationDataset,
  baseline~ : Double,
  calibration : GridCalibration,
) -> Double {
  let baseline_error = calibration_score(route, dataset, baseline)
  safe_div(
    baseline_error.mae - calibration.best.error.mae,
    baseline_error.mae,
    0.0,
  )
}

///|
/// Create a calibration dataset from the deterministic demo trace.
pub fn demo_calibration_dataset() -> ObservationDataset {
  let trace = noisy_demo_trace()
  dataset_from_targets(
    trace.observations,
    trace.actual_remaining,
    name="demo-calibration",
  )
}

///|
/// Calibrate the deterministic demo route using the reusable grid API.
pub fn grid_calibrate_demo() -> GridCalibration {
  grid_calibrate(demo_route(), demo_calibration_dataset(), steps=12)
}

///|
/// Return calibration candidates in congestion order.
pub fn candidates_by_congestion(
  calibration : GridCalibration,
) -> Array[CalibrationCandidate] {
  let result = calibration.candidates.copy()
  result.sort_by((left, right) => {
    compare_double(left.congestion, right.congestion)
  })
  result
}

///|
/// Return the error curve as forecast points for charting.
pub fn calibration_error_curve(
  calibration : GridCalibration,
) -> Array[ForecastPoint] {
  let curve : Array[ForecastPoint] = []
  for candidate in calibration.candidates {
    curve.push({ predicted: candidate.congestion, actual: candidate.error.mae })
  }
  curve
}
