# SecureServe – Temporary Quickstart (README)

> **Status:** This file is temporary until full documentation is finished.
>
> **Goal:** Help you get SecureServe running safely with clear, non‑developer steps.

---

## 1) Install

1. **Create a folder** in your server files named **`[anticheat]`**.
2. **Place both resources** inside it:

   * `SecureServe`
   * `keep-alive`
3. In your `server.cfg`, ensure the folder (or each resource) is started:

   ```cfg
   # Option A – ensure the whole category
   ensure [anticheat]

   # Option B – ensure resources individually
   # ensure SecureServe
   # ensure keep-alive
   ```

> **Important:** Keep `keep-alive` enabled together with `SecureServe`.

---

## 2) Configure (open `config.lua`)

Read the config file from top to bottom and adjust values to your server.

### Admin Panel

* **Command:** `/ssm`
* **Who can open it:** Defined by your admin settings below (licenses & webhook).

```lua
-- !!! IMPORTANT !!! ADMIN PANEL COMMAND: /ssm
SecureServe.AdminMenu = {
    Webhook = "",           -- Discord webhook URL for admin actions/logs
    Licenses = {             -- Add Rockstar licenses of your admins here
        -- "license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    },
    AutoRefresh = {          -- UI refresh intervals (milliseconds)
        players = 5000,
        bans    = 15000,
        stats   = 10000
    }
}
```

> **Tip:** Paste a valid Discord webhook into `Webhook` and add trusted admin licenses.

### Server Security

There is a `Secure.ServerSecurity` section in your config. **Adjust it to your server’s framework and rules** (kicks/bans thresholds, identifiers, etc.).

---

## 3) Enable the Protection Module (recommended)

The module gives you **event**, **entity**, and **explosion** protections. To fully benefit from SecureServe, **enable the module** and (optionally) the explosion protection.

```lua
-- !!! IMPORTANT !!!
-- If you want SecureServe to work properly and enjoy all protections, enable EnableModule.
SecureServe.Module = {
	ModuleEnabled = false, -- set to true to activate module-wide protections
	Events = {
		Whitelist = { -- Events explicitly allowed even if flagged (prevents false bans)
			"TestEvent",
			"playerJoining",
		},
	},

	Entity = {
		LockdownMode = "inactive", -- 'inactive' | 'relaxed' | 'strict'
		-- relaxed: blocks client-only spawned entities not linked to scripts
		-- strict : only server-side scripts can create entities

		SecurityWhitelist = {
			-- { resource = "bob74_ipl", whitelist = true },
			-- { resource = "6x_houserobbery", whitelist = true },
		},

		Limits = { -- Maximum per-player spawns before action is taken
			Vehicles = 10,
			Peds     = 12,
			Objects  = 20,
			Entities = 40,
		},
	},

	Explosions = {
		ModuleEnabled = false, -- set to true to protect against unauthorized explosion events
		Whitelist = {         -- Allow specific resources to trigger explosions legitimately
			["resource_name_1"] = true,
			["resource_name_2"] = true,
		},
	},
}
```

**Recommended starting point:**

* Set `ModuleEnabled = true` under `SecureServe.Module`.
* If your server has legit explosion logic (heists, special jobs), set `Explosions.ModuleEnabled = true` and **whitelist** the resources that are allowed to trigger explosions.
* Begin with `Entity.LockdownMode = "relaxed"`. If you run strictly server‑spawned entities only, use `"strict"`.

> **False positives?** Add the exact event name or resource to the relevant **Whitelist**.

---

## 4) Discord Logs

Add your **Discord webhook URL** to `SecureServe.AdminMenu.Webhook`. Use separate channels/webhooks for admin actions, bans, and security alerts if desired.

> **Tip:** Keep logs in private channels only visible to your staff.

---

## 5) Quick Checklist

* [ ] `[anticheat]` folder contains **SecureServe** and **keep-alive**.
* [ ] `server.cfg` has `ensure [anticheat]` (or individual `ensure` lines).
* [ ] Admin panel opens with **`/ssm`** for licensed admins.
* [ ] `Webhook` set and tested (you should see test messages).
* [ ] Module **enabled** (and **Explosions** if needed).
* [ ] Event/Resource **whitelists** set for known safe triggers.
* [ ] Entity **LockdownMode** and **Limits** tuned to your server.

---

## 6) Troubleshooting

**Admins can’t open `/ssm`**

* Add their license to `SecureServe.AdminMenu.Licenses`.
* Check webhook and that the resource is started.

**Legit scripts get flagged/banned**

* Copy the **exact event or resource name** from the console logs and add it to the right **Whitelist**.
* Consider `Entity.LockdownMode = "relaxed"` if you run client-spawned helper props.

**Players hit spawn limits**

* Increase the relevant numbers in `Module.Entity.Limits`, but keep them conservative to prevent abuse.

**Explosions blocked that should be allowed**

* Enable `Explosions.ModuleEnabled = true` and whitelist the resource that legitimately triggers them.

---

## 7) Safety Tips

* Keep module protections **on**; whitelist **only** trusted, reviewed resources.
* Review logs regularly; adjust limits/whitelists based on real incidents.
* Store webhooks securely and rotate if leaked.

---

## 8) Minimal Example (copy/paste & edit)

```lua
-- Admin
SecureServe.AdminMenu = {
    Webhook = "https://discord.com/api/webhooks/your_webhook_here",
    Licenses = {
        "license:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        "license:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
    },
    AutoRefresh = { players = 5000, bans = 15000, stats = 10000 }
}

-- Module (recommended baseline)
SecureServe.Module = {
    ModuleEnabled = true,
    Events = { Whitelist = { "playerJoining" } },
    Entity = {
        LockdownMode = "relaxed",
        SecurityWhitelist = {},
        Limits = { Vehicles = 10, Peds = 12, Objects = 20, Entities = 40 },
    },
    Explosions = {
        ModuleEnabled = true,
        Whitelist = { ["your_heist_resource"] = true },
    },
}
```

---

**You’re set.** Keep this quickstart handy until the full docs are published.
