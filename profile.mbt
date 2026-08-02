///|
pub fn SegmentProfile::expected_speed(
  self : SegmentProfile,
  congestion~ : Double,
) -> Double {
  let c = clamp(congestion, 0.0, 1.0)
  let normal = self.free_flow_speed * (1.0 - c) + self.rush_hour_speed * c
  normal * self.reliability + self.typical_speed * (1.0 - self.reliability)
}

///|
pub fn SegmentProfile::expected_seconds(
  self : SegmentProfile,
  congestion~ : Double,
) -> Double {
  safe_div(self.distance, self.expected_speed(congestion~), 0.0)
}

///|
pub fn RouteProfile::total_distance(self : RouteProfile) -> Double {
  let mut total = 0.0
  for segment in self.segments {
    total += segment.distance
  }
  total
}

///|
pub fn RouteProfile::historical_eta(
  self : RouteProfile,
  congestion~ : Double,
) -> Double {
  let mut total = 0.0
  for segment in self.segments {
    total += segment.expected_seconds(congestion~)
  }
  total
}

///|
pub fn RouteProfile::average_reliability(self : RouteProfile) -> Double {
  if self.segments.length() == 0 {
    0.0
  } else {
    let mut total = 0.0
    for segment in self.segments {
      total += segment.reliability
    }
    total / self.segments.length().to_double()
  }
}

///|
pub fn demo_route() -> RouteProfile {
  {
    segments: [
      {
        segment_id: "origin-ramp",
        distance: 1600.0,
        free_flow_speed: 18.0,
        typical_speed: 13.0,
        rush_hour_speed: 6.0,
        reliability: 0.86,
      },
      {
        segment_id: "arterial-1",
        distance: 2800.0,
        free_flow_speed: 16.0,
        typical_speed: 10.5,
        rush_hour_speed: 4.5,
        reliability: 0.72,
      },
      {
        segment_id: "last-mile",
        distance: 950.0,
        free_flow_speed: 11.0,
        typical_speed: 7.5,
        rush_hour_speed: 3.0,
        reliability: 0.68,
      },
    ],
  }
}
