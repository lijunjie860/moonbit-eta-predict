///|
/// Return whether a breakdown's totals match its segment contributions.
pub fn breakdown_is_consistent(breakdown : RouteBreakdown) -> Bool {
  let summed_distance = breakdown.segments.fold(init=0.0, (total, segment) => {
    total + segment.distance
  })
  let summed_eta = sum_segment_eta(breakdown.segments)
  abs_double(summed_distance - breakdown.total_distance) < 0.000001 &&
  abs_double(summed_eta - breakdown.total_eta_seconds) < 0.000001 &&
  breakdown.confidence >= 0.0 &&
  breakdown.confidence <= 1.0
}

///|
/// Check a detailed breakdown including segment IDs and ordering.
pub fn detailed_breakdown_is_consistent(detailed : DetailedBreakdown) -> Bool {
  if !breakdown_is_consistent(detailed.total) ||
    detailed.forecasts.length() != detailed.total.segments.length() {
    false
  } else {
    let mut valid = true
    for index, forecast in detailed.forecasts {
      if forecast.index != index ||
        forecast.eta.segment_id != forecast.segment.segment_id ||
        !validate_calendar_bucket({
          start_second: 0.0,
          end_second: 1.0,
          congestion: forecast.congestion,
          label: "check",
        }) {
        valid = false
      }
    }
    valid
  }
}

///|
/// Return a bounded remaining distance for a route observation.
pub fn route_remaining_distance(
  route : RouteProfile,
  observation : Observation,
) -> Double {
  clamp(
    route.total_distance() - observation.distance,
    0.0,
    route.total_distance(),
  )
}

///|
/// Return whether ETA results have finite non-negative fields.
pub fn results_are_finite(results : Array[EtaResult]) -> Bool {
  results.all(result => check_eta_result(result))
}

///|
/// Return a normalized route progress fraction.
pub fn route_progress(route : RouteProfile, distance : Double) -> Double {
  safe_div(
    clamp(distance, 0.0, route.total_distance()),
    route.total_distance(),
    0.0,
  )
}

///|
/// Return progress values for a trace.
pub fn trace_progress(
  route : RouteProfile,
  observations : Array[Observation],
) -> Array[Double] {
  let values : Array[Double] = []
  for observation in observations {
    values.push(route_progress(route, observation.distance))
  }
  values
}

///|
/// Return the first index at which route completion is reached.
pub fn completion_index(
  route : RouteProfile,
  observations : Array[Observation],
) -> Int? {
  let distance = route.total_distance()
  for index, observation in observations {
    if observation.distance >= distance {
      return Some(index)
    }
  }
  None
}

///|
/// Return a route's total length after removing invalid negative segments.
pub fn safe_route_distance(route : RouteProfile) -> Double {
  let mut total = 0.0
  for segment in route.segments {
    if segment.distance > 0.0 && is_finite_value(segment.distance) {
      total += segment.distance
    }
  }
  total
}

///|
/// Return route segments whose reliability meets a floor.
pub fn reliable_segments(
  route : RouteProfile,
  floor? : Double = 0.5,
) -> Array[SegmentProfile] {
  let result : Array[SegmentProfile] = []
  let threshold = clamp(floor, 0.0, 1.0)
  for segment in route.segments {
    if segment.reliability >= threshold {
      result.push(segment)
    }
  }
  result
}

///|
/// Return the fraction of a route covered by reliable segments.
pub fn reliable_distance_fraction(
  route : RouteProfile,
  floor? : Double = 0.5,
) -> Double {
  let reliable = reliable_segments(route, floor~)
  let distance = reliable.fold(init=0.0, (total, segment) => {
    total + segment.distance
  })
  safe_div(distance, route.total_distance(), 0.0)
}
