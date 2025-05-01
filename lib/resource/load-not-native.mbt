///|
fn ResourceLoader::get_image_loader(self : ResourceLoader) -> ImageLoader = "resource" "get_image_loader"

///|
pub fn get_default_image_loader() -> ImageLoader = "resource" "get_default_image_loader"

///|
fn load_image(self : ImageLoader, bid : Int) -> Image = "resource" "load_image"
