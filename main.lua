-- Todo:
-- Targeted by N players
-- See how DBM does auto marking of blood beasts to get them to add in the same order (bind onto SUMMON combat log event)
-- track unit specific auras, ie festergut stacks, rotface ooze stacks

local AddonName, Private = ...

local BHB = LibStub("AceAddon-3.0"):NewAddon("BossHealthBar", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0")
Private.BHB = BHB
BHB.VERSION = 1 -- Increment to reset DBs

local LSM = LibStub("LibSharedMedia-3.0")
LSM:Register("statusbar", "BHBFlat", [[Interface\AddOns\BossHealthBar\media\BHBFlat.tga]])
LSM:Register("font", "ExpresswayBold", [[Interface\Addons\BossHealthBar\media\ExpBold.ttf]])

Private.DEBUG_PRINT = function (info, ...)
	if BHB.config.profile.debugMode then
		BHB:Print(...)
	end
end

local defaultSettings = {
	profile = {
		ver = 0,
		barLocked = false,
		hideAnchorWhenLocked = true,
		scale = 1.0,
		barWidth = 300,
		barHeight = 22,
		maxBars = 6,
		powerBarFraction = 0.18,
		resetBarsOnEncounterFinish = false,
		showTargetMarkerIcons = true,
		reverseOrder = false,
		barTexture = "BHBFlat",
		font = "ExpresswayBold",
		fontSize = 14,
		healthDisplayOption = "PercentageDetailed", -- Default: PercentageDetailed. Options: Percentage, PercentageDetailed, Remaining, TotalRemaining
		debugMode = false
	}
}

local options = {
	name = "Boss Health Bars",
	handler = BHB,
	type = "group",
	args = {
		generalsettings={
			order = 0,
			name = "General Settings",
			type = "group",
			args={
				desc = {
					name = "General Boss Health Bar configuration:",
					type = "description",
					order = 0,
				},
				resetBarsOnEncounterFinish = {
					order = 5,
					name = "Clear Bars on Encounter End",
					desc = "Clear any active health bars on encounter end? Otherwise health bars remain up until next encounter, which can be useful for determining your wipe percentage.",
					type = "toggle",
					set = "SetResetOnEncounterEnd",
					get = "GetResetOnEncounterEnd",
					width = "full"
				},
				showTargetMarkerIcons = {
					order = 6,
					name = "Show Marker Icons",
					desc = "If enabled, wrap the name of units in their raid icon (skull, cross, etc).",
					type = "toggle",
					set = function (info, val)
						BHB.config.profile.showTargetMarkerIcons = val
					end,
					get = function (info)
						return BHB.config.profile.showTargetMarkerIcons
					end,
					width = "full"
				},
				healthDisplayOption = {
					type = "select",
					name = "Health Display Option",
					desc = "Choose how to display boss health.",
					order = 7,
					values = {
						Percentage = "Percentage (50%)",
						PercentageDetailed = "Percentage Detailed (50.00%)",
						Remaining = "Remaining (50000))",
						TotalRemaining = "Total/Remaining (500000/1000000)",
					},
					sorting = {
						[1] = "Percentage",
						[2] = "PercentageDetailed",
						[3] = "Remaining",
						[4] = "TotalRemaining",
					},
					get = function (info)
						return BHB.config.profile.healthDisplayOption
					end,
					set = function (info, val)
						BHB.config.profile.healthDisplayOption = val
					end,
					width = "full"
				},
			}
		},
		layoutsettings={
			order = 1,
			name = "Bar Layout/Style",
			type = "group",
			args={
				desc = {
					name = "Alter the positioning and sizes of the boss health bars:",
					type = "description",
					order = 0,
				},
				barLocked = {
					order = 1,
					name = "Lock Bar Anchor",
					desc = "Lock the bar anchor in place, preventing it from being moved.",
					type = "toggle",
					set = "SetBarLocked",
					get = "GetBarLocked",
					width = "full"
				},
				hideAnchorWhenLocked = {
					order = 1,
					name = "Hide Anchor When Locked",
					desc = "When the bar is locked (or locked click-through), should the anchor be hidden outside of encounters?",
					type = "toggle",
					set = "SetHideAnchorWhenLocked",
					get = "GetHideAnchorWhenLocked",
					width = "full"
				},
				reverseOrder = {
					order = 2,
					name = "Reverse Order",
					desc = "Reverse the order in which rows are sorted, usually the boss is at the top and any additional enemies are added below.",
					type = "toggle",
					set = "SetReverseOrder",
					get = "GetReverseOrder",
					width = "full"
				},

				scale = {
					order = 8,
					name = "Scale",
					desc = "Overall boss health bar widget scaling, Default: " .. tostring(defaultSettings.profile.scale),
					type = "range",
					softMin = 0.3,
					min = 0.00001,
					softMax = 2.0,
					step = 0.01,
					set = "SetScale",
					get= "GetScale",
					width = "full"
				},
				barWidth = {
					order = 10,
					name = "Bar Width",
					desc = "Width of each boss health bar, Default: " .. tostring(defaultSettings.profile.barWidth),
					type = "range",
					softMin = 50,
					min = 160,
					softMax = 520,
					step = 2,
					set = "SetBarWidth",
					get= "GetBarWidth",
					width = "full"
				},
				barHeight = {
					order = 11,
					name = "Bar Height",
					desc = "Height of each boss health bar, Default:  " .. tostring(defaultSettings.profile.barHeight),
					type = "range",
					min = 12,
					softMax = 75,
					step = 1,
					set = "SetBarHeight",
					get= "GetBarHeight",
					width = "full"
				},
				maxBars = {
					order = 11,
					name = "Max Bars",
					desc = "Max number of bars we can display. 6 is recommended for ICC encounters. Default:  " .. tostring(defaultSettings.profile.maxBars),
					type = "range",
					min = 1,
					softMax = 10,
					step = 1,
					set = "SetMaxBars",
					get= "GetMaxBars",
					width = "full"
				},
				powerBarFraction = {
					order = 13,
					name = "Resource Bar Height Percentage",
					desc = "Proportion of the health bar height that is taken up by the resource bar, Default:  " .. tostring(defaultSettings.profile.powerBarFraction*100) .. "%",
					type = "range",
					min = 0,
					max = 100,
					step = 1,
					set = function(info, val) BHB:SetResourceBarHeight(val / 100) end,
					get= function() return BHB:GetResourceBarHeight() * 100 end,
					width = "full"
				},
				barTexture = {
					type = "select",
					name = "Bar Texture",
					order = 20,
					dialogControl = "LSM30_Statusbar",
					values = AceGUIWidgetLSMlists.statusbar,
					width = "full",
					set = "SetBarTexture",
					get= "GetBarTexture",
				},
				barFont = {
					type = "select",
					name = "Bar Font",
					order = 21,
					dialogControl = "LSM30_Font",
					values = AceGUIWidgetLSMlists.font,
					width = "0.5",
					set = "SetFont",
					get= "GetFont",
				},
				fontSize = {
					order = 22,
					name = "Font Size",
					desc = "Size of the boss name & health value. Default: " .. tostring(defaultSettings.profile.fontSize),
					type = "range",
					min = 1,
					softMax = 64,
					step = 1,
					set = "SetFontSize",
					get= "GetFontSize",
					width = "0.5"
				},
			}
		}
	}
}

local function GetIDFromGuid(guid)
	if string.sub(guid, 0, 8) ~= "Creature" and string.sub(guid, 0, 7) ~= "Vehicle" then return nil end
	-- Parse out NPC ID from [unitType]-0-[serverID]-[instanceID]-[zoneUID]-[ID]-[spawnUID]
	local npcID = select(6, strsplit("-", guid))
	return tonumber(npcID)
end

local function GetNPCInfo(unitID)
	local guid = UnitGUID(unitID)
	if guid == nil then return nil, nil end
	return guid, GetIDFromGuid(guid)
end

function BHB:OnInitialize()
	-- Settings	
	self.config = LibStub("AceDB-3.0"):New("BossHealthBar", defaultSettings, true)
	self.config.RegisterCallback(self, "OnProfileChanged", function(db, newProfile) self:OnConfigUpdated("change") end)
	self.config.RegisterCallback(self, "OnProfileCopied", function(db, sourceProfile) self:OnConfigUpdated("copy") end)
	self.config.RegisterCallback(self, "OnProfileReset", function(db)
		self.config = defaultSettings
		self:OnConfigUpdated("reset")
	end)

	-- Reset the config if the version changes
	if self.config.profile.ver ~= self.VERSION then
		if self.config.profile.ver > 0 then
			BHB:Print("Migrating BHB profile from version " .. tostring(self.config.profile.ver) .. " to " .. tostring(self.VERSION))
		end

		-- Initial setup
		if self.config.profile.ver == 0 then
			-- Migrate to the new default fonts if using the old defaults
			if self.config.profile.font == "Friz Quadrata TT" then
				self.config.profile.font = "ExpresswayBold"
			end

			if self.config.profile.barTexture == "Blizzard Raid Bar" or self.config.profile.barTexture == "Blizzard" then
				self.config.profile.barTexture = "BHBFlat"
			end

			-- Migrate old positions from rootX, rootY, rootPoint to the new anchorX, anchorY
			if self.config.profile.rootX ~= nil and self.config.profile.rootY ~= nil then
				BHB.config.profile.hasAnchorPosition = true
				BHB.config.profile.anchorPoint = self.config.profile.rootPoint
				BHB.config.profile.relativePoint = self.config.profile.rootPoint
				BHB.config.profile.anchorX = self.config.profile.rootX
				BHB.config.profile.anchorY = self.config.profile.rootY
				Private:DEBUG_PRINT("Migrating from old rootX, rootY, rootPoint to new anchorX, anchorY, anchorPoint")
			end

			-- Increase font size if using old default
			if self.config.profile.fontSize == 12 then
				self.config.profile.fontSize = 14
			end

			-- Forcefully unlock, as we want to prompt the user to reposition us after the change to a fixed number of bars
			self.config.profile.barLocked = false

			-- Hide anchor when locked going forward
			self.config.profile.hideAnchorWhenLocked = true

			-- Use DetailedPercentage instead of Percentage if applied
			if self.config.profile.healthDisplayOption == "Percentage" then
				self.config.profile.healthDisplayOption = "PercentageDetailed"
			end
		end

		--self.config:RegisterDefaults(defaultSettings)
		--self.config:ResetDB("Default")

		self.config.profile.ver = self.VERSION
		self:OnConfigUpdated("reset")
	end

	if self.config.profile.debugMode then
		self:Print("DEBUG MODE ENABLED")
	end

	LibStub("AceConfig-3.0"):RegisterOptionsTable("BossHealthBar", options)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BossHealthBar", "Boss Health Bars")

	local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.config)
	LibStub("AceConfig-3.0"):RegisterOptionsTable("BossHealthBar_Profiles", profiles)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BossHealthBar_Profiles", "Profiles", "Boss Health Bars")

	self:RegisterEvent("ENCOUNTER_START", "OnEncounterStart")
	self:RegisterEvent("ENCOUNTER_END", "OnEncounterEnd")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnRegenDisabled")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnRegenEnabled")

	self:RegisterMessage("BHB_SIZE_CHANGED")
	self:RegisterMessage("BHB_SCALE_CHANGED")
	self:RegisterMessage("BHB_MAXBARS_CHANGED")
	self:RegisterMessage("BHB_LOCK_STATE_CHANGED")
	self:RegisterMessage("BHB_REVERSE_CHANGED")
	self:RegisterMessage("BHB_RESOURCE_SIZE_CHANGED")
	self:RegisterMessage("BHB_RESET")
	
	self:RegisterChatCommand("bhb", "OnSlashCommand")
	self:RegisterChatCommand("bosshealthbars", "OnSlashCommand")

	LSM.RegisterCallback(self, "LibSharedMedia_Registered")
	
	self.lockdown = InCombatLockdown() -- Are we in combat? Used to prevent certain actions
	Private:DEBUG_PRINT("Combat lockdown: " .. tostring(self.lockdown))

	self.boundCLEU = false
