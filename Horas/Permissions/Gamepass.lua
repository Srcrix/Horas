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

local Settings = require(script.Parent.Parent.Settings)
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local Gamepass = {}

--[[
	Runs the init function for the permission, useful for saving cache data or setting up connections.
]]
function Gamepass:Init()
	self._gamepassDataCache = {}
	
	Players.PlayerRemoving:Connect(function(player: Player)
		if self._gamepassDataCache[player] then
			self._gamepassDataCache[player] = nil
		end
	end)
end

--[[
	Runs the auth function for the permission segment and returns the result.
	** @param player: Player - The player to check permissions for.
	** @param ...: any - Additional parameters for the auth function.
	** @return boolean - Returns true if the player has all the permissions, false otherwise.
	** @return string - Returns a string with the error message or the function you used return a string.
]]
function Gamepass:checkPermission(player: Player, ...): boolean
	local args = { ... }
	
	if not args[1] then
		return nil, "No gamepass ID provided"
	end
	
	local gamepassId = tonumber(args[1])
	
	if Settings.UseCache then
		if (self._gamepassDataCache[player] and self._gamepassDataCache[player][gamepassId]) then return true end
	end
	
	if MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId) then
		if Settings.UseCache then self._gamepassDataCache[player][gamepassId] = true end
		return true
	else
		return false, "Gamepass not owned"
	end
end

return Gamepass
