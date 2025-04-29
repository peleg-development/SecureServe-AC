/**
 * SecureServe installation module
 * Handles key generation, resource discovery, and manifest modification
 * @module install
 * @author SecureServe Development Team
 */

const fs = require('fs');
const path = require('path');

// Configuration constants
const CURRENT_RESOURCE_NAME = GetCurrentResourceName();
const RESOURCES_PATH = GetResourcePath(CURRENT_RESOURCE_NAME);
const PARENT_PATH = path.dirname(RESOURCES_PATH);
const DEFAULT_KEY_PATTERNS = [
    "dont-touch-this-will-auto-update-next-restart", 
    "Please Change this", 
    "default", 
    "please-change"
];
const MIN_KEY_LENGTH = 10;
const MAX_RETRIES = 60;
const SERVER_RESTART_DELAY = 500;

/**
 * Logger utility to standardize console output
 * @namespace Logger
 */
const Logger = {
    /**
     * Log an info message
     * @param {string} message - The message to log
     */
    info: (message) => console.log(`[INFO] ${message}`),
    
    /**
     * Log a success message
     * @param {string} message - The message to log
     */
    success: (message) => console.log(`[SUCCESS] ${message}`),
    
    /**
     * Log a warning message
     * @param {string} message - The message to log
     */
    warning: (message) => console.log(`[WARNING] ${message}`),
    
    /**
     * Log an error message
     * @param {string} message - The message to log
     */
    error: (message) => console.error(`[ERROR] ${message}`),
    
    /**
     * Log a critical error message
     * @param {string} message - The message to log
     */
    critical: (message) => console.error(`[CRITICAL] ${message}`),
    
    /**
     * Log a debug message
     * @param {string} message - The message to log
     */
    debug: (message) => console.log(`[DEBUG] ${message}`),
    
    /**
     * Log a restart notice
     * @param {string} message - The message to log
     */
    restart: (message) => console.log(`[RESTART] ${message}`)
};

/**
 * Get the full path to a resource
 * @param {string} resourceName - Name of the resource to get path for
 * @return {string} Full path to the resource
 */
function getResourcePath(resourceName) {
    return GetResourcePath(resourceName);
}

/**
 * Find all resources on the server
 * @return {Array<Object>} Array of resource objects with name, path, and manifest properties
 */
function findAllResources() {
    const resourceDirs = [];
    
    let currentPath = PARENT_PATH;
    let resourcesPath = null;
    let attempts = 0;
    
    while (!resourcesPath && attempts < 5) {
        attempts++;
        
        if (path.basename(currentPath).toLowerCase() === 'resources') {
            resourcesPath = currentPath;
            break;
        }
        
        const possibleResourcesPath = path.join(currentPath, 'resources');
        if (fs.existsSync(possibleResourcesPath)) {
            resourcesPath = possibleResourcesPath;
            break;
        }
        
        const parentPath = path.dirname(currentPath);
        if (parentPath === currentPath) {
            break;
        }
        currentPath = parentPath;
    }
    
    if (resourcesPath) {
        scanDirectory(resourcesPath, resourceDirs);
    } else {
        Logger.warning("Could not find main resources directory, using parent directory only");
        scanDirectory(PARENT_PATH, resourceDirs);
    }
    
    return resourceDirs;
}

/**
 * Recursively scan directories to find resource directories
 * @param {string} dirPath - Directory to scan
 * @param {Array} resourceDirs - Array to collect results
 * @param {number} [depth=0] - Current recursion depth
 */
