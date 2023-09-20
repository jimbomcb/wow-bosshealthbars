-- Maybe TODO:
-- Clickable bars
-- Default to Clean/Expressway
-- Targeted by N players
-- See how DBM does auto marking of blood beasts to get them to add in the same order (bind onto SUMMON combat log event)
-- TTK
-- MaxBars (max per NPC?)
-- Names can be unknown when picked up via nameplates
-- Target on mouse down not mouse up
-- Right-click focus?
local AddonName, Private = ...

local BHB = LibStub("AceAddon-3.0"):NewAddon("BossHealthBar", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0")
Private.BHB = BHB
BHB.VERSION = 5 -- Increment to reset DBs
local LSM = LibStub("LibSharedMedia-3.0")
local FEATURE_BossUnits = false -- NOCHECKIN

Private.DEBUG_PRINT = function (info, ...)
	if BHB.config.profile.debugMode then
		BHB:Print(...)
	end
end

local defaultSettings = {
	profile = {
		ver = 0,
		barLockState = "UNLOCKED", -- Valid: UNLOCKED, LOCKED, LOCKED_CLICKTHROUGH
		hideAnchorWhenLocked = false,
		scale = 1.0,
		barWidth = 260,
		barHeight = 22,
		maxBars = 6,
		powerBarFraction = 0.18,
		resetBarsOnEncounterFinish = false,
		showTargetMarkerIcons = true,
		reverseOrder = false,
		barTexutre = "Blizzard Raid Bar",
		font = "Friz Quadrata TT",
		fontSize = 12,
		healthDisplayOption = "PercentageDetailed", -- Default: Percentage. Options: Percentage, PercentageDetailed, Remaining, TotalRemaining
		debugMode = false,
		leftOffset = 0.5,
		topOffset = 0.8
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
					set = function (info, val)
						BHB.config.profile.resetBarsOnEncounterFinish = val
						if val and not BHB.encounterActive then BHB:WaitingForEncounter() end -- We want the bars to hide after encounter, reset if we're not in encounter
					end,
					get = function (info)
						return BHB.config.profile.resetBarsOnEncounterFinish
					end,
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
				barLockState = {
					type = "select",
					name = "Bar Lock",
					desc = "How should the Boss Health Bar panel respond to mouse input?",
					order = 0,
					values = {
						UNLOCKED = "Unlocked",
						LOCKED = "Locked",
						LOCKED_CLICKTHROUGH = "Locked & Click-through"
					},
					sorting = {
						[1] = "UNLOCKED",
						[2] = "LOCKED",
						[3] = "LOCKED_CLICKTHROUGH"
					},
					get = "GetBarLockState",
					set = "SetBarLockState",
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
					desc = "Max number of bars we can display. Default:  " .. tostring(defaultSettings.profile.maxBars),
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

local unitIdList = { "target", "targettarget", "focus", "focustarget", "mouseover", "mouseovertarget", "nameplate1", "nameplate2", "nameplate3", "nameplate4", "nameplate5", "nameplate6", "nameplate7", "nameplate8", "nameplate9", "nameplate10",
	"nameplate11", "nameplate12", "nameplate13", "nameplate14", "nameplate15", "nameplate16", "nameplate17", "nameplate18", "nameplate19", "nameplate20",
	"nameplate21", "nameplate22", "nameplate23", "nameplate24", "nameplate25", "nameplate26", "nameplate27", "nameplate28", "nameplate29", "nameplate30",
	"nameplate31", "nameplate32", "nameplate33", "nameplate34", "nameplate35", "nameplate36", "nameplate37", "nameplate38", "nameplate39", "nameplate40",
	"raid1target", "raid2target", "raid3target", "raid4target", "raid5target", "raid6target", "raid7target", "raid8target", "raid9target", "raid10target",
	"raid11target", "raid12target", "raid13target", "raid14target", "raid15target", "raid16target", "raid17target", "raid18target", "raid19target", "raid20target",
	"raid21target", "raid22target", "raid23target", "raid24target", "raid25target", "raid26target", "raid27target", "raid28target", "raid29target", "raid30target",
	"raid31target", "raid32target", "raid33target", "raid34target", "raid35target", "raid36target", "raid37target", "raid38target", "raid39target", "raid40target"
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

		self.config:RegisterDefaults(defaultSettings)
		self.config:ResetDB("Default")
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
	
	self:RegisterChatCommand("bhb", "OnSlashCommand")
	self:RegisterChatCommand("bosshealthbars", "OnSlashCommand")

	--self.baseFrame = CreateFrame("Frame", "BossHealthBar", UIParent)
	--self.baseFrame:SetWidth(self:GetBarWidth())
	--self.baseFrame:SetHeight(self:GetBarHeight())
	--self.baseFrame:SetClampedToScreen(true)
	--self.baseFrame:SetMovable(true)
--
	--self.barPool = {} -- Pool of active bars given widgets are never destroyed
	--self.boundCL = false -- Are we actively bound to the combat log events

	self.lockdown = InCombatLockdown() -- Are we in combat? Used to prevent certain actions
	Private:DEBUG_PRINT("Combat lockdown: " .. tostring(self.lockdown))

	--self.currentStatus = ""
	--self.statusColorR = 0; self.statusColorG = 1; self.statusColorB = 0; self.statusColorA = 1
end

function BHB:OnEnable()
	-- Context menu
	BHB.contextMenu = CreateFrame("FRAME", nil, self.anchorFrame, "UIDropDownMenuTemplate")
	do
		--BHB.contextMenu:SetPoint("TOPLEFT", 0, -40)
		UIDropDownMenu_Initialize(BHB.contextMenu, DropdownInit_ContextMenu, "MENU")
		BHB.contextMenu:Hide()
	end

	if not FEATURE_BossUnits then
		Private:DEBUG_PRINT("WARNING: BossUnits feature disabled, stock boss health bars will not be shown.")
	end

	-- Bind for media updates, any later-loading addons will call this
	LSM.RegisterCallback(self, "LibSharedMedia_SetGlobal", "OnMediaUpdate")
	LSM.RegisterCallback(self, "LibSharedMedia_Registered", "OnMediaUpdate")

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
	self.anchorFrame:SetPoint("TOP", 0, -250)
	self:RestoreAnchorPosition(self.anchorFrame)
end

function BHB:OnMediaUpdate(event, mediatype, media)
	if 	(mediatype == LSM.MediaType.STATUSBAR and media == self:GetBarTexture()) or
		(mediatype == LSM.MediaType.FONT and media == self:GetFont()) then
		self:OnBarMediaUpdate()
	end
end

function BHB:WaitingForEncounter()
	self:UpdateStatus("Waiting for encounter...", 0, 0.5, 0, 1)

	self.encounterInfo = {
		trackedIDs = {},
		currentTargets = {},
		trackedUnits = {}
	}
	self.encounterActive = false
	self.encounterSize = 25
	self.npcCount = {}

	self:ResetBarPool()
	self:UpdateAnchorVisibility()
end


local anchorFontFlags = "OUTLINE"
local anchorFontStatusShrink = 4

function BHB:CreateAnchor()
	local baseBar = CreateFrame("Frame", "BossHealthBarBase", self.baseFrame)
	baseBar:SetAllPoints()

	local tex = baseBar:CreateTexture()
	tex:SetColorTexture(0, 0, 0, 1.0)
	tex:SetAllPoints()
	tex:SetAlpha(0.5)

	local baseBarHealth = CreateFrame("StatusBar", nil, baseBar)
	baseBarHealth:SetMinMaxValues(0,1)
	baseBarHealth:SetValue(1.0)
	baseBarHealth:SetPoint("TOPLEFT", baseBar, "TOPLEFT", 1, -1)
	baseBarHealth:SetPoint("BOTTOMRIGHT", baseBar, "BOTTOMRIGHT", -1, 1)
	baseBarHealth:SetStatusBarTexture(self:GetBarTextureMedia())
	baseBarHealth:SetStatusBarColor(self.statusColorR, self.statusColorG, self.statusColorB, self.statusColorA)
	baseBar.healthBar = baseBarHealth

	local overlay = CreateFrame("Frame", nil, baseBarHealth)
	overlay:SetAllPoints(true)
	overlay:SetFrameLevel(baseBarHealth:GetFrameLevel()+1)

	local name = overlay:CreateFontString(nil, "OVERLAY")
	name:SetPoint("TOPLEFT", baseBar, "TOPLEFT", 4, 0)
	name:SetPoint("BOTTOMRIGHT", baseBar, "BOTTOMRIGHT", - (floor(self.baseFrame:GetWidth() * 0.33)), 0)
	name:SetJustifyH("LEFT")
	name:SetJustifyV("MIDDLE")
	name:SetFont(self:GetFontMedia(), self:GetFontSize(), anchorFontFlags)
	name:SetWordWrap(false)
	name:SetText("Boss Health Bar")
	baseBar.nameText = name

	local status = overlay:CreateFontString(nil, "OVERLAY")
	status:SetPoint("TOPLEFT", baseBar, "TOPRIGHT", - (floor(self.baseFrame:GetWidth() * 0.33)), 0)
	status:SetPoint("BOTTOMRIGHT", baseBar, "BOTTOMRIGHT", -6, 0)
	status:SetFont(self:GetFontMedia(), self:GetFontSize() - anchorFontStatusShrink, anchorFontFlags)
	status:SetNonSpaceWrap(true)
	status:SetJustifyH("RIGHT")
	status:SetJustifyV("MIDDLE")
	status:SetText(self.currentStatus)
	baseBar.statusText = status

	return baseBar
end

function BHB:OnConfigUpdated(source)
	Private:DEBUG_PRINT("OnConfigUpdated", source)
	self:BHB_SIZE_CHANGED()

	-- self:RestorePosition()

	-- self:SetBarLockState(nil, self:GetBarLockState())
	-- self:SetGrowUp(nil, self:GetGrowUp())
	-- self:SetHideAnchorWhenLocked(nil, self:GetHideAnchorWhenLocked())
	-- --self:OnSizeChanged()
	-- self:OnBarMediaUpdate()
end

function BHB:OnEncounterStart(_, encounterId, encounterName, difficultyID, groupSize)
	--self:Print("BHB Dbg: Encounter " .. encounterId)
	Private:DEBUG_PRINT("OnEncounterStart", _, encounterId, encounterName, difficultyID, groupSize)

	local encounterData = Private.encounterMap[encounterId]
	if encounterData == nil then
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

	--self:InitForEncounter(encounterData)

	-- Initialize the encounter tracker (if anchor exists, might not exist if we init in a restricted combat state)
	self:BeginTrackingEncounter(encounterData)
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

function BHB:ClearActiveEncounter()
	if self.trackedEncounter == nil then return end
	Private:DEBUG_PRINT("Clearing active encounter.")
	self.trackedEncounter = nil
end

function BHB:BeginTrackingEncounter(encounterData)
	Private:DEBUG_PRINT("Tracking encounter: ", #encounterData.npcs .. " NPCs")
	
	-- Initialize the encounter tracker
	self.trackedEncounter = Private.TrackerTest:New(nil, encounterData)
	self:QueueEncounterTicking()
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
	else
		self:Print("Unknown BHB command: " .. input)
	end
end

function BHB:ShowContextMenu()
	ToggleDropDownMenu(1, nil, self.contextMenu, "cursor", 3, -3)
end

function BHB:GetBarLockState()
	return BHB.config.profile.barLockState
end

function BHB:SetBarLockState(info, value)
	BHB.config.profile.barLockState = value
	self:SendMessage("BHB_LOCK_STATE_CHANGED")
end

function BHB:SetReverseOrder(info, state)
	BHB.config.profile.reverseOrder = state
	self:SendMessage("BHB_REVERSE_CHANGED")
end

function BHB:GetReverseOrder(info)
	return BHB.config.profile.reverseOrder
end

function BHB:SetHideAnchorWhenLocked(info, state)
	BHB.config.profile.hideAnchorWhenLocked = state
	BHB:UpdateAnchorVisibility()
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

function BHB:OnSizeChanged()
	---- Update relative frame sizes
	--local saneW = max(10, self:GetBarWidth())
	--local saneH = max(10, self:GetBarHeight())
	--local saneResourceH = self:GetResourceBarHeight()
--
	--self.baseFrame:SetWidth(saneW)
	--self.baseFrame:SetHeight(saneH)
	--self.anchorBar:SetWidth(10)
	--self.anchorBar:SetHeight(saneH)
--
	---- TODO: Can we better handle the layout of the frame to not require this? Still figuring out the frame setup	
	----self.anchorBar.nameText:SetPoint("BOTTOMRIGHT", self.anchorBar, "BOTTOMRIGHT", - (floor(self.baseFrame:GetWidth() * 0.33)), 0)
	----self.anchorBar.statusText:SetPoint("TOPLEFT", self.anchorBar, "TOPRIGHT", - (floor(self.baseFrame:GetWidth() * 0.33)), 0)
--
	---- Pooled bars
	--for idx, bar in pairs(self.barPool) do
	--	bar:UpdateSizes(saneW, saneH, saneResourceH)
	--end
--
	---- Re-sort given change in vertical offset
	--self:SortActiveBars()
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

function BHB:SavePosition()
end

function BHB:RestorePosition()
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
	if BHB.config.profile.hasAnchorPosition then
		anchorWidget:ClearAllPoints()
		anchorWidget:SetPoint(BHB.config.profile.anchorPoint, UIParent, BHB.config.profile.relativePoint, BHB.config.profile.anchorX, BHB.config.profile.anchorY)
		Private:DEBUG_PRINT("Restored anchor position", BHB.config.profile.anchorPoint, BHB.config.profile.relativePoint, BHB.config.profile.anchorX, BHB.config.profile.anchorY)
	end
end

function BHB:SetBarTexture(info, texture)
	BHB.config.profile.barTexutre = texture
	self:OnBarMediaUpdate()
end

function BHB:GetBarTexture()
	return BHB.config.profile.barTexutre
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

function BHB:OnBarMediaUpdate()
	-- Update existing bars
	local newBarTexture = self:GetBarTextureMedia()
	local newFont = self:GetFontMedia()
	self.anchorBar.healthBar:SetStatusBarTexture(newBarTexture)
	self.anchorBar.nameText:SetFont(newFont, self:GetFontSize(), anchorFontFlags)
	self.anchorBar.statusText:SetFont(newFont, math.max(1, self:GetFontSize() - anchorFontStatusShrink), anchorFontFlags)

	for idx, bar in pairs(self.barPool) do
		bar:OnMediaUpdate()
	end
end

function BHB:UpdateAnchorVisibility()
	-- Always hide anchor when there's active encounter bars
	if self:HasActiveBar() then
		self.anchorBar:Hide()
		return
	end

	-- Always show if there's no active encounter bars but we're in an encounter
	if self.encounterActive then
		self.anchorBar:Show()
		return
	end

	-- Not in an encounter, so hide when locked if desired, otherwise show
	if BHB.config.profile.barLockState ~= "UNLOCKED" and BHB.config.profile.hideAnchorWhenLocked then
		self.anchorBar:Hide()
	else
		self.anchorBar:Show()
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
		
		--local info = UIDropDownMenu_CreateInfo()
		--info.text = "Hide Anchor While Locked"
		--info.arg1 = not BHB.config.profile.hideAnchorWhenLocked
		--info.checked = BHB.config.profile.hideAnchorWhenLocked
		--info.func = function(info, arg1)
		--	BHB.config.profile.hideAnchorWhenLocked = arg1
		--	BHB:UpdateAnchorVisibility()
		--end
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

		-- Create a multi-select to pick the lock state
		local lockDropdown = {}
		lockDropdown.text = "Lock State"
		lockDropdown.notCheckable = true
		lockDropdown.hasArrow = true
		lockDropdown.menuList = { meta="lockState", data = {
			{
				text = "Unlocked",
				checked = function() return BHB:GetBarLockState() == "UNLOCKED" end,
				func = function() 
					BHB:SetBarLockState(nil, "UNLOCKED")
					CloseDropDownMenus()
					BHB:Print("Bars are now draggable.")
				end
			},
			{
				text = "Locked",
				checked = function() return BHB:GetBarLockState() == "LOCKED" end,
				func = function() 
					BHB:SetBarLockState(nil, "LOCKED")
					CloseDropDownMenus()
					BHB:Print("Bars are now locked.")
				end
			},
			{
				text = "Locked + Clickthrough",
				checked = function() return BHB:GetBarLockState() == "LOCKED_CLICKTHROUGH" end,
				func = function() 
					BHB:SetBarLockState(nil, "LOCKED_CLICKTHROUGH")
					CloseDropDownMenus()
					BHB:Print("Bars locked and click-through, edit via /bhb.")
				end
			}
		} }
		UIDropDownMenu_AddButton(lockDropdown)
		
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

function BHB:InitForEncounter(encounterData) -- encounterData is null in the event we don't have an encounterMap entry
	-- -- In the rare case that a new encounter starts while our old encounter has a pending shutdown, do cleanup
	-- if self.encounterActive then
	-- 	if self.endEncounterDelay ~= nil then self:CancelTimer(self.endEncounterDelay) end
	-- 	self:EndActiveEncounter()
	-- end
-- 
	-- self:ResetBarPool()
-- 
	-- -- Hook onto CLEU for UNIT_KILLED
	-- if not self.boundCL then
	-- 	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "OnActiveEncounterCLEU")
	-- 	self.boundCL = true
	-- end
-- 
	-- -- self:Print("BHB New Encounter: " .. tostring(encounterData))
	-- self.encounterActive = true
	-- self.encounterInfo = {
	-- 	trackedIDs = {},
	-- 	currentTargets = {},
	-- 	trackedUnits = {}
	-- }
	-- self.npcCount = {}
-- 
	-- self:UpdateStatus("Seeking targets...", 0.5, 0.5, 0.5, 1.0)
-- 
	-- if encounterData ~= nil then
	-- 	local npcIdx = 1
	-- 	while encounterData.npcs[npcIdx] ~= nil do
	-- 		local npcData = encounterData.npcs[npcIdx]
	-- 		self.encounterInfo.trackedIDs[npcData.id] = npcData
	-- 
	-- 		-- If there's no specific priority, use the definition order 
	-- 		if self.encounterInfo.trackedIDs[npcData.id].priority == nil then
	-- 			self.encounterInfo.trackedIDs[npcData.id].priority = 0 - npcIdx
	-- 		end
	-- 
	-- 		npcIdx = npcIdx + 1
	-- 	end
	-- end
-- 
	-- self.encounterTick = self:ScheduleRepeaatingTimer("TickActiveEncounter", 1/8) -- Tick at 8hz for hp check (todo: expose to settings)
	-- self:TickActiveEncounter()
	-- self:UpdateAnchorVisibility()
end

function BHB:EndActiveEncounter()
	self.endEncounterDelay = nil

	if self.boundCL then
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self.boundCL = false
	end

	self.encounterActive = false
	self:UpdateAnchorVisibility()

	if self.encounterTick ~= nil then
		self:DEBUG_PRINT("Stopping encounter tick")
		self:CancelTimer(self.encounterTick)
		self.encounterTick = nil
	end

	-- Clear the tracked state of any still tracked bars
	for _, npcBar in pairs(self.encounterInfo.trackedUnits) do
		if not npcBar:HasExpired() and npcBar:IsTracked() then
			npcBar:LostTracking()
		end
	end

	-- Reset full state if user wants
	if BHB.config.profile.resetBarsOnEncounterFinish then
		self:WaitingForEncounter()
	end
end

-- Delayed ending that gives a brief window for the CLEU UNIT_DEATH to be received, it often doesn't otherwise
function BHB:EndActiveEncounterDelayed()
	self.endEncounterDelay = self:ScheduleTimer("EndActiveEncounter", 2.0)
end

-- Filter UNIT_DIED to the individual rows for their specific behaviour
function BHB:OnActiveEncounterCLEU()
	local ts, event, _, _, _, _, _, destGuid, _, _, _ = CombatLogGetCurrentEventInfo()
	if event ~= "UNIT_DIED" then return end
	local trackedUnitBar = self.encounterInfo.trackedUnits[destGuid]
	if trackedUnitBar ~= nil then
		trackedUnitBar:OnDeath()
	end
end

local targetedUnitArray = {}
function BHB:TickActiveEncounterOld()
	local overallSeenNPCs = {} -- All NPC Guid to IDs that we saw this tick, anything not here is considered missing/untracked
	local hadBarInvalidation = false

	-- Maintain a set of bars for any "boss" units, a feature that was added in the ICC patch for things that aren't a unit like the gunship
	local trackedBossGuids = {} -- The list of known boss NPCs
	if select(4, GetBuildInfo()) > 30402 and FEATURE_BossUnits then
		for i=1, 4 do
			local unitId = "boss" .. i
			local npcGuid, npcID = GetNPCInfo(unitId)
			if npcGuid ~= nil and npcID ~= nil then
				-- Ensure that a bar exists for this boss
				if self.encounterInfo.trackedUnits[npcGuid] == nil then
					-- Newly tracked unit
					-- Don't newly track a dead NPC
					if not UnitIsDead(unitId) then
						overallSeenNPCs[npcGuid] = npcID

						local npcCount = self.npcCount[npcID] ~= nil and self.npcCount[npcID] or 1
						self.npcCount[npcID] = npcCount + 1

						-- Try and find the tracking settings for an NPC of this ID, but it could be nil for boss units that we don't have mapped above
						local trackingSettings = self.encounterInfo.trackedIDs[npcID]
						local isResourceBar = trackingSettings ~= nil and trackingSettings.resourceBar ~= nil and trackingSettings.resourceBar
						local newBar = self:GetNewBar(isResourceBar)
						newBar:Activate(npcGuid, unitId, trackingSettings, npcCount, i)
						newBar:Show()

						self.encounterInfo.trackedUnits[npcGuid] = newBar
						self:UpdateAnchorVisibility()
						hadBarInvalidation = true
					end
				else
					-- Already tracked unit, update (if not updated this tick)
					if (overallSeenNPCs[npcGuid] == nil) then
						overallSeenNPCs[npcGuid] = npcID
						self.encounterInfo.trackedUnits[npcGuid]:UpdateFrom(unitId)
					end
				end
			end
		end
	end

	-- Set targetedUnitArray to nil, repopulate any still valid targeted, focused, mouseover'd, raidtargeted NPCs
	for k in pairs(targetedUnitArray) do
		targetedUnitArray[k] = nil
	end

	local unitGuid = nil

	-- Iterate all the possible UnitIDs in unitIdList
	for _, unitId in pairs(unitIdList) do
		unitGuid = GetNPCInfo(unitId)
		if unitGuid ~= nil and targetedUnitArray[unitGuid] == nil then targetedUnitArray[unitGuid] = unitId end
	end

	-- Find desired NPCs to track from our target set
	for npcGuid, sourceUnitId in pairs(targetedUnitArray) do
		local npcID = GetIDFromGuid(npcGuid)
		if npcID ~= nil and self.encounterInfo.trackedIDs[npcID] ~= nil then

			-- NPC currently targeted by unitID 'v' is an npc of interest
			if self.encounterInfo.trackedUnits[npcGuid] == nil then
				-- Newly tracked unit
				-- Don't newly track a dead NPC
				if not UnitIsDead(sourceUnitId) then
					overallSeenNPCs[npcGuid] = npcID

					local npcCount = self.npcCount[npcID] ~= nil and self.npcCount[npcID] or 1
					self.npcCount[npcID] = npcCount + 1

					--if npcCount == 2 then
						-- TODO: This is the second instance of an NPC with the same ID, find the previous bar and append #1
					--end

					local trackingSettings = self.encounterInfo.trackedIDs[npcID]
					local newBar = self:GetNewBar(trackingSettings.resourceBar)
					newBar:Activate(npcGuid, sourceUnitId, trackingSettings, npcCount, nil)
					newBar:Show()

					self.encounterInfo.trackedUnits[npcGuid] = newBar
					self:UpdateAnchorVisibility()
					hadBarInvalidation = true
				end
			else
				-- Already tracked unit, update (if not updated this tick)
				if (overallSeenNPCs[npcGuid] == nil) then
					overallSeenNPCs[npcGuid] = npcID
					self.encounterInfo.trackedUnits[npcGuid]:UpdateFrom(sourceUnitId)
				end
			end
		end
	end

	local expiredBars = {}
	for npcGuid, npcBar in pairs(self.encounterInfo.trackedUnits) do
		if npcBar:HasExpired() then
			-- Bar expiration
			npcBar:Reset()
			expiredBars[npcGuid] = true
			hadBarInvalidation = true
		elseif overallSeenNPCs[npcGuid] == nil and npcBar:IsTracked() then
			-- Signal tracking lost for anything that wasn't present in this scan
			npcBar:LostTracking()
		end
	end

	if next(expiredBars) ~= nil then
		-- todo: We've cleaned up bars, reorder
		for npcGuid, _ in pairs(expiredBars) do
			self.encounterInfo.trackedUnits[npcGuid] = nil
		end

		self:UpdateAnchorVisibility()
	end

	if hadBarInvalidation then
		self:SortActiveBars()
	end
end

function BHB:HasActiveBar()
	--if not self.encounterActive then return false end -- Disabled, we don't invalidate this until the next encounter starts
	if self.encounterInfo ~= nil then
		for npcGuid, npcBar in pairs(self.encounterInfo.trackedUnits) do
			if npcBar:IsActive() then
				return true
			end
		end
	end
	return false
end

function BHB:GetNewBar(isResourceBar)
	local lastIdx = 0
	for idx, bar in pairs(self.barPool) do
		if not bar:IsActive() then return bar end
		lastIdx = idx
	end

	local baseBar =_G.BHB.HealthBar:New(self.baseFrame, self:GetBarWidth(), self:GetBarHeight(), self:GetResourceBarHeight())
	self.barPool[lastIdx + 1] = baseBar
	return baseBar
end

function BHB:SortActiveBars()
	local activeBars = {}
	local activeBarIdx = 1
	for idx, bar in pairs(self.barPool) do
		if bar:IsActive() then
			activeBars[activeBarIdx] = bar
			activeBarIdx = activeBarIdx + 1
		end
	end

	table.sort(activeBars, function(a,b)
		local prioA = a:GetPriority()
		local prioB = b:GetPriority()
		if prioA ~= prioB then return prioA > prioB end
		-- Fall back to bar spawn order
		return a:GetBarUID() < b:GetBarUID()
	end)
	
	--local verticalOffset = 0
	--if BHB.config.profile.reverseOrder then
	--	for i = #activeBars, 1, -1 do
	--		activeBars[i]:SetPoint("TOPLEFT", 0, -floor(verticalOffset))
	--		verticalOffset = verticalOffset + activeBars[i]:GetHeight()
	--	end
	--else
	--	for i = 1, #activeBars do
	--		activeBars[i]:SetPoint("TOPLEFT", 0, -floor(verticalOffset))
	--		verticalOffset = verticalOffset + activeBars[i]:GetHeight()
	--	end
	--end

	local verticalOffset = 0
	local heightScale = BHB.config.profile.growUp and -1 or 1
	if BHB.config.profile.reverseOrder then
		for i = #activeBars, 1, -1 do
			activeBars[i]:SetPoint("TOPLEFT", 0, -floor(verticalOffset * heightScale))
			verticalOffset = verticalOffset + activeBars[i]:GetHeight()
		end
	else
		for i = 1, #activeBars do
			activeBars[i]:SetPoint("TOPLEFT", 0, -floor(verticalOffset * heightScale))
			verticalOffset = verticalOffset + activeBars[i]:GetHeight()
		end
	end

	return verticalOffset
end

function BHB:UpdateStatus(msg, r, g, b, a)
	self.currentStatus = msg
	if self.anchorBar ~= nil then
		self.anchorBar.statusText:SetText(msg)
		if r ~= nil then
			self.anchorBar.healthBar:SetStatusBarColor(r, g, b, a)
		end
	end
end

function BHB:ResetBarPool()
	for idx, bar in pairs(self.barPool) do
		bar:Hide()
		bar:SetParent(nil)
	end
	self.barPool = {}
end