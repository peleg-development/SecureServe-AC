## New Update | Soon
# SecureServe - Free & Open Source Fivem Anti-Cheat

- **Discord:** [Join Our Server](https://discord.gg/z6qGGtbcr4) for live support and updates.
- **Docs:** [SecureServe Documentation](https://peleg.gitbook.io/secureserve/)
- **Support the anticheat for future updates:** [KOFI](https://ko-fi.com/peleg)
- **Please use the release beta or v versions only unless u want to the test latest version (might be bugged)!**

SecureServe is a state-of-the-art anti-cheat solution designed specifically for FiveM servers. Combining advanced detection techniques with comprehensive server protection, it ensures a fair and secure gaming environment. This open-source script is completely free to use, modify, and extend.

---

## 🚀 **Getting Started**

### Step-by-Step Installation
1. **Encountering Ban Messages:** During the initial setup, you may see the following ban reason:
   > *"A player has been banned for Trigger Event with an executor (name of the event)"*
2. **How to Fix It:**
   - Open the configuration file.
   - Identify the event name causing the issue.
   - Add the event name to the **whitelisted events list** in the config.
3. **Still Have Issues?**
   - Read our docs: [SecureServe Documentation](https://peleg.gitbook.io/secureserve/)
   - Join our [Discord](https://discord.gg/z6qGGtbcr4) and open a ticket for personalized support.

---

## 🛡️ **Core Features**

### Advanced Entity Detections
- **Unauthorized Entity Blocking:** Prevents cheats from spawning illegitimate entities.
- **Trigger Event Monitoring:** Automatically detects and prevents unauthorized triggers.
- **Suspicious Resource Scanning:** Identifies and flags unauthorized resources.
- **Internal Executor Protection:** Detects hidden executor exploits.
- **Audio Manipulation Defense:** Stops unauthorized sound exploits.
- **Entity Control Safeguard:** Secures entities from control hijacking.
- **Enhanced Player Safety:** Ensures players are shielded from typical exploits.

### Intelligent Client-Side Protections
- **Menu and Cheat Detection:** Flags unauthorized cheat menus.
- **Noclip & Freecam Defense:** Prevents players from abusing these features.
- **Godmode Prevention:** Detects invincibility cheats.
- **Weapon Exploit Detection:** Identifies rapid-fire and recoil cheats.
- **AI Modification Alerts:** Flags altered AI files used for exploits.

### Comprehensive Server-Side Monitoring
- **Weapon and Particle Oversight:** Tracks unauthorized items and particle effects.
- **Explosion Management:** Detects and blocks unauthorized explosions.
- **Resource Security:** Stops unauthorized attempts to halt server resources.

---

## 📥 **Installation Guide**

1. **Set Up Logging Webhooks:** Enable webhook logs for monitoring actions.
2. **Adjust Whitelisted Events:** Update the config file with events causing false positives.
3. **Explosion Threshold Tuning:** Set minimum and maximum values for explosion detections tailored to your server.

**Sample Ban Export Command:**
```lua
exports['SecureServe']:banPlayer(source, 'Detected Cheat Activity')
```

---

## 🌐 **Upcoming Enhancements**
- **Anti Internal Module:** Returning soon with optimized performance.
- **Standalone Admin Panel:** Features added for ESX, QBCore, and standalone frameworks.

---

## 🤝 **Contributing to SecureServe**
We value contributions! If you encounter issues, have suggestions, or want to contribute code, submit a pull request or report issues on our GitHub.

---

## 🎥 **Screenshots & Video Previews**

# **Admin Panel (Ingame Panel)**
   ![Admin Panel](https://github.com/user-attachments/assets/17db7796-9602-474a-9549-e2fb7b701a22)
   ![Detection Interface](https://github.com/user-attachments/assets/5ec653eb-6fdd-47ce-9e4a-d727fb449aa2)
   ![Image 1](https://github.com/user-attachments/assets/4d5864d8-a984-4b89-bce6-7c26a74264f2)
   ![Image 2](https://github.com/user-attachments/assets/19745935-d0e8-460a-af98-944ca078ee8e)
   ![Image 3](https://github.com/user-attachments/assets/e680de5d-eef3-44b0-bf47-65b5397a1b55)
   ![Image 4](https://github.com/user-attachments/assets/93aae8da-67ae-43c4-bdff-e7f3ecc1adb0)

# **Detections**
   ![Image 5](https://github.com/user-attachments/assets/6d381556-3273-4b45-b2c6-fd1e07c836b9)
   ![Image 6](https://github.com/user-attachments/assets/f7f51ae5-0229-4261-a91f-525cd64afd6d)
   ![Image 7](https://github.com/user-attachments/assets/7ff2e07e-5f4c-4caa-b308-fedb87e44aa3)
   ![Image 8](https://github.com/user-attachments/assets/7a73d5ec-bd6f-441e-9761-7f4734d8c471)
   ![Image 9](https://github.com/user-attachments/assets/14964ca5-85eb-4df1-8aa1-b8b000790d8c)
   ![Image 10](https://github.com/user-attachments/assets/788300fa-0c1b-4361-bf84-c0d066af9cba)
   ![Image 11](https://github.com/user-attachments/assets/74bbe83a-1967-4f2f-8ec6-0b9bc85604eb)

### Video Previews
- **[Watch Preview 1](https://www.youtube.com/watch?v=xgFFfGNQehk)**
- **[Watch Preview 2](https://youtu.be/BfSHgVtE3eE)**

---

## 🏷️ **License**
SecureServe is licensed under the [GNU Affero General Public License v3.0](https://www.gnu.org/licenses/agpl-3.0.en.html). You are free to use, modify, and share it under the terms of this license.

---

## 📞 **Contact & Support**
- **Join Us on Discord:** [Get Help Here](https://discord.gg/z6qGGtbcr4)

--- 

## 📚 **Documentation**
Access our detailed documentation for installation, configuration, and troubleshooting guides: 
- **GitBook:** [SecureServe Documentation](https://peleg.gitbook.io/secureserve/)

**Experience unmatched security with SecureServe, the professional-grade anti-cheat solution for FiveM servers.**
