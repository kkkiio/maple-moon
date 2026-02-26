///|
struct CliArgs {
  input : String
  output : String
}

///|
fn parse_args() -> CliArgs? {
  let args = @sys.get_cli_args()
  let argv : Array[String] = []
  for i = 1; i < args.length(); i = i + 1 {
    argv.push(args[i].to_string())
  }
  if argv.length() < 2 {
    println("Usage: stringpack <input-string-nx.json> <output-dir>")
    println("Example: stringpack .local/string.nx.json assets/String")
    return None
  }
  Some({ input: argv[0], output: argv[1] })
}

///|
fn ensure_output_dir(output : String) -> Unit {
  if not(@fsx.exists_sync(output)) {
    @fsx.mkdir_sync(output)
  }
}

///|
fn write_shard(output_dir : String, key : String, value : Json) -> Unit {
  let output_path = join_path(output_dir, key + ".json")
  let content = value.stringify(indent=2)
  @fsx.write_file_sync(output_path, content)
}

///|
fn join_path(dir : String, file : String) -> String {
  let dir = dir.strip_suffix("/").unwrap_or(dir)
  "\{dir}/\{file}"
}

///|
fn main {
  guard parse_args() is Some(args) else { return }
  ensure_output_dir(args.output)
  let content = @fsx.read_file_sync(args.input, "utf-8")
  let root = @json.parse(content) catch {
    e => {
      println("Failed to parse JSON: \{e}")
      @sys.exit(1)
      return
    }
  }
  guard root is Object(entries) else {
    println("Input JSON must be an object.")
    @sys.exit(1)
    return
  }
  let keys : Array[String] = []
  for key, _ in entries {
    keys.push(key)
  }
  keys.sort()
  for key in keys {
    guard entries.get(key) is Some(value) else { continue }
    write_shard(args.output, key, value)
  }
  println("stringpack: wrote \{keys.length()} shards to \{args.output}")
}
