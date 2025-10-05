---@IMPORTANT <WHITELISTING>
--[[
WHITELIST SYSTEM INSTRUCTIONS:

To whitelist players from SecureServe detections, add one of these to your server.cfg:

1. WHITELIST BY IDENTIFIER (License):
   add_ace identifier.license:YOUR_LICENSE_HERE secure.bypass.all allow

2. WHITELIST BY DISCORD ID:
   add_ace identifier.discord:YOUR_DISCORD_ID secure.bypass.all allow

3. WHITELIST BY STEAM ID:
   add_ace identifier.steam:YOUR_STEAM_ID secure.bypass.all allow

4. WHITELIST BY FIVEM ID:
   add_ace builtin.everyone secure.bypass.all allow

EXAMPLES:
   add_ace identifier.license:abc123def456 secure.bypass.all allow
   add_ace identifier.discord:123456789012345678 secure.bypass.all allow
   add_ace identifier.steam:110000100000000 secure.bypass.all allow

You can also whitelist specific protections only:
   add_ace identifier.license:YOUR_LICENSE secure.bypass.noclip allow
   add_ace identifier.license:YOUR_LICENSE secure.bypass.teleport allow
   add_ace identifier.license:YOUR_LICENSE secure.bypass.godmode allow
   add_ace identifier.license:YOUR_LICENSE secure.bypass.invisible allow
   add_ace identifier.license:YOUR_LICENSE secure.bypass.speedhack allow
   add_ace identifier.license:YOUR_LICENSE secure.bypass.superjump allow
   add_ace identifier.license:YOUR_LICENSE secure.bypass.spectate allow
   add_ace identifier.license:YOUR_LICENSE secure.bypass.freecam allow
   add_ace identifier.license:YOUR_LICENSE secure.bypass.visions allow
   add_ace identifier.license:YOUR_LICENSE secure.bypass.playerblips allow
   add_ace identifier.license:YOUR_LICENSE secure.bypass.noragdoll allow
   add_ace identifier.license:YOUR_LICENSE secure.bypass.infinitestamina allow
   add_ace identifier.license:YOUR_LICENSE secure.bypass.magicbullet allow
   add_ace identifier.license:YOUR_LICENSE secure.bypass.norecoil allow
   add_ace identifier.license:YOUR_LICENSE secure.bypass.aimassist allow
