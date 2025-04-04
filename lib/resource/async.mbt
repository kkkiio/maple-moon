///|
extern type PollableData

///|
fn is_ready(self : PollableData) -> Bool = "resource" "is_ready"

///|
fn get_result(self : PollableData) -> RawData = "resource" "get_result"

///|
extern type AsyncResourceLoader

///|
fn get_image_loader(self : AsyncResourceLoader) -> ImageLoader = "resource" "get_image_loader"

///|
struct AsyncLoader {
  name : String
  loader : AsyncResourceLoader
}

///|
pub fn AsyncLoader::new(name : String) -> AsyncLoader {
  { name, loader: get_async_resource_loader(name) }
}

///|
pub fn AsyncLoader::load_res(
  self : AsyncLoader,
  path : Array[String]
) -> @utils.Future[NxNode] {
  let pollable = self.loader.load_desc_async(join_path(path))
  @utils.Future::new(fn() {
    if pollable.is_ready() {
      Some({
        loader_name: self.name,
        image_loader: Some(self.loader.get_image_loader()),
        name: path.last().unwrap(),
        desc: get_result(pollable).as_moonjson(),
        path: path |> @immut/array.from_array,
      })
    } else {
      None
    }
  })
}