function scanDirectory(dirPath, resourceDirs, depth = 0) {
    if (depth > 3) return;
    
    try {
        const items = fs.readdirSync(dirPath);
        
        for (const item of items) {
            if (item.startsWith('.') || item === 'node_modules' || item === 'cache') continue;
            
            const fullPath = path.join(dirPath, item);
            
            if (fs.statSync(fullPath).isDirectory()) {
                const manifestPath = path.join(fullPath, 'fxmanifest.lua');
                const legacyManifestPath = path.join(fullPath, '__resource.lua');
                
                if (fs.existsSync(manifestPath) || fs.existsSync(legacyManifestPath)) {
                    resourceDirs.push({
                        name: item,
                        path: fullPath,
                        manifest: fs.existsSync(manifestPath) ? 'fxmanifest.lua' : '__resource.lua'
                    });
                } else {
                    scanDirectory(fullPath, resourceDirs, depth + 1);
                }
            }
        }
    } catch (error) {
        Logger.error(`Scanning directory ${dirPath}: ${error.message}`);
    }
}

/**
 * Read a manifest file
 * @param {string} filePath - Path to manifest file
 * @return {string|null} Content of the manifest file or null if read failed
 */
function readManifestFile(filePath) {
    try {
        return fs.readFileSync(filePath, 'utf8');
    } catch (error) {
        Logger.error(`Reading manifest file ${filePath}: ${error.message}`);
        return null;
    }
}

/**
 * Write to a manifest file
 * @param {string} filePath - Path to manifest file
 * @param {string} content - New content to write
 * @return {boolean} Success status
 */
function writeManifestFile(filePath, content) {
    try {
        fs.writeFileSync(filePath, content, 'utf8');
        return true;
    } catch (error) {
        Logger.error(`Writing manifest file ${filePath}: ${error.message}`);
        return false;
    }
}

/**
 * Check if manifest has old SecureServe include
 * @param {string} manifestContent - Content of manifest file
 * @return {boolean} Whether it has the old SecureServe include
 */
function hasOldSecureServe(manifestContent) {
    return manifestContent.includes(`shared_script "@${CURRENT_RESOURCE_NAME}/module.lua"`);
}

/**
 * Check if manifest has new SecureServe includes
 * @param {string} manifestContent - Content of manifest file
 * @return {boolean} Whether it has the new SecureServe includes
 */
function hasNewSecureServe(manifestContent) {
    return manifestContent.includes(`shared_script "@${CURRENT_RESOURCE_NAME}/src/module/module.lua"`) || 
           manifestContent.includes(`shared_script "@${CURRENT_RESOURCE_NAME}/src/module/module.js"`);
}

/**
 * Check if manifest has key file reference
 * @param {string} manifestContent - Content of manifest file
 * @return {boolean} Whether it has the key file reference
 */
function hasKeyFile(manifestContent) {
    return manifestContent.includes(`file "@${CURRENT_RESOURCE_NAME}/secureserve.key"`);
}

/**
 * Add SecureServe includes to manifest content
 * @param {string} manifestContent - Content of manifest file
 * @return {string} Updated manifest content
 */
function addSecureServe(manifestContent) {
    if (manifestContent.includes(`name "${CURRENT_RESOURCE_NAME}"`) || 
        manifestContent.includes(`name '${CURRENT_RESOURCE_NAME}'`)) {
        return manifestContent;
    }
    
    if (hasNewSecureServe(manifestContent) && hasKeyFile(manifestContent)) {
        return manifestContent;
    }
    
    if (hasOldSecureServe(manifestContent)) {
        manifestContent = manifestContent.replace(`shared_script "@${CURRENT_RESOURCE_NAME}/module.lua"`, '');
    }
    
    let insertPosition = 0;
    
    if (manifestContent.includes('fx_version')) {
        const fxVersionPos = manifestContent.indexOf('fx_version');
        const lineEnd = manifestContent.indexOf('\n', fxVersionPos);
        insertPosition = lineEnd + 1;
    } else {
        const positions = [
            manifestContent.indexOf('client_script'),
            manifestContent.indexOf('server_script'),
            manifestContent.indexOf('shared_script')
        ].filter(pos => pos !== -1);
        
        if (positions.length > 0) {
            insertPosition = Math.min(...positions);
        }
    }
    
    let insertion = '';
    
    if (!hasNewSecureServe(manifestContent)) {
        insertion += `\nshared_script "@${CURRENT_RESOURCE_NAME}/src/module/module.lua"\nshared_script "@${CURRENT_RESOURCE_NAME}/src/module/module.js"`;
    }
    
    if (!hasKeyFile(manifestContent)) {
        insertion += `\nfile "@${CURRENT_RESOURCE_NAME}/secureserve.key"`;
    }
    
    insertion += '\n';
    
    return manifestContent.slice(0, insertPosition) + insertion + manifestContent.slice(insertPosition);
}

