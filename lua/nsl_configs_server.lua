-- Natural Selection League Plugin
-- Source located at - https://github.com/xToken/NSL
-- lua\nsl_configs_server.lua
-- - Dragon

--NSL Configs
local configFileName = "NSLConfig.json"
local leagueConfigUpdateURL = "https://raw.githubusercontent.com/xToken/NSL/master/configs/nsl_leagueconfig.json"
local perfConfigUpdateURL = "https://raw.githubusercontent.com/xToken/NSL/master/configs/nsl_perfconfig.json"
local spawnConfigUpdateURL = "https://raw.githubusercontent.com/xToken/NSL/master/configs/nsl_spawnconfig.json"
local teamConfigUpdateURL = "https://raw.githubusercontent.com/xToken/NSL/master/configs/nsl_teamconfig.json"
local consistencyConfigUpdateURL = "https://raw.githubusercontent.com/xToken/NSL/master/configs/nsl_consistencyconfig.json"
local configRequestTracking = { 
								leagueConfigRequest = false, leagueConfigRetries = 0, leagueLocalConfig = "configs/nsl_leagueconfig.json", leagueExpectedVersion = 2.2, leagueConfigComplete = false,
								perfConfigRequest = false, perfConfigRetries = 0, perfLocalConfig = "configs/nsl_perfconfig.json", perfExpectedVersion = 1.0, perfConfigComplete = false,
								consistencyConfigRequest = false, consistencyConfigRetries = 0, consistencyLocalConfig = "configs/nsl_consistencyconfig.json", consistencyExpectedVersion = 1.0, consistencyConfigComplete = false,
								spawnConfigRequest = false, spawnConfigRetries = 0, spawnLocalConfig = "configs/nsl_spawnconfig.json", spawnExpectedVersion = 1.0, spawnConfigComplete = false,
								teamConfigRequest = false, teamConfigRetries = 0, teamLocalConfig = "configs/nsl_teamconfig.json", teamExpectedVersion = 1.3, teamConfigComplete = false
								}
local NSL_Mode = "PCW"
local NSL_League = "NSL"
local NSL_PerfLevel = "DEFAULT"
local NSL_CachedScores = { }
local NSL_Scores = { }
local NSL_ServerCommands = { }
local NSL_LeagueAdminsAccess = false
local NSL_PerfConfigsBlocked = false
local cachedScoresValidFor = 10 * 60

function GetNSLMode()
	return NSL_Mode
end

function GetNSLModEnabled()
	return NSL_Mode ~= "DISABLED"
end

function GetActiveLeague()
	return NSL_League
end

function GetRecentScores()
	return NSL_CachedScores
end

function GetNSLPerfLevel()
	return NSL_PerfLevel
end

function GetNSLLeagueAdminsAccess()
	return NSL_LeagueAdminsAccess
end

function GetNSLPerfConfigsBlocked()
	return NSL_PerfConfigsBlocked
end

function RegisterNSLServerCommand(commandName, commandFunction, helpText, optionalAlwaysAllowed, nslAdminCommand)
	NSL_ServerCommands[string.gsub(commandName, "Console_", "")] = nslAdminCommand or false
	CreateServerAdminCommand(commandName, commandFunction, helpText, optionalAlwaysAllowed)
end

local function LoadConfig()
	local defaultConfig = { mode = "PCW", league = "NSL", perf = "DEFAULT", recentgames = { }, adminaccess = false, perfconfigsblocked = false }
	WriteDefaultConfigFile(configFileName, defaultConfig)
	local config = LoadConfigFile(configFileName) or defaultConfig
	NSL_Mode = config.mode or "PCW"
	NSL_League = config.league or "NSL"
	NSL_PerfLevel = config.perf or "DEFAULT"
	NSL_LeagueAdminsAccess = config.adminaccess or false
	NSL_PerfConfigsBlocked = config.perfconfigsblocked or false
	local loadedScores = config.recentgames or { }
	local updated = false
	for t, s in pairs(loadedScores) do
		if type(s) == "table" and (Shared.GetSystemTime() - (s.scoretime or 0) < cachedScoresValidFor) and (s.score or 0) > 0 then
			NSL_CachedScores[t] = s.score or 0
		end
	end
end

LoadConfig()

local function SetSeasonOnLoad()
	if GetNSLModEnabled() then
		Server.SetServerProperty(Seasons.kPropertyKey, Seasons.kNone)
	end
end

SetSeasonOnLoad()

local function SavePluginConfig()
	SaveConfigFile(configFileName, { mode = NSL_Mode, league = NSL_League, perf = NSL_PerfLevel, recentgames = NSL_Scores, adminaccess = NSL_LeagueAdminsAccess, perfconfigsblocked = NSL_PerfConfigsBlocked })