end

-- Triggered externally when the addon is activating, after initializing above
function BHB:OnEnable()
	-- Context menu
	BHB.contextMenu = CreateFrame("FRAME", nil, self.anchorFrame, "UIDropDownMenuTemplate")
	do
		--BHB.contextMenu:SetPoint("TOPLEFT", 0, -40)
		UIDropDownMenu_Initialize(BHB.contextMenu, DropdownInit_ContextMenu, "MENU")
		BHB.contextMenu:Hide()
	end

	-- Try initialize the encounter monitor if we're not in combat and out of an encounter
	if not InCombatLockdown() then
		Private:DEBUG_PRINT("Not in active combat, initializing protected anchor bar")
		self:InitializeAnchorBar()
	else
		Private:DEBUG_PRINT("Queued anchor init due to combat lock")
		self.queuedAnchorInit = true
	end
end

function BHB:InitializeAnchorBar()
	self.anchorFrame = BHB.Anchor:New()
	self:RestoreAnchorPosition(self.anchorFrame)
end

function BHB:LibSharedMedia_Registered(event, mediatype, media)
	-- Update the anchor bar media if a relevant bar texture or font is getting registered
	if 	(mediatype == LSM.MediaType.STATUSBAR and media == self:GetBarTexture()) or
		(mediatype == LSM.MediaType.FONT and media == self:GetFont()) then
		self:OnBarMediaUpdate()
	end
