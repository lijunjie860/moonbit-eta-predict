///|
fn route_candidate_score(
  breakdown : RouteBreakdown,
  risk_penalty : Double,
) -> Double {
  breakdown.total_eta_seconds +
  abs_double(risk_penalty) *
  (1.0 - breakdown.confidence) *
  breakdown.total_eta_seconds
}

///|
/// Build route candidates from multiple profiles.
pub fn make_route_candidates(
  routes : Array[(String, RouteProfile)],
  speed~ : Double,
  congestion~ : Double,
  risk_penalty? : Double = 0.25,
) -> Array[RouteCandidate] {
  let candidates : Array[RouteCandidate] = []
  for item in routes {
    let route_id = item.0
    let route = item.1
    let breakdown = forecast_breakdown(route, speed~, congestion~)
    let risk = (1.0 - breakdown.confidence) * breakdown.total_eta_seconds
    candidates.push({
      route_id,
      route,
      breakdown,
      score: route_candidate_score(breakdown, risk_penalty),
      risk,
    })
  }
  candidates
}

///|
/// Select the lowest-risk-adjusted ETA candidate.
pub fn select_route(candidates : Array[RouteCandidate]) -> RouteSelection {
  if candidates.length() == 0 {
    { selected: None, alternatives: [], reason: "no route candidates" }
  } else {
    let sorted = candidates.copy()
    sorted.sort_by((left, right) => compare_double(left.score, right.score))
    let alternatives : Array[RouteCandidate] = []
    for candidate in sorted[1:] {
      alternatives.push(candidate)
    }
    {
      selected: Some(sorted[0]),
      alternatives,
      reason: "minimum ETA-risk score",
    }
  }
}

///|
/// Return route candidates in score order.
pub fn rank_routes(candidates : Array[RouteCandidate]) -> Array[RouteCandidate] {
  let ranked = candidates.copy()
  ranked.sort_by((left, right) => compare_double(left.score, right.score))
  ranked
}

///|
/// Return candidate IDs in rank order.
pub fn route_ids(candidates : Array[RouteCandidate]) -> Array[String] {
  let ids : Array[String] = []
  for candidate in rank_routes(candidates) {
    ids.push(candidate.route_id)
  }
  ids
}

///|
/// Return routes that are not dominated by both ETA and risk.
pub fn pareto_routes(
  candidates : Array[RouteCandidate],
) -> Array[RouteCandidate] {
  let result : Array[RouteCandidate] = []
  for candidate in candidates {
    let dominated = candidates.any(other => {
      other.breakdown.total_eta_seconds < candidate.breakdown.total_eta_seconds &&
      other.risk < candidate.risk &&
      other.route_id != candidate.route_id
    })
    if !dominated {
      result.push(candidate)
    }
  }
  result
}

///|
/// Add a fixed operational risk budget to a candidate score.
pub fn with_risk_budget(
  candidate : RouteCandidate,
  budget~ : Double,
) -> RouteCandidate {
  let extra = abs_double(budget) * candidate.risk
  { ..candidate, score: candidate.breakdown.total_eta_seconds + extra }
}

///|
/// Compare selected route to the fastest raw ETA route.
pub fn selection_risk_premium(selection : RouteSelection) -> Double {
  match selection.selected {
    None => 0.0
    Some(selected) =>
      if selection.alternatives.length() == 0 {
        0.0
      } else {
        let fastest = selection.alternatives.fold(
          init=selected.breakdown.total_eta_seconds,
          (current, candidate) => {
            if candidate.breakdown.total_eta_seconds < current {
              candidate.breakdown.total_eta_seconds
            } else {
              current
            }
          },
        )
        safe_div(selected.breakdown.total_eta_seconds - fastest, fastest, 0.0)
      }
  }
}
