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

function replaceEventRegistrations(filePath) {
  try {
    let content = fs.readFileSync(filePath, 'utf8');

    const netEventRegex = /RegisterNetEvent\s*\(\s*'([^']+)'\s*\)\s*AddEventHandler\s*\(\s*'([^']+)'\s*,\s*function\(([^)]*)\)/g;
    content = content.replace(netEventRegex, (match, eventName1, eventName2, params) => {
      if (eventName1 === eventName2) {
        return `RegisterNetEvent('${eventName1}', function(${params})`;
      }
      return match;
    });

    const serverEventRegex = /RegisterServerEvent\s*\(\s*'([^']+)'\s*\)\s*AddEventHandler\s*\(\s*'([^']+)'\s*,\s*function\(([^)]*)\)/g;
    content = content.replace(serverEventRegex, (match, eventName1, eventName2, params) => {
      if (eventName1 === eventName2) {
        return `RegisterNetEvent('${eventName1}', function(${params})`;
      }
      return match;
    });

    fs.writeFileSync(filePath, content, 'utf8');
    // console.log(`Updated file: ${filePath}`);
  } catch (err) {
    // console.error(`Error processing file: ${filePath}`, err);
  }
}


function fileContainsLine(filePath, lineToFind) {
  try {
    const data = fs.readFileSync(filePath, 'utf8');
    const lines = data.split(/\r?\n/);
    return lines.some(line => line.includes(lineToFind));
  } catch (err) {
    // console.error(`Could not open file: ${filePath}`, err);
    return false;
  }
}


function searchInDirectory(directory, resourceName) {
  function traverseDir(currentPath) {
    let entries;
    try {
      entries = fs.readdirSync(currentPath, { withFileTypes: true });
    } catch (err) {
      console.error(`Could not open directory: ${currentPath}`, err);
      return;
    }
    entries.forEach(entry => {
      const fullPath = path.join(currentPath, entry.name);
      if (entry.isDirectory()) {
        traverseDir(fullPath);
      } else if (entry.isFile() && fullPath.endsWith('.lua')) {
        replaceEventRegistrations(fullPath);

        /*
        if (
          fileContainsLine(fullPath, "CreateObject") ||
          fileContainsLine(fullPath, "CreateVehicle") ||
          fileContainsLine(fullPath, "CreatePed") ||
          fileContainsLine(fullPath, "CreatePedInsideVehicle") ||
          fileContainsLine(fullPath, "CreateRandomPed") ||
          fileContainsLine(fullPath, "CreateRandomPedAsDriver")
        ) {
          console.log("Whitelisted resource with entity creation: " + resourceName);
        }
        */
      }
    });
  }
  traverseDir(directory);
}

function searchForAssetPackDependency() {
  const resourcesDir = path.join(__dirname, 'resources');
  let resourceFolders;
  try {
    resourceFolders = fs.readdirSync(resourcesDir, { withFileTypes: true });
  } catch (err) {
    console.error(`Could not open resources directory: ${resourcesDir}`, err);
    return;
  }

  resourceFolders.forEach(entry => {
    if (entry.isDirectory()) {
      const resourceName = entry.name;
      const resourcePath = path.join(resourcesDir, resourceName);
      const fxManifestPath = path.join(resourcePath, 'fxmanifest.lua');
      const resourceLuaPath = path.join(resourcePath, '__resource.lua');

      let hasAssetPackDependency = false;
      if (fs.existsSync(fxManifestPath) && fileContainsLine(fxManifestPath, "dependency '/assetpacks'")) {
        hasAssetPackDependency = true;
      } else if (fs.existsSync(resourceLuaPath) && fileContainsLine(resourceLuaPath, "dependency '/assetpacks'")) {
        hasAssetPackDependency = true;
      }

      if (hasAssetPackDependency) {
        // console.log("Whitelisted encrypted resource: " + resourceName);
      } else {
        searchInDirectory(resourcePath, resourceName);
      }
    }
  });
}

searchForAssetPackDependency();