end

function BHB:OnConfigUpdated(source)
	Private:DEBUG_PRINT("OnConfigUpdated", source)

	self:BHB_SIZE_CHANGED()
	self:OnBarMediaUpdate()

	if self.anchorFrame ~= nil then
		self:RestoreAnchorPosition(self.anchorFrame)
	end
	
	if self.anchorFrame ~= nil then
		self.anchorFrame:UpdateBarVisibility()
	end

	self:SendMessage("BHB_LOCK_STATE_CHANGED")
	self:SendMessage("BHB_REVERSE_CHANGED")
	self:SendMessage("BHB_SCALE_CHANGED")
	self:SendMessage("BHB_SIZE_CHANGED")
	self:SendMessage("BHB_MAXBARS_CHANGED")
	self:SendMessage("BHB_RESOURCE_SIZE_CHANGED")
end

function BHB:QueueEncounterTicking()
	if self.encounterTick == nil then
		Private:DEBUG_PRINT("Starting encounter tick")
		self.encounterTick = BHB:ScheduleRepeatingTimer("TickActiveEncounter", 1/8) -- Tick at 8hz for hp check (todo: expose to settings)
	end
end

function BHB:TickActiveEncounter()
	if self.trackedEncounter == nil then
		if self.encounterTick ~= nil then
			Private:DEBUG_PRINT("Active encounter gone away, stopping tick")
			self:CancelTimer(self.encounterTick)
			self.encounterTick = nil
		end
		return
	end

	self.trackedEncounter:Tick()

	if self.anchorFrame ~= nil then
		self.anchorFrame:UpdateFromTracker(self.trackedEncounter)
	end
