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
local Always = {}

--[[
	Runs the init function for the permission, useful for saving cache data or setting up connections.
]]
function Always:Init()
	
end

--[[
	Runs the auth function for the permission segment and returns the result.
	** @param player: Player - The player to check permissions for.
	** @param ...: any - Additional parameters for the auth function.
	** @return boolean - Returns true if the player has all the permissions, false otherwise.
	** @return string - Returns a string with the error message or the function you used return a string.
]]
function Always:checkPermission(player: Player, ...): boolean
	return true
end

return Always
