struct OpenNpcShopHandler {
  module : Module
  charlook_getter : () -> @character.CharLook?
  inventory_getter : () -> @inventory.Inventory?
}

fn OpenNpcShopHandler::new(
  module : Module,
  charlook_getter : () -> @character.CharLook?,
  inventory_getter : () -> @inventory.Inventory?
) -> OpenNpcShopHandler {
  { module, charlook_getter, inventory_getter }
}

impl @net.PacketHandler for OpenNpcShopHandler with handle(
  self : OpenNpcShopHandler,
  recv : @net.InPacket
) -> Unit! {
  guard let Some(charlook) = (self.charlook_getter)() else { None => return  }
  guard let Some(inventory) = (self.inventory_getter)() else { None => return  }
  let npcid = recv.read_int!()
  let size = recv.read_short!()
  let items = []
  for i in 0..<size {
    let itemid = recv.read_int!()
    let price = recv.read_int!()
    let pitch = recv.read_int!()
    let time = recv.read_int!()
    recv.skip!(4)
    let norecharge = recv.read_short!() == 1
    if norecharge {
      let buyable = recv.read_short!()
      items.push({ id: itemid, price, pitch, time, charge_price: 0, buyable })
    } else {
      recv.skip!(4)
      let rechargeprice = recv.read_short!()
      let slotmax = recv.read_short!()
      items.push(
        {
          id: itemid,
          price,
          pitch,
          time,
          charge_price: rechargeprice,
          buyable: slotmax,
        },
      )
    }
  }
  let shop = UIShop::new(
    self.module.countset,
    charlook,
    inventory,
    npcid,
    items,
  )
  self.module.container.add_ui(@ui.Element::new(shop), true)
}

struct ShopItem {
  id : Int
  price : Int
  pitch : Int
  time : Int
  charge_price : Int
  buyable : Int
} derive(Show)
