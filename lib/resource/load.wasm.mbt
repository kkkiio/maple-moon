///|
fn load_desc_async(self : AsyncResourceLoader, path : String) -> PollableData = "resource" "load_desc_async"

///|
fn load_desc(self : ResourceLoader, path : String) -> RawData = "resource" "load_desc"

///|
fn as_jsonstring(v : RawData) -> String = "resource" "as_jsonstring"

///|
fn get_async_resource_loader(name : String) -> AsyncResourceLoader = "resource" "get_async_loader"

///|
fn get_resource_loader(name : String) -> ResourceLoader = "resource" "get_loader"

///|
fn load_image_by_path(self : ImageLoader, path : String) -> Image = "resource" "load_image_by_path"
