local AddonName, Private = ...

local TrackerEncounter = Private.TrackerBase:New()
Private.TrackerEncounter = TrackerEncounter

function TrackerEncounter:New(o, encounterData)
	o = o or Private.TrackerBase:New(o)
	setmetatable(o, self)
	self.__index = self

	if encounterData == nil then error "Encounter data required" end

	self.encounterData = encounterData
	self.trackedUnits = {}
	self.trackedUnitsSorted = {}
	self.trackedUnitsThisTick = {}
	self.tickCount = 0
	self.encounterActive = true
	self.removedUnits = {} -- The ongoing list of units that have been removed from tracking, to avoid re-adding a bar on death

	-- Build some maps for our encounter data for quicker runtime lookup
	self.encounterNPCs = {}
	for _, npc in pairs(encounterData.npcs) do
		self.encounterNPCs[tostring(npc.id)] = npc
	end

	self.encounterNPCPriority = {}
	for idx, npc in pairs(encounterData.npcs) do
		self.encounterNPCPriority[tostring(npc.id)] = npc.priority or (0 - idx) -- Either use the specified priority or fall back to 0 minus index, so that display order matches definition order
	end

	-- Mpa of encounter boss units to boss unit priority
	self.encounterBosses = encounterData.bosses ~= nil and encounterData.bosses or {}
	Private:DEBUG_PRINT("Encounter bosses: " .. #self.encounterBosses)
	for bossUnit, bossPrio in pairs(self.encounterBosses) do
		Private:DEBUG_PRINT("Boss " .. bossUnit, bossPrio)
	end

	return o
end

local unitIdList = { "target", "targettarget", "targettargettarget", "focus", "focustarget", "mouseover", "mouseovertarget",
	"nameplate1", "nameplate2", "nameplate3", "nameplate4", "nameplate5", "nameplate6", "nameplate7", "nameplate8", "nameplate9", "nameplate10",
	"nameplate11", "nameplate12", "nameplate13", "nameplate14", "nameplate15", "nameplate16", "nameplate17", "nameplate18", "nameplate19", "nameplate20",
	"nameplate21", "nameplate22", "nameplate23", "nameplate24", "nameplate25", "nameplate26", "nameplate27", "nameplate28", "nameplate29", "nameplate30",
	"nameplate31", "nameplate32", "nameplate33", "nameplate34", "nameplate35", "nameplate36", "nameplate37", "nameplate38", "nameplate39", "nameplate40",
	"raid1target", "raid2target", "raid3target", "raid4target", "raid5target", "raid6target", "raid7target", "raid8target", "raid9target", "raid10target",
	"raid11target", "raid12target", "raid13target", "raid14target", "raid15target", "raid16target", "raid17target", "raid18target", "raid19target", "raid20target",
	"raid21target", "raid22target", "raid23target", "raid24target", "raid25target", "raid26target", "raid27target", "raid28target", "raid29target", "raid30target",
	"raid31target", "raid32target", "raid33target", "raid34target", "raid35target", "raid36target", "raid37target", "raid38target", "raid39target", "raid40target"
}

local sortFunction = function(a,b)
	local prioA = a:GetPriority()
	local prioB = b:GetPriority()
	if prioA ~= prioB then return prioA > prioB end
	--- Fall back to bar spawn order
	return a:GetCreationTime() < b:GetCreationTime()
end

function TrackerEncounter:OnEncounterEnding()
	Private:DEBUG_PRINT("TrackerEncounter:OnEncounterEnding()")
	self.encounterActive = false

	-- Clear tracked state of any tracked units at time of end
	for guid, unit in pairs(self.trackedUnits) do
		unit:OnEnd()
	end
end

local markersThisTick = {}
local curUnitGuid
local newUnits = false
function TrackerEncounter:Tick()
	self.tickCount = self.tickCount + 1

	-- Remove anything from trackedUnits that has ShouldRemove
	for guid, unit in pairs(self.trackedUnits) do
		if unit:ShouldRemove() then
			self:RemoveTrackedUnit(guid)
		end
	end

	-- Gather the Guids of all the relevant tracked units this tick
	for k, v in pairs(self.trackedUnitsThisTick) do self.trackedUnitsThisTick[k] = nil end
	for k, v in pairs(markersThisTick) do markersThisTick[k] = nil end

	-- Iterate any relevant boss units
	for bossUnit, bossTrackingData in pairs(self.encounterBosses) do
		curUnitGuid = UnitGUID(bossUnit)
		if curUnitGuid ~= nil and not self.trackedUnitsThisTick[curUnitGuid] and self.removedUnits[curUnitGuid] == nil then
			if self.trackedUnits[curUnitGuid] == nil then
				self.trackedUnits[curUnitGuid] = Private.TrackedUnit.New(curUnitGuid, bossUnit, 0, bossTrackingData.priority or 0, bossTrackingData)
				table.insert(self.trackedUnitsSorted, self.trackedUnits[curUnitGuid])
				newUnits = true
				Private:DEBUG_PRINT("Adding tracked unit " .. curUnitGuid .. " to tracked list")
			else
				self.trackedUnits[curUnitGuid]:UpdateLastSeen(bossUnit, self.encounterActive)
			end

			if GetRaidTargetIndex(bossUnit) ~= nil then
				markersThisTick[GetRaidTargetIndex(bossUnit)] = curUnitGuid
			end

			self.trackedUnitsThisTick[curUnitGuid] = true
		end
	end

	-- Iterate all the raid targets, nameplates etc.
	for _, unitId in pairs(unitIdList) do
		curUnitGuid = UnitGUID(unitId)
		if curUnitGuid ~= nil and not self.trackedUnitsThisTick[curUnitGuid] and self.removedUnits[curUnitGuid] == nil then
			local npcId = select(6, strsplit("-", curUnitGuid))

			if self.encounterNPCs[npcId] ~= nil then
				if self.encounterNPCPriority[npcId] == nil then error("No priority for npcId: " .. npcId) end
				if self.trackedUnits[curUnitGuid] == nil then
					local npcTrackingData = self.encounterNPCs[npcId]
					local prio = self.encounterNPCPriority[npcId]

					self.trackedUnits[curUnitGuid] = Private.TrackedUnit.New(curUnitGuid, unitId, npcId, prio, npcTrackingData)
					table.insert(self.trackedUnitsSorted, self.trackedUnits[curUnitGuid])
					newUnits = true
					Private:DEBUG_PRINT("Adding tracked unit " .. curUnitGuid .. " to tracked list")
				else
					self.trackedUnits[curUnitGuid]:UpdateLastSeen(unitId, self.encounterActive)
				end

				if GetRaidTargetIndex(unitId) ~= nil then
					markersThisTick[GetRaidTargetIndex(unitId)] = curUnitGuid
				end
			end

			self.trackedUnitsThisTick[curUnitGuid] = true
		end
	end

	-- Sort for any new additions	
	if newUnits then
		table.sort(self.trackedUnitsSorted, sortFunction)
		newUnits = false
	end

	-- Clear flag for any units that are no longer actively tracked
	for guid, _ in pairs(self.trackedUnits) do
		if not self.trackedUnitsThisTick[guid] and self.trackedUnits[guid].active then
			self.trackedUnits[guid]:OnInactive()
		end
	end

	-- Do a post-processing scan that will remove the marker from any units that hve not been tracked this tick,
	-- if that marker is now in use by a tracked unit.
	for guid, _ in pairs(self.trackedUnits) do
		local marker = self.trackedUnits[guid].marker
		if marker ~= nil and markersThisTick[marker] ~= nil and markersThisTick[marker] ~= guid then
			self.trackedUnits[guid]:ClearMarker()
		end
	end
end

function TrackerEncounter:GetTrackedUnits()
	return #self.trackedUnitsSorted
end

function TrackerEncounter:GetTrackedUnit(idx)
	return self.trackedUnitsSorted[idx]
end

-- Called when a unit has expired, some units will be removed entirely after being untracked for N seconds
function TrackerEncounter:RemoveTrackedUnit(unitGuid)
	Private:DEBUG_PRINT("Removing tracked unit " .. unitGuid)
	self.removedUnits[unitGuid] = true
	self.trackedUnits[unitGuid] = nil
	for idx, unit in pairs(self.trackedUnitsSorted) do
		if unit:GetUnitGUID() == unitGuid then
			table.remove(self.trackedUnitsSorted, idx)
			return
		end
	end

	Private:DEBUG_PRINT("Failed to remove tracked unit " .. unitGuid .. ", not found in sorted list")
end

-- Called when the CLEU has a UNIT_DIED event, pass to the active encounter if known to more quickly signal death
function TrackerEncounter:OnUnitDied(unitGuid)
	if self.trackedUnits[unitGuid] ~= nil then
		self.trackedUnits[unitGuid]:OnDied()
	end
end