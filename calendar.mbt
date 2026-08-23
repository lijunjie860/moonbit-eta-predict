///|
/// Normalize arbitrary weekday values into Monday=0 through Sunday=6.
pub fn normalize_weekday(weekday : Int) -> Int {
  let mut result = weekday % 7
  if result < 0 {
    result += 7
  }
  result
}

///|
/// Construct a safe calendar bucket.
pub fn CalendarBucket::new(
  start_second : Double,
  end_second : Double,
  congestion : Double,
  label? : String = "custom",
) -> CalendarBucket {
  {
    start_second: clamp(start_second, 0.0, 86400.0),
    end_second: clamp(end_second, 0.0, 86400.0),
    congestion: clamp(congestion, 0.0, 1.0),
    label,
  }
}

///|
/// Select a bucket when its half-open range contains the requested second.
pub fn CalendarBucket::contains(
  self : CalendarBucket,
  second_of_day : Double,
) -> Bool {
  second_of_day >= self.start_second && second_of_day < self.end_second
}

///|
/// Return the bucket's midpoint in seconds.
pub fn CalendarBucket::midpoint(self : CalendarBucket) -> Double {
  (self.start_second + self.end_second) / 2.0
}

///|
/// Select a day's congestion, falling back when no bucket matches.
pub fn DayCalendar::congestion_at(
  self : DayCalendar,
  second_of_day : Double,
) -> Double {
  let second = clamp(second_of_day, 0.0, 86399.999999)
  let mut result = clamp(self.fallback_congestion, 0.0, 1.0)
  for bucket in self.buckets {
    if bucket.contains(second) {
      result = bucket.congestion
    }
  }
  result
}

///|
/// Find a day by weekday and evaluate its buckets.
pub fn RouteCalendar::congestion_at(
  self : RouteCalendar,
  weekday : Int,
  second_of_day : Double,
) -> Double {
  let wanted = normalize_weekday(weekday)
  let mut result = clamp(self.default_congestion, 0.0, 1.0)
  for day in self.days {
    if normalize_weekday(day.weekday) == wanted {
      result = day.congestion_at(second_of_day)
    }
  }
  result
}

///|
/// Return the selected bucket label, or `default` when no bucket matches.
pub fn DayCalendar::label_at(
  self : DayCalendar,
  second_of_day : Double,
) -> String {
  for bucket in self.buckets {
    if bucket.contains(second_of_day) {
      return bucket.label
    }
  }
  "default"
}

///|
/// Count valid buckets in a day.
pub fn DayCalendar::valid_bucket_count(self : DayCalendar) -> Int {
  let mut count = 0
  for bucket in self.buckets {
    if validate_calendar_bucket(bucket) {
      count += 1
    }
  }
  count
}

///|
/// Validate and normalize a route calendar.
pub fn normalize_calendar(calendar : RouteCalendar) -> RouteCalendar {
  let days : Array[DayCalendar] = []
  for day in calendar.days {
    let buckets : Array[CalendarBucket] = []
    for bucket in day.buckets {
      if validate_calendar_bucket(bucket) {
        buckets.push({
          ..bucket,
          congestion: clamp(bucket.congestion, 0.0, 1.0),
        })
      }
    }
    days.push({
      weekday: normalize_weekday(day.weekday),
      buckets,
      fallback_congestion: clamp(day.fallback_congestion, 0.0, 1.0),
    })
  }
  { days, default_congestion: clamp(calendar.default_congestion, 0.0, 1.0) }
}

///|
/// Build the reference weekly calendar used by examples and benchmarks.
pub fn demo_calendar() -> RouteCalendar {
  let morning = CalendarBucket::new(
    7.0 * 3600.0,
    9.5 * 3600.0,
    0.72,
    label="morning-peak",
  )
  let evening = CalendarBucket::new(
    17.0 * 3600.0,
    19.5 * 3600.0,
    0.86,
    label="evening-peak",
  )
  let quiet = CalendarBucket::new(0.0, 6.0 * 3600.0, 0.18, label="overnight")
  let days : Array[DayCalendar] = []
  for weekday in 0..<5 {
    days.push({
      weekday,
      buckets: [quiet, morning, evening],
      fallback_congestion: 0.35,
    })
  }
  for weekday in 5..<7 {
    days.push({ weekday, buckets: [quiet], fallback_congestion: 0.25 })
  }
  normalize_calendar({ days, default_congestion: 0.35 })
}

///|
/// Return a human-readable label for the current calendar bucket.
pub fn calendar_label(
  calendar : RouteCalendar,
  weekday : Int,
  second_of_day : Double,
) -> String {
  let wanted = normalize_weekday(weekday)
  for day in calendar.days {
    if normalize_weekday(day.weekday) == wanted {
      return day.label_at(second_of_day)
    }
  }
  "default"
}

///|
/// Interpolate between two congestion values over a time interval.
pub fn interpolate_congestion(
  start : Double,
  end : Double,
  progress : Double,
) -> Double {
  let p = clamp(progress, 0.0, 1.0)
  clamp(start + (end - start) * p, 0.0, 1.0)
}

///|
/// Evaluate a calendar over evenly spaced samples.
pub fn sample_calendar(
  calendar : RouteCalendar,
  weekday : Int,
  start_second : Double,
  interval : Double,
  count : Int,
) -> Array[Double] {
  let result : Array[Double] = []
  for index in 0..<count {
    result.push(
      calendar.congestion_at(
        weekday,
        start_second + interval * index.to_double(),
      ),
    )
  }
  result
}
