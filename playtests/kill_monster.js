const bot = globalThis.__bot;

const assert = (condition, message, data = {}) => {
  if (!condition) {
    const error = new Error(message);
    error.data = data;
    throw error;
  }
};

await bot.warp(100010000, 0, { timeoutFrames: 1200 });
await bot.idle(60);

let state = bot.state();
assert(state.phase === "GameActive", "game is not active after mob map warp", state);
assert(state.mapId === 100010000, "expected Henesys Hunting Ground I", state);
assert(state.aliveMonsters > 0, "expected monsters on mob map", state);

let target = bot.nearest_monster();
assert(target, "nearest_monster returned null", state);

const approachX = target.x > state.player.x ? target.x - 56 : target.x + 56;
await bot.walk_to(approachX, target.y, { timeoutFrames: 1600 });

target = bot.nearest_monster();
assert(target, "nearest_monster returned null after approach", bot.state());
bot.telemetry.log("kill target selected", target);

await bot.attack_target(target.oid, { timeoutFrames: 1800 });
await bot.idle(20);

state = bot.state();
const after = bot.nearest_monster();
assert(!after || after.oid !== target.oid, "target monster is still present after attack_target", {
  target,
  after,
  state,
});

return {
  scenario: "kill_monster",
  killedOid: target.oid,
  remainingMonsters: state.aliveMonsters,
  player: state.player,
};
