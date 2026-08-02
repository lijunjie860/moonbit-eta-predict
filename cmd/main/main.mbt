///|
fn main {
  let results = @eta.run_demo()
  if results.length() == 0 {
    println("no observations")
  } else {
    let last = results[results.length() - 1]
    println("MoonBit ETA demo")
    println(
      "remaining=\{last.remaining_distance}s speed=\{last.smoothed_speed} eta=\{last.eta_seconds}",
    )
  }
}
