let encryption_key = "";

/**
 * @return {string} - The encryption key from secureserve.key file
 */
function getEncryptionKey() {
    try {
        const keyFile = LoadResourceFile("SecureServe", "secureserve.key");
        
        if (!keyFile || keyFile === "") {
            console.warn("[WARNING] Failed to load SecureServe encryption key. Using temporary key.");
            return "temp_key_" + GetCurrentResourceName();
        }
        
        return keyFile.trim();
    } catch (error) {
        console.error("[ERROR] Failed to load SecureServe encryption key:", error);
        return "c4a2ec5dc103a3f730460948f2e3c01df39ea4212bc2c82f"; 
    }
}

encryption_key = getEncryptionKey();

/**
 * @param {string|number} input - The input string or number to encrypt
 * @return {string} - The encrypted string
 */
function encryptDecrypt(input) {
    const output = [];
    const inputStr = String(input);
    for (let i = 0; i < inputStr.length; i++) {
        const char = inputStr.charCodeAt(i);
        const keyChar = encryption_key.charCodeAt(i % encryption_key.length);
        const encryptedChar = (char + keyChar) % 256;
        output.push(String.fromCharCode(encryptedChar));
    }
    return output.join('');
}

/**
 * @param {string} input - The encrypted string to decrypt
 * @return {string} - The decrypted string
 */
function decrypt(input) {
    const output = [];
    const inputStr = String(input);
    for (let i = 0; i < inputStr.length; i++) {
        const char = inputStr.charCodeAt(i);
        const keyChar = encryption_key.charCodeAt(i % encryption_key.length);
        const decryptedChar = (char - keyChar) % 256;
        output.push(String.fromCharCode(decryptedChar));
    }
    return output.join('');
}

const originalEmit = typeof emit !== 'undefined' ? emit : null;
const originalOn = typeof on !== 'undefined' ? on : null;
const originalOnServer = typeof onServer !== 'undefined' ? onServer : null;
const originalOnAll = typeof onAll !== 'undefined' ? onAll : null;
const originalEmitNet = typeof emitNet !== 'undefined' ? emitNet : null;
const originalOnNet = typeof onNet !== 'undefined' ? onNet : null;

if (originalEmit) {
    /**
     * @param {string} eventName - The name of the event to emit
     * @param {...any} args - The arguments to pass to the event handlers
     * @return {void}
     */
    emit = function(eventName, ...args) {
        return originalEmit(encryptDecrypt(eventName), ...args);
    };
}

if (originalEmitNet) {
    /**
     * @param {string} eventName - The name of the event to emit over the network
     * @param {...any} args - The arguments to pass to the event handlers
     * @return {void}
     */
    emitNet = function(eventName, ...args) {
        return originalEmitNet(encryptDecrypt(eventName), ...args);
    };
}

if (originalOn) {
    /**
     * @param {string} eventName - The name of the event to listen for
     * @param {Function} callback - The callback function to execute when the event is triggered
     * @return {number} - The event handler ID
     */
    on = function(eventName, callback) {
        originalOn(encryptDecrypt(eventName), callback);
        return originalOn(eventName, callback);
    };
}

if (originalOnNet) {
    /**
     * @param {string} eventName - The name of the network event to listen for
     * @param {Function} callback - The callback function to execute when the event is triggered
     * @return {void}
     */
    onNet = function(eventName, callback) {
        const encryptedEvent = encryptDecrypt(eventName);
        
        originalOnNet(eventName, (...args) => {
            if (IsDuplicityVersion()) { 
                const src = source;
                if (GetPlayerPing(src) > 0) {
                    const resourceName = GetCurrentResourceName();
                    const banMessage = `Tried triggering a restricted event: ${eventName} in resource: ${resourceName}.`;
                    if (exports["SecureServe"] && exports["SecureServe"].module_punish) {
                        exports["SecureServe"].module_punish(src, banMessage);
                    }
                }
            }
            callback(...args);
        });
        
        originalOnNet(encryptedEvent, (...args) => {
            if (IsDuplicityVersion()) { // Server side
                const src = source;
                if (GetPlayerPing(src) > 0 && 
                    eventName !== "add_to_trigger_list" && 
                    eventName !== "check_trigger_list") {
                    
                    emit(encryptDecrypt("check_trigger_list"), src, eventName, GetCurrentResourceName());
                }
            }
            callback(...args);
        });
    };
}

if (originalOnServer) {
    /**
     * @param {string} eventName - The name of the server event to listen for
     * @param {Function} callback - The callback function to execute when the event is triggered
     * @return {void}
     */
    onServer = function(eventName, callback) {
        return originalOnServer(encryptDecrypt(eventName), callback);
    };
}

if (originalOnAll) {
    /**
     * @param {Function} callback - The callback function to execute when any event is triggered
     * @return {void}
     */
    onAll = function(callback) {
        return originalOnAll(callback);
    };
}

/**
 * @param {Function} originalFunction - The original entity creation function
 * @return {Function} - The wrapped entity creation function
 */
function createEntityWrapper(originalFunction) {
    /**
     * @param {...any} args - The arguments to pass to the original function
     * @return {number} - The entity handle
     */
    return function(...args) {
        const entity = originalFunction(...args);
        if (entity && DoesEntityExist(entity)) {
            if (IsDuplicityVersion()) { // Server-side
                emitNet('entity2', -1, GetEntityModel(entity));
                emit("entityCreatedByScript", entity, 'fdgfd', true, GetEntityModel(entity));
            } else { 
                emit('entityCreatedByScriptClient', entity);
                emitNet(encryptDecrypt("entityCreatedByScript"), entity, 'fdgfd', true, GetEntityModel(entity));
            }
            return entity;
        }
        return entity;
    };
}

/**
 * @param {string} resourceName - The name of the resource to check
 * @return {boolean} - Whether the resource is valid
 */
function isValidResource(resourceName) {
    const invalidResources = [null, "fivem", "gta", "citizen", "system"];
    return !invalidResources.includes(resourceName);
}

/**
 * @param {Function} originalFunction - The original explosion function
 * @return {Function} - The wrapped explosion function
 */
function handleExplosionEvent(originalFunction) {
    /**
     * @param {...any} args - The arguments to pass to the original function
     * @return {any} - The result of the original function
     */
    return function(...args) {
        const resourceName = GetCurrentResourceName();
        if (!IsDuplicityVersion() && isValidResource(resourceName)) {
            emitNet("SecureServe:Explosions:Whitelist", {
                source: GetPlayerServerId(PlayerId()),
                resource: resourceName
            });
        }
        return originalFunction(...args);
    };
}

const entityFunctions = [
    "CreateObject", "CreateObjectNoOffset", "CreateVehicle", "CreatePed", 
    "CreatePedInsideVehicle", "CreateRandomPed", "CreateRandomPedAsDriver"
];

for (const funcName of entityFunctions) {
    if (typeof global[funcName] === 'function') {
        const original = global[funcName];
        global[funcName] = createEntityWrapper(original);
    }
}

const explosionFunctions = [
    "AddExplosion", "AddExplosionWithUserVfx", "ExplodeVehicle", 
    "NetworkExplodeVehicle", "ShootSingleBulletBetweenCoords", 
    "AddOwnedExplosion", "StartScriptFire", "RemoveScriptFire"
];

if (!IsDuplicityVersion()) {
    for (const funcName of explosionFunctions) {
        if (typeof global[funcName] === 'function') {
            const original = global[funcName];
            global[funcName] = handleExplosionEvent(original);
        }
    }
} 