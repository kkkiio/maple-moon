///|
struct CountingItemBundleLoader {
  counts : Ref[Map[String, Int]]
}

///|
fn CountingItemBundleLoader::new() -> CountingItemBundleLoader {
  { counts: Ref::new(Map::new()) }
}

///|
fn CountingItemBundleLoader::increment(
  self : CountingItemBundleLoader,
  path : String,
) -> Unit {
  let next = self.counts.val.get(path).unwrap_or(0) + 1
  self.counts.val.set(path, next)
}

///|
fn CountingItemBundleLoader::get_count(
  self : CountingItemBundleLoader,
  path : String,
) -> Int {
  self.counts.val.get(path).unwrap_or(0)
}

///|
fn mock_icon(path : String) -> Json {
  { "__i": path, "__w": 1, "__h": 1, "origin": [0, 0] }
}

///|
fn mock_item_entry(icon_path : String, icon_raw_path : String) -> Json {
  {
    "info": {
      "icon": mock_icon(icon_path),
      "iconRaw": mock_icon(icon_raw_path),
    },
  }
}

///|
fn mock_consume_0299_bundle_json() -> Json {
  {
    "02999998": mock_item_entry(
      "images/Item/mock_1.png", "images/Item/mock_2.png",
    ),
    "02999999": mock_item_entry(
      "images/Item/mock_3.png", "images/Item/mock_4.png",
    ),
  }
}

///|
struct MockStringLoader {}

///|
fn MockStringLoader::new() -> MockStringLoader {
  MockStringLoader::{  }
}

///|
impl @resource.AsyncResourceLoader for CountingItemBundleLoader with load_data(
  self,
  path,
) -> Json {
  let key = path.to_string()
  self.increment(key)
  match key {
    "Consume/0299.img" => mock_consume_0299_bundle_json()
    _ => fail("unexpected item bundle path: \{key}")
  }
}

///|
impl @resource.AsyncResourceLoader for MockStringLoader with load_data(
  self,
  path,
) -> Json {
  ignore(self)
  match path.to_string() {
    "Consume.img" =>
      {
        "29999998": { "name": "mock item 1", "desc": "mock desc 1" },
        "29999999": { "name": "mock item 2", "desc": "mock desc 2" },
      }
    _ => null
  }
}

///|
async test "item data loader should not request same bundle json twice" {
  let counting_loader = CountingItemBundleLoader::new()
  let async_loader = @resource.AsyncLoader::new("item", loader=counting_loader)
  @resource.register_async_loader("character", async_loader)
  @resource.register_async_loader(
    "string",
    @resource.AsyncLoader::new("string", loader=MockStringLoader::new()),
  )

  ignore(ItemData::load_item_data_with_loader(2999998, async_loader))
  ignore(ItemData::load_item_data_with_loader(2999999, async_loader))

  inspect(counting_loader.get_count("Consume/0299.img"), content="1")
}