/**
 * Remove SecureServe references from manifest content
 * @param {string} manifestContent - Content of manifest file
 * @return {string} Updated manifest content with SecureServe removed
 */
function removeSecureServe(manifestContent) {
    manifestContent = manifestContent.replace(`shared_script "@${CURRENT_RESOURCE_NAME}/module.lua"`, '');
    manifestContent = manifestContent.replace(`shared_script "@${CURRENT_RESOURCE_NAME}/src/module/module.lua"`, '');
    manifestContent = manifestContent.replace(`shared_script "@${CURRENT_RESOURCE_NAME}/src/module/module.js"`, '');
    manifestContent = manifestContent.replace(`file "@${CURRENT_RESOURCE_NAME}/secureserve.key"`, '');
    
    // Clean up excess newlines
    manifestContent = manifestContent.replace(/\n\s*\n\s*\n/g, '\n\n');
    
    return manifestContent;
}

/**
 * Update SecureServe references in manifest content
 * @param {string} manifestContent - Content of manifest file
 * @return {string} Updated manifest content
 */
function updateSecureServe(manifestContent) {
    if (hasNewSecureServe(manifestContent) || !hasOldSecureServe(manifestContent)) {
        return manifestContent;
    }
    
    manifestContent = manifestContent.replace(`shared_script "@${CURRENT_RESOURCE_NAME}/module.lua"`, '');
    
    let insertPosition = 0;
    
    if (manifestContent.includes('fx_version')) {
        const fxVersionPos = manifestContent.indexOf('fx_version');
        const lineEnd = manifestContent.indexOf('\n', fxVersionPos);
        insertPosition = lineEnd + 1;
    } else {
        const scriptPos = Math.min(
            manifestContent.indexOf('client_script'),
            manifestContent.indexOf('server_script'),
            manifestContent.indexOf('shared_script')
        ).filter(pos => pos !== -1);
        
        if (scriptPos.length > 0) {
            insertPosition = scriptPos[0];
        }
    }
    
    const insertion = `
shared_script "@${CURRENT_RESOURCE_NAME}/src/module/module.lua"
shared_script "@${CURRENT_RESOURCE_NAME}/src/module/module.js"
`;
    
    return manifestContent.slice(0, insertPosition) + insertion + manifestContent.slice(insertPosition);
}

/**
 * Generate a cryptographically secure random key
 * @param {number} [length] - Optional key length (defaults to a random length between 24-32)
 * @return {string} A secure random key
 */
function generateSecureKey(length) {
    const charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()-_=+[{]}|;:,<.>/?";
    let result = "";
    const randomLength = Math.floor(Math.random() * 9) + 24; 
    const finalLength = length || randomLength;
    
    try {
        const crypto = require('crypto');
        for (let i = 0; i < finalLength; i++) {
            const randomValue = crypto.randomBytes(1)[0] % charset.length;
            result += charset[randomValue];
        }
    } catch (e) {
        for (let i = 0; i < finalLength; i++) {
            const randomIndex = Math.floor(Math.random() * charset.length);
            result += charset[randomIndex];
        }
    }
    
    return result;
}

/**
 * Check and fix default key if needed
 * @return {boolean} Whether a key was created or fixed
 */
