///|
struct RunSummary {
  issue_count : Int
  error_count : Int
  warning_count : Int
}

///|
fn make_issue(
  module_name : String,
  severity : Severity,
  path : String,
  detail : String,
) -> CheckIssue {
  { module_name, severity, path, detail }
}

///|
fn issue_level_text(severity : Severity) -> String {
  match severity {
    Error => "ERROR"
  }
}

///|
fn run_pipeline(
  ctx : RescheckContext,
  checks : Array[Checker],
  only_modules : Array[String],
) -> RunSummary {
  let selected : Array[Checker] = []
  if only_modules.is_empty() {
    for c in checks {
      selected.push(c)
    }
  } else {
    for c in checks {
      if only_modules.contains(c.name) {
        selected.push(c)
      }
    }
  }

  if selected.is_empty() {
    println("[rescheck] no checker selected")
    return { issue_count: 0, error_count: 0, warning_count: 0 }
  }

  let mut issue_count = 0
  let mut error_count = 0
  let warning_count = 0

  for checker in selected {
    println("[rescheck] run module: \{checker.name}")
    let issues = (checker.run)(ctx)
    for issue in issues {
      issue_count = issue_count + 1
      if issue.severity is Error {
        error_count = error_count + 1
      }
      println(
        "[\{issue_level_text(issue.severity)}] [\{issue.module_name}] \{issue.path} :: \{issue.detail}",
      )
    }
    println("[rescheck] module \{checker.name} done, issues=\{issues.length()}")
  }

  println(
    "[rescheck] finished, total=\{issue_count}, errors=\{error_count}, warnings=\{warning_count}",
  )
  { issue_count, error_count, warning_count }
}
