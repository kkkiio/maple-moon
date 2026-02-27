///|
fn LocalServer::on_talk_to_npc(self : LocalServer, json : Json) -> Unit raise {
  let msg : @server_proto.TalkToNpcMessage = @json.from_json(json)
  match self.npc_id_by_oid.get(msg.oid) {
    Some(npc_id) =>
      match self.get_shop_by_npc_id(npc_id) {
        Some(shop) => {
          self.active_shop = Some(shop)
          self.send_server_message(shop)
        }
        None => ()
      }
    None => ()
  }
}

///|
fn LocalServer::on_npc_shop_action(
  self : LocalServer,
  json : Json,
) -> Unit raise {
  let msg : @server_proto.NpcShopActionMessage = @json.from_json(json)
  match msg.mode {
    0 => self.on_npc_shop_buy(msg)
    1 => self.on_npc_shop_sell(msg)
    2 => self.on_npc_shop_recharge(msg)
    3 => self.active_shop = None
    _ => self.send_shop_confirm(6)
  }
}

///|
fn LocalServer::send_shop_confirm(self : LocalServer, code : Int) -> Unit {
  self.send_server_message(@server_proto.ConfirmShopTransactionMessage::{
    code,
  })
}

///|
fn LocalServer::on_npc_shop_buy(
  self : LocalServer,
  msg : @server_proto.NpcShopActionMessage,
) -> Unit {
  guard self.active_shop is Some(shop) else {
    self.send_shop_confirm(6)
    return
  }
  guard msg.slot >= 0 && msg.slot < shop.items.length() else {
    self.send_shop_confirm(6)
    return
  }
  guard msg.qty > 0 else {
    self.send_shop_confirm(6)
    return
  }
  let item = shop.items[msg.slot]
  if item.id != msg.item_id {
    self.send_shop_confirm(6)
    return
  }
  if item.buyable > 0 && msg.qty > item.buyable {
    self.send_shop_confirm(1)
    return
  }
  let price = if item.price > 0 { item.price } else { 0 }
  let cost = price * msg.qty
  if self.player_meso < cost {
    self.send_shop_confirm(2)
    return
  }
  if not(self.add_item_to_inventory(item.id, msg.qty)) {
    self.send_shop_confirm(3)
    return
  }
  self.player_meso -= cost
  self.save_character_inventory_snapshot()
  self.save_character_core_snapshot()
  self.send_server_message(@server_proto.ChangeStatsMesoMessage::{
    meso: self.player_meso,
  })
  self.send_shop_confirm(0)
}

///|
fn LocalServer::on_npc_shop_sell(
  self : LocalServer,
  msg : @server_proto.NpcShopActionMessage,
) -> Unit {
  guard self.active_shop is Some(_) else {
    self.send_shop_confirm(6)
    return
  }
  let qty = if msg.qty > 0 { msg.qty } else { 1 }
  guard @server_proto.InventoryType::by_item_id(msg.item_id) is Some(invtype) else {
    self.send_shop_confirm(5)
    return
  }
  guard self.player_items.get(invtype) is Some(tab_items) else {
    self.send_shop_confirm(5)
    return
  }
  guard tab_items.get(msg.slot) is Some((stored_item_id, stored_count)) else {
    self.send_shop_confirm(5)
    return
  }
  if stored_item_id != msg.item_id {
    self.send_shop_confirm(5)
    return
  }
  if stored_count <= 0 {
    self.send_shop_confirm(5)
    return
  }
  let sell_qty = if qty <= stored_count { qty } else { stored_count }
  let remain = stored_count - sell_qty
  if remain > 0 {
    tab_items.set(msg.slot, (stored_item_id, remain))
  } else {
    tab_items.remove(msg.slot) |> ignore
  }
  self.send_server_message(@server_proto.ModifyInventoryItemMessage::{
    item: @server_proto.InventoryItemEntry::Item(
      invtype~,
      slot=msg.slot,
      id=stored_item_id,
      cash=false,
      expire=0,
      count=remain,
      owner="",
      flag=0,
    ),
  })
  let unit_price = 1
  self.player_meso += unit_price * sell_qty
  self.save_character_inventory_snapshot()
  self.save_character_core_snapshot()
  self.send_server_message(@server_proto.ChangeStatsMesoMessage::{
    meso: self.player_meso,
  })
  self.send_shop_confirm(8)
}

///|
fn LocalServer::on_npc_shop_recharge(
  self : LocalServer,
  _msg : @server_proto.NpcShopActionMessage,
) -> Unit {
  guard self.active_shop is Some(_) else {
    self.send_shop_confirm(6)
    return
  }
  self.send_shop_confirm(8)
}

///|
fn LocalServer::add_item_to_inventory(
  self : LocalServer,
  item_id : Int,
  quantity : Int,
) -> Bool {
  if quantity <= 0 {
    return false
  }
  guard @server_proto.InventoryType::by_item_id(item_id) is Some(invtype) else {
    return false
  }
  guard self.player_items.get(invtype) is Some(tab_items) else { return false }
  let stackable = invtype != @server_proto.InventoryType::EQUIP
  if stackable {
    for slot, it in tab_items {
      let (existing_item_id, existing_count) = it
      if existing_item_id == item_id {
        let next_count = existing_count + quantity
        tab_items.set(slot, (item_id, next_count))
        self.send_server_message(@server_proto.ModifyInventoryItemMessage::{
          item: @server_proto.InventoryItemEntry::Item(
            invtype~,
            slot~,
            id=item_id,
            cash=false,
            expire=0,
            count=next_count,
            owner="",
            flag=0,
          ),
        })
        return true
      }
    }
    guard find_next_empty_slot(
        tab_items,
        self.slot_max_by_tab.get(invtype).unwrap_or(0),
      )
      is Some(slot) else {
      return false
    }
    tab_items.set(slot, (item_id, quantity))
    self.send_server_message(@server_proto.ModifyInventoryItemMessage::{
      item: @server_proto.InventoryItemEntry::Item(
        invtype~,
        slot~,
        id=item_id,
        cash=false,
        expire=0,
        count=quantity,
        owner="",
        flag=0,
      ),
    })
    return true
  }
  let mut inserted = 0
  while inserted < quantity {
    guard find_next_empty_slot(
        tab_items,
        self.slot_max_by_tab.get(invtype).unwrap_or(0),
      )
      is Some(slot) else {
      return false
    }
    tab_items.set(slot, (item_id, 1))
    self.send_server_message(@server_proto.ModifyInventoryItemMessage::{
      item: @server_proto.InventoryItemEntry::Item(
        invtype~,
        slot~,
        id=item_id,
        cash=false,
        expire=0,
        count=1,
        owner="",
        flag=0,
      ),
    })
    inserted += 1
  }
  true
}
