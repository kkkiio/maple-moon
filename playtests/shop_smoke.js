const bot = globalThis.__bot;

const assert = (condition, message, data = {}) => {
  if (!condition) {
    const error = new Error(message);
    error.data = data;
    throw error;
  }
};

await bot.warp(100000101, 0, { timeoutFrames: 1200 });
await bot.idle(60);

const click = await bot.click_npc(1011000, { timeoutFrames: 900 });
assert(click.npcId === 1011000, "clicked the wrong shop NPC", { click });
assert(Number.isFinite(click.screenX), "shop NPC screen x is invalid", { click });
assert(Number.isFinite(click.screenY), "shop NPC screen y is invalid", { click });

let shop = null;
for (let attempt = 0; attempt < 180; attempt += 1) {
  await bot.idle(2);
  const state = JSON.parse(globalThis.$console.render_game_to_text());
  shop = state.shop ?? null;
  if (
    shop?.visible &&
    shop.open_shop_ready &&
    shop.resources_ready &&
    shop.render_entity_count > 0
  ) {
    break;
  }
}

assert(shop?.visible, "NPC shop did not become visible", { shop, click });
assert(shop.open_shop_ready, "NPC shop data did not finish loading", { shop, click });
assert(shop.resources_ready, "NPC shop UI resources did not load", { shop, click });
assert(shop.npc_id === 1011000, "NPC shop opened for the wrong NPC", { shop, click });
assert(shop.item_count === 13, "NPC shop has an unexpected item count", { shop, click });
assert(shop.render_entity_count > 0, "NPC shop did not render", { shop, click });

const openedShop = shop;
await bot.tap_key("Escape");
await bot.idle(4);
const closedShop = JSON.parse(globalThis.$console.render_game_to_text()).shop;
assert(!closedShop.visible, "NPC shop did not close with Escape", { closedShop });
assert(!closedShop.open_shop_ready, "NPC shop data remained open after close", {
  closedShop,
});
assert(closedShop.render_entity_count === 0, "NPC shop entities remained after close", {
  closedShop,
});

return {
  scenario: "shop_smoke",
  click,
  openedShop,
  closedShop,
};
