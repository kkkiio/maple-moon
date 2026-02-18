/// Reanim CLI tool: process game animations
/// CLI entry point handles argument parsing and dispatches to processing logic.

///|
fn parse_args() -> CliArgs? {
  let args = @sys.get_cli_args()
  let argv = if args.length() > 0 {
    let arr : Array[String] = []
    for i = 1; i < args.length(); i = i + 1 {
      arr.push(args[i].to_string())
    }
    arr
  } else {
    []
  }
  let match_pattern : Ref[String] = Ref::new("")
  let bitmaps_dir : Ref[String] = Ref::new("")
  let spritesheet_dir : Ref[String] = Ref::new("")
  let resize : Ref[Bool] = Ref::new(false)
  let keep_source_sheets : Ref[Bool] = Ref::new(false)
  let positional : Array[String] = []
  let spec : Array[(String, String, @ArgParser.Spec, String)] = [
    (
      "--match",
      "-m",
      @ArgParser.Set_string(match_pattern),
      "Filter by path pattern (e.g., BasicEff.img/Teleport)",
    ),
    (
      "--bitmaps-dir",
      "-b",
      @ArgParser.Set_string(bitmaps_dir),
      "Override bitmaps dir (default: <input-dir>/bitmaps)",
    ),
    (
      "--spritesheet-dir",
      "-s",
      @ArgParser.Set_string(spritesheet_dir),
      "Spritesheet dir (for __i mode)",
    ),
    (
      "--resize",
      "-r",
      @ArgParser.Set(resize),
      "Resize frames to unified size (legacy mode, default: off)",
    ),
    (
      "--keep-source-sheets",
      "-k",
      @ArgParser.Set(keep_source_sheets),
      "Keep source spritesheets and only inject __off",
    ),
  ]
  let usage =
    #| Reanim CLI tool - Process game animations
    #| 
    #| Usage: reanim <input.json> <output-dir> [options]
    #| 
    #| Examples:
    #|   reanim .local/r2/Mob/1210100.img.json assets/mob -s .local/r2/spritesheets/Mob
    #|   reanim .local/nx/Effect.nx/nx.json assets/Effect -m BasicEff.img/Teleport
    #|
  @ArgParser.parse(spec, fn(arg) { positional.push(arg) }, usage, argv) catch {
    @ArgParser.ErrorMsg(msg) => {
      println(msg)
      return None
    }
    e => {
      println("Error: \{e}")
      return None
    }
  }
  if positional.length() < 2 {
    println("Error: Missing required arguments <input.json> <output-dir>")
    println("")
    println(usage)
    return None
  }
  Some({
    input: positional[0],
    output: positional[1],
    spritesheet_dir: spritesheet_dir.val,
    bitmaps_dir: if bitmaps_dir.val == "" {
      let parts = positional[0].split("/").to_array()
      parts.pop() |> ignore
      parts.push("bitmaps")
      parts.join("/")
    } else {
      bitmaps_dir.val
    },
    match_pattern: if match_pattern.val == "" {
      None
    } else {
      Some(match_pattern.val)
    },
    resize: resize.val,
    keep_source_sheets: keep_source_sheets.val,
  })
}

///|
async fn main {
  guard parse_args() is Some(args) else { return }
  let input_content = @fs.read_file_to_string(args.input) catch {
    e => {
      println("Error reading input: \{e}")
      @sys.exit(1)
      return
    }
  }
  let input_json = @json.parse(input_content) catch {
    e => {
      println("Error parsing JSON: \{e}")
      @sys.exit(1)
      return
    }
  }
  let mode = detect_mode(input_json)
  match mode {
    Bitmap => {
      println("Detected bitmap mode (__b references)")
      process_bitmap(args) catch {
        e => {
          println("Error: \{e}")
          @sys.exit(1)
        }
      }
    }
    Spritesheet => {
      println("Detected spritesheet mode (__i references)")
      process_spritesheet(args) catch {
        e => {
          println("Error: \{e}")
          @sys.exit(1)
        }
      }
    }
  }
}
