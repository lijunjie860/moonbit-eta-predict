///|
/// Return a JSON-like line for one benchmark case without external dependencies.
pub fn benchmark_case_line(case : BenchmarkCase) -> String {
  "{\"name\":\"\{case.name}\",\"points\":\{case.points},\"mae\":\{case.summary.mae},\"rmse\":\{case.summary.rmse},\"mape\":\{case.summary.mape}}"
}

///|
/// Return benchmark rows for a log collector.
pub fn benchmark_lines(report : BenchmarkReport) -> Array[String] {
  let lines : Array[String] = []
  for case in report.cases {
    lines.push(benchmark_case_line(case))
  }
  lines.push(
    "{\"name\":\"aggregate\",\"points\":\{report.total_points},\"mae\":\{report.aggregate.mae},\"rmse\":\{report.aggregate.rmse}}",
  )
  lines
}

///|
/// Render a terminal-friendly benchmark table.
pub fn render_benchmark_table(report : BenchmarkReport) -> String {
  let builder = StringBuilder()
  builder.write_string("name points mae rmse confidence\n")
  for case in report.cases {
    builder.write_string(
      "\{case.name} \{case.points} \{case.summary.mae} \{case.summary.rmse} \{case.mean_confidence}\n",
    )
  }
  builder.write_string(
    "all \{report.total_points} \{report.aggregate.mae} \{report.aggregate.rmse}\n",
  )
  builder.to_string()
}

///|
/// Return a plain-language benchmark interpretation.
pub fn benchmark_interpretation(report : BenchmarkReport) -> String {
  if report.cases.length() == 0 {
    "No benchmark cases were evaluated."
  } else {
    let best = match best_benchmark_case(report) {
      Some(case) => case.name
      None => "unknown"
    }
    let worst = match worst_benchmark_case(report) {
      Some(case) => case.name
      None => "unknown"
    }
    "best=\{best} worst=\{worst} cases=\{report.cases.length()} points=\{report.total_points}"
  }
}

///|
/// Join benchmark metadata into one reproducible evidence block.
pub fn benchmark_evidence(report : BenchmarkReport, command : String) -> String {
  let builder = StringBuilder()
  builder.write_string("command: ")
  builder.write_string(command)
  builder.write_char('\n')
  builder.write_string(benchmark_annotation(report))
  builder.write_char('\n')
  builder.write_string(benchmark_interpretation(report))
  builder.write_char('\n')
  builder.write_string(report.rendered)
  builder.to_string()
}