function checkAndFixDefaultKey() {
    const keyPath = path.join(RESOURCES_PATH, 'secureserve.key');
    
    try {
        if (fs.existsSync(keyPath)) {
            let keyData = fs.readFileSync(keyPath, 'utf8');
            
            let isDefaultKey = false;
            
            Logger.debug(`Checking key file content (${keyData.length} chars)...`);
            
            for (const pattern of DEFAULT_KEY_PATTERNS) {
                if (keyData.toLowerCase().includes(pattern.toLowerCase())) {
                    Logger.debug(`Default key pattern detected: "${pattern}"`);
                    isDefaultKey = true;
                    break;
                }
            }
            
            if (!isDefaultKey && (keyData.trim() === "" || keyData.trim().length < MIN_KEY_LENGTH)) {
                Logger.debug(`Key is empty or too short (${keyData.trim().length} chars)`);
                isDefaultKey = true;
            }
            
            if (isDefaultKey) {
                Logger.critical(`Regenerating secureserve.key file due to default key...`);
                
                const newKey = generateSecureKey();
                
                try {
                    fs.unlinkSync(keyPath);
                    Logger.debug(`Removed existing key file`);
                } catch (deleteError) {
                    Logger.debug(`Could not delete existing key file: ${deleteError.message}`);
                }
                
                fs.writeFileSync(keyPath, newKey, 'utf8');
                
                const verifyKey = fs.readFileSync(keyPath, 'utf8').trim();
                if (verifyKey === newKey) {
                    Logger.success(`Generated and saved new secure key successfully.`);
                    Logger.info(`New key will be used by all SecureServe components.`);
                    Logger.restart(`The server will now restart to apply the new key.`);
                    setTimeout(() => {
                        process.exit(0);
                    }, SERVER_RESTART_DELAY);
                    return true;
                } else {
                    Logger.error(`Key verification failed - file content doesn't match!`);
                    return false;
                }
            } else {
                Logger.info(`Existing key is not a default key, keeping it.`);
            }
            
            return true; 
        } else {
            const newKey = generateSecureKey();
            fs.writeFileSync(keyPath, newKey, 'utf8');
            Logger.success(`Created new secureserve.key file with secure random key.`);
            Logger.restart(`The server will now restart to apply the new key.`);
            setTimeout(() => {
                process.exit(0); 
            }, SERVER_RESTART_DELAY);
            return true;
        }
    } catch (error) {
        Logger.error(`Failed to check/fix default key: ${error.message}`);
        return false;
    }
}

/**
 * Ensure secureserve.key exists with a secure random key
 * @param {boolean} [forceNew=false] - Whether to force create a new key regardless of existing content
 * @return {boolean} Whether the key was created or already existed
 */
