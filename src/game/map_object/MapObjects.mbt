///|
/// Manages a collection of map objects, organizing them by ID and layer.
///
/// `MapObjects` serves as a central registry for dynamic entities on a map, such as monsters, drops, or NPCs.
/// It provides mechanisms to:
/// - **Storage**: Efficient lookups by Object ID (OID).
/// - **Layering**: Tracking objects across different map layers (e.g. for collision or rendering sorting).
/// - **Lifecycle**: Handling updates, additions, and removals via `update()`.
/// - **Events**: Notifying listeners when objects are added, removed, or the collection is cleared.
struct MapObjects[T] {
  objects : Map[Int, T]
  layers : FixedArray[Map[Int, Unit]]
  event_listeners : Array[(MapObjectEvent[T]) -> Bool]
}

///|
pub enum MapObjectEvent[T] {
  Add(T)
  Remove(Int)
  Clear
}

///|
pub fn[T] MapObjects::MapObjects() -> MapObjects[T] {
  {
    objects: Map([]),
    layers: @graphics.map_layers.map(fn(_id) { Map([]) }),
    event_listeners: Array::new(),
  }
}

///|
pub fn[T] MapObjects::get(self : MapObjects[T], oid : Int) -> T? {
  self.objects.get(oid)
}

///|
pub fn[T : MapObject] MapObjects::update(
  self : MapObjects[T],
  physics : @physics.Physics,
) -> Unit {
  self.objects.each(fn(oid, mmo) {
    let oldlayer = mmo.get_layer()
    let newlayer = mmo.update(physics)
    if newlayer == -1 {
      self.remove(oid)
    } else if newlayer != oldlayer {
      self.layers[oldlayer].remove(oid)
      self.layers[newlayer].set(oid, ())
    }
  })
}

///|
pub fn[T : MapObject] MapObjects::clear(self : MapObjects[T]) -> Unit {
  self.objects.each(fn(_oid, obj) { obj.destroy() })
  self.objects.clear()
  self.layers.each(fn(layer) { layer.clear() })
  self.event_listeners.retain(fn(listener) { listener(MapObjectEvent::Clear) })
}

///|
pub fn[T] MapObjects::contains(self : MapObjects[T], oid : Int) -> Bool {
  self.objects.contains(oid)
}

///|
pub fn[T : MapObject] MapObjects::add(self : MapObjects[T], toadd : T) -> Unit {
  let oid = toadd.get_oid()
  let layer = toadd.get_layer()
  self.objects.set(oid, toadd)
  self.layers[layer].set(oid, ())
  self.event_listeners.retain(fn(listener) {
    listener(MapObjectEvent::Add(toadd))
  })
}

///|
pub fn[T : MapObject] MapObjects::remove(
  self : MapObjects[T],
  oid : Int,
) -> Unit {
  match self.objects.get(oid) {
    Some(mmo) => {
      mmo.destroy()
      let layer = mmo.get_layer()
      self.objects.remove(oid)
      self.layers[layer].remove(oid)
      self.event_listeners.retain(fn(listener) {
        listener(MapObjectEvent::Remove(oid))
      })
    }
    None => ()
  }
}

///|
pub fn[T] MapObjects::iter2(self : MapObjects[T]) -> Iter2[Int, T] {
  self.objects.iter2()
}

///|
pub fn[T] MapObjects::size(self : MapObjects[T]) -> Int {
  self.objects.length()
}

///|
pub fn[T] MapObjects::listen_object_changes(
  self : MapObjects[T],
  listener : (MapObjectEvent[T]) -> Bool,
) -> Unit {
  self.event_listeners.push(listener)
}