end

function BHB:BeginTrackingEncounter(encounterData)
	-- Clear any possible previous encounter
	if self.trackedEncounter ~= nil then self:ClearActiveEncounter() end

	-- Initialize the encounter tracker
	if self.trackedEncounter ~= nil then error("Already tracking an encounter") end

	Private:DEBUG_PRINT("Tracking encounter: ", #encounterData.npcs .. " NPCs")
	self.trackedEncounter = Private.TrackerEncounter:New(nil, encounterData)
	self:QueueEncounterTicking()

	-- Register for combat log events (UNIT_DIED specifically)
	if not self.boundCLEU then
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "OnActiveEncounterCLEU")
		self.boundCLEU = true
	end

	-- Signal anchor bar 
	if self.anchorFrame ~= nil then
		self.anchorFrame:OnEncounterStart(encounterData)
	end
end

function BHB:ClearActiveEncounter()
	if self.trackedEncounter == nil then return end
	Private:DEBUG_PRINT("Clearing active encounter.")

	self.trackedEncounter:OnEncounterEnding()

	-- One final tick to grab the dead state of units
	self:TickActiveEncounter()

	self.trackedEncounter = nil

	if self.boundCLEU then
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self.boundCLEU = false
	end

	-- Signal anchor bar
	if self.anchorFrame ~= nil then
		self.anchorFrame:OnEncounterEnd()
	end
