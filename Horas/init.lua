--!nocheck
debug.setmemorycategory("Horas")

--[[
	Horas - Permission Management System
	Copyright (c) 2025 3xp0x3d

	This work is licensed under the Creative Commons Attribution 4.0 International License.
	To view a copy of this license, visit:
	https://creativecommons.org/licenses/by/4.0/

	Full Legal Code:
	https://creativecommons.org/licenses/by/4.0/legalcode.en

	You are free to:
	  * Share — copy and redistribute the material in any medium or format.
	  * Adapt — remix, transform, and build upon the material for any purpose, even commercially.

	Under the following terms:
	  * Attribution — You must give appropriate credit, provide a link to the license, 
	    and indicate if changes were made. You may do so in any reasonable manner, 
	    but not in any way that suggests the licensor endorses you or your use.
]]--
local version    = "1.1.0"
local Settings   = require(script.Settings)
--
local RunService = game:GetService("RunService")
local Players    = game:GetService("Players")

local Horas = {}

--[[

Runs the init function for Horas.

]]
function Horas:Init()
	if self.hasInited then
		warn(string.format("[Horas] A script tried to init Horas when its already on.\nScript & Line: %s", debug.traceback(nil, 2)))
		return false, "Horas has already been inited"
	end
	
	if Settings.DebugMode then
		print("[Horas] Init function called, initiating Horas.")
	end
	
	self.hasInited = true
	self.authFunction = {}
	
	for _, module in ipairs(script.Permissions:GetChildren()) do
		if module:IsA("ModuleScript") then
			local requiredModule = require(module)
			requiredModule:Init()
			self.authFunction[module.Name] = requiredModule
			
			if Settings.DebugMode then
				print(string.format("[Horas] Loaded permission module: %s", module.Name))
			end
		end
	end
	
	if RunService:IsServer() then
		local HorasNetwork = script:FindFirstChild("HorasNetwork")
		
		if not HorasNetwork then
			HorasNetwork = Instance.new("RemoteFunction")
			HorasNetwork.Name = "HorasNetwork"
			HorasNetwork.Parent = script
		end
		self.__horasNetwork = HorasNetwork
		
		HorasNetwork.OnServerInvoke = function(player: Player, authChecks: { string })
			if typeof(authChecks) ~= "table" then return false end

			if Settings.DebugMode then
				print(string.format("[Horas Networking] Server received check from %s", player.Name))
			end

			return self:HasPermission(player, authChecks)
		end

	elseif RunService:IsClient() then
		local HorasNetwork = script:WaitForChild("HorasNetwork", 10)
		
		if HorasNetwork then
			self.__horasNetwork = HorasNetwork
		else
			warn("[Horas] Client Init Warning: RemoteFunction 'HorasNetwork' not found. VerifyWithServer will fail.")
		end
	end
end