end

function SetNSLMode(state)
	if NSL_Mode ~= state then
		NSL_Mode = state
		SavePluginConfig()
		if NSL_Mode == "DISABLED" then
			GetGamerules():OnTournamentModeDisabled()
		else
			GetGamerules():OnTournamentModeEnabled()
		end
		for i = 1, #gPluginStateChange do
			gPluginStateChange[i](NSL_Mode)
		end
	end
end

function SetActiveLeague(state)
	if NSL_League ~= state then
		NSL_League = state
		SavePluginConfig()
		if GetNSLModEnabled() then
			EstablishConfigDependantSettings("all")
		end
	end
end

function SetPerfLevel(state)
	if NSL_PerfLevel ~= state then
		NSL_PerfLevel = state
		SavePluginConfig()
		if GetNSLModEnabled() then
			EstablishConfigDependantSettings("all")
		end
	end
end

function SetNSLAdminAccess(state)
	if NSL_LeagueAdminsAccess ~= state then
		NSL_LeagueAdminsAccess = state
		SavePluginConfig()
	end
end

function SetNSLPerfConfigAccess(state)
	if NSL_PerfConfigsBlocked ~= state then
		NSL_PerfConfigsBlocked = state
		SavePluginConfig()
	end
	if NSL_PerfConfigsBlocked then
		SetPerfLevel("DEFAULT")
	end
end

function UpdateNSLScores(team1name, team1score, team2name, team2score)
	NSL_Scores[team1name] = { score = team1score, scoretime = Shared.GetSystemTime() }
	NSL_Scores[team2name] = { score = team2score, scoretime = Shared.GetSystemTime() }
	SavePluginConfig()
end

local DefaultConfig = {
LeagueName							= "Default",
AutomaticMapCycleDelay				= 180 * 60,
PauseEndDelay 						= 5,
PauseStartDelay 					= 1,
PauseMaxPauses 						= 3,
PausedReadyNotificationDelay 		= 30,
PauseEnabled 						= true,
FriendlyFireDamagePercentage 		= 0.33,
FriendlyFireEnabled			 		= false,
TournamentModeAlertDelay 			= 30,
TournamentModeGameStartDelay 		= 15,
PausedMaxDuration 					= 120,
TournamentModeForfeitClock			= 0,
TournamentModeRestartDuration 		= 90,
Limit6PlayerPerTeam 				= false,
MercsRequireApproval 				= false,
FirstPersonSpectate					= false,
UseCustomSpawnConfigs				= false,
UseFixedSpawnsPerMap				= false,
UseDefaultSkins						= false,
PauseOnDisconnect					= false,
SavePlayerStates					= false,
OverrideTeamNames					= false,
MessageColor						= "00BFFF",
NetworkTruncation					= 0,
LeagueDecal							= 1
}

local DefaultPerfConfig = {
Interp 								= 100,
MoveRate 							= 30,
ClientRate 							= 20,
TickRate 							= 30,
MaxDataRate 						= 50,
}

local Configs = { }
local PerfConfigs = { }

local function OnLoadLocalConfig(configFile)
	local config = { }
	local file = io.open(configFile, "r")
	if file then
		config = json.decode(file:read("*all"))
		file:close()
	end
	return config
end

local function ValidateResponse(response, request)
	local responseTable
	if response then
		responseTable = json.decode(response)
		if not responseTable or not responseTable.Version or not responseTable.EndOfTable then
			if configRequestTracking[request .. "ConfigRetries"] < 3 then
				configRequestTracking[request .. "ConfigRequest"] = false
				configRequestTracking[request .. "ConfigRetries"] = configRequestTracking[request .. "ConfigRetries"] + 1
				responseTable = nil
			else
				Shared.Message(string.format("NSL - Failed getting %s config from GitHub, using local copy.", request))
				responseTable = OnLoadLocalConfig(configRequestTracking[request .. "LocalConfig"])
			end
		elseif responseTable.Version < configRequestTracking[request .. "ExpectedVersion"] then
			--Old version still on github, use local cache
			Shared.Message(string.format("NSL - Old copy of %s config on GitHub, using local copy.", request))
			responseTable = OnLoadLocalConfig(configRequestTracking[request .. "LocalConfig"])
		end
		if responseTable then
			--GOOD DATA ITS AMAZING
			configRequestTracking[request .. "ConfigComplete"] = true
		end
	end
	return responseTable
end

local function CheckForExistingConfig(leagueName)
	if not Configs[leagueName] then
		Configs[leagueName] = { }
		--Shared.Message("NSL - Adding league " .. leagueName .. ".")
	end
end

