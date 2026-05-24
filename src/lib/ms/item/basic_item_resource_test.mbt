///|
struct MockBasicItemLoader {}

///|
fn basic_mock_icon(path : String) -> Json {
  { "__i": path, "__w": 1, "__h": 1, "origin": [0, 0] }
}

///|
fn basic_mock_item_entry(icon_path : String, icon_raw_path : String) -> Json {
  {
    "info": {
      "icon": basic_mock_icon(icon_path),
      "iconRaw": basic_mock_icon(icon_raw_path),
    },
  }
}

///|
pub impl @resource.AsyncResourceLoader for MockBasicItemLoader with fn load_data(
  self,
  path,
) -> Json? {
  ignore(self)
  Some(
    match path.to_owned() {
      "Consume/0200.img" =>
        {
          "02000000": basic_mock_item_entry(
            "images/Item/consume_icon.png", "images/Item/consume_icon_raw.png",
          ),
        }
      "Etc/0400.img" =>
        {
          "04000000": basic_mock_item_entry(
            "images/Item/etc_icon.png", "images/Item/etc_icon_raw.png",
          ),
        }
      p if p.has_prefix("Consume/") || p.has_prefix("Etc/") => {}
      _ => abort("unexpected item bundle path: \{path}")
    },
  )
}

///|
struct MockBasicStringLoader {}

///|
pub impl @resource.AsyncResourceLoader for MockBasicStringLoader with fn load_data(
  self,
  path,
) -> Json? {
  ignore(self)
  Some(
    match path.to_owned() {
      "Consume.img" => { "2000000": { "name": "apple", "desc": "red potion" } }
      "Etc.img" =>
        { "Etc": { "4000000": { "name": "ore", "desc": "gray ore" } } }
      "Eqp.img" | "Ins.img" | "Cash.img" => {}
      _ => abort("unexpected string bundle path: \{path}")
    },
  )
}

///|
test "basic item resource should preload consume/etc and install to cache" {
  let item_loader = @resource.AsyncLoader::new("item", loader=MockBasicItemLoader::{

  })
  let string_loader = @resource.AsyncLoader::new("string", loader=MockBasicStringLoader::{

  })
  @resource.register_async_loader("item", item_loader)
  @resource.register_async_loader("string", string_loader)
  set_item_data_system(ItemDataSystem::new(item_loader))

  let basic_resource = BasicItemResource::load(item_loader, string_loader)
  inspect(basic_resource.ids().length(), content="2")

  basic_resource.install()
  inspect(request_item_data(2000000).get_category(), content="Consume")
  inspect(request_item_data(4000000).get_category(), content="Etc")
}
