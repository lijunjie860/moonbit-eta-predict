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

///|
pub(all) struct ScenarioConfig {
  steps : Int
  interval_seconds : Double
  base_speed : Double
  congestion : Double
  noise_stride : Int
  noise_magnitude : Double
} derive(Debug, Eq)

///|
pub(all) struct ScenarioTrace {
  observations : Array[Observation]
  actual_remaining : Array[Double]
} derive(Debug, Eq)

///|
pub(all) struct CalibrationConfig {
  min_congestion : Double
  max_congestion : Double
  steps : Int
} derive(Debug, Eq)

///|
pub(all) struct CalibrationResult {
  best_congestion : Double
  best_error : ErrorSummary
  candidates : Array[ForecastPoint]
} derive(Debug, Eq)

///|
/// Validation categories returned by input and configuration checks.
pub(all) enum ValidationCode {
  EmptyInput
  NonFiniteValue
  NegativeTimestamp
  NegativeDistance
  NonMonotonicTime
  NonMonotonicDistance
  InvalidConfiguration
  InvalidRange
} derive(Debug, Eq)

///|
/// A stable, machine-readable validation finding.
pub(all) struct ValidationIssue {
  code : ValidationCode
  index : Int
  message : String
} derive(Debug, Eq)

///|
/// The result of validating a public input collection.
pub(all) struct ValidationReport {
  valid : Bool
  checked : Int
  issues : Array[ValidationIssue]
} derive(Debug, Eq)

///|
/// A confidence interval over a scalar estimate.
pub(all) struct ConfidenceInterval {
  estimate : Double
  lower : Double
  upper : Double
  level : Double
} derive(Debug, Eq)

///|
/// A time-of-day congestion bucket.
pub(all) struct CalendarBucket {
  start_second : Double
  end_second : Double
  congestion : Double
  label : String
} derive(Debug, Eq)

///|
/// Congestion buckets for one weekday.
pub(all) struct DayCalendar {
  weekday : Int
  buckets : Array[CalendarBucket]
  fallback_congestion : Double
} derive(Debug, Eq)

///|
/// A weekly route calendar.
pub(all) struct RouteCalendar {
  days : Array[DayCalendar]
  default_congestion : Double
} derive(Debug, Eq)

///|
/// ETA contributed by one route segment.
pub(all) struct SegmentEta {
  segment_id : String
  distance : Double
  speed : Double
  eta_seconds : Double
  confidence : Double
} derive(Debug, Eq)

///|
/// A route-level ETA breakdown.
pub(all) struct RouteBreakdown {
  segments : Array[SegmentEta]
  total_distance : Double
  total_eta_seconds : Double
  confidence : Double
} derive(Debug, Eq)

///|
/// A validated, ordered collection of observations.
pub(all) struct ObservationBatch {
  observations : Array[Observation]
  source : String
  dropped : Int
} derive(Debug, Eq)

///|
/// A parsed row with an optional target value.
pub(all) struct DatasetRow {
  observation : Observation
  actual_remaining : Double?
  weight : Double
} derive(Debug, Eq)

///|
/// A dataset used by batch evaluation and calibration.
pub(all) struct ObservationDataset {
  rows : Array[DatasetRow]
  name : String
} derive(Debug, Eq)

///|
/// Explicit codec outcome; parsers do not panic on bad external input.
pub(all) enum ParseOutcome[T] {
  Parsed(T)
  ParseFailed(ParseError)
} derive(Debug, Eq)

///|
/// Parse failure details for CSV and JSON-line input.
pub(all) enum ParseError {
  EmptyInput
  MissingHeader
  MissingField(line~ : Int, field~ : String)
  ExtraField(line~ : Int)
  InvalidNumber(line~ : Int, field~ : String, value~ : String)
  InvalidSyntax(line~ : Int, message~ : String)
  UnsupportedSchema(String)
} derive(Debug, Eq)

///|
/// Result returned by observation codecs.
pub(all) struct ObservationParseResult {
  observations : Array[Observation]
  error : ParseError?
  lines_read : Int
} derive(Debug, Eq)