local function tablemerge(tab1, tab2)
	if tab1 and tab2 then
		for k, v in pairs(tab2) do
			if type(v) == "table" and type(tab1[k]) == "table" then
				tablemerge(tab1[k], tab2[k])
			else
				tab1[k] = v
			end
		end
	end
end

local function OnConfigResponse(response, request)
	response = ValidateResponse(response, request)
	if response and response.Configs then
		for i, config in ipairs(response.Configs) do
			if config.LeagueName then
				--assume valid, update Configs table, always uppercase
				CheckForExistingConfig(string.upper(config.LeagueName))
				--Shared.Message("NSL - Loading config " .. request .. " for " .. config.LeagueName .. ".")
				tablemerge(Configs[string.upper(config.LeagueName)], config)
			elseif config.PerfLevel then
				--Performance configs
				--Shared.Message("NSL - Loading perf config " .. config.PerfLevel .. ".")
				PerfConfigs[string.upper(config.PerfLevel)] = config
			end
		end
		if GetNSLModEnabled() then
			EstablishConfigDependantSettings(request)
		end
	end
end

local function OnServerUpdated()
	if not configRequestTracking["leagueConfigRequest"] then
		Shared.SendHTTPRequest(leagueConfigUpdateURL, "GET", function(response) OnConfigResponse(response, "league") end)
		configRequestTracking["leagueConfigRequest"] = true
	end
	if not configRequestTracking["perfConfigRequest"] and configRequestTracking["leagueConfigComplete"] then
		Shared.SendHTTPRequest(perfConfigUpdateURL, "GET", function(response) OnConfigResponse(response, "perf") end)
		configRequestTracking["perfConfigRequest"] = true
	end
	if not configRequestTracking["consistencyConfigRequest"] and configRequestTracking["perfConfigComplete"] then
		Shared.SendHTTPRequest(consistencyConfigUpdateURL, "GET", function(response) OnConfigResponse(response, "consistency") end)
		configRequestTracking["consistencyConfigRequest"] = true
	end
	if not configRequestTracking["spawnConfigRequest"] and configRequestTracking["consistencyConfigComplete"] then
		Shared.SendHTTPRequest(spawnConfigUpdateURL, "GET", function(response) OnConfigResponse(response, "spawn") end)
		configRequestTracking["spawnConfigRequest"] = true
	end
	if not configRequestTracking["teamConfigRequest"] and configRequestTracking["spawnConfigComplete"] then
		Shared.SendHTTPRequest(teamConfigUpdateURL, "GET", function(response) OnConfigResponse(response, "team") end)
		configRequestTracking["teamConfigRequest"] = true
	end
end

Event.Hook("UpdateServer", OnServerUpdated)

function GetNSLConfigValue(value)
	--Check League config
	if Configs[NSL_League] then
		--Check League/Mode Specific config
		if Configs[NSL_League][NSL_Mode] and Configs[NSL_League][NSL_Mode][value] then
			return Configs[NSL_League][NSL_Mode][value]
		end
		--Check League Specific config
		if Configs[NSL_League][value] then
			return Configs[NSL_League][value]
		end
	end
	--Base Config
	if DefaultConfig[value] then
		return DefaultConfig[value]
	end
	return nil
end

function GetNSLPerfValue(value)
	--Check base config
	if PerfConfigs[NSL_PerfLevel] and PerfConfigs[NSL_PerfLevel][value] then
		return PerfConfigs[NSL_PerfLevel][value]
	end
	if DefaultPerfConfig[value] then
		return DefaultPerfConfig[value]
	end
	return nil
end

function GetNSLLeagueValid(league)
	if Configs[league] and Configs[league].LeagueName then
		return true
	end
	return false
end

function GetPerfLevelValid(level)
	if PerfConfigs[level] and PerfConfigs[level].PerfLevel then
		return true
	end
	return false
end

function GetIsNSLRef(ns2id)
	if ns2id then
		local pData = GetNSLUserData(ns2id)
		if pData and pData.NSL_Level then
			return pData.NSL_Level >= GetNSLConfigValue("PlayerRefLevel")
		end
	end
	return false
end

function GetIsNSLAdmin(ns2id)
	if ns2id then
		local pData = GetNSLUserData(ns2id)
		if pData and pData.NSL_Level then
			return pData.NSL_Level >= GetNSLConfigValue("PlayerAdminLevel")
		end
	end
	return false
end

local function GetGroupCanRunCommand(groupData, commandName)
    
	local existsInList = false
	local commands = groupData.commands
	
	if commands then
		for c = 1, #groupData.commands do
			if groupData.commands[c] == commandName then
				existsInList = true
				break
			end
		end
	end
	
	if groupData.type == "allowed" then
		return existsInList
	elseif groupData.type == "disallowed" then
		return not existsInList
	else
		--Invalid structure
		return false
	end
	
