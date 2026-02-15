///|
pub fn ImageLoader::load_image(self : ImageLoader, bid : Int) -> Image = "resource" "load_image"

///|
pub fn ImageLoader::get_path_image_loader() -> ImageLoader = "resource" "get_path_image_loader"

///|
pub trait AsyncResourceLoader {
  async load_data(self : Self, path : StringView) -> Json
}

///|
struct AsyncLoader {
  name : String
  loader : &AsyncResourceLoader
}

///|
pub fn AsyncLoader::new(
  name : String,
  loader~ : &AsyncResourceLoader,
  base_url? : String = OLD_BASE_URL,
  image_base_url? : String = base_url,
) -> AsyncLoader {
  {
    name,
    loader: SpritesheetMergeLoader::new(loader, base_url, image_base_url),
  }
}

///|
pub async fn AsyncLoader::load_res_async(
  self : AsyncLoader,
  path : Array[String],
) -> NxNode {
  let promise = self.loader.load_data(join_path(path))
  {
    loader_name: self.name,
    image_loader: None,
    name: path.last().unwrap(),
    desc: promise,
    path: path |> @immut/array.from_array,
  }
}

///|
struct CompositeAsyncResourceLoader {
  prefixLoaderMap : Map[String, &AsyncResourceLoader]
}

///|
pub fn CompositeAsyncResourceLoader::new(
  prefixLoaderMap : Map[String, &AsyncResourceLoader],
) -> CompositeAsyncResourceLoader {
  { prefixLoaderMap, }
}

///|
pub impl AsyncResourceLoader for CompositeAsyncResourceLoader with load_data(
  self,
  path,
) -> Json {
  let (path, loader) = for prefix, loader in self.prefixLoaderMap {
    if path.strip_prefix(prefix) is Some(path) {
      break (path, loader)
    }
  } nobreak {
    fail("path not found: \{path}")
  }
  loader.load_data(path.to_string())
}

///|
/// A resource loader that loads resources from a directory.
/// The directory splits resources by first level of the path and stores them in json files.
/// For example, if we want to load grassySoil/ani/0, it will load $rootPath/grassySoil.img.json and then get the value of "ani/0".
struct DirResourceLoader {
  rootPath : String
}

///|
pub fn DirResourceLoader::new(rootPath : String) -> DirResourceLoader {
  { rootPath, }
}

///|
pub impl AsyncResourceLoader for DirResourceLoader with load_data(self, path) -> Json {
  let (child, rest) = if path.find("/") is Some(i) {
    (path.view(start_offset=0, end_offset=i), path.view(start_offset=i + 1))
  } else {
    (path, "")
  }
  let path = join_dir(self.rootPath, child.to_string() + ".json")
  let text : String = fetch_string(path)
  let root_value : Json = @json.parse(text)
  get_by_path(root_value, rest.to_string())
}

///|
extern "js" fn js_fetch_json_string(path : String) -> @js.Promise =
  #| (p) => fetch(p).then((res) => {
  #|  const contentType = res.headers.get('content-type') || '';
  #|  if (!contentType.includes('application/json')) {
  #|    throw new Error(`expected JSON response, got content-type: ${contentType}`);
  #|  }
  #|  return res.text();
  #|})

///|
async fn fetch_string(path : String) -> String {
  (js_fetch_json_string(path).wait() catch {
    @js.Error_(e) => {
      let message : String = e.get_with_string("message")
      fail("failed to fetch string: \{path}, error=\{message}")
    }
    e => fail("failed to fetch string: \{path}, error=\{e}")
  })
  |> @js.Value::cast
}

///|
fn join_dir(root : String, path : String) -> String {
  // remove '/' from the end of root and the beginning of path
  let root = root.strip_suffix("/").unwrap_or(root)
  let path = path.strip_prefix("/").unwrap_or(path)
  return "\{root}/\{path}"
}

///|
fn get_by_path(obj : Json, path : String) -> Json {
  if path.is_empty() {
    return obj
  }
  let parts = path.split("/")
  parts.fold(init=obj, fn(acc, part) {
    guard acc.as_object() is Some(obj) else {
      null // TODO: throw error
    }
    guard obj.get(part.to_string()) is Some(value) else {
      null // TODO: throw error
    }
    value
  })
}

///|
pub const OLD_BASE_URL : String = "https://maple-res.kkkiiox.work"
