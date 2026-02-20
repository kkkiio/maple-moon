///|
struct CliArgs {
  assets_root : String
  only_modules : Array[String]
}

///|
fn print_usage() -> Unit {
  println("rescheck - assets resource integrity checker")
  println("")
  println("Usage: rescheck [--assets-root <path>] [--module <name>]...")
  println("")
  println("Examples:")
  println("  rescheck")
  println("  rescheck --assets-root assets --module item")
}

///|
fn parse_args() -> CliArgs? {
  let raw = @sys.get_cli_args()
  let argv : Array[String] = []
  for i = 1; i < raw.length(); i = i + 1 {
    argv.push(raw[i].to_string())
  }

  let mut assets_root = "assets"
  let only_modules : Array[String] = []

  let mut i = 0
  while i < argv.length() {
    let arg = argv[i]
    if arg == "--help" || arg == "-h" {
      print_usage()
      return None
    }
    if arg == "--assets-root" {
      if i + 1 >= argv.length() {
        println("Error: --assets-root requires a path")
        return None
      }
      assets_root = argv[i + 1]
      i = i + 2
      continue
    }
    if arg == "--module" {
      if i + 1 >= argv.length() {
        println("Error: --module requires a module name")
        return None
      }
      only_modules.push(argv[i + 1])
      i = i + 2
      continue
    }
    println("Error: unknown argument: \{arg}")
    return None
  }

  Some({ assets_root, only_modules })
}

///|
fn all_checkers() -> Array[Checker] {
  [
    register_json_format_checker(),
    register_item_checker(),
    register_mob_checker(),
    register_ui_checker(),
  ]
}

///|
fn validate_selected_modules(
  selected : Array[String],
  checks : Array[Checker],
) -> Bool {
  if selected.is_empty() {
    return true
  }
  let known : Map[String, Bool] = Map::new()
  for check in checks {
    known[check.name] = true
  }
  let mut ok = true
  for name in selected {
    if not(known.contains(name)) {
      println("Error: unknown module '\{name}'")
      ok = false
    }
  }
  if not(ok) {
    println("Available modules:")
    for check in checks {
      println("  - \{check.name}")
    }
  }
  ok
}

///|
fn main {
  guard parse_args() is Some(args) else { return }

  if not(file_exists(args.assets_root)) {
    println("Error: assets root not found: \{args.assets_root}")
    @sys.exit(2)
    return
  }

  let checks = all_checkers()
  if not(validate_selected_modules(args.only_modules, checks)) {
    @sys.exit(2)
    return
  }

  let ctx = build_context(args.assets_root)
  println(
    "[rescheck] assets_root=\{ctx.assets_root}, files=\{ctx.all_files.length()}",
  )
  let summary = run_pipeline(ctx, checks, args.only_modules)
  println(
    "[rescheck] summary total=\{summary.issue_count}, warnings=\{summary.warning_count}, errors=\{summary.error_count}",
  )
  if summary.error_count > 0 {
    @sys.exit(1)
  }
}
