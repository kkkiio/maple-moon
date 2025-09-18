///|
struct NxMapTilesObjs {
  layers : Array[NxLayer]
  back : BackgroundsResource
  portal : Array[PortalMarker]
}

///|
pub impl @json.FromJson for NxMapTilesObjs with from_json(json, path) {
  let layers = @resource.parse_map_based_array(json, path~)
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "expected object"))
  }
  let back : BackgroundsResource = if obj.get("back") is Some(back) {
    @json.from_json(back, path=path.add_key("back"))
  } else {
    BackgroundsResource([])
  }
  let portal : Array[PortalMarker] = if obj.get("portal") is Some(portal) {
    @resource.parse_map_based_array(portal, path=path.add_key("portal"))
  } else {
    []
  }
  { layers, back, portal }
}

///|
struct NxLayer {
  info : MapLayerInfoResource?
  tile : Array[NxTileRef]
  obj : Array[NxObj]
} derive(Show)

///|
pub impl @json.FromJson for NxLayer with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "expected object"))
  }
  let info = if obj is { "info": Object(_) as info, .. } {
    Some(@json.from_json(info, path=path.add_key("info")))
  } else {
    None
  }
  let tile = if obj is { "tile": Object(_) as tile, .. } {
    @resource.parse_map_based_array(tile, path=path.add_key("tile"))
  } else {
    []
  }
  let obj = if obj is { "obj": Object(_) as obj, .. } {
    @resource.parse_map_based_array(obj, path=path.add_key("obj"))
  } else {
    []
  }
  { info, tile, obj }
}

///|
test "parse empty layer" {
  let data =
    #|{
    #|    "info": null,
    #|    "obj": null,
    #|    "tile": null
    #|}
  let json = @json.parse(data)
  let layer : NxLayer = @json.from_json(json)
  inspect(layer, content="{info: None, tile: [], obj: []}")
}

///|
struct NxTileRef {
  /// tile index
  no : Int
  /// group name
  u : String
  x : Int
  y : Int
  zM : Int
} derive(@json.FromJson, Show)

///|
pub struct NxObj {
  f : Bool
  l0 : String
  l1 : String
  l2 : String
  oS : String
  x : Int
  y : Int
  z : Int
  zM : Int
} derive(Show)

///|
pub impl @json.FromJson for NxObj with from_json(json, path) {
  match json {
    {
      "f": Number(f, ..),
      "l0": String(l0),
      "l1": String(l1),
      "l2": String(l2),
      "oS": String(oS),
      "x": Number(x, ..),
      "y": Number(y, ..),
      "z": Number(z, ..),
      "zM": Number(zM, ..),
      ..
    } =>
      {
        f: f != 0,
        l0,
        l1,
        l2,
        oS,
        x: x.to_int(),
        y: y.to_int(),
        z: z.to_int(),
        zM: zM.to_int(),
      }
    _ => raise @json.JsonDecodeError((path, "missing obj fields"))
  }
}

///|
priv struct MapLayerInfoResource {
  tS : String
} derive(@json.FromJson, Show)
