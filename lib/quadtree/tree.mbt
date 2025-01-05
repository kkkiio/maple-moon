///|
pub(all) enum Direction {
  BL
  TR
  TL
  BR
} derive(Eq, Show)

///|
pub(open) trait QuadCompare {
  compare_to(Self, Self) -> Direction
}

///|
pub struct Node[K, V] {
  key : K
  value : V
  priv mut parent : Node[K, V]?
  priv mut bl : Node[K, V]?
  priv mut tr : Node[K, V]?
  priv mut tl : Node[K, V]?
  priv mut br : Node[K, V]?
}

///|
struct Tree[K, V] {
  nodes : Map[K, Node[K, V]]
  mut root : Node[K, V]?
}

///|
pub fn Tree::new[K, V]() -> Tree[K, V] {
  { nodes: Map::new(), root: None }
}

///|
pub fn add[K : Hash + Eq, V : QuadCompare](
  self : Tree[K, V],
  key : K,
  value : V
) -> Bool {
  if self.nodes.contains(key) {
    return false
  }
  let node = {
    key,
    value,
    parent: None,
    bl: None,
    tr: None,
    tl: None,
    br: None,
  }
  self.set_link(self.root, node)
  self.nodes.set(key, node)
  true
}

///|
pub fn ceiling_key[K : Hash + Eq, V : QuadCompare](
  self : Tree[K, V],
  value : V
) -> K? {
  self.ceiling_entry(value).map(fn(n) { n.key })
}

///|
pub fn ceiling_entry[K : Hash + Eq, V : QuadCompare](
  self : Tree[K, V],
  value : V
) -> Node[K, V]? {
  self.find_ceiling_from(self.root, value)
}

///|
fn find_ceiling_from[K : Hash + Eq, V : QuadCompare](
  self : Tree[K, V],
  start : Node[K, V]?,
  value : V
) -> Node[K, V]? {
  let start_node = match start {
    Some(n) => n
    None => return None
  }
  match value.compare_to(start_node.value) {
    TR =>
      if is_enough(start_node.value, value) {
        start
      } else {
        self.find_ceiling_from(start_node.tr, value) // find bigger
      }
    BR =>
      match self.find_ceiling_from(start_node.br, value) { // try lower-height
        Some(_) as res => res
        None =>
          if is_enough(start_node.value, value) {
            start
          } else {
            self.find_ceiling_from(start_node.tr, value) // find bigger
          }
      }
    TL =>
      match self.find_ceiling_from(start_node.tl, value) { // try lower-width
        Some(_) as res => res
        None =>
          if is_enough(start_node.value, value) {
            start
          } else {
            self.find_ceiling_from(start_node.tr, value) // find bigger
          }
      }
    BL => // start_node is enough, try better-fit before return start_node
      match self.find_ceiling_from(start_node.bl, value) { // try smaller
        Some(_) as res => res
        None =>
          match self.find_ceiling_from(start_node.br, value) { // try lower-height
            Some(_) as res => res
            None =>
              match self.find_ceiling_from(start_node.tl, value) { // try lower-width
                Some(_) as res => res
                None => start
              }
          }
      }
  }
}

///|
pub fn remove[K : Hash + Eq, V : QuadCompare](self : Tree[K, V], key : K) -> V? {
  let node = match self.nodes.get(key) {
    Some(n) => n
    None => return None
  }
  self.nodes.remove(key)
  let parent = node.parent
  match parent {
    Some(p) => p.remove_child(key)
    None => self.root = None
  }
  [node.bl, node.tr, node.tl, node.br].each(fn(it) {
    match it {
      Some(child) => {
        let start = match parent {
          Some(_) => parent
          None => self.root
        }
        self.set_link(start, child)
      }
      _ => ()
    }
  })
  Some(node.value)
}

///|
pub fn clear[K, V](self : Tree[K, V]) -> Unit {
  self.nodes.clear()
  self.root = None
}

///|
fn set_link[K : Hash + Eq, V : QuadCompare](
  self : Tree[K, V],
  start : Node[K, V]?,
  node : Node[K, V]
) -> Unit {
  if self.root.is_empty() {
    self.root = Some(node)
    node.parent = None
    return
  }
  loop start {
    Some(next) => continue next.add_or_next(node)
    None => break
  }
}

///|
fn add_or_next[K : Hash + Eq, V : QuadCompare](
  self : Node[K, V],
  child : Node[K, V]
) -> Node[K, V]? {
  let cmp = child.value.compare_to(self.value)
  match cmp {
    BL => {
      let prev = self.bl
      if self.bl.is_empty() {
        self.bl = Some(child)
        child.parent = Some(self)
      }
      prev
    }
    TR => {
      let prev = self.tr
      if self.tr.is_empty() {
        self.tr = Some(child)
        child.parent = Some(self)
      }
      prev
    }
    TL => {
      let prev = self.tl
      if self.tl.is_empty() {
        self.tl = Some(child)
        child.parent = Some(self)
      }
      prev
    }
    BR => {
      let prev = self.br
      if self.br.is_empty() {
        self.br = Some(child)
        child.parent = Some(self)
      }
      prev
    }
  }
}

///|
fn remove_child[K : Hash + Eq, V : QuadCompare](
  self : Node[K, V],
  key : K
) -> Unit {
  match self.bl {
    Some(k) =>
      if k.key == key {
        self.bl = None
        return
      }
    _ => ()
  }
  match self.tr {
    Some(k) =>
      if k.key == key {
        self.tr = None
        return
      }
    _ => ()
  }
  match self.tl {
    Some(k) =>
      if k.key == key {
        self.tl = None
        return
      }
    _ => ()
  }
  match self.br {
    Some(k) =>
      if k.key == key {
        self.br = None
        return
      }
    _ => ()
  }
}

///|
fn is_enough[T : QuadCompare](my : T, other : T) -> Bool {
  return my.compare_to(other) == Direction::TR
}
