if (GetCurrentResourceName() === "SecureServe") return;

const encryption_key = "c4a2ec5dc103a3f730460948f2e3c01df39ea4212bc2c82f";

function encryptDecrypt(input) {
    const s = String(input), r = [];
    for (let i = 0; i < s.length; i++) {
        const c = s.charCodeAt(i), k = encryption_key.charCodeAt(i % encryption_key.length);
        r.push(String.fromCharCode((c + k) % 256));
    }
    return r.join("");
}

function decrypt(input) {
    const s = String(input), r = [];
    for (let i = 0; i < s.length; i++) {
        const c = s.charCodeAt(i), k = encryption_key.charCodeAt(i % encryption_key.length);
        r.push(String.fromCharCode((c - k) % 256));
    }
    return r.join("");
}

const _onNet = onNet;
const _emitNet = emitNet;
const events_to_listen = {};

if (IsDuplicityVersion()) {
    globalThis.onNet = (event_name, handler) => {
        const enc_event_name = encryptDecrypt(event_name);
        events_to_listen[event_name] = enc_event_name;
        _onNet(event_name, () => {
            const src = global.source;
            if (GetPlayerPing(src) > 0) {
                exports["SecureServe"].module_punish(src, `Tried triggering a restricted event: ${event_name} in resource: ${GetCurrentResourceName()}.`);
            }
        });
        _onNet(enc_event_name, function () {
            const src = global.source;
            if (
                GetPlayerPing(src) > 0 &&
                decrypt(enc_event_name) !== "add_to_trigger_list" &&
                decrypt(enc_event_name) !== "check_trigger_list"
            ) {
                emit(encryptDecrypt("check_trigger_list"), src, decrypt(enc_event_name), GetCurrentResourceName());
            }
            handler.apply(null, arguments);
        });
    };
} else {
    globalThis.emitNet = (event_name, ...args) => {
        const enc_event_name = encryptDecrypt(event_name);
        return _emitNet(enc_event_name, ...args);
    };
}