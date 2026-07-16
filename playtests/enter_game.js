const bot = globalThis.__bot;

const assert = (condition, message, data = {}) => {
  if (!condition) {
    const error = new Error(message);
    error.data = data;
    throw error;
  }
};

await bot.idle(120);

const state = bot.state();
assert(state.phase === "GameActive", "game is not active after entering the initial map", state);
assert(Number.isInteger(state.mapId) && state.mapId > 0, "initial map id is invalid", state);
assert(state.player, "player is missing after entering the initial map", state);
assert(Number.isFinite(state.player.x), "player x coordinate is invalid", state);
assert(Number.isFinite(state.player.y), "player y coordinate is invalid", state);
assert(Number.isFinite(state.player.hp) && state.player.hp > 0, "player hp is invalid", state);
assert(state.action === null, "bot action is still pending after entering the initial map", state);

return {
  scenario: "enter_game",
  mapId: state.mapId,
  player: state.player,
};
