///|
fn main {
  let arguments = @env.args()
  let command = if arguments.length() > 1 {
    arguments[1:].to_owned()
  } else {
    []
  }
  println(@eta.run_cli(command))
}
