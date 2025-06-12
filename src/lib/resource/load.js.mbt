///|
extern "js" fn load_data(
  self : AsyncResourceLoader,
  path : String
) -> @js.Promise =
  #| (l,p) => {
  #|   return l.loadData(p)
  #| }

///|
extern "js" fn load_desc(self : SyncResourceLoader, path : String) -> RawData =
  #| (l,p) => {
  #|   return l.loadDesc(p)
  #| }

///|
extern "js" fn as_jsonstring(v : RawData) -> String =
  #|(v)=> {
  #|  return JSON.stringify(v);
  #|}

///|
extern "js" fn SyncResourceLoader::make(url : String) -> @js.Promise =
  #| (u) => resource.make_file_resource_loader(u)

///|
pub extern "js" fn ImageLoader::new_bid_image_loader(
  url : String
) -> ImageLoader =
  #| (u) => resource.new_bid_image_loader(u)

///|
extern "js" fn get_async_resource_loader(name : String) -> AsyncResourceLoader =
  #| (n) => resource.get_async_loader(n)

///|
pub extern "js" fn load_image_by_path(
  self : ImageLoader,
  path : String
) -> Image =
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
  prefixedLoaders : Array[PrefixedLoader]
) -> AsyncResourceLoader =
  #| (p) => {
  #|   return resource.new_composite_async_resource_loader(p);
  #| }

///|
pub fn AsyncResourceLoader::new_composite_async_resource_loader(
  loaderMap : Map[String, DirResourceLoader]
) -> AsyncResourceLoader {
  new_composite_async_resource_loader(
    loaderMap.iter().map(fn(kv) { { prefix: kv.0, loader: kv.1 } }).to_array(),
  )
}
