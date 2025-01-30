const acName = GetCurrentResourceName();
const fs = require("fs");
const path = require("path");

function hasScriptKeywords(manifestCode) {
    const keywords = [
        "client_script", "client_scripts",
        "server_script", "server_scripts",
        "shared_script", "shared_scripts"
    ];
    return keywords.some(keyword => manifestCode.includes(keyword));
}

function installModule() {
    const numResources = GetNumResources();
    let changes = 0;

    for (let i = 0; i < numResources; i++) {
        const resource = GetResourceByFindIndex(i);

        if (resource !== "_cfx_internal" && resource !== "monitor" && resource !== acName) {
            const fxManifestPath = GetResourcePath(resource) + "/fxmanifest.lua";
            const resourceLuaPath = GetResourcePath(resource) + "/__resource.lua";

            let manifestPath = fs.existsSync(fxManifestPath) ? fxManifestPath :
                fs.existsSync(resourceLuaPath) ? resourceLuaPath : null;

            if (!manifestPath) continue;

            let manifestCode = fs.readFileSync(manifestPath, "utf8");

            if (!manifestCode.includes(`shared_script "@${acName}/module.lua"`) &&
                hasScriptKeywords(manifestCode)) {

                let newManifest = `shared_script "@${acName}/module.lua"\n${manifestCode}`;
                fs.writeFileSync(manifestPath, newManifest, "utf8");
                changes++;
            }
        }
    }

    if (changes > 0) {
        console.log("Exiting in 5 seconds...");
        console.log("\x1b[31m%s\x1b[0m", "Please Restart your server so the module will work! Make sure secureserve is ensured first!");
        setTimeout(() => process.exit(0), 5000);
    } else {
        console.log("No applicable resources need the module, or all already have it installed.");
    }
}

RegisterCommand("ssinstall", (source, args, rawCommand) => {
    installModule();
}, true);

RegisterCommand("ssuninstall", (source, args) => {
    const numResources = GetNumResources();

    for (let i = 0; i < numResources; i++) {
        const resource = GetResourceByFindIndex(i);

        if (resource !== "_cfx_internal" && resource !== "monitor" && resource !== acName) {
            const fxManifestPath = GetResourcePath(resource) + "/fxmanifest.lua";
            const resourceLuaPath = GetResourcePath(resource) + "/__resource.lua";

            let manifestPath = fs.existsSync(fxManifestPath) ? fxManifestPath :
                fs.existsSync(resourceLuaPath) ? resourceLuaPath : null;

            if (!manifestPath) continue;

            let manifestCode = fs.readFileSync(manifestPath, "utf8");
            let updatedManifest = manifestCode.replace(new RegExp(`shared_script "@${args[0] || acName}/module.lua"`, "g"), "");

            fs.writeFileSync(manifestPath, updatedManifest, "utf8");
        }
    }

    console.log("Module has been uninstalled from all resources!");
    console.log("Exiting in 5 seconds...");
    setTimeout(() => process.exit(0), 5000);
}, true);

on("onResourceStart", (resource) => {
    if (resource === acName) {
        installModule();
    }
});
