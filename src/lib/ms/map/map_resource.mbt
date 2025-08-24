///|
struct MapTilesObjsNxResource {
  layers : @resource.MapBasedArray[LayerNxResource]
  back : BackgroundsResource
  portal : @resource.MapBasedArray[PortalMarker]
}

///|
pub impl @json.FromJson for MapTilesObjsNxResource with from_json(json, path) {
  let layers : @resource.MapBasedArray[LayerNxResource] = @json.from_json(
    json,
    path~,
  )
  guard json.as_object() is Some(obj) else {
    raise @json.JsonDecodeError((path, "expected object"))
  }
  let back : BackgroundsResource = @json.from_json(
    obj.get("back").or(Json::null()),
    path=path.add_key("back"),
  )
  let portal : @resource.MapBasedArray[PortalMarker] = @json.from_json(
    obj.get("portal").or(Json::null()),
    path=path.add_key("portal"),
  )
  { layers, back, portal }
}

///|
struct LayerNxResource {
  info : @resource.Nullable[MapLayerInfoResource]
  tile : @resource.Nullable[@resource.MapBasedArray[TileResource]]
  obj : @resource.Nullable[@resource.MapBasedArray[ObjNxResource]]
} derive(@json.FromJson)

///|
test "parse empty layer" {
  let data =
    #|{
    #|    "info": null,
    #|    "obj": null,
    #|    "tile": null
    #|}
  let json = @json.parse(data)
  let layer : LayerNxResource = @json.from_json(json)
  @json.inspect(layer.unwrap(), content={ "tile": [], "obj": [] })
}

///|
struct TileResource {
  no : Int
  u : String
  x : Int
  y : Int
  zM : Int
} derive(@json.FromJson, ToJson)

///|
priv struct ObjNxResource {
  f : @resource.IntBool
  l0 : String
  l1 : String
  l2 : String
  oS : String
  x : Int
  y : Int
  z : Int
  zM : Int
} derive(@json.FromJson)

///|
pub fn MapTilesObjsNxResource::unwrap(
  self : MapTilesObjsNxResource
) -> MapTilesObjsResource {
  let layers = self.layers.inner().map(fn(layer) { layer.unwrap() })
  { layers, back: self.back, portal: self.portal.inner() }
}

///|
pub fn LayerNxResource::unwrap(self : LayerNxResource) -> LayerResource {
  {
    info: self.info.inner().map(fn(it) { { tS: it.tS } }),
    tile: self.tile.inner().map_or([], fn(it) { it.inner() }),
    obj: self.obj.inner().map_or([], fn(it) {
      it.inner().map(fn(obj) {
        {
          f: obj.f.inner(),
          l0: obj.l0,
          l1: obj.l1,
          l2: obj.l2,
          oS: obj.oS,
          x: obj.x,
          y: obj.y,
          z: obj.z,
          zM: obj.zM,
        }
      })
    }),
  }
}

///|
struct MapTilesObjsResource {
  layers : Array[LayerResource]
  back : BackgroundsResource
  portal : Array[PortalMarker]
} derive(ToJson)

///|
priv struct MapLayerInfoResource {
  tS : String
} derive(@json.FromJson, ToJson)

///|
struct ObjResource {
  f : Bool
  l0 : String
  l1 : String
  l2 : String
  oS : String
  x : Int
  y : Int
  z : Int
  zM : Int
} derive(ToJson)

///|
struct LayerResource {
  info : MapLayerInfoResource?
  tile : Array[TileResource]
  obj : Array[ObjResource]
} derive(ToJson)
