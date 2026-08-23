///|
/// Default speed policy for combining route profile evidence.
pub fn default_speed_policy() -> SpeedPolicy {
  {
    free_flow_weight: 0.15,
    typical_weight: 0.25,
    rush_hour_weight: 0.15,
    live_weight: 0.45,
    minimum_speed: 0.5,
    maximum_speed: 60.0,
  }
}

///|
/// Return a policy with bounded non-negative weights.
pub fn sanitize_speed_policy(policy : SpeedPolicy) -> SpeedPolicy {
  {
    free_flow_weight: if policy.free_flow_weight < 0.0 {
      0.0
    } else {
      policy.free_flow_weight
    },
    typical_weight: if policy.typical_weight < 0.0 {
      0.0
    } else {
      policy.typical_weight
    },
    rush_hour_weight: if policy.rush_hour_weight < 0.0 {
      0.0
    } else {
      policy.rush_hour_weight
    },
    live_weight: if policy.live_weight < 0.0 {
      0.0
    } else {
      policy.live_weight
    },
    minimum_speed: if policy.minimum_speed <= 0.0 {
      0.1
    } else {
      policy.minimum_speed
    },
    maximum_speed: if policy.maximum_speed < policy.minimum_speed {
      policy.minimum_speed
    } else {
      policy.maximum_speed
    },
  }
}

///|
/// Map congestion to a coarse traffic regime.
pub fn regime_for_congestion(congestion : Double) -> TrafficRegime {
  let c = clamp(congestion, 0.0, 1.0)
  if c < 0.25 {
    FreeFlow
  } else if c < 0.65 {
    Typical
  } else {
    RushHour
  }
}

///|
/// Return the profile speed associated with a regime.
pub fn SegmentProfile::speed_for_regime(
  self : SegmentProfile,
  regime : TrafficRegime,
) -> Double {
  match regime {
    FreeFlow => self.free_flow_speed
    Typical => self.typical_speed
    RushHour => self.rush_hour_speed
    Live => self.typical_speed
  }
}

///|
/// Blend historical and live speed according to policy and reliability.
pub fn predict_segment_speed(
  segment : SegmentProfile,
  live_speed : Double,
  congestion : Double,
  policy? : SpeedPolicy = default_speed_policy(),
) -> Double {
  let safe = sanitize_speed_policy(policy)
  let regime = regime_for_congestion(congestion)
  let historical = segment.expected_speed(congestion~)
  let regime_speed = segment.speed_for_regime(regime)
  let live = if live_speed <= 0.0 { historical } else { live_speed }
  let regime_weight = if regime == FreeFlow {
    safe.free_flow_weight
  } else if regime == RushHour {
    safe.rush_hour_weight
  } else {
    safe.typical_weight
  }
  let live_weight = safe.live_weight * clamp(segment.reliability, 0.0, 1.0)
  let historical_weight = regime_weight + (1.0 - live_weight) * 0.5
  let total = live_weight + historical_weight
  clamp(
    safe_div(
      live * live_weight + (historical + regime_speed) * historical_weight * 0.5,
      total,
      historical,
    ),
    safe.minimum_speed,
    safe.maximum_speed,
  )
}

///|
/// Estimate confidence from segment reliability and speed agreement.
pub fn speed_confidence(
  segment : SegmentProfile,
  live_speed : Double,
  predicted_speed : Double,
) -> Double {
  let agreement = 1.0 -
    safe_div(abs_double(live_speed - predicted_speed), predicted_speed, 1.0)
  clamp(
    clamp(segment.reliability, 0.0, 1.0) * clamp(agreement, 0.0, 1.0),
    0.0,
    1.0,
  )
}

///|
/// Convert a live route speed into segment-local speed with a floor.
pub fn allocate_live_speed(
  route : RouteProfile,
  live_speed : Double,
  segment : SegmentProfile,
) -> Double {
  let average = safe_div(
    route.total_distance(),
    route.historical_eta(congestion=0.4),
    live_speed,
  )
  clamp(
    live_speed * safe_div(segment.expected_speed(congestion=0.4), average, 1.0),
    0.1,
    60.0,
  )
}

///|
/// Return weighted speed candidates for diagnostics and benchmark reports.
pub fn speed_candidates(
  segment : SegmentProfile,
  congestion~ : Double,
) -> Array[Double] {
  [
    segment.free_flow_speed,
    segment.typical_speed,
    segment.rush_hour_speed,
    segment.expected_speed(congestion~),
  ]
}

///|
/// Measure how far live speed is from a segment's historical envelope.
pub fn historical_deviation(
  segment : SegmentProfile,
  live_speed : Double,
) -> Double {
  let candidates = speed_candidates(segment, congestion=0.5)
  let center = median(candidates)
  safe_div(abs_double(live_speed - center), center, 0.0)
}
