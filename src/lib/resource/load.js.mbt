///|
extern "js" fn load_desc_async(
  self : AsyncResourceLoader,
  path : String
) -> PollableData =
  #| (l,p) => {
  #|   return l.loadDescAsync(p)
  #| }

///|
extern "js" fn load_desc(self : ResourceLoader, path : String) -> RawData =
  #| (l,p) => {
  #|   return l.loadDesc(p)
  #| }

///|
extern "js" fn as_jsonstring(v : RawData) -> String =
  #|(v)=> {
  #|  return JSON.stringify(v);
  #|}

///|
extern "js" fn get_resource_loader(name : String) -> ResourceLoader =
  #| (n) => resource.get_loader(n)

///|
extern "js" fn get_async_resource_loader(name : String) -> AsyncResourceLoader =
  #| (n) => resource.get_async_loader(n)

///|
extern "js" fn load_image_by_path(self : ImageLoader, path : String) -> Image =
  #| (l,p) => l.loadImageByPath(p)

///|
extern type DirResourceLoader

///|
pub extern "js" fn DirResourceLoader::new(url : String) -> DirResourceLoader =
  #| (u) => resource.new_dir_resource_loader(u)

///|
priv struct PrefixedLoader {
  prefix : String
  loader : DirResourceLoader
}

///|
extern "js" fn new_composite_async_resource_loader(
  prefixedLoaders : Array[PrefixedLoader],
  image_loader : ImageLoader
) -> AsyncResourceLoader =
  #| (p, l) => {
  #|   return resource.new_composite_async_resource_loader(p, l);
  #| }

///|
pub fn AsyncResourceLoader::new_composite_async_resource_loader(
  loaderMap : Map[String, DirResourceLoader],
  image_loader : ImageLoader
) -> AsyncResourceLoader {
  new_composite_async_resource_loader(
    loaderMap.iter().map(fn(kv) { { prefix: kv.0, loader: kv.1 } }).to_array(),
    image_loader,
  )
}
