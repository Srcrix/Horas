# Horas

[![Roblox](https://img.shields.io/badge/Platform-Roblox-blue.svg)](https://www.roblox.com/)

**Horas** is an open-source **Permission Management System (PMS)** designed to help developers manage access control efficiently while serving as an educational resource for mastering `ModuleScripts` and cross-boundary communication (Client-Server) in Roblox.

## 🌟 Key Features

* **Modular Architecture:** Easily add new permission rules by creating simple ModuleScripts in the `Permissions` folder.
* **Hybrid Support:** Works on both the **Server** (for security) and **Client**.
* **Secure Verification:** Includes a `VerifyWithServer` method to let the Client ask the Server to validate permissions securely.
* **Logic Gates:** Supports complex checks (e.g., "Must have Group A OR Group B" vs "Must have Group A AND Group B").

---

## 📦 Installation

1.  Download the latest `.rbxm` file from the [Releases Page](../../releases).
2.  Drag and drop the file into **Roblox Studio**.
3.  Place the `Horas` module inside **ReplicatedStorage**.
    * *Note: Placing it in ReplicatedStorage allows both the Client and Server to access it.*

---

## 🚀 Usage

### 1. Basic Usage (Server or Client)
You can check permissions instantly. If run on the Client, this is good for hiding UI elements (but not secure against exploiters).

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Horas = require(ReplicatedStorage.Horas)

-- Check if player has the 'Admin' permission OR belongs to Group 123
local hasAccess = Horas:HasPermission(player, { "Admin", "Group:123" })

if hasAccess then
    print("Welcome, Admin!")
end
```

### 2. Secure Server Verification (Client Only)
When performing a critical action from a LocalScript (like showing an Admin Panel that triggers server events), you should verify with the server to ensure the player isn't spoofing the result.

```lua
local Horas = require(game.ReplicatedStorage.Horas)

-- This sends a request to the Server to run the check
local isConfirmed = Horas:HasPermission(player, { "Admin" }, true) -- Forces the check to run on the Server

if isConfirmed then
    AdminFrame.Visible = true
else
    warn("Security check failed.")
end
```

### 3. Logic Gates (RequireAll vs RequireAny)
By default, Horas returns true if the player meets ANY of the requirements. You can force them to meet ALL requirements using RequireAll.

```lua
-- Player must be in Group 123 AND have the 'VIP' rank
local strictCheck = Horas:HasPermission(player, {
    RequireAll = true, -- Enforces all checks
    "Group:123",
    "VIP"
})

-- You could do it this way too
local strictCheck = Horas:HasPermission(player, {
    "RequireAll", -- Enforces all checks
    "Group:123",
    "VIP"
})
```

### 4. Adding Custom Permissions
Horas is designed to be extended easily. You don't need to edit the main script.

1. Open the Permissions folder inside the Horas module.
2. Create a new ModuleScript (e.g., MyCheck).
3. Use the following structure or copy the ExamplePermission one

```lua
local MyCheck = {}

function MyCheck:Init()
    -- Optional: Run code when Horas starts
    print("MyCheck module loaded")
end

-- The function name matches the check string (e.g., "MyCheck:Arg1")
function MyCheck:checkPermission(player, argument)
    -- Your logic here
    if player.Name == "3xp0x3d" then
        return true
    end
    return false
end

return MyCheck
```
4. Now you can use it in your code: ```Horas:HasPermission(player, {"MyCheck:SomeArg"}).```

##📄 License
This project is licensed under the Creative Commons Attribution 4.0 International (CC BY 4.0).

You are free to:
 - Share — copy and redistribute the material in any medium or format.
 - Adapt — remix, transform, and build upon the material for any purpose, even commercially.

Under the following terms:
 - Attribution — You must give appropriate credit, provide a link to the license, and indicate if changes were made.

See LICENSE for more details.
