///|
#external
type AsyncResourceLoader

///|
fn get_image_loader(self : AsyncResourceLoader) -> ImageLoader = "resource" "get_image_loader"

///|
struct AsyncLoader {
  name : String
  loader : AsyncResourceLoader
}

///|
pub fn AsyncLoader::new(
  name : String,
  loader? : AsyncResourceLoader
) -> AsyncLoader {
  { name, loader: loader.or_else(fn() { get_async_resource_loader(name) }) }
}

///|
pub async fn AsyncLoader::load_res_async(
  self : AsyncLoader,
  path : Array[String]
) -> NxNode raise {
  let promise = self.loader.load_data(join_path(path))
  let data : RawData = try promise.wait() |> @js.Value::cast catch {
    e => fail("failed to load resource: \{e}, path=\{path}")
  }
  {
    loader_name: self.name,
    image_loader: Some(self.loader.get_image_loader()),
    name: path.last().unwrap(),
    desc: data.as_moonjson(),
    path: path |> @immut/array.from_array,
  }
}

///|
pub fn AsyncResourceLoader::new_async_resource_loader(
  loader : DirResourceLoader
) -> AsyncResourceLoader = "resource" "new_async_resource_loader"
