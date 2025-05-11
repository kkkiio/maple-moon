import { get_module } from 'lib/ffi/ffi.js';
export const pollMod = (mod, name, game) => {
    setTimeout(() => {
        const m = get_module(game, name);
        if (m) {
            mod.value = m;
        } else {
            pollMod(mod, name, game);
        }
    }, 1000);
};
