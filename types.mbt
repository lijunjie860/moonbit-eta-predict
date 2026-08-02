///|
pub(all) struct Observation {
  timestamp : Double
  distance : Double
  elapsed : Double
} derive(Debug, Eq)

///|
pub(all) struct VelocitySample {
  timestamp : Double
  speed : Double
  confidence : Double
} derive(Debug, Eq)

///|
pub(all) struct KalmanConfig {
  process_noise : Double
  measurement_noise : Double
  initial_error : Double
  min_variance : Double
  gate_sigma : Double
} derive(Debug, Eq)

///|
pub(all) struct KalmanState {
  estimate : Double
  covariance : Double
  process_noise : Double
  measurement_noise : Double
  min_variance : Double
  gate_sigma : Double
} derive(Debug, Eq)

///|
pub(all) struct WindowConfig {
  min_size : Int
  max_size : Int
  low_variance : Double
  high_variance : Double
  expansion_step : Int
  shrink_step : Int
} derive(Debug, Eq)

///|
pub(all) struct WindowState {
  values : Array[Double]
  target_size : Int
  config : WindowConfig
} derive(Debug, Eq)

///|
pub(all) struct SegmentProfile {
  segment_id : String
  distance : Double
  free_flow_speed : Double
  typical_speed : Double
  rush_hour_speed : Double
  reliability : Double
} derive(Debug, Eq)

///|
pub(all) struct RouteProfile {
  segments : Array[SegmentProfile]
} derive(Debug, Eq)

///|
pub(all) struct EtaConfig {
  min_speed : Double
  max_speed : Double
  history_weight : Double
  live_weight : Double
  reliability_floor : Double
} derive(Debug, Eq)

///|
pub(all) struct EtaResult {
  eta_seconds : Double
  smoothed_speed : Double
  raw_speed : Double
  confidence : Double
  remaining_distance : Double
} derive(Debug, Eq)

///|
pub(all) struct ErrorSummary {
  count : Int
  mae : Double
  rmse : Double
  mape : Double
  max_error : Double
} derive(Debug, Eq)

///|
pub(all) struct ForecastPoint {
  predicted : Double
  actual : Double
} derive(Debug, Eq)
