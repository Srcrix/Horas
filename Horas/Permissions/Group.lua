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
--
local GroupService = game:GetService("GroupService")
local Players = game:GetService("Players")

local Group = {}

function Group:_loadPlayerGroups(player: Player)
	if not self.playerGroups[player] then
		self.playerGroups[player] = {}
		
		local success, result = xpcall(function()
			local playerGroups = GroupService:GetGroupsAsync(player.UserId)
			
			for _, groupInfo in ipairs(playerGroups) do
				if table.find(self.importantGroupIds, groupInfo.Id) then
					self.playerGroups[player][groupInfo.Id] = {
						["Rank"] = groupInfo.Rank,
						["Role"] = groupInfo.Role,
					}
				end
			end
		end, function(err)
			if Settings.KickOnFail then
				player:Kick("\n[Horas]\nAn error occurred while loading groups. Please rejoin or try again later.\n\nError: ".. tostring(err))
			end
			
			warn("[Horas] An error occurred while loading ".. player.Name .." groups.\n\n".. tostring(err))
			return err
		end)
	end
end

--[[
	Runs the init function for the permission, useful for saving cache data or setting up connections.
]]
function Group:Init()
	self.playerGroups = {}
	self.importantGroupIds = {}
	self.groupIdToAbreviation = {}
	
	for abreviation, id in pairs(Settings.GroupAbreviations) do
		table.insert(self.importantGroupIds, id)
		self.groupIdToAbreviation[id] = abreviation
	end

	Players.PlayerAdded:Connect(function(player: Player)
		self:_loadPlayerGroups(player)
	end)

	for _,player: Player in pairs(Players:GetPlayers()) do
		if not self.playerGroups[player] then
			self:_loadPlayerGroups(player)
		end
	end
	
	Players.PlayerRemoving:Connect(function(player: Player)
		if self.playerGroups[player] then
			self.playerGroups[player] = nil
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
function Group:checkPermission(player: Player, ...): boolean
	local args = { ... }

	local groupNameOrId = args[1]
	local groupRank = args[2]
	local numericId = tonumber(groupNameOrId)
	local isExternalGroup = false

	if numericId then
		groupNameOrId = numericId
		isExternalGroup = true
	else
		groupNameOrId = Settings.GroupAbreviations[groupNameOrId]
	end
	
	if not groupNameOrId then
		return nil, "Group not found (Invalid ID or Abbreviation): " .. tostring(groupNameOrId)
	end
	
	local playerData = self.playerGroups[player]
	
	if not playerData then
		warn("[Horas] Group data for ".. player.Name .."was not found, loading new one.")
		self:_loadPlayerGroups(player)
		
		local startTime = os.clock()

		repeat
			task.wait(0.1)
			playerData = self.playerGroups[player]
		until playerData or (os.clock() - startTime > 5)

		if not playerData then
			return nil, "Timeout: Could not load group data for " .. player.Name
		end
	end
	
	local currentRank: number = playerData[groupNameOrId] and playerData[groupNameOrId]["Rank"]
	local currentRole: string = playerData[groupNameOrId] and playerData[groupNameOrId]["Role"]
	
	if isExternalGroup and currentRank == nil then
		local success, rank = pcall(function() return player:GetRankInGroup(groupNameOrId) end)
		local successRole, role = pcall(function() return player:GetRoleInGroup(groupNameOrId) end)
		
		local success, error = xpcall(function()
			currentRank = player:GetRankInGroup(groupNameOrId)
			currentRole = player:GetRoleInGroup(groupNameOrId)
		end, function()
			warn("[Horas] Error while getting group data for ".. player.Name ..": ".. tostring(error))
			return nil, "Error while getting group data"
		end)

		if success then currentRank = rank else currentRank = 0 end
		if successRole then currentRole = role else currentRole = "Guest" end
	elseif currentRank == nil then
		currentRank = 0
		currentRole = "Guest"
	end
	
	if groupRank == nil then
		local isInGroup = playerData[groupNameOrId] or false
		return isInGroup, if isInGroup then "User is in the group." else "User isn't in the group."
	end
	
	if string.find(groupRank, "-") then
		local minRank, maxRank = string.match(groupRank, "^(%d+)-(%d+)$")
		
		if minRank and maxRank then
			local min = tonumber(minRank)
			local max = tonumber(maxRank)
			
			if currentRank >= min and currentRank <= max then
				return true
			else
				return false, "Player is not in the group range"
			end
		end
	end
	
	local rankAsNumber = tonumber(groupRank)

	if rankAsNumber then
		if currentRank == rankAsNumber then
			return true
		else
			return false, "Player doesn't have the same rank Id"
		end
	else
		if currentRole == groupRank then
			return true
		else
			return false, "Player doesn't have the same role"
		end
	end
end

return Group
