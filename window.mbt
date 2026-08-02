///|
pub fn WindowState::new(config : WindowConfig) -> WindowState {
  { values: [], target_size: config.min_size, config }
}

///|
pub fn mean(values : Array[Double]) -> Double {
  if values.length() == 0 {
    0.0
  } else {
    let mut total = 0.0
    for value in values {
      total += value
    }
    total / values.length().to_double()
  }
}

///|
pub fn variance(values : Array[Double]) -> Double {
  if values.length() <= 1 {
    0.0
  } else {
    let avg = mean(values)
    let mut total = 0.0
    for value in values {
      total += square(value - avg)
    }
    total / values.length().to_double()
  }
}

///|
fn trim_to(values : Array[Double], size : Int) -> Array[Double] {
  let out : Array[Double] = []
  let start = if values.length() > size { values.length() - size } else { 0 }
  for i in start..<values.length() {
    out.push(values[i])
  }
  out
}

///|
pub fn WindowState::push(self : WindowState, value : Double) -> WindowState {
  let values = self.values.copy()
  values.push(value)
  let recent = trim_to(values, self.config.max_size)
  let v = variance(recent)
  let next_size = if v <= self.config.low_variance {
    self.target_size + self.config.expansion_step
  } else if v >= self.config.high_variance {
    self.target_size - self.config.shrink_step
  } else {
    self.target_size
  }
  let target_size = clamp(
    next_size.to_double(),
    self.config.min_size.to_double(),
    self.config.max_size.to_double(),
  ).to_int()
  { ..self, values: trim_to(recent, target_size), target_size }
}

///|
pub fn WindowState::average(self : WindowState) -> Double {
  mean(self.values)
}

///|
pub fn WindowState::stability(self : WindowState) -> Double {
  1.0 / (1.0 + variance(self.values))
}