///|
/// The result of forecasting a whole dataset.
pub(all) struct BatchForecast {
  results : Array[EtaResult]
  points : Array[ForecastPoint]
  summary : ErrorSummary
  skipped : Int
} derive(Debug, Eq)

///|
/// One rolling evaluation window.
pub(all) struct EvaluationWindow {
  start : Int
  end : Int
  summary : ErrorSummary
} derive(Debug, Eq)

///|
/// Rolling error analysis over a forecast trace.
pub(all) struct RollingEvaluation {
  windows : Array[EvaluationWindow]
  overall : ErrorSummary
} derive(Debug, Eq)

///|
/// A benchmark scenario with deterministic input and output metrics.
pub(all) struct BenchmarkCase {
  name : String
  points : Int
  summary : ErrorSummary
  mean_confidence : Double
  notes : String
} derive(Debug, Eq)

///|
/// A complete benchmark report.
pub(all) struct BenchmarkReport {
  cases : Array[BenchmarkCase]
  aggregate : ErrorSummary
  total_points : Int
  rendered : String
} derive(Debug, Eq)

///|
/// A parameter candidate and its evaluation score.
pub(all) struct CalibrationCandidate {
  congestion : Double
  error : ErrorSummary
  rank : Int
} derive(Debug, Eq)

///|
/// Calibration report with deterministic candidate ordering.
pub(all) struct GridCalibration {
  candidates : Array[CalibrationCandidate]
  best : CalibrationCandidate
  evaluated : Int
} derive(Debug, Eq)

///|
/// Traffic regime selected by a calendar or a caller.
pub(all) enum TrafficRegime {
  FreeFlow
  Typical
  RushHour
  Live
} derive(Debug, Eq)

///|
/// Weights used to combine historical and live speed evidence.
pub(all) struct SpeedPolicy {
  free_flow_weight : Double
  typical_weight : Double
  rush_hour_weight : Double
  live_weight : Double
  minimum_speed : Double
  maximum_speed : Double
} derive(Debug, Eq)

///|
/// One entry in a route breakdown with contextual metadata.
pub(all) struct SegmentForecast {
  index : Int
  segment : SegmentProfile
  eta : SegmentEta
  regime : TrafficRegime
  congestion : Double
} derive(Debug, Eq)

///|
/// Route forecast retaining both summary and per-segment decisions.
pub(all) struct DetailedBreakdown {
  forecasts : Array[SegmentForecast]
  total : RouteBreakdown
  weekday : Int
  second_of_day : Double
} derive(Debug, Eq)

///|
/// Canonical fields accepted by the observation interchange layer.
pub(all) enum SchemaField {
  Timestamp
  Distance
  Elapsed
  ActualRemaining
  Weight
} derive(Debug, Eq)

///|
/// A named schema with required and optional fields.
pub(all) struct DatasetSchema {
  name : String
  required : Array[SchemaField]
  optional : Array[SchemaField]
  version : String
} derive(Debug, Eq)

///|
/// A schema validation result.
pub(all) struct SchemaReport {
  valid : Bool
  missing : Array[SchemaField]
  unknown : Array[String]
  message : String
} derive(Debug, Eq)

///|
/// A dataset-level descriptive summary.
pub(all) struct DatasetSummary {
  rows : Int
  duration : Double
  distance : Double
  average_speed : Double
  missing_targets : Int
  average_weight : Double
} derive(Debug, Eq)

///|
/// A cross-validation fold result.
pub(all) struct CrossValidationFold {
  fold : Int
  train_count : Int
  test_count : Int
  summary : ErrorSummary
} derive(Debug, Eq)

///|
/// Aggregate cross-validation report.
pub(all) struct CrossValidationReport {
  folds : Array[CrossValidationFold]
  aggregate : ErrorSummary
  best_congestion : Double
} derive(Debug, Eq)

///|
/// Quality thresholds used by CI and consumers.
pub(all) struct QualityGateConfig {
  max_mae : Double
  max_rmse : Double
  min_confidence : Double
  min_points : Int
  require_monotonic_distance : Bool
} derive(Debug, Eq)

///|
/// Quality gate outcome with actionable reasons.
pub(all) struct QualityGateResult {
  passed : Bool
  reasons : Array[String]
  checked_points : Int
  summary : ErrorSummary
} derive(Debug, Eq)

