type Pollable

fn is_ready(self : Pollable) -> Bool = "resource" "is_ready"

fn get_result(self : Pollable) -> JsJson = "resource" "get_result"

type AsyncResourceLoader

extern "js" fn load_desc(self : AsyncResourceLoader, path : String) -> Pollable =
  #| (l,p) => {
  #|   return l.loadDesc(p)
  #| }

fn get_image_loader(self : AsyncResourceLoader) -> ImageLoader = "resource" "get_image_loader"

fn get_async_resource_loader(name : Js_string) -> AsyncResourceLoader = "resource" "get_async_loader"

struct AsyncLoader {
  name : String
  loader : AsyncResourceLoader
}

pub fn AsyncLoader::new(name : String) -> AsyncLoader {
  { name, loader: get_async_resource_loader(name.to_js_string()) }
}

pub fn load_res(self : AsyncLoader, path : Array[String]) -> LoadingResource {
  {
    loader: self,
    name: path.last().unwrap(),
    path: path |> @immut/array.from_array,
    pollable: self.loader.load_desc(join_path(path)),
  }
}

struct LoadingResource {
  loader : AsyncLoader
  name : String
  path : @immut/array.T[String]
  pollable : Pollable
}

pub fn poll(self : LoadingResource) -> NxNode? {
  if is_ready(self.pollable) {
    Some(
      {
        loader_name: self.loader.name,
        image_loader: self.loader.loader.get_image_loader(),
        name: self.name,
        desc: get_result(self.pollable).as_moonjson(),
        path: self.path,
      },
    )
  } else {
    None
  }
}
