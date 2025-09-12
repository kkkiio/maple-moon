///|
struct SpritesheetMergeLoader {
  source : &AsyncResourceLoader
  cache : @lru_cache.Cache[String, Json]
  spritesheet_json_cache : Map[String, SpritesheetMetadata]
}

///|
pub fn SpritesheetMergeLoader::new(
  source : &AsyncResourceLoader,
) -> SpritesheetMergeLoader {
  {
    source,
    cache: @lru_cache.Cache::new(100),
    spritesheet_json_cache: Map::new(),
  }
}

///|
pub impl AsyncResourceLoader for SpritesheetMergeLoader with load_data(
  self,
  path,
) -> Json {
  let path = path.to_string()
  if self.cache.get(path) is Some(value) {
    return value
  }
  let origin_value = self.source.load_data(path)
  // collect all the spritesheet paths first
  let spritesheet_paths = collect_spritesheet_paths(origin_value)
  // filter missing spritesheet paths
  let spritesheet_paths = spritesheet_paths.filter(fn(path) {
    self.spritesheet_json_cache.get(path) is None
  })
  // load all the spritesheet json and cache them
  if spritesheet_paths.length() > 0 {
    @log.info({ "spritesheet_paths": spritesheet_paths }, "spritesheet paths")
    @js.async_all(
      spritesheet_paths.map(fn(path) {
        async fn() {
          let spritesheet_json_url = if path.has_prefix("/") {
            BASE_URL + path + ".json"
          } else {
            BASE_URL + "/" + path + ".json"
          }
          let fetched = js_fetch_string(spritesheet_json_url).wait()
            |> @js.Value::cast
          let j = @json.from_json(@json.parse(fetched)) catch {
            e =>
              fail(
                "failed to parse spritesheet json, error=\{e}, path=\{spritesheet_json_url}",
              )
          }
          self.spritesheet_json_cache.set(path, j)
        }
      }),
    )
    |> ignore
  }
  let value = preorder_replace(origin_value, fn(data) {
    fill_offset_from_spritesheet_json(data, self.spritesheet_json_cache)
  })
  self.cache.set(path, value)
  value
}

///|
pub fn patch_spritesheet_json(
  data : Json,
  spritesheet_jsons : Map[String, SpritesheetMetadata],
) -> Json raise {
  preorder_replace(data, fn(data) {
    fill_offset_from_spritesheet_json(data, spritesheet_jsons)
  })
}

///|
/// replace the json with the new json in preorder. 
/// if process returns Some(new_json), which means the replace is done, return the new json.
/// otherwise, continue to replace the children nodes.
fn preorder_replace(json : Json, process : (Json) -> Json? raise) -> Json raise {
  if process(json) is Some(new_json) {
    return new_json
  }
  match json {
    Object(obj) => {
      for key, value in obj {
        let new_json = preorder_replace(value, process)
        obj[key] = new_json
      }
      json
    }
    Array(arr) => {
      for index, value in arr {
        let new_json = preorder_replace(value, process)
        arr[index] = new_json
      }
      json
    }
    _ => json
  }
}

///|
/// fill `__off` for each frame json from the spritesheet json and return the new json.
/// the `__off` is the offset (x,y) of the frame in the spritesheet.
/// maybe cache the spritesheet json under the `/tmp/` directory
/// 
/// for example, before:
/// {
/// 			"__h": 14,
/// 			"__w": 8,
/// 			"group": "skin",
/// 			"map": { "hand": [-5, 5], "navel": [-11, 1] },
/// 			"origin": [6, 8],
/// 			"z": "armOverHair",
/// 			"__i": "/Character/Body/spritesheets/00002000.img#36"
/// 		}
/// after:
/// {
/// 			"__h": 14,
/// 			"__w": 8,
/// 			"group": "skin",
/// 			"map": { "hand": [-5, 5], "navel": [-11, 1] },
/// 			"origin": [6, 8],
/// 			"z": "armOverHair",
/// 			"__i": "/Character/Body/spritesheets/00002000.img.png"
/// 			"__off": [444, 244]
/// 		}
/// we can get the offset from the `jq '.frames."36.png".frame' http://maple-res.kkkiiox.work/Character/Body/spritesheets/00002000.img.json`
fn fill_offset_from_spritesheet_json(
  frame_json : Json,
  spritesheet_jsons : Map[String, SpritesheetMetadata],
) -> Json? raise {
  guard frame_json is { "__i": String(spritesheet_path), .. } &&
    spritesheet_path.contains("#") else {
    return None
  }

  // split path and frame key
  guard spritesheet_path.split("#").to_array() is [sheet_name, frame_name] else {
    return None
  }
  let image_path = sheet_name + ".png"
  let frame_key = frame_name + ".png"

  // build remote url and local cache path
  let path = sheet_name.to_string()
  let cached = spritesheet_jsons.get(path)
  // load spritesheet json from cache or remote
  guard cached is Some(sheet_json) else {
    fail("missing spritesheet json, path=\{path}")
  }
  guard sheet_json.frames.get(frame_key.to_string()) is Some(v) else {
    fail(
      "missing frame in spritesheet json, path=\{path}, frame_key=\{frame_key}",
    )
  }
  let x = v.frame.x
  let y = v.frame.y
  let new_obj = {}
  for k, v in frame_json.as_object().unwrap() {
    new_obj[k] = v
  }
  new_obj["__off"] = Json::array([
    Json::number(x.to_double()),
    Json::number(y.to_double()),
  ])
  new_obj["__i"] = Json::string(image_path.to_string())
  Some(Json::object(new_obj))
}

///|
pub(all) struct SpritesheetMetadata {
  frames : Map[String, SpritesheetImageMetadata]
} derive(@json.FromJson)
// {
// 			"frame": {"x":0,"y":0,"w":90,"h":91},
// 			"rotated": false,
// 			"trimmed": false,
// 			"spriteSourceSize": {"x":0,"y":0,"w":90,"h":91},
// 			"sourceSize": {"w":90,"h":91}
// 		}

///|
pub(all) struct SpritesheetImageMetadata {
  frame : SpritesheetFrameMetadata
} derive(@json.FromJson)

///|
pub(all) struct SpritesheetFrameMetadata {
  x : Int
  y : Int
} derive(@json.FromJson)

///|
const BASE_URL : String = "https://maple-res.kkkiiox.work"

///|
fn collect_spritesheet_paths(json : Json) -> Array[String] {
  let paths : Set[String] = Set::new()
  fn dfs(json : Json) -> Unit {
    match json {
      { "__i": String(path), .. } =>
        if path.split("#").to_array() is [sheet_name, _] {
          paths.add(sheet_name.to_string())
        }
      Object(obj) =>
        for _, value in obj {
          dfs(value)
        }
      Array(arr) =>
        for value in arr {
          dfs(value)
        }
      _ => ()
    }
  }

  dfs(json)
  paths.to_array()
}