function ensureKeyFileExists(forceNew = false) {
    const keyPath = path.join(RESOURCES_PATH, 'secureserve.key');
    
    try {
        if (forceNew) {
            const newKey = generateSecureKey();
            fs.writeFileSync(keyPath, newKey, 'utf8');
            Logger.success(`Created new secureserve.key with secure random key: ${keyPath}`);
            Logger.restart(`The server will now restart to apply the new key.`);
            setTimeout(() => {
                process.exit(0);
            }, SERVER_RESTART_DELAY);
            return true;
        }
        
        if (fs.existsSync(keyPath)) {
            let existingKey = fs.readFileSync(keyPath, 'utf8');
            
            let isDefaultKey = false;
            
            for (const pattern of DEFAULT_KEY_PATTERNS) {
                if (existingKey.toLowerCase().includes(pattern.toLowerCase())) {
                    isDefaultKey = true;
                    break;
                }
            }
            
            if (!isDefaultKey && (existingKey.trim() === "" || existingKey.trim().length < MIN_KEY_LENGTH)) {
                isDefaultKey = true;
            }
            
            if (!isDefaultKey) {
                Logger.info(`secureserve.key exists with custom key: ${keyPath}`);
                return true;
            }
            
            Logger.critical(`Default/invalid key detected in secureserve.key. Generating new secure key...`);
            const newKey = generateSecureKey();
            fs.writeFileSync(keyPath, newKey, 'utf8');
            Logger.success(`Updated secureserve.key with new secure random key: ${keyPath}`);
            
            try {
                const checkKey = fs.readFileSync(keyPath, 'utf8').trim();
                if (checkKey === newKey) {
                    Logger.success(`New key successfully written to file.`);
                    Logger.restart(`The server will now restart to apply the new key.`);
                    setTimeout(() => {
                        process.exit(0); 
                    }, SERVER_RESTART_DELAY);
                } else {
                    Logger.error(`Key verification failed! File content doesn't match generated key.`);
                }
            } catch (verifyError) {
                Logger.error(`Could not verify key was written: ${verifyError.message}`);
            }
            
            return true;
        } else {
            const newKey = generateSecureKey();
            fs.writeFileSync(keyPath, newKey, 'utf8');
            Logger.success(`Created new secureserve.key file with secure random key: ${keyPath}`);
            Logger.restart(`The server will now restart to apply the new key.`);
            setTimeout(() => {
                process.exit(0);
            }, SERVER_RESTART_DELAY);
            return true;
        }
    } catch (error) {
        Logger.critical(`Managing key file: ${error.message}`);
        return false;
    }
}

/**
 * Find resource directories in the specified path
 * @param {string} dirPath - Directory to scan
 * @return {Array<Object>} Array of resource objects with name, path, and manifest properties
 */
function findResourceDirectories(dirPath) {
    try {
        const items = fs.readdirSync(dirPath);
        const resourceDirs = [];

        for (const item of items) {
            const fullPath = path.join(dirPath, item);
            
            if (fs.statSync(fullPath).isDirectory()) {
                const manifestPath = path.join(fullPath, 'fxmanifest.lua');
                const legacyManifestPath = path.join(fullPath, '__resource.lua');
                
                if (fs.existsSync(manifestPath) || fs.existsSync(legacyManifestPath)) {
                    resourceDirs.push({
                        name: item,
                        path: fullPath,
                        manifest: fs.existsSync(manifestPath) ? 'fxmanifest.lua' : '__resource.lua'
                    });
                }
            }
        }
        
        return resourceDirs;
    } catch (error) {
        Logger.error(`Scanning directory ${dirPath}: ${error.message}`);
        return [];
    }
}

/**
 * Recursively search for server.cfg
 * @param {string} startDir - Directory to start searching from
 * @param {number} maxDepth - Maximum depth to search
 * @param {number} [currentDepth=0] - Current recursion depth
 * @returns {string|null} Path to server.cfg or null if not found
 */
function findServerCfg(startDir, maxDepth, currentDepth = 0) {
    if (currentDepth > maxDepth) return null;
    
    try {
        const serverCfgPath = path.join(startDir, 'server.cfg');
        if (fs.existsSync(serverCfgPath)) {
            return serverCfgPath;
        }
        
        const items = fs.readdirSync(startDir);
        for (const item of items) {
            if (item.startsWith('.') || item === 'node_modules' || item === 'cache') continue;
            
            const fullPath = path.join(startDir, item);
            if (fs.statSync(fullPath).isDirectory()) {
                const result = findServerCfg(fullPath, maxDepth, currentDepth + 1);
                if (result) return result;
            }
        }
        
        if (currentDepth < maxDepth) {
            const parentPath = path.dirname(startDir);
            if (parentPath !== startDir) { 
                return findServerCfg(parentPath, maxDepth, currentDepth + 1);
            }
        }
        
        return null;
    } catch (error) {
        Logger.error(`Searching for server.cfg in ${startDir}: ${error.message}`);
        return null;
    }
}

/**
 * Ensures SecureServe starts before other resources in server.cfg
 * @return {boolean} Success status
 */
