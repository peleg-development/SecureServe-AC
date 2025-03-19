---@class EncryptionLib
---@field encryption_key string The encryption key used for encryption/decryption
local Encryption = {
    encryption_key = "",
}


function Encryption.initialize()
    local keyFile = LoadResourceFile("SecureServe", "secureserve.key")
    if not keyFile or keyFile == "" then
        print("^3[WARNING] Failed to load SecureServe encryption key. Using temporary key.^7")
        Encryption.encryption_key = ""
    else
        Encryption.encryption_key = keyFile:gsub("%s+", "")
    end
end

---@param input string The string to encrypt/decrypt
---@return string The encrypted/decrypted string
function Encryption.encrypt_decrypt(input)
    local output = {}
    for i = 1, #tostring(input) do
        local char = tostring(input):byte(i)
        local key_char = Encryption.encryption_key:byte((i - 1) % #Encryption.encryption_key + 1)
        local encrypted_char = (char + key_char) % 256  
        output[i] = string.char(encrypted_char)
    end
    return table.concat(output)
end

---@param input string The string to decrypt
---@return string The decrypted string
function Encryption.decrypt(input)
    local output = {}
    for i = 1, #tostring(input) do
        local char = tostring(input):byte(i)
        local key_char = Encryption.encryption_key:byte((i - 1) % #Encryption.encryption_key + 1)
        local decrypted_char = (char - key_char) % 256  
        output[i] = string.char(decrypted_char)
    end
    return table.concat(output)
end

return Encryption 