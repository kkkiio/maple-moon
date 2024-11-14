extern "js" fn load_desc_async(
  self : AsyncResourceLoader,
  path : String
) -> PollableData =
  #| (l,p) => {
  #|   return l.loadDescAsync(p)
  #| }

extern "js" fn load_desc(self : ResourceLoader, path : String) -> RawData =
  #| (l,p) => {
  #|   return l.loadDesc(p)
  #| }

extern "js" fn as_jsonstring(v : RawData) -> String =
  #|(v)=> {
  #|  return JSON.stringify(v);
  #|}

extern "js" fn get_resource_loader(name : String) -> ResourceLoader =
  #| (n) => resource.get_loader(n)

extern "js" fn get_async_resource_loader(name : String) -> AsyncResourceLoader =
  #| (n) => resource.get_async_loader(n)