function ensureSecureServeStartsFirst() {
    const possibleLocations = [
        path.join(PARENT_PATH, 'server.cfg'),
        path.join(PARENT_PATH, 'server', 'server.cfg'),
        path.join(PARENT_PATH, 'config', 'server.cfg'),
        path.join(PARENT_PATH, '..', 'server.cfg'),
        path.join(PARENT_PATH, '..', 'server', 'server.cfg'),
        path.join(PARENT_PATH, '..', 'config', 'server.cfg'),
        path.join(PARENT_PATH, '..', '..', 'server.cfg'),
        path.join(PARENT_PATH, '..', '..', 'server', 'server.cfg'),
        path.join(PARENT_PATH, '..', '..', 'config', 'server.cfg')
    ];
    
    let serverCfgPath = null;
    
    for (const loc of possibleLocations) {
        if (fs.existsSync(loc)) {
            serverCfgPath = loc;
            Logger.debug(`Found server.cfg at: ${serverCfgPath}`);
            break;
        }
    }
    
    if (!serverCfgPath) {
        serverCfgPath = findServerCfg(PARENT_PATH, 4); 
        
        if (serverCfgPath) {
            Logger.debug(`Found server.cfg by searching: ${serverCfgPath}`);
        }
    }
    
    if (!serverCfgPath) {
        Logger.error('Could not find server.cfg. Please manually ensure SecureServe starts first.');
        return false;
    }
    
    try {
        let content = fs.readFileSync(serverCfgPath, 'utf8');
        
        content = content.replace(new RegExp(`\\s*ensure\\s+${CURRENT_RESOURCE_NAME}\\s*`, 'g'), '\n');
        
        const firstEnsurePos = content.indexOf('ensure ');
        if (firstEnsurePos === -1) {
            content += `\n\nensure ${CURRENT_RESOURCE_NAME}\n`;
        } else {
            content = content.slice(0, firstEnsurePos) + 
                     `\nensure ${CURRENT_RESOURCE_NAME}\n\n` + 
                     content.slice(firstEnsurePos);
        }
        
        fs.writeFileSync(serverCfgPath, content, 'utf8');
        Logger.success(`Updated ${serverCfgPath} to ensure ${CURRENT_RESOURCE_NAME} starts first.`);
        return true;
    } catch (error) {
        Logger.error(`Updating server.cfg: ${error.message}`);
        return false;
    }
}

/**
 * Install SecureServe protection on all resources
 * @return {void}
 */
function installSecureServe() {
    Logger.info(`Starting ${CURRENT_RESOURCE_NAME} installation...`);
    
    if (!ensureKeyFileExists()) {
        Logger.critical(`Failed to ensure secureserve.key exists. Installation may be incomplete.`);
        Logger.critical(`Try running the 'securenewkey' command to manually generate a new key.`);
    }
    
    const resources = findAllResources();
    Logger.info(`Found ${resources.length} resources to process.`);
    
    let successCount = 0;
    let failCount = 0;
    
    for (const resource of resources) {
        if (resource.name === CURRENT_RESOURCE_NAME) continue;
        
        const manifestPath = path.join(resource.path, resource.manifest);
        const content = readManifestFile(manifestPath);
        
        if (!content) {
            failCount++;
            continue;
        }
        
        if (hasNewSecureServe(content) && hasKeyFile(content)) {
            // Logger.debug(`${resource.name} already has ${CURRENT_RESOURCE_NAME} protection.`);
            successCount++;
            continue;
        }
        
        const updatedContent = addSecureServe(content);
        
        if (writeManifestFile(manifestPath, updatedContent)) {
            Logger.success(`Added ${CURRENT_RESOURCE_NAME} to ${resource.name}`);
            successCount++;
        } else {
            Logger.error(`Failed to add ${CURRENT_RESOURCE_NAME} to ${resource.name}`);
            failCount++;
        }
    }
    
    ensureSecureServeStartsFirst();
    
    Logger.info(`${CURRENT_RESOURCE_NAME} installation complete. Success: ${successCount}, Failed: ${failCount}`);
}

