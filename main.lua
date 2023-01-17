local BossHealthBar = LibStub("AceAddon-3.0"):NewAddon("BossHealthBar", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0")
_G.BHB = BossHealthBar;

local temp_font = "Fonts\\FRIZQT__.TTF" -- TODO: Expose to settings

local defaultSettings = {
	profile = {
		ver = 1,
		barLockState = "UNLOCKED", -- Valid: UNLOCKED, LOCKED, LOCKED_CLICKTHROUGH
		hideAnchorWhenLocked = false,
		growUp = false
	}
}

local options = { 
	name = "Boss Health Bars",
	handler = BossHealthBar,
	type = "group",
	args = {
		moreoptions={
		  name = "Bar Settings",
		  type = "group",
		  args={
			desc = {
				name = "Alter the look and feel of the boss health bars.",
				type = "description",
				order = 0,
			},
			barLockState = {
				type = "select",
				name = "Bar Lock",
				desc = "How should the Boss Health Bar panel respond to mouse input?",
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
				set = "SetBarLockState"
			},
			hideAnchorWhenLocked = {
				name = "Hide Anchor When Locked",
				desc = "When the bar is locked (or locked click-through), should the anchor be hidden outside of encounters?",
				type = "toggle",
				set = "SetHideAnchorWhenLocked",
				get = "GetHideAnchorWhenLocked"
			},
			growUp = {
				name = "Grow Up",
				desc = "Add new elements above the anchor instead of below",
				type = "toggle",
				set = "SetGrowUp",
				get = "GetGrowUp"
			},
		  }
		}
	}
}

-- Map encounter ID to NPCs
-- encounterMap has interger key representing encounter ID
-- data is:
--   - NPCs: Lua-style array via integer-indexed table , NPC ID for each boss character to track
-- https://wowpedia.fandom.com/wiki/DungeonEncounterID 
local encounterMap = {
	-- Classic IDs:
	[744] = { npcs = { [1] = { id = 33113 } } }, -- Flame lev
	[745] = { npcs = { [1] = { id = 33118 } } }, -- Ignis
	[746] = { npcs = { [1] = { id = 33186 } } }, -- Razorscale
	[747] = { npcs = { [1] = { id = 33293 }, [2] = { id = 33329 } } }, -- XT
	[748] = { npcs = { [1] = { id = 32867 }, [2] = { id = 32927 }, [3] = { id = 32857 } } }, -- Iron Council
	[749] = { npcs = { [1] = { id = 32930 }, [2] = { id = 32934 }, [3] = { id = 32933 } } }, -- Kologarn
	[750] = { npcs = { [1] = { id = 33515 }, [2] = { id = 34035 } } }, -- Auriaya, Feral Defenders
	[751] = { npcs = { [1] = { id = 32845 } } }, -- Hodir
	[752] = { npcs = { [1] = { id = 32865 }, [2] = { id = 32872 }, [3] = { id = 32873 } } }, -- Thorim, Runic Colossus, Ancient Rune Giant
	[753] = { npcs = { [1] = { id = 32906 }, [2] = { id = 33203, expireAfterDeath = 30.0 }, [3] = { id = 33202, expireAfterDeath = 30.0 }, [4] = { id = 32919, expireAfterDeath = 30.0 }, [5] = { id = 32916, expireAfterDeath = 30.0 }, [6] = { id = 33228, expireAfterDeath = 5.0, expireAfterTrackingLoss = 15.0 } } }, -- Freya, Ancient Conservator, Ancient Water Spirit, Storm Lasher, Snap Lasher, Eonar's Gift
	[754] = { npcs = { [1] = { id = 33432 }, [2] = { id = 33651 }, [3] = { id = 33670 } } }, -- Mimiron: Leviathan, Body, Head
	[755] = { npcs = { [1] = { id = 33271 }, [2] = { id = 33524, expireAfterDeath = 10.0 } } }, -- Vezax, Animus
	[756] = { npcs = { [1] = { id = 33134, priority = -100 }, [2] = { id = 33288 }, [3] = { id = 33890 } } }, -- Yogg: Sara, Yogg, Brain
	[757] = { npcs = { [1] = { id = 32871 } } }, -- Algalon

	-- Retail IDs (for testing the addon ahead of Ulduar release):
	[1132] = { npcs = { [1] = { id = 33113 } } }, -- Flame lev
	[1136] = { npcs = { [1] = { id = 33118 } } }, -- Ignis
	[1139] = { npcs = { [1] = { id = 33186 } } }, -- Razorscale
	[1142] = { npcs = { [1] = { id = 33293 }, [2] = { id = 33329 } } }, -- XT
	[1140] = { npcs = { [1] = { id = 32867 }, [2] = { id = 32927 }, [3] = { id = 32857 } } }, -- Iron Council
	[1137] = { npcs = { [1] = { id = 32930 }, [2] = { id = 32934 }, [3] = { id = 32933 } } }, -- Kologarn
	[1131] = { npcs = { [1] = { id = 33515 }, [2] = { id = 34035 } } }, -- Auriaya, Feral Defenders
	[1135] = { npcs = { [1] = { id = 32845 } } }, -- Hodir
	[1141] = { npcs = { [1] = { id = 32865 }, [2] = { id = 32872 }, [3] = { id = 32873 } } }, -- Thorim, Runic Colossus, Ancient Rune Giant
	[1133] = { npcs = { [1] = { id = 32906 }, [2] = { id = 33203, expireAfterDeath = 30.0 }, [3] = { id = 33202, expireAfterDeath = 30.0 }, [4] = { id = 32919, expireAfterDeath = 30.0 }, [5] = { id = 32916, expireAfterDeath = 30.0 }, [6] = { id = 33228, expireAfterDeath = 5.0, expireAfterTrackingLoss = 15.0 } } }, -- Freya, Ancient Conservator, Ancient Water Spirit, Storm Lasher, Snap Lasher, Eonar's Gift
	[1138] = { npcs = { [1] = { id = 33432 }, [2] = { id = 33651 }, [3] = { id = 33670 } } }, -- Mimiron: Leviathan, Body, Head
	[1134] = { npcs = { [1] = { id = 33271 }, [2] = { id = 33524, expireAfterDeath = 10.0 } } }, -- Vezax, Animus
	[1143] = { npcs = { [1] = { id = 33134, priority = -100 }, [2] = { id = 33288 }, [3] = { id = 33890 } } }, -- Yogg: Sara, Yogg, Brain
	[1130] = { npcs = { [1] = { id = 32871 } } }, -- Algalon

	-- Naxx
	[1107] = { npcs = { [1] = { id = 15956 } } }, -- Anub
	[1108] = { npcs = { [1] = { id = 15932 } } }, -- Gluth
	[1109] = { npcs = { [1] = { id = 16060 } } }, -- Gothik
	[1110] = { npcs = { [1] = { id = 15953 } } }, -- Faer
	[1111] = { npcs = { [1] = { id = 15931 } } }, -- Grobb
	[1112] = { npcs = { [1] = { id = 15936 } } }, -- Heigan
	[1113] = { npcs = { [1] = { id = 16061 } } }, -- Raz
	[1114] = { npcs = { [1] = { id = 15990 } } }, -- KT
	[1115] = { npcs = { [1] = { id = 16011 }, [2] = { id = 16286, expireAfterDeath = 5.0, expireAfterTrackingLoss = 5.0 } } }, -- Loatheb, Spore
	[1116] = { npcs = { [1] = { id = 15952 }, [2] = { id = 16486, expireAfterDeath = 5.0, expireAfterTrackingLoss = 5.0 } } }, -- Maex, WebWrap
	[1117] = { npcs = { [1] = { id = 15954 } } }, -- Noth
	[1118] = { npcs = { [1] = { id = 16028 } } }, -- Patch
	[1119] = { npcs = { [1] = { id = 15989 } } }, -- Sapph
	[1120] = { npcs = { [1] = { id = 15928 }, [2] = { id = 15929, expireAfterDeath = 8.0 }, [3] = { id = 15930, expireAfterDeath = 8.0 } } }, -- Thadd
	[1121] = { npcs = { [1] = { id = 16064 }, [2] = { id = 16065 }, [3] = { id = 30549 }, [4] = { id = 16063 } } }, -- FourHoursemen

	-- Debug encounter
	[0] = {
		npcs = {
			[1] = {
				id = 26316,
				expireAfterDeath = 3.0, -- Optional: Remove the health bar for this unit n seconds after death
				--priority = 25 -- Optional: Ordered high to low, uses npc array idx if no manual priority
			},
			[2] = {
				id = 26291
			}
		}
	},
	[1] = {
		npcs = {
			[1] = {
				id = 29724,
				expireAfterDeath = 3.0
			},
			[2] = {
				id = 29746,
				expireAfterTrackingLoss = 10.0
			}
		}
	},
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

function BossHealthBar:OnInitialize() 
	-- Settings
	self.db = LibStub("AceDB-3.0"):New("BossHealthBar", defaultSettings, true)
	self.db.RegisterCallback(self, "OnProfileChanged", function(db, newProfile) self:RefreshConfig("change") end)
	self.db.RegisterCallback(self, "OnProfileCopied", function(db, sourceProfile) self:RefreshConfig("copy") end)
	self.db.RegisterCallback(self, "OnProfileReset", function(db) self:RefreshConfig("reset") end)

	LibStub("AceConfig-3.0"):RegisterOptionsTable("BossHealthBar", options)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BossHealthBar", "Boss Health Bars")

	local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	LibStub("AceConfig-3.0"):RegisterOptionsTable("BossHealthBar_Profiles", profiles)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BossHealthBar_Profiles", "Profiles", "Boss Health Bars")

	self:RegisterEvent("ENCOUNTER_START", "OnEncounterStart")
	self:RegisterEvent("ENCOUNTER_END", "OnEncounterEnd")
	
	self:RegisterChatCommand("bhb", "OnSlashCommand")

	self.baseFrame = CreateFrame("Frame", "BossHealthBarBase", UIParent)
	self.baseFrame:SetWidth(220)
	self.baseFrame:SetHeight(22)
	self.baseFrame:SetClampedToScreen(true)
	self.baseFrame:SetMovable(true)

	self:UpdateBarLockState()
	self:RestorePosition() -- Restore saved position

	self.encounterInfo = nil
	self.encounterActive = false -- Is the encounter ongoing
	self.encounterSize = 25
	self.barPool = {} -- Pool of active bars given widgets are never destroyed
	self.boundCL = false

	-- Context menu
	self.contextMenu = CreateFrame("FRAME", nil, self.baseFrame, "UIDropDownMenuTemplate")
	do
		self.contextMenu:SetPoint("TOPLEFT", 0, -40);
		UIDropDownMenu_Initialize(self.contextMenu, DropdownInit_ContextMenu, "MENU");
		self.contextMenu:Hide()
	end

	-- Anchor bar
	self.anchorBar = self:CreateAnchor()
	self.anchorBar:SetPoint("TOPLEFT", 0, 0)
	BossHealthBar:UpdateAnchorVisibility()
end

function BossHealthBar:CreateAnchor()
	local baseBar = CreateFrame("Frame", "BossHealthBarBase", self.baseFrame)
	baseBar:SetWidth(220)
	baseBar:SetHeight(22)

	local tex = baseBar:CreateTexture();
	tex:SetColorTexture(0, 0, 0, 1.0)
	tex:SetAllPoints();
	tex:SetAlpha(0.5);

	local baseBarHealth = CreateFrame("StatusBar", nil, baseBar)
	baseBarHealth:SetMinMaxValues(0,1)
	baseBarHealth:SetValue(1.0)
	baseBarHealth:SetPoint("TOPLEFT",1,-1)
	baseBarHealth:SetPoint("BOTTOMRIGHT",-1,1)
	baseBarHealth:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
	baseBarHealth:SetStatusBarColor(0, 1, 0, 1)

	local overlay = CreateFrame("Frame", nil, baseBarHealth)
	overlay:SetAllPoints(true)
	overlay:SetFrameLevel(baseBarHealth:GetFrameLevel()+1)

	local name = overlay:CreateFontString(nil, "OVERLAY")
	name:SetPoint("LEFT", 4, 0)
	name:SetFont(temp_font, 12)
	name:SetShadowColor(0, 0, 0, 1)
	name:SetShadowOffset(-1, -1)
	name:SetText("Boss Health Bar")
	return baseBar
end

function BossHealthBar:UpdateBarLockState()
	local lockMovement = self.db.profile.barLockState ~= "UNLOCKED"
	local lockClickthrough = self.db.profile.barLockState == "LOCKED_CLICKTHROUGH"

	if lockMovement then
		--self.baseFrame:SetMovable(false)
		self.baseFrame:EnableMouse(false)
		self.baseFrame:SetScript("OnDragStart", nil);
		self.baseFrame:SetScript("OnDragStop", nil);
		self.baseFrame:SetScript("OnMouseUp", nil);
	else
		--self.baseFrame:SetMovable(true)
		self.baseFrame:EnableMouse(true)
		self.baseFrame:RegisterForDrag("LeftButton")
		self.baseFrame:SetScript("OnDragStart", self.baseFrame.StartMoving);
		self.baseFrame:SetScript("OnDragStop", function()
			self.baseFrame:StopMovingOrSizing()
			BossHealthBar:SavePosition()
		end);
	end

	if lockClickthrough then
		self.baseFrame:SetScript("OnMouseUp", nil);
	else
		self.baseFrame:SetScript("OnMouseUp", function (self, button)
			if button == "RightButton" then
				BossHealthBar:ShowContextMenu()
			end
		end);
	end
end

function BossHealthBar:RefreshConfig(source)
	self:RestorePosition()

	-- TODO: Rethink how we apply settings given what needs to change switching profiles
	self:SetBarLockState(nil, self:GetBarLockState())
	self:SetGrowUp(nil, self:GetGrowUp())
	self:SetHideAnchorWhenLocked(nil, self:GetHideAnchorWhenLocked())
end

function BossHealthBar:OnEnable()
end

function BossHealthBar:OnDisable()
end

function BossHealthBar:OnEncounterStart(_, encounterId, encounterName, difficultyId, groupSize)
	--print("BHB Dbg: Encounter " .. encounterId .. " name " .. encounterName .. " diff " .. difficultyId .. " size " .. groupSize)

	local encounterData = encounterMap[encounterId];
	if encounterData == nil then
		-- No encounter data, no healthbar available
		return
	end

	self.encounterSize = groupSize
	self:InitForEncounter(encounterData)
end

function BossHealthBar:OnEncounterEnd(_, encounterId, encounterName, difficultyId, groupSize, success)
	if self.encounterActive then
		self:EndActiveEncounterDelayed()
	end
end

function BossHealthBar:OnSlashCommand(input)
	if string.sub(input, 1, 5) == "debug" then
		local _, cmd, param1, param2 = strsplit(" ", input)
		if cmd == "start" then
			local encounterId = tonumber(param1)
			print("BHB Debug Start: Encounter " .. encounterId)

			local encounterData = encounterMap[encounterId];
			if encounterData == nil then
				print("BHB Debug Start: No encounter found.")
			else
				self.encounterSize = 25
				self:InitForEncounter(encounterData)
			end
		elseif cmd == "end" then
			self:EndActiveEncounter()
		end
	else
		print("Unknown BHB command: " .. input)
	end
end

function BossHealthBar:ShowContextMenu()
	ToggleDropDownMenu(1, nil, self.contextMenu, "cursor", 3, -3);
end

function BossHealthBar:GetBarLockState()
	return self.db.profile.barLockState
end

function BossHealthBar:SetBarLockState(info, value)
	self.db.profile.barLockState = value
	self:UpdateBarLockState()
	self:UpdateAnchorVisibility()
end

function BossHealthBar:SetGrowUp(info, state)
	self.db.profile.growUp = state

	-- Perform the order change
	self:SortActiveBars()
end

function BossHealthBar:GetGrowUp(info)
	return self.db.profile.growUp
end

function BossHealthBar:SetHideAnchorWhenLocked(info, state)
	BossHealthBar.db.profile.hideAnchorWhenLocked = state
	BossHealthBar:UpdateAnchorVisibility()
end

function BossHealthBar:GetHideAnchorWhenLocked(info)
	return BossHealthBar.db.profile.hideAnchorWhenLocked
end

function BossHealthBar:SavePosition()
	local point, relativeTo, relativePoint, xOfs, yOfs = self.baseFrame:GetPoint(1)
	self.db.profile.hasPos = true
	self.db.profile.rootPoint = point
	self.db.profile.rootX = xOfs
	self.db.profile.rootY = yOfs
end

function BossHealthBar:RestorePosition()
	self.baseFrame:ClearAllPoints()

	if self.db.profile.hasPos ~= nil and self.db.profile.hasPos then
		self.baseFrame:SetPoint(self.db.profile.rootPoint, "UIParent", self.db.profile.rootX, self.db.profile.rootY)
	else
		-- Store initial position
		self.baseFrame:SetPoint("TOP", 0, -100)
		self:SavePosition()
	end
end

function BossHealthBar:UpdateAnchorVisibility()
	local isLocked = self.db.profile.barLockState ~= "UNLOCKED"
	if (self.db.profile.hideAnchorWhenLocked and isLocked) or self:HasActiveBar() then
		self.anchorBar:Hide()
	else
		self.anchorBar:Show()
	end
end

function DropdownInit_ContextMenu()
	local barLocked = BossHealthBar:GetBarLockState() == "LOCKED"

	local info = UIDropDownMenu_CreateInfo();
	info.text = "Bar Lock";
	info.arg1 = (barLocked and "UNLOCKED" or "LOCKED")
	info.checked = barLocked
	info.func = function(info, arg1) BossHealthBar:SetBarLockState(nil, arg1) end
	UIDropDownMenu_AddButton(info);

	local info = UIDropDownMenu_CreateInfo();
	info.text = "Hide Anchor While Locked";
	info.arg1 = not BossHealthBar.db.profile.hideAnchorWhenLocked
	info.checked = BossHealthBar.db.profile.hideAnchorWhenLocked
	info.func = function(info, arg1) 
		BossHealthBar.db.profile.hideAnchorWhenLocked = arg1
		BossHealthBar:UpdateAnchorVisibility() 
	end
	UIDropDownMenu_AddButton(info);

	local info = UIDropDownMenu_CreateInfo();
	info.text = "Settings";
	info.notCheckable = true 
	info.func = function() LibStub("AceConfigDialog-3.0"):Open("BossHealthBar") end
	UIDropDownMenu_AddButton(info);

	local info = UIDropDownMenu_CreateInfo();
	info.text = "Cancel";
	info.notCheckable = true 
	info.func = function() CloseDropDownMenus() end
	UIDropDownMenu_AddButton(info);
end

function BossHealthBar:InitForEncounter(encounterData)
	-- In the rare case that a new encounter starts while our old encounter has a pending shutdown, do cleanup
	if self.encounterActive then
		if self.endEncounterDelay ~= nil then self:CancelTimer(self.endEncounterDelay) end
		self:EndActiveEncounter()
	end

	-- Reset all bars
	for idx, bar in pairs(self.barPool) do
		bar:Reset()
	end 

	-- Hook onto CLEU for UNIT_KILLED
	if not self.boundCL then
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "OnActiveEncounterCLEU")
		self.boundCL = true
	end

	-- print("BHB New Encounter: " .. tostring(encounterData))
	self.encounterActive = true;
	self.encounterInfo = {
		trackedIDs = {},
		currentTargets = {},
		trackedUnits = {}
	}

	local npcIdx = 1

	while encounterData.npcs[npcIdx] ~= nil do
		local npcData = encounterData.npcs[npcIdx]
		self.encounterInfo.trackedIDs[npcData.id] = npcData

		-- If there's no specific priority, use the definition order 
		if self.encounterInfo.trackedIDs[npcData.id].priority == nil then
			self.encounterInfo.trackedIDs[npcData.id].priority = 0 - npcIdx
		end

		npcIdx = npcIdx + 1
	end

	self.encounterTick = self:ScheduleRepeatingTimer("TickActiveEncounter", 0.333) -- Tick at 3hz for hp check (todo: expose to settings)
	self:TickActiveEncounter()
	self:UpdateAnchorVisibility()
end

function BossHealthBar:EndActiveEncounter()

	self.endEncounterDelay = nil

	if self.boundCL then
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self.boundCL = false
	end

	self.encounterActive = false

	if self.encounterTick ~= nil then
		self:CancelTimer(self.encounterTick)
		self.encounterTick = nil
	end
end

-- Delayed ending that gives a brief window for the CLEU UNIT_DEATH to be received, it often doesn't otherwise
function BossHealthBar:EndActiveEncounterDelayed()
	self.endEncounterDelay = self:ScheduleTimer("EndActiveEncounter", 2.0)
end

-- Filter UNIT_DIED to the individual rows for their specific behaviour
function BossHealthBar:OnActiveEncounterCLEU()
	local ts, event, _, _, _, _, _, destGuid, _, _, _ = CombatLogGetCurrentEventInfo()
	if event ~= "UNIT_DIED" then return end
	local trackedUnitBar = self.encounterInfo.trackedUnits[destGuid]
	if trackedUnitBar ~= nil then
		trackedUnitBar:OnDeath()
	end
end

function BossHealthBar:TickActiveEncounter()
	-- Enumerate the targeted NPCs
	local targetedUnits = {}

	local unitGuid = UnitGUID("target")
	if unitGuid ~= nil and targetedUnits[unitGuid] == nil then targetedUnits[unitGuid] = "target" end

	unitGuid = GetNPCInfo("focus")
	if unitGuid ~= nil and targetedUnits[unitGuid] == nil then targetedUnits[unitGuid] = "focus" end

	-- Iterate the n raid players targets
	for i=1, self.encounterSize do
		unitGuid = GetNPCInfo("raid" .. i .. "target")
		if unitGuid ~= nil and targetedUnits[unitGuid] == nil then targetedUnits[unitGuid] = "raid" .. i .. "target" end
	end

	-- Find desired NPCs to track from our target set
	local foundNPCsOfInterest = {}
	local hadBarInvalidation = false
	for npcGuid, sourceUnitId in pairs(targetedUnits) do
		local npcID = GetIDFromGuid(npcGuid)
		if npcID ~= nil and self.encounterInfo.trackedIDs[npcID] ~= nil then
			foundNPCsOfInterest[npcGuid] = npcID

			-- NPC currently targeted by unitID 'v' is an npc of interest
			if self.encounterInfo.trackedUnits[npcGuid] == nil then
				-- Newly tracked unit
				-- Don't newly track a dead NPC
				if not UnitIsDead(sourceUnitId) then
					local trackingSettings = self.encounterInfo.trackedIDs[npcID]
					local newBar = self:GetNewBar()
					newBar:Activate(npcGuid, sourceUnitId, trackingSettings)
					newBar:Show()

					self.encounterInfo.trackedUnits[npcGuid] = newBar
					self:UpdateAnchorVisibility()
					hadBarInvalidation = true
				end
			else
				-- Already tracked unit, update
				self.encounterInfo.trackedUnits[npcGuid]:UpdateFrom(sourceUnitId)
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
		elseif foundNPCsOfInterest[npcGuid] == nil and npcBar:IsTracked() then
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

function BossHealthBar:HasActiveBar()
	if not self.encounterActive then return false end
	for npcGuid, npcBar in pairs(self.encounterInfo.trackedUnits) do
		if npcBar:IsActive() then
			return true
		end
	end
	return false
end

function BossHealthBar:GetNewBar()
	local lastIdx = 0
	for idx, bar in pairs(self.barPool) do
		if not bar:IsActive() then return bar end
		lastIdx = idx
	end 

	local baseBar =_G.BHB.HealthBar:New(self.baseFrame)
	self.barPool[lastIdx + 1] = baseBar
	return baseBar
end

function BossHealthBar:SortActiveBars()
	local activeBars = {}
	local activeBarIdx = 1
	for idx, bar in pairs(self.barPool) do
		if bar:IsActive() then 
			activeBars[activeBarIdx] = bar
			activeBarIdx = activeBarIdx + 1
		end
	end 

	table.sort(activeBars, function(a,b) 
		return a:GetPriority() > b:GetPriority()
	end)

	for k, v in ipairs(activeBars) do 
		v:SetPoint("TOPLEFT", 0, (k - 1) * (22 * (self.db.profile.growUp and 1 or -1)))
	end
end