///|
/// A route state retained between streaming updates.
pub(all) struct RouteStreamState {
  route : RouteProfile
  engine : EtaEngine
  calendar : RouteCalendar
  weekday : Int
  second_of_day : Double
  updates : Int
} derive(Debug, Eq)

///|
/// An immutable update record for an online route stream.
pub(all) struct StreamSnapshot {
  update : Int
  observation : Observation
  result : EtaResult
  label : String
} derive(Debug, Eq)

///|
/// Online stream summary used by dashboards and loggers.
pub(all) struct StreamSummary {
  snapshots : Array[StreamSnapshot]
  latest : EtaResult
  average_confidence : Double
  dropped : Int
} derive(Debug, Eq)

///|
/// A fixed-width bin for calibration and reliability reports.
pub(all) struct MetricBin {
  lower : Double
  upper : Double
  count : Int
  mean_error : Double
  mean_confidence : Double
} derive(Debug, Eq)

///|
/// A collection of complementary forecast metrics.
pub(all) struct MetricReport {
  summary : ErrorSummary
  bias : Double
  smape : Double
  median_absolute_error : Double
  coverage : Double
  bins : Array[MetricBin]
} derive(Debug, Eq)

///|
/// Alert categories emitted by a streaming consumer.
pub(all) enum AlertKind {
  LowConfidence
  EtaJump
  StalledProgress
  RouteComplete
  InvalidObservation
} derive(Debug, Eq)

///|
/// A forecast alert with a stable severity score.
pub(all) struct ForecastAlert {
  kind : AlertKind
  update : Int
  severity : Double
  message : String
} derive(Debug, Eq)

///|
/// Route candidate for ETA-aware route selection.
pub(all) struct RouteCandidate {
  route_id : String
  route : RouteProfile
  breakdown : RouteBreakdown
  score : Double
  risk : Double
} derive(Debug, Eq)

///|
/// Selected route and discarded alternatives.
pub(all) struct RouteSelection {
  selected : RouteCandidate?
  alternatives : Array[RouteCandidate]
  reason : String
} derive(Debug, Eq)

///|
/// One point in a deterministic sensitivity curve.
pub(all) struct SensitivityPoint {
  input : Double
  eta_seconds : Double
  speed : Double
  confidence : Double
  delta_from_baseline : Double
} derive(Debug, Eq)

///|
/// Sensitivity report for one route and parameter.
pub(all) struct SensitivityReport {
  parameter : String
  baseline : SensitivityPoint
  points : Array[SensitivityPoint]
  monotonic : Bool
  elasticity : Double
} derive(Debug, Eq)

///|
/// Descriptive time-series statistics.
pub(all) struct TimeSeriesSummary {
  count : Int
  first : Double
  last : Double
  minimum : Double
  maximum : Double
  mean : Double
  trend : Double
  volatility : Double
} derive(Debug, Eq)

///|
/// An explanation of one ETA decision.
pub(all) struct EtaExplanation {
  remaining_distance : Double
  raw_speed : Double
  smoothed_speed : Double
  historical_speed : Double
  live_weight : Double
  history_weight : Double
  confidence : Double
  factors : Array[String]
} derive(Debug, Eq)

///|
/// Package health checks suitable for an embedding application.
pub(all) struct HealthReport {
  ready : Bool
  route_valid : Bool
  config_valid : Bool
  calendar_valid : Bool
  messages : Array[String]
} derive(Debug, Eq)

///|
/// Bounds applied before an observation enters a live engine.
pub(all) struct InputGuardConfig {
  maximum_distance : Double
  maximum_timestamp : Double
  reject_backwards_time : Bool
  reject_backwards_distance : Bool
} derive(Debug, Eq)

///|
/// Sanitized observation and reasons for any adjustment.
pub(all) struct GuardResult {
  accepted : Bool
  observation : Observation
  reasons : Array[String]
} derive(Debug, Eq)

///|
/// Contract result for a complete forecast trace.
pub(all) struct ContractReport {
  valid : Bool
  checks : Int
  failures : Array[String]
} derive(Debug, Eq)