/**
 * Uninstall SecureServe protection from all resources
 * @return {void}
 */
function uninstallSecureServe() {
    Logger.info(`Starting ${CURRENT_RESOURCE_NAME} uninstallation...`);
    
    const resources = findAllResources();
    Logger.info(`Found ${resources.length} resources to process.`);
    
    let successCount = 0;
    let failCount = 0;
    
    for (const resource of resources) {
        if (resource.name === CURRENT_RESOURCE_NAME) continue;
        
        const manifestPath = path.join(resource.path, resource.manifest);
        const content = readManifestFile(manifestPath);
        
        if (!content) {
            failCount++;
            continue;
        }
        
        if (!hasOldSecureServe(content) && !hasNewSecureServe(content) && !hasKeyFile(content)) {
            Logger.debug(`${resource.name} doesn't have ${CURRENT_RESOURCE_NAME} protection.`);
            successCount++;
            continue;
        }
        
        const updatedContent = removeSecureServe(content);
        
        if (writeManifestFile(manifestPath, updatedContent)) {
            Logger.success(`Removed ${CURRENT_RESOURCE_NAME} from ${resource.name}`);
            successCount++;
        } else {
            Logger.error(`Failed to remove ${CURRENT_RESOURCE_NAME} from ${resource.name}`);
            failCount++;
        }
    }
    
    Logger.info(`${CURRENT_RESOURCE_NAME} uninstallation complete. Success: ${successCount}, Failed: ${failCount}`);
}

/**
 * Update SecureServe protection on all resources
 * @return {void}
 */
function updateSecureServe() {
    Logger.info(`Starting ${CURRENT_RESOURCE_NAME} update...`);
    
    ensureKeyFileExists();
    
    const resources = findAllResources();
    Logger.info(`Found ${resources.length} resources to process.`);
    
    let updatedCount = 0;
    let alreadyUpdatedCount = 0;
    let failCount = 0;
    
    for (const resource of resources) {
        if (resource.name === CURRENT_RESOURCE_NAME) continue;
        
        const manifestPath = path.join(resource.path, resource.manifest);
        const content = readManifestFile(manifestPath);
        
        if (!content) {
            failCount++;
            continue;
        }
        
        if (hasNewSecureServe(content) && hasKeyFile(content)) {
            Logger.debug(`${resource.name} already has updated ${CURRENT_RESOURCE_NAME} protection.`);
            alreadyUpdatedCount++;
            continue;
        }
        
        const updatedContent = addSecureServe(content);
        
        if (writeManifestFile(manifestPath, updatedContent)) {
            Logger.success(`Updated ${CURRENT_RESOURCE_NAME} in ${resource.name}`);
            updatedCount++;
        } else {
            Logger.error(`Failed to update ${CURRENT_RESOURCE_NAME} in ${resource.name}`);
            failCount++;
        }
    }
    
    ensureSecureServeStartsFirst();
    
    Logger.info(`${CURRENT_RESOURCE_NAME} update complete. Updated: ${updatedCount}, Already updated: ${alreadyUpdatedCount}, Failed: ${failCount}`);
}

/**
 * Get the encryption key from secureserve.key
 * @return {string} The encryption key to use
 */
