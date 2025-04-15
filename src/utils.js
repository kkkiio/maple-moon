export const pollMod = (mod, fKey, game) => {
    setTimeout(() => {
        const f = game[fKey];
        const m = f();
        if (m) {
            mod.value = m;
        } else {
            pollMod(mod, fKey, game);
        }
    }, 1000);
};