end

function BHB:OnEncounterStart(_, encounterId, encounterName, difficultyID, groupSize)
	--self:Print("BHB Dbg: Encounter " .. encounterId)
	Private:DEBUG_PRINT("OnEncounterStart", _, encounterId, encounterName, difficultyID, groupSize)

	if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
		if Private.retailEncounterAliases[encounterId] ~= nil then
			Private:DEBUG_PRINT("Remapping encounter ID: ", encounterId, " -> ", Private.retailEncounterAliases[encounterId])
			encounterId = Private.retailEncounterAliases[encounterId]
		end
	end

	local encounterData = Private.encounterMap[encounterId]
	if encounterData == nil then
		Private:DEBUG_PRINT("Unknown encounter ID: ", encounterId)

		-- No encounter data, potentially untrackable encounter
		-- Clear existing encounter bars and update the status to signal we can't track this		
		-- local knownUntrackableName = BHB.knownMissingEncounters[encounterId]
		-- if knownUntrackableName ~= nil then
		-- 	self:WaitingForEncounter()
		-- 	self:UpdateStatus(format("Unable to track %s", knownUntrackableName), 0.5, 0.5, 0.5, 1.0)
		-- 	return
		-- end
		return
	end

	Private:DEBUG_PRINT("Encounter data found for: ", encounterId)

	--self:InitForEncounter(encounterData)

	-- Initialize the encounter tracker (if anchor exists, might not exist if we init in a restricted combat state)
	self:BeginTrackingEncounter(encounterData)
end

-- Filter UNIT_DIED to the individual rows for their specific behaviour
function BHB:OnActiveEncounterCLEU()
	local ts, event, _, _, _, _, _, destGuid, _, _, _ = CombatLogGetCurrentEventInfo()
	if event ~= "UNIT_DIED" then return end

	if self.trackedEncounter == nil then return end
	self.trackedEncounter:OnUnitDied(destGuid)
end

function BHB:OnEncounterEnd(_, encounterId, encounterName, difficultyId, groupSize, success)
	Private:DEBUG_PRINT("OnEncounterEnd", _, encounterId, encounterName, difficultyId, groupSize, success)
	self:ClearActiveEncounter()
end

function BHB:OnRegenDisabled()
	Private:DEBUG_PRINT("BHB OnRegenDisabled")
	self.lockdown = true

	if self.anchorFrame ~= nil then
		self.anchorFrame:OnRegenDisabled()
	end
end