end

function GetCanRunCommandviaNSL(ns2id, commandName)
	if NSL_LeagueAdminsAccess and GetIsNSLRef(ns2id) then
		local pData = GetNSLUserData(ns2id)
		if pData and pData.NSL_Level then
			local level = tostring(pData.NSL_Level)
			local groupData = GetNSLConfigValue("AdminGroups")
			if groupData and groupData[level] then
				return GetGroupCanRunCommand(groupData[level], commandName)
			end
		end		
	end
	return false
end

--NSL Server Admin Hooks
local oldGetClientCanRunCommand = GetClientCanRunCommand
function GetClientCanRunCommand(client, commandName, printWarning)

	if not client then return end
	local NS2ID = client:GetUserId()
	local canRun = false
	if NSL_ServerCommands[commandName] ~=nil and GetNSLModEnabled() and GetIsNSLRef(NS2ID) then
		--Check if cmd is an NSL command, check perms
		return true
	elseif NSL_LeagueAdminsAccess and GetNSLModEnabled() and GetIsNSLRef(NS2ID) then
		--Check if cmd is vanilla and leagueadminaccess is enabled
		canRun = GetCanRunCommandviaNSL(NS2ID, commandName)
	end
	if not canRun then
		return oldGetClientCanRunCommand(client, commandName, printWarning)
	end
	return canRun
	
end

local Shine = Shine

if Shine then
    -- Adds the graphical AdminMenu button to Shine's VoteMenu
    -- for NSL admins who can use sh_adminmenu
    local oldHasAccess = Shine.HasAccess
    function Shine:HasAccess(client, commandName)
        if not client then return true end

        local _, ns2id = Shine:GetUserData(client)
        local oldAccess = oldHasAccess(self, client, commandName)
        local newAccess = GetCanRunCommandviaNSL(ns2id, commandName)

        return oldAccess or newAccess
    end

    -- Gives NSL admins access to their group's Shine commands
    local oldGetPermission = Shine.GetPermission
    function Shine:GetPermission(client, commandName)
        if not client then return true end

        local _, ns2id = Shine:GetUserData(client)
        local oldPerm = oldGetPermission(self, client, commandName)
        local newPerm = GetCanRunCommandviaNSL(ns2id, commandName)

        return oldPerm or newPerm
    end
end

local Messages = {
PauseResumeMessage 					= "Game Resumed.  %s have %s pauses remaining",
PausePausedMessage					= "Game Paused.",
PauseWarningMessage					= "Game will %s in %d seconds.",
PauseResumeWarningMessage 			= "Game will automatically resume in %d seconds.",
PausePlayerMessage					= "%s has paused the game.",
PauseTeamReadiedMessage				= "%s readied for %s, resuming game.",
PauseTeamReadyMessage				= "%s readied for %s, waiting for the %s.",
PauseTeamReadyPeriodicMessage		= "%s are ready, waiting for the %s.",
PauseNoTeamReadyMessage				= "No team is ready to resume, type unpause in console to ready for your team.",
PauseCancelledMessage				= "Game Pause Cancelled.",
PauseDisconnectedMessage			= "%s disconnected, pausing game.",
PauseTooManyPausesMessage			= "Your team is out of pauses.",
TournamentModeTeamReadyAlert 		= "%s are ready, waiting on %s to start game.",
TournamentModeCountdown 			= "Game will start in %s seconds!",
TournamentModeReadyAlert 			= "Both teams need to ready for the game to start.",
TournamentModeTeamReady				= "%s has %s for %s.",
TournamentModeGameCancelled			= "Game start cancelled.",
TournamentModeForfeitWarning		= "%s have %d %s left to ready before forfeiting.",
TournamentModeGameForfeited			= "%s have forfeit the round due to not reading within %s seconds.",
TournamentModeReadyNoComm			= "Your team needs a commander to ready.",
TournamentModeStartedGameCancelled  = "%s un-readied for the %s, resetting game.",
UnstuckCancelled					= "You moved or were unable to be unstuck currently.",
Unstuck								= "Unstuck!",
UnstuckIn							= "You will be unstuck in %s seconds.",
UnstuckRecently						= "You have unstucked too recently, please wait %d seconds.",
UnstuckFailed						= "Unstuck Failed after %s attempts.",
MercApprovalNeeded					= "The opposite team will need to approve you as a merc.",
MercApproved 						= "%s has been approved as a merc for %s.",
MercsReset 							= "Merc approvals have been reset."
}

function GetNSLMessage(message)
	return Messages[message] or ""
end