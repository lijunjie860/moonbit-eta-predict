///|
/// Forecast each route segment from a single live speed and congestion value.
pub fn forecast_breakdown(
  route : RouteProfile,
  speed~ : Double,
  congestion~ : Double,
  policy? : SpeedPolicy = default_speed_policy(),
) -> RouteBreakdown {
  let segments : Array[SegmentEta] = []
  let mut total_distance = 0.0
  let mut total_eta = 0.0
  let mut confidence_total = 0.0
  for segment in route.segments {
    let local_speed = predict_segment_speed(segment, speed, congestion, policy~)
    let confidence = speed_confidence(
      segment,
      if speed <= 0.0 {
        local_speed
      } else {
        speed
      },
      local_speed,
    )
    let eta_seconds = safe_div(segment.distance, local_speed, 0.0)
    segments.push({
      segment_id: segment.segment_id,
      distance: segment.distance,
      speed: local_speed,
      eta_seconds,
      confidence,
    })
    total_distance += segment.distance
    total_eta += eta_seconds
    confidence_total += confidence * segment.distance
  }
  {
    segments,
    total_distance,
    total_eta_seconds: total_eta,
    confidence: safe_div(confidence_total, total_distance, 0.0),
  }
}

///|
/// Sum segment ETA values without recomputing speeds.
pub fn sum_segment_eta(segments : Array[SegmentEta]) -> Double {
  let mut total = 0.0
  for segment in segments {
    total += segment.eta_seconds
  }
  total
}

///|
/// Forecast a route using a weekly calendar context.
pub fn forecast_breakdown_at(
  route : RouteProfile,
  speed~ : Double,
  calendar : RouteCalendar,
  weekday~ : Int,
  second_of_day~ : Double,
  policy? : SpeedPolicy = default_speed_policy(),
) -> DetailedBreakdown {
  let congestion = calendar.congestion_at(weekday, second_of_day)
  let total = forecast_breakdown(route, speed~, congestion~, policy~)
  let forecasts : Array[SegmentForecast] = []
  for index, segment in route.segments {
    let eta = total.segments[index]
    forecasts.push({
      index,
      segment,
      eta,
      regime: regime_for_congestion(congestion),
      congestion,
    })
  }
  { forecasts, total, weekday: normalize_weekday(weekday), second_of_day }
}

///|
/// Return segment ETAs as a cumulative timeline.
pub fn cumulative_segment_eta(segments : Array[SegmentEta]) -> Array[Double] {
  let result : Array[Double] = []
  let mut total = 0.0
  for segment in segments {
    total += segment.eta_seconds
    result.push(total)
  }
  result
}

///|
/// Return the slowest segment by ETA, if the route is non-empty.
pub fn bottleneck_segment(segments : Array[SegmentEta]) -> SegmentEta? {
  if segments.length() == 0 {
    None
  } else {
    let mut best = segments[0]
    for segment in segments[1:] {
      if segment.eta_seconds > best.eta_seconds {
        best = segment
      }
    }
    Some(best)
  }
}

///|
/// Scale a breakdown to a new remaining-distance fraction.
pub fn scale_breakdown(
  breakdown : RouteBreakdown,
  remaining_fraction~ : Double,
) -> RouteBreakdown {
  let fraction = clamp(remaining_fraction, 0.0, 1.0)
  let segments : Array[SegmentEta] = []
  for segment in breakdown.segments {
    segments.push({
      ..segment,
      distance: segment.distance * fraction,
      eta_seconds: segment.eta_seconds * fraction,
    })
  }
  {
    ..breakdown,
    segments,
    total_distance: breakdown.total_distance * fraction,
    total_eta_seconds: breakdown.total_eta_seconds * fraction,
  }
}