function BHB:OnRegenEnabled()
	Private:DEBUG_PRINT("BHB OnRegenEnabled")
	self.lockdown = false

	-- Check for queued anchor init	
	if self.queuedAnchorInit ~= nil then
		self:InitializeAnchorBar()
		self.queuedAnchorInit = nil
	end

	if self.anchorFrame ~= nil then
		self.anchorFrame:OnRegenEnabled()
	end
end

function BHB:OnSlashCommand(input)
	if input == "settings" or input == "options" or input == "" then
		LibStub("AceConfigDialog-3.0"):Open("BossHealthBar")
	elseif string.sub(input, 1, 5) == "debug" then
		local _, cmd, param1, param2 = strsplit(" ", input)
		if cmd == "start" then
			local encounterId = tonumber(param1)
			self:Print("BHB Debug Start: Encounter " .. encounterId)

			self:OnEncounterStart(nil, encounterId, "debug", 0, 25)
		elseif cmd == "end" or cmd == "stop" then
			self:ClearActiveEncounter()
			self:Print("Encounter ended")
		elseif cmd == "toggle" then
			BHB.config.profile.debugMode = not BHB.config.profile.debugMode
			self:Print("Debug mode: " .. tostring(BHB.config.profile.debugMode))
		end
	elseif input == "unlock" then
		self:SetBarLocked(nil, false)
	elseif input == "lock" then
		self:SetBarLocked(nil, true)
	else
		self:Print("Unknown BHB command: " .. input)
	end
end

function BHB:ShowContextMenu()
	ToggleDropDownMenu(1, nil, self.contextMenu, "cursor", 3, -3)
end

function BHB:GetBarLocked()
	return BHB.config.profile.barLocked
end

function BHB:SetBarLocked(info, value)
	BHB.config.profile.barLocked = value
	self:SendMessage("BHB_LOCK_STATE_CHANGED")

	if value then 
		BHB:Print("Boss Health Bar locked, use /bhb unlock to unlock.")
	else
		BHB:Print("Boss Health Bar unlocked, anchor is now movable.")
	end
end

function BHB:SetReverseOrder(info, state)
	BHB.config.profile.reverseOrder = state
	self:SendMessage("BHB_REVERSE_CHANGED")

	if state then 
		BHB:Print("Boss Health Bar reverse order enabled, bars will populate from bottom to top.")
	else
		BHB:Print("Boss Health Bar reverse order disabled, bars will populate top to bottom.")
	end
end

function BHB:GetReverseOrder(info)
	return BHB.config.profile.reverseOrder
end

function BHB:SetHideAnchorWhenLocked(info, state)
	BHB.config.profile.hideAnchorWhenLocked = state

	if state then
		BHB:Print("Boss Health Bar anchor will be hidden when locked.")
	else
		BHB:Print("Boss Health Bar anchor will be shown when locked.")
	end

	if self.anchorFrame ~= nil then
		self.anchorFrame:UpdateBarVisibility()
	end
end

function BHB:GetHideAnchorWhenLocked(info)
	return BHB.config.profile.hideAnchorWhenLocked
end

function BHB:SetScale(info, scale)
	BHB.config.profile.scale = scale
	self:SendMessage("BHB_SCALE_CHANGED")
end

function BHB:GetScale()
	if BHB.config.profile.scale == nil then return defaultSettings.profile.scale end
	return BHB.config.profile.scale
end

function BHB:SetBarWidth(info, width)
	BHB.config.profile.barWidth = width
	self:SendMessage("BHB_SIZE_CHANGED")
end

function BHB:GetBarWidth()
	if BHB.config.profile.barWidth == nil then return defaultSettings.profile.barWidth end
	return BHB.config.profile.barWidth
end

function BHB:SetBarHeight(info, height)
	BHB.config.profile.barHeight = height
	self:SendMessage("BHB_SIZE_CHANGED")
end

function BHB:GetBarHeight(info)
	if BHB.config.profile.barHeight == nil then return defaultSettings.profile.barHeight end
	return BHB.config.profile.barHeight
end