function getEncryptionKey() {
    try {
        const keyFile = LoadResourceFile("SecureServe", "secureserve.key");
        
        if (!keyFile || keyFile === "") {
            Logger.warning("SecureServe key not found, using temporary key");
            return "temp_key_" + GetCurrentResourceName();
        }
        
        if (keyFile === "Please Change this if u wont the ac just wont start until u do this delete this message and instead write a random combination of letters like a random password without any spaces" || 
            keyFile === "dont-touch-this-will-auto-update-next-restart") {
            
            Logger.critical("Default SecureServe key detected. Running ensureKeyFileExists() to create a new one.");
            checkAndFixDefaultKey();
            
            const updatedKey = LoadResourceFile("SecureServe", "secureserve.key");
            if (updatedKey && updatedKey !== keyFile) {
                Logger.success("Now using the new secure key");
                return updatedKey.trim();
            } else {
                Logger.error("Could not update the key. Using a temporary key.");
                return generateSecureKey();
            }
        }
        
        return keyFile.trim();
    } catch (error) {
        Logger.error(`Failed to load SecureServe encryption key: ${error.message}`);
        return "c4a2ec5dc103a3f730460948f2e3c01df39ea4212bc2c82f"; 
    }
}

/**
 * Encrypt or decrypt a string using XOR with the encryption key
 * @param {string|number} input - The input string or number to encrypt
 * @return {string} - The encrypted string
 */
function encryptDecrypt(input) {
    const output = [];
    const inputStr = String(input);
    for (let i = 0; i < inputStr.length; i++) {
        const char = inputStr.charCodeAt(i);
        const keyChar = enc_key.charCodeAt(i % enc_key.length);
        const encryptedChar = (char + keyChar) % 256;
        output.push(String.fromCharCode(encryptedChar));
    }
    return output.join('');
}

/**
 * Decrypt a string using XOR with the encryption key
 * @param {string} input - The encrypted string to decrypt
 * @return {string} - The decrypted string
 */
function decrypt(input) {
    const output = [];
    const inputStr = String(input);
    for (let i = 0; i < inputStr.length; i++) {
        const char = inputStr.charCodeAt(i);
        const keyChar = enc_key.charCodeAt(i % enc_key.length);
        const decryptedChar = (char - keyChar) % 256;
        output.push(String.fromCharCode(decryptedChar));
    }
    return output.join('');
}

RegisterCommand('secureinstall', (source, args, raw) => {
    if (source !== 0) {
        Logger.warning('This command can only be run from the server console');
        return;
    }
    
    installSecureServe();
}, true);

RegisterCommand('secureuninstall', (source, args, raw) => {
    if (source !== 0) {
        Logger.warning('This command can only be run from the server console');
        return;
    }
    
    uninstallSecureServe();
}, true);

RegisterCommand('secureupdate', (source, args, raw) => {
    if (source !== 0) {
        Logger.warning('This command can only be run from the server console');
        return;
    }
    
    updateSecureServe();
}, true);

RegisterCommand('securenewkey', (source, args, raw) => {
    if (source !== 0) {
        Logger.warning('This command can only be run from the server console');
        return;
    }
    
    Logger.info('Forcing regeneration of secureserve.key...');
    const success = ensureKeyFileExists(true);
    if (success) {
        Logger.success('Generated new SecureServe encryption key. The server will restart to apply changes.');
    } else {
        Logger.error('Failed to generate new key. Check permissions and try again.');
    }
}, true);

Logger.info(`${CURRENT_RESOURCE_NAME} install script loaded.`);

const enc_key = getEncryptionKey();
let key_loaded = false;
let retry_count = 0;

/**
 * Run installation after server has fully started
 */
on('onServerResourceStart', (resourceName) => {
    if (resourceName === CURRENT_RESOURCE_NAME) {
        Citizen.CreateThread(() => {
            Citizen.Wait(5000);
            
            Logger.info(`${CURRENT_RESOURCE_NAME} install script starting...`);

            checkAndFixDefaultKey();

            if (!fs.existsSync(path.join(RESOURCES_PATH, 'secureserve.key'))) {
                const keySuccess = ensureKeyFileExists();
                if (!keySuccess) {
                    Logger.critical(`Could not create or verify secureserve.key`);
                    Logger.critical(`Check file permissions and server configuration`);
                }
            } else {
                installSecureServe();
            }
        });
    }
});
