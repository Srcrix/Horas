--!strict

type ConfigData = {
	DebugMode: boolean,
	KickOnFail: boolean,
	UseCache: boolean,
	GroupAbreviations: { [string]: number },
	TeamAbreviations: { [string]: string },
}

local module: ConfigData = {
	DebugMode = true, -- Enable debug prints, useful for error handling.
	KickOnFail = true, -- Kick the player if the script fails to load their groups or other data. If set to false in case the script fails to load it will load them again but might take small amount of time to return the response.
	UseCache = true, -- Save data on the cache for some permissions to work faster.

	GroupAbreviations = {
		["TestGroup"] = 1234567890,
	},
	
	TeamAbreviations = {
		["TestTeam"] = "TestTeam"
	},
}

return module