function BHB:SetMaxBars(info, maxBars)
	BHB.config.profile.maxBars = maxBars
	self:SendMessage("BHB_MAXBARS_CHANGED")
end

function BHB:GetMaxBars(info)
	if BHB.config.profile.maxBars == nil then return defaultSettings.profile.maxBars end
	return BHB.config.profile.maxBars
end

function BHB:SetResourceBarHeight(height)
	BHB.config.profile.powerBarFraction = height
	self:SendMessage("BHB_RESOURCE_SIZE_CHANGED")
end

function BHB:GetResourceBarHeight()
	if BHB.config.profile.powerBarFraction == nil then return defaultSettings.profile.powerBarFraction end
	return BHB.config.profile.powerBarFraction
end

function BHB:SetResetOnEncounterEnd(_, reset)
	BHB.config.profile.resetBarsOnEncounterFinish = reset
	self:SendMessage("BHB_RESET")
end

function BHB:GetResetOnEncounterEnd()
	if BHB.config.profile.resetBarsOnEncounterFinish == nil then return defaultSettings.profile.resetBarsOnEncounterFinish end
	return BHB.config.profile.resetBarsOnEncounterFinish
end

function BHB:BHB_SIZE_CHANGED()
	if self.anchorFrame ~= nil then
		self.anchorFrame:BHB_SIZE_CHANGED()
	end
end

function BHB:BHB_SCALE_CHANGED()
	if self.anchorFrame ~= nil then
		self.anchorFrame:BHB_SCALE_CHANGED()
	end
end

function BHB:BHB_MAXBARS_CHANGED()
	if self.anchorFrame ~= nil then
		self.anchorFrame:BHB_MAXBARS_CHANGED()
	end
end

function BHB:BHB_LOCK_STATE_CHANGED()
	if self.anchorFrame ~= nil then
		self.anchorFrame:BHB_LOCK_STATE_CHANGED()
	end
end

function BHB:BHB_REVERSE_CHANGED()
	if self.anchorFrame ~= nil then
		self.anchorFrame:BHB_REVERSE_CHANGED()
	end
end

function BHB:BHB_RESOURCE_SIZE_CHANGED()
	if self.anchorFrame ~= nil then
		self.anchorFrame:BHB_RESOURCE_SIZE_CHANGED()
	end
end

function BHB:BHB_RESET()
	if self.anchorFrame ~= nil then
		self.anchorFrame:ResetState()
	end
end

function BHB:SaveAnchorPosition(anchorWidget)
	-- Store the anchor point and relative offsets for restore on load
	local anchorPoint, _, relativePoint, xOfs, yOfs = anchorWidget:GetPoint(1)
	BHB.config.profile.hasAnchorPosition = true
	BHB.config.profile.anchorPoint = anchorPoint
	BHB.config.profile.relativePoint = relativePoint
	BHB.config.profile.anchorX = xOfs
	BHB.config.profile.anchorY = yOfs
	Private:DEBUG_PRINT("Saved anchor position", anchorPoint, relativePoint, xOfs, yOfs)
end

function BHB:RestoreAnchorPosition(anchorWidget)
	anchorWidget:ClearAllPoints()
	if BHB.config.profile.hasAnchorPosition then
		anchorWidget:SetPoint(BHB.config.profile.anchorPoint, UIParent, BHB.config.profile.relativePoint, BHB.config.profile.anchorX, BHB.config.profile.anchorY)
		Private:DEBUG_PRINT("Restored anchor position", BHB.config.profile.anchorPoint, BHB.config.profile.relativePoint, BHB.config.profile.anchorX, BHB.config.profile.anchorY)
	else
		-- Default position
		anchorWidget:SetPoint("TOP", 0, -250)
	end
end

function BHB:SetBarTexture(info, texture)
	BHB.config.profile.barTexture = texture
	self:OnBarMediaUpdate()
end

function BHB:GetBarTexture()
	return BHB.config.profile.barTexture