--[[

Runs the auth function for the permission segment and returns the result.
** @param player: Player - The player to check permissions for.
** @param authChecks: {string} - A table of permission segments to check.
** @param verifyWithServer: boolean - If true, the function will verify the permissions with the server. Default is false. Only works on Client.
** @return boolean | string - Returns true if the player has all the permissions, false otherwise. Returns a string with the error message or the function you used return a string.

]]
function Horas:HasPermission(player: Player, authChecks: {string}, verifyWithServer: boolean): boolean | string
	if not self.hasInited then
		warn("[Horas] You tried to use HasPermission before initializing. Attempting auto-init...")
		self:Init()
	end

	if authChecks == nil then
		warn("[Horas] You tried to use the HasPermission function without any auth checks.\nScript & Line: "..debug.traceback(nil, 2))
		return false, "No auth checks provided"
	end
	
	if RunService:IsClient() and verifyWithServer == true then
		if not self.remoteFunction then
			warn("[Horas] VerifyWithServer failed: RemoteFunction not ready.")
			return false, "RemoteFunction not ready"
		end
		
		return self.__horasNetwork:InvokeServer(authChecks)
	end

	if typeof(player) == "number" then
		player = Players:GetPlayerByUserId(player)
		
		if not player then 
			return false, "Couldn't found a player with that user id"
		end
	end

	if player == nil then
		if RunService:IsClient() then
			player = Players.LocalPlayer
		else
			return false, "Player is nil (Server requires player argument)"
		end
	end

	local debugPrintMessage = ""
	local requireAll = false
	
	if authChecks.RequireAll ~= nil then
		requireAll = authChecks.RequireAll
	elseif authChecks[1] == "RequireAll" then
		requireAll = true
	end

	if Settings.DebugMode then
		local checkSegments = {}
		
		for _, v in pairs(authChecks) do
			if typeof(v) == "string" then table.insert(checkSegments, v)
			elseif typeof(v) == "table" then table.insert(checkSegments, "NestedTable") end
		end

		debugPrintMessage = string.format("\n[Horas Debug]\nChecking %s\nMode: %s\nChecks: [ %s ]", 
			player.Name, 
			requireAll and "RequireAll" or "RequireAny", 
			table.concat(checkSegments, ", ")
		)
	end

	for key, permissionSegment in pairs(authChecks) do
		if key == "RequireAll" or permissionSegment == "RequireAll" then continue end

		local isAuthed = false
		local checkNameForLog = "Unknown"
		local actualReturnValue = nil
		local returnedMessage = nil

		if typeof(permissionSegment) == "table" then
			local result = self:HasPermission(player, permissionSegment)

			checkNameForLog = "Intermediate table"
			actualReturnValue = result
			isAuthed = (result ~= false and result ~= nil)
		elseif typeof(permissionSegment) == "string" then
			checkNameForLog = permissionSegment
			local expectedResult = true

			if string.sub(permissionSegment, 1, 1) == "!" then
				expectedResult = false
				permissionSegment = string.sub(permissionSegment, 2)
			end

			local args = string.split(permissionSegment, ":")
			local funcName = args[1]

			if self.authFunction[funcName] then
				local result, response = self.authFunction[funcName]:checkPermission(player, table.unpack(args, 2))
				actualReturnValue = result
				
				if result == nil then
					warn("[Horas] Auth function returned nil for: ".. funcName .."\nAuth Check: ".. permissionSegment .."\nAuth Error: ".. (response and tostring(response) or "No error") .."\nScript & Line: ".. debug.traceback(nil, 2))
					return false, "Auth function returned nil"
				end
				
				returnedMessage = response

				local resultAsBool = (result ~= false and result ~= nil)
				isAuthed = (resultAsBool == expectedResult) 

				if isAuthed and not resultAsBool then
					actualReturnValue = true
				end
			else
				warn("[Horas] Auth function not found: " .. funcName)
				isAuthed = false
			end
		else
			warn("[Horas] Auth check is not a string or table.\nScript & Line: "..debug.traceback(nil, 2))
		end

		if Settings.DebugMode then
			debugPrintMessage = debugPrintMessage .. string.format("\n\t> Check: '%s' | Passed: %s | Returned: %s | Reason: %s", checkNameForLog, tostring(isAuthed), tostring(actualReturnValue), returnedMessage or "No reason")
		end

		if requireAll then
			if not isAuthed then
				if Settings.DebugMode then print(debugPrintMessage .. "\n\n[Result] FAILED (RequireAll enforcement)") end
				return false
			end
		elseif isAuthed then
			if Settings.DebugMode then print(debugPrintMessage .. "\n\n[Result] PASSED (Met at least one)") end
			return actualReturnValue 
		end
	end

	if Settings.DebugMode then 
		print(debugPrintMessage .. "\n[Result] " .. (requireAll and "PASSED" or "FAILED") .. " (End of checks)") 
	end

	return requireAll
end


return Horas