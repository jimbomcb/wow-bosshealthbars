local BossHealthBar = LibStub("AceAddon-3.0"):NewAddon("BossHealthBar", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0")
_G.BHB = BossHealthBar;

local temp_font = "Fonts\\FRIZQT__.TTF" -- TODO: Expose to settings

local defaultSettings = {
    profile = {
        ver = 1,
        barLockState = "UNLOCKED", -- Valid: UNLOCKED, LOCKED, LOCKED_CLICKTHROUGH
        hideAnchorWhenLocked = false
    }
}

local options = { 
	name = "Boss Health Bars",
	handler = BossHealthBar,
	type = "group",
	args = {
		barLockState = {
			type = "select",
			name = "Bar Lock",
			desc = "How should the health bars respond to mouse input?",
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
	},
}

-- Map encounter ID to NPCs
-- encounterMap has interger key representing encounter ID
-- data is:
--   - NPCs: Lua-style array via integer-indexed table , NPC ID for each boss character to track
-- https://wowpedia.fandom.com/wiki/DungeonEncounterID 
local encounterMap = {
    -- Classic IDs:
    [744] = { npcs = { [1] = 33113 } }, -- Flame lev
    [745] = { npcs = { [1] = 33118 } }, -- Ignis
    [746] = { npcs = { [1] = 33186 } }, -- Razorscale
    [747] = { npcs = { [1] = 33293 } }, -- XT
    [748] = { npcs = { [1] = 32867, [2] = 32927, [3] = 32857 }  }, -- Iron Council
    [749] = { npcs = { [1] = 32930, [2] = 32933, [3] = 32934 } }, -- Kologarn
    [750] = { npcs = { [1] = 33515 } }, -- Auriaya
    [751] = { npcs = { [1] = 32845 } }, -- Hodir
    [752] = { npcs = { [1] = 32865 } }, -- Thorim
    [753] = { npcs = { [1] = 32906 } }, -- Freya
    [754] = { npcs = { [1] = 33350 } }, -- Mimiron
    [755] = { npcs = { [1] = 33271 } }, -- Vezax
    [756] = { npcs = { [1] = 33288 } }, -- Yogg
    [757] = { npcs = { [1] = 32871 } }, -- Algalon

    -- Retail IDs (for testing the addon ahead of Ulduar release):
    [1132] = { npcs = { [1] = 33113 } }, -- Flame lev
    [1136] = { npcs = { [1] = 33118 } }, -- Ignis
    [1139] = { npcs = { [1] = 33186 } }, -- Razorscale
    [1142] = { npcs = { [1] = 33293 } }, -- XT
    [1140] = { npcs = { [1] = 32867, [2] = 32927, [3] = 32857 } }, -- Iron Council
    [1137] = { npcs = { [1] = 32930, [2] = 32933, [3] = 32934 } }, -- Kologarn
    [1131] = { npcs = { [1] = 33515 } }, -- Auriaya
    [1135] = { npcs = { [1] = 32845 } }, -- Hodir
    [1141] = { npcs = { [1] = 32865 } }, -- Thorim
    [1133] = { npcs = { [1] = 32906 } }, -- Freya
    [1138] = { npcs = { [1] = 33350 } }, -- Mimiron
    [1134] = { npcs = { [1] = 33271 } }, -- Vezax
    [1143] = { npcs = { [1] = 33288 } }, -- Yogg
    [1130] = { npcs = { [1] = 32871 } }, -- Algalon

    -- Naxx
    [1107] = { npcs = { [1] = 15956 } }, -- Anub
    [1108] = { npcs = { [1] = 15932 } }, -- Gluth
    [1109] = { npcs = { [1] = 16060 } }, -- Gothik
    [1110] = { npcs = { [1] = 15953 } }, -- Faer
    [1111] = { npcs = { [1] = 15931 } }, -- Grobb
    [1112] = { npcs = { [1] = 15936 } }, -- Heigan
    [1113] = { npcs = { [1] = 16061 } }, -- Raz
    [1114] = { npcs = { [1] = 15990 } }, -- KT
    [1115] = { npcs = { [1] = 16011 } }, -- Loatheb
    [1116] = { npcs = { [1] = 15952 } }, -- Maex
    [1117] = { npcs = { [1] = 15954 } }, -- Noth
    [1118] = { npcs = { [1] = 16028 } }, -- Patch
    [1119] = { npcs = { [1] = 15989 } }, -- Sapph
    [1120] = { npcs = { [1] = 15928, [2] = 15929, [3] = 15930 } }, -- Thadd
    [1121] = { npcs = { [1] = 16064, [2] = 16065, [3] = 30549, [4] = 16063 } }, -- FourHoursemen

    -- Debug
    [0] = { npcs = { [1] = 42859 } }, -- Debug encounter
}

local function GetIDFromGuid(guid)
    if string.sub(guid, 0, 8) ~= "Creature" and string.sub(guid, 0, 7) ~= "Vehicle" then return nil end
    -- Parse out NPC ID from [unitType]-0-[serverID]-[instanceID]-[zoneUID]-[ID]-[spawnUID]
    local npcID = select(6, strsplit("-", guid))
    return tonumber(npcID)
end

local function GetUnitNPCID(unitID)
    local guid = UnitGUID(unitID)
    if guid == nil then return nil end
    return GetIDFromGuid(guid)
end

function BossHealthBar:OnInitialize() 

    -- Settings
    self.db = LibStub("AceDB-3.0"):New("BossHealthBar", defaultSettings, true)
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

    LibStub("AceConfig-3.0"):RegisterOptionsTable("BossHealthBar", options)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BossHealthBar", "Boss Health Bars")

	local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	LibStub("AceConfig-3.0"):RegisterOptionsTable("BossHealthBar_Profiles", profiles)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BossHealthBar_Profiles", "Profiles", "Boss Health Bars")

    self:RegisterEvent("ENCOUNTER_START", "OnEncounterStart")
    self:RegisterEvent("ENCOUNTER_END", "OnEncounterEnd")
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "OnActiveEncounterCLEU")
    
    self:RegisterChatCommand("bhb", "OnSlashCommand")

	self.baseFrame = CreateFrame("Frame", "BossHealthBarBase", UIParent)
	self.baseFrame:SetWidth(220)
	self.baseFrame:SetHeight(22)
	self.baseFrame:SetClampedToScreen(true)
    self.baseFrame:SetPoint("CENTER")
    self:UpdateBarLockState()

    self.encounterData = nil
    self.encounterActve = false -- Is the encounter ongoing
    self.encounterDeaths = {} -- Tracked NPCs that have died this encounter
    self.encounterSize = 25
    self.activeDataSources = {} -- Map NPC to datasource UnitID
    self.barPool = {} -- Pool of active bars given widgets are never destroyed
    self.activeBarMap = {} -- Current NPC to Frame mapping

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
end

function BossHealthBar:CreateAnchor()
    local baseBar = CreateFrame("Frame", "BossHealthBarBase", self.baseFrame)
	baseBar:SetWidth(220)
	baseBar:SetHeight(22)

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
    name:SetText("Boss Health Bar Anchor")
    return baseBar
end

function BossHealthBar:UpdateBarLockState()
    local lockMovement = self.db.profile.barLockState ~= "UNLOCKED"
    local lockClickthrough = self.db.profile.barLockState == "LOCKED_CLICKTHROUGH"

    if lockMovement then
        self.baseFrame:SetMovable(false)
        self.baseFrame:EnableMouse(false)
        self.baseFrame:SetScript("OnDragStart", nil);
        self.baseFrame:SetScript("OnDragStop", nil);
        self.baseFrame:SetScript("OnMouseUp", nil);
    else
        self.baseFrame:SetMovable(true)
        self.baseFrame:EnableMouse(true)
        self.baseFrame:RegisterForDrag("LeftButton")
        self.baseFrame:SetScript("OnDragStart", self.baseFrame.StartMoving);
        self.baseFrame:SetScript("OnDragStop", self.baseFrame.StopMovingOrSizing);
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

function BossHealthBar:RefreshConfig()
  -- would do some stuff here
end

function BossHealthBar:OnEnable()
end

function BossHealthBar:OnDisable()
end

function BossHealthBar:OnEncounterStart(_, encounterId, encounterName, difficultyId, groupSize)
    print("BHB Dbg: Encounter " .. encounterId .. " name " .. encounterName .. " diff " .. difficultyId .. " size " .. groupSize)

    -- Todo: Clear state if self.activeEncounter is not nil
    -- Todo: Track encounter active state, detect encounter end (separate from ENCOUNTER_END which can be missed if releasing early)

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
        self:EndActiveEncounter()
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

function BossHealthBar:UpdateAnchorVisibility()
    local isLocked = self.db.profile.barLockState ~= "UNLOCKED"
    if (self.db.profile.hideAnchorWhenLocked and isLocked) or (next(self.activeBarMap) ~= nil) then
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
        self:EndActiveEncounterDelayed()
    end

    -- Hook onto CLEU for UNIT_KILLED
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "OnActiveEncounterCLEU")

    -- print("BHB New Encounter: " .. tostring(encounterData))
    self.encounterActive = true;
    self.encounterData = encounterData
    self.encounterDeaths = {}
    self.encounterTick = self:ScheduleRepeatingTimer("TickActiveEncounter", 0.333) -- Tick at 3hz for hp check (todo: expose to settings)

    -- Hide anchor
    self.anchorBar:Hide()

    self.activeBarMap = {}
    self.npcUnitIDs = {}

    local npcIdx = 1

    -- Get/create bars for current encounter NPCs
    while encounterData.npcs[npcIdx] ~= nil do
        local npcId = encounterData.npcs[npcIdx]

        local baseBar = self:GetBarByIndex(npcIdx, true)
        baseBar:Reset()
        baseBar:SetName(tostring(npcId), true)
        baseBar:SetHealthFractionText(1.0, "Seeking...") -- TODO: Default HP value for different phases? 
    
        self.activeBarMap[npcId] = baseBar;
        npcIdx = npcIdx + 1
    end

    local priorActiveBars = self.activeBars ~= nil and self.activeBars or 0
    self.activeBars = npcIdx - 1

    -- Clean up any remaining bars that might be active from prior encounters
    while npcIdx <= priorActiveBars do
        local cleanupBar = self:GetBarByIndex(npcIdx, false)
        if cleanupBar ~= nil then cleanupBar:Hide() end
        npcIdx = npcIdx + 1
    end
end

function BossHealthBar:EndActiveEncounter()
    self.endEncounterDelay = self:ScheduleTimer("EndActiveEncounterDelayed", 2.0)
end

-- Delayed ending that gives a brief window for the CLEU UNIT_DEATH to be received, it often doesn't otherwise
function BossHealthBar:EndActiveEncounterDelayed()
    self.endEncounterDelay = nil
    self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

    self.encounterActive = false

    if self.encounterTick ~= nil then
        self:CancelTimer(self.encounterTick)
        self.encounterTick = nil
    end
end

function BossHealthBar:OnActiveEncounterCLEU() 
	local ts, event, _, _, _, _, _, destGuid, _, _, _ = CombatLogGetCurrentEventInfo()
	if event ~= "UNIT_DIED" then return end
    local npcID = GetIDFromGuid(destGuid)
    if npcID ~= nil then
        self.encounterDeaths[npcID] = true
        local widget = self.activeBarMap[npcID]
        if widget ~= nil then widget:SetHealthFractionText(0.0, "DEAD") end
    end
end

function BossHealthBar:TickActiveEncounter()
    -- Try and determine the status of our tracked NPC ids in the fewest operations possible.
    local pastDataSources = self.activeDataSources
    local dataSources = {}

    -- Determine which datasources we need to newly seek
    local npcsToSeek = {}
    for k, v in pairs(self.encounterData.npcs) do
        if pastDataSources[v] == nil and self.encounterDeaths[v] == nil then
            npcsToSeek[v] = true
        end
    end

    -- Try and carry over any data sources that are still targeting the unit without doing another scan
    -- Any data sources that we don't yet have will be scanned below
    for k, v in pairs(pastDataSources) do
        if GetUnitNPCID(v) == k and self.encounterDeaths[v] == nil then
            -- Still targeting the desired unit
            dataSources[k] = v
        end
    end

    -- Try find a datasource for any NPC that we don't yet have
    if next(npcsToSeek) ~= nil then -- A lua object with no entries will return nil for next(obj)
        -- Enumerate local target, focus & raid member targets
        local remainingTargets = {}
        for k, v in pairs(npcsToSeek) do remainingTargets[k] = v end

        local foundUnitIds = {}
        local testGuid = GetUnitNPCID("target")
        --print("a " .. UnitGUID("target") .. " b " .. testGuid)
        if testGuid ~= nil then
            if foundUnitIds[testGuid] == nil then
                foundUnitIds[testGuid] = "target"
                remainingTargets[testGuid] = nil
            end
        end

        testGuid = GetUnitNPCID("focus")
        if testGuid ~= nil then
            if foundUnitIds[testGuid] == nil then
                foundUnitIds[testGuid] = "focus"
                remainingTargets[testGuid] = nil
            end
        end

        -- Iterate the n raid players targets
        for i=1, self.encounterSize do
            if next(remainingTargets) == 0 then print("early out!") break end

            testGuid = GetUnitNPCID("raid" .. i .. "target")
            if testGuid ~= nil and foundUnitIds[testGuid] == nil then
                foundUnitIds[testGuid] = "raid" .. i .. "target"
                remainingTargets[testGuid] = nil
            end
        end

        -- Link the unitIDS targeting our desired NPC with the correct data source
        for k, v in pairs(npcsToSeek) do
            if foundUnitIds[k] ~= nil then
                dataSources[k] = foundUnitIds[k]
                break
            end
        end
    end

    -- Toggle active states for data sources gained/lost
    for k, v in pairs(self.encounterData.npcs) do
        local npcIsDead = self.encounterDeaths[v] ~= nil
        local npcWasPresent = pastDataSources[v] ~= nil
        local npcIsPresent = dataSources[v] ~= nil
        --print("ID"..v.." - Was " .. tostring(npcWasPresent) .. " Is " .. tostring(npcIsPresent))
        if npcIsDead then
            -- Noop
        elseif (npcIsPresent and not npcWasPresent) then
            local widget = self.activeBarMap[v]
            if widget ~= nil then
                widget:SetActive(true)
            end
        elseif (not npcIsPresent and npcWasPresent) then
            local widget = self.activeBarMap[v]
            if widget ~= nil then
                widget:SetActive(false)
            end
        end
    end

    -- Update data for actively tracked NPCs
    for k, v in pairs(dataSources) do
        local widget = self.activeBarMap[k]
        if widget ~= nil then
            if not widget:HasName() and UnitName(v) ~= nil then
                widget:SetName(UnitName(v), false)
            end

            local unitHealth = UnitHealth(v)
            local unitHealthMax = UnitHealthMax(v)
            widget:SetHealth(unitHealth, unitHealthMax)
        end
    end

    self.activeDataSources = dataSources;
end

function BossHealthBar:GetBarByIndex(index, createIfMissing)
    if self.barPool[index] ~= nil then return self.barPool[index] end
    if not createIfMissing then return nil end
    local baseBar =_G.BHB.HealthBar:New(self.baseFrame)
    baseBar:SetPoint("TOPLEFT", 0, (index - 1) * -22)
    self.barPool[index] = baseBar
    return baseBar
end