end

function BHB:GetBarTextureMedia()
	return LSM:Fetch("statusbar", self:GetBarTexture())
end

function BHB:SetFont(info, font)
	BHB.config.profile.font = font
	self:OnBarMediaUpdate()
end

function BHB:GetFont()
	return BHB.config.profile.font
end

function BHB:GetFontMedia()
	return LSM:Fetch("font", self:GetFont())
end

function BHB:SetFontSize(info, size)
	BHB.config.profile.fontSize = size
	self:OnBarMediaUpdate()
end

function BHB:GetFontSize(info)
	return BHB.config.profile.fontSize
end

-- Called when bar or fonts change, we need to reapply some settings
function BHB:OnBarMediaUpdate()
	if self.anchorFrame ~= nil then
		Private:DEBUG_PRINT("Triggering anchor OnBarMediaUpdate")
		self.anchorFrame:OnBarMediaUpdate()
	end
end

function DropdownInit_ContextMenu(frame, level, menuList)
	if level == 1 then
		--local barLocked = BHB:GetBarLockState() == "LOCKED"
		
		--local info = UIDropDownMenu_CreateInfo()
		--info.text = "Bar Lock"
		--info.arg1 = (barLocked and "UNLOCKED" or "LOCKED")
		--info.checked = barLocked
		--info.func = function(info, arg1) BHB:SetBarLockState(nil, arg1) end
		--UIDropDownMenu_AddButton(info)

		local info = UIDropDownMenu_CreateInfo()
		info.text = "Settings"
		info.notCheckable = true
		info.func = function() LibStub("AceConfigDialog-3.0"):Open("BossHealthBar") end
		UIDropDownMenu_AddButton(info)

		-- Option to clear the data for any encounters that are no longer active, resetting to anchor only
		--local showResetButton = not BHB.encounterActive and BHB:HasActiveBar()

		--[[local info = UIDropDownMenu_CreateInfo()
		info.text = "Clear Previous Encounter"
		info.notCheckable = true
		info.func = function() BHB:WaitingForEncounter() end
		info.opacity = 0.1
		UIDropDownMenu_AddButton(info);]]--
		
		local info = UIDropDownMenu_CreateInfo()
		info.text = "Hide Anchor While Locked"
		info.arg1 = BHB:GetHideAnchorWhenLocked()
		info.checked = BHB:GetHideAnchorWhenLocked()
		info.func = function(info, arg1)
			BHB:SetHideAnchorWhenLocked(nil, not BHB:GetHideAnchorWhenLocked())
		end
		UIDropDownMenu_AddButton(info)
		
		local info = UIDropDownMenu_CreateInfo()
		info.text = "Lock Bar Anchor"
		info.arg1 = BHB:GetBarLocked()
		info.checked = BHB:GetBarLocked()
		info.func = function(info, arg1)
			BHB:SetBarLocked(nil, not BHB:GetBarLocked())
		end
		UIDropDownMenu_AddButton(info)
		
		local info = UIDropDownMenu_CreateInfo()
		info.text = "Reverse Order"
		info.arg1 = BHB:GetReverseOrder()
		info.checked = BHB:GetReverseOrder()
		info.func = function(info, arg1)
			BHB:SetReverseOrder(nil, not BHB:GetReverseOrder())
		end
		UIDropDownMenu_AddButton(info)
	
		local info = UIDropDownMenu_CreateInfo()
		info.text = "Cancel"
		info.notCheckable = true
		info.func = function() CloseDropDownMenus() end
		UIDropDownMenu_AddButton(info)

	elseif level == 2 and menuList.meta == "lockState" then
		local info = UIDropDownMenu_CreateInfo()
		for _, option in pairs(menuList.data) do
			info.text = option.text
			info.checked = option.checked
			info.func = option.func
			UIDropDownMenu_AddButton(info, level)
		end
	end
end
