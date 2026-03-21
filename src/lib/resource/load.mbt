///|
pub fn ImageLoader::load_image(self : ImageLoader, bid : Int) -> Image = "resource" "load_image"

///|
pub fn ImageLoader::get_path_image_loader() -> ImageLoader = "resource" "get_path_image_loader"

///|
pub(open) trait AsyncResourceLoader {
  async load_data(self : Self, path : StringView) -> Json
}

///|
struct AsyncLoader {
  loader : &AsyncResourceLoader
}

///|
pub fn AsyncLoader::new(
  _name : String,
  loader~ : &AsyncResourceLoader,
  base_url? : String = OLD_BASE_URL,
  image_base_url? : String = base_url,
) -> AsyncLoader {
  { loader: SpritesheetMergeLoader::new(loader, base_url, image_base_url) }
}

///|
pub async fn AsyncLoader::load_resource(
  self : AsyncLoader,
  path : ArrayView[String],
) -> Json {
  self.loader.load_data(join_path(path))
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
  let root_value : Json = fetch_json(path)
  get_by_path(root_value, rest.to_string())
}

///|
#external
priv type Response

///|
extern "js" fn Response::text(self : Response) -> @js_async.Promise[String] =
  #| (r) => r.text()

///|
extern "js" fn Response::content_type(self : Response) -> String =
  #| (r) => r.headers.get('content-type') || ''

///|
extern "js" fn Response::is_ok(self : Response) -> Bool =
  #| (r) => r.ok

///|
extern "js" fn Response::status(self : Response) -> Int =
  #| (r) => r.status

///|
extern "js" fn js_fetch(path : String) -> @js_async.Promise[Response] =
  #| (p) => fetch(p)

///|
async fn fetch_json(path : String) -> Json {
  let response = js_fetch(path).wait() catch {
    e => fail("failed to fetch string: \{path}, error=\{e}")
  }
  if !response.is_ok() {
    fail("failed to fetch string: \{path}, status=\{response.status()}")
  }
  let content_type = response.content_type()
  if !content_type.contains("application/json") {
    fail(
      "expected JSON response, got content-type: \{content_type}, path=\{path}",
    )
  }
  response.text().wait() |> @json.parse
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
    guard acc is Object(obj) else {
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
