struct ModifyInventoryHandler {
  inventory : Inventory
  player_getter : () -> @player.Player?
}

pub fn ModifyInventoryHandler::new(
  inventory : Inventory,
  player_getter : () -> @player.Player?
) -> ModifyInventoryHandler {
  { inventory, player_getter }
}

struct Mod {
  mode : Modification
  t : TypeId
  pos : Int
  arg : Int
}

pub fn handle(self : ModifyInventoryHandler, recv : @net.InPacket) -> Unit! {
  let inventory = self.inventory
  guard let Some(player) = (self.player_getter)() else { None => return  }
  recv.read_bool!() |> ignore // 'updatetick'
  let mods = Array::new()
  let size = recv.read_byte!()
  for i in 0..<size {
    let mut mode = recv.read_byte!() |> Modification::from_int |> Option::unwrap
    let t = TypeId::by_value(recv.read_byte!()) |> Option::unwrap
    let pos = recv.read_short!()
    let mut arg = 0
    match mode {
      Modification::ADD => parse_item!(recv, t, pos, inventory)

      // if (auto keyconfig = UI::get().get_element<UIKeyConfig>()) {
      //     let count_now =
      //         inventory.get_item_count(mod.type, mod.pos);
      //     keyconfig.update_item_count(mod.type,
      //                                        mod.pos,
      //                                        count_now);
      // }

      Modification::CHANGE_COUNT => {
        arg = recv.read_short!()
        let count_before = inventory.get_item_count(t, pos)
        let count_now = arg
        inventory.modify(t, pos, mode, arg, Movement::MOVE_NONE)

        // TODO: ui

        if count_before < count_now {
          mode = Modification::ADD_COUNT
        }
      }
      Modification::SWAP => arg = recv.read_short!()
      Modification::REMOVE =>
        // TODO: ui
        inventory.modify(t, pos, mode, arg, Movement::MOVE_INTERNAL)
    }
    mods.push({ mode, t, pos, arg })
  }
  let move = if recv.available() {
    Movement::from_int(recv.read_byte!()).unwrap()
  } else {
    Movement::MOVE_INTERNAL
  }
  for mod in mods {
    if mod.mode == Modification::SWAP {
      inventory.modify(mod.t, mod.pos, mod.mode, mod.arg, move)
    }

    // TODO: shop

    match move {
      Movement::MOVE_INTERNAL =>
        match mod.t {
          TypeId::EQUIPPED => {
            // TODO: ui
            change_equip!(inventory, player, -mod.pos)
            change_equip!(inventory, player, -mod.arg)
          }
          TypeId::EQUIP
          | TypeId::USE | TypeId::SETUP | TypeId::ETC | TypeId::CASH =>
            // TODO: ui
            ()
        }
      Movement::MOVE_EQUIP | Movement::MOVE_UNEQUIP =>
        if mod.pos < 0 {
          // TODO: ui
          change_equip!(inventory, player, -mod.pos)
        } else if mod.arg < 0 {
          // TODO: ui
          change_equip!(inventory, player, -mod.arg)
        }
    }
  }
  player.recalc_stats!(true)
  // UI::get().enable();
}

fn change_equip(
  inventory : Inventory,
  player : @player.Player,
  slot : Int
) -> Unit! {
  match inventory.get_item_id(TypeId::EQUIPPED, slot) {
    0 => player.get_look().remove_equip(@slot.Id::from_int(slot))
    itemid => player.get_look().add_equip!(itemid)
  }
}
