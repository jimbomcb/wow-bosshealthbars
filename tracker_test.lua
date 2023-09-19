local AddonName, Private = ...

local TrackerTest = Private.TrackerBase:New()
Private.TrackerTest = TrackerTest

function TrackerTest:New(o, encounterData)
	o = o or Private.TrackerBase:New(o)
	setmetatable(o, self)
	self.__index = self

	if encounterData == nil then error "Encounter data required" end

	self.encounterData = encounterData
	self.trackedUnits = {}
	self.trackedUnitsSorted = {}
	self.trackedUnitsThisTick = {}
	self.tickCount = 0

	-- Build some maps for our encounter data for quicker runtime lookup
	self.encounterNPCs = {}
	for _, npc in pairs(encounterData.npcs) do
		self.encounterNPCs[tostring(npc.id)] = npc
	end

	self.encounterNPCPriority = {}
	for idx, npc in pairs(encounterData.npcs) do
		self.encounterNPCPriority[tostring(npc.id)] = npc.priority or (0 - idx) -- Either use the specified priority or fall back to 0 minus index, so that display order matches definition order
	end

	return o
end

local unitIdList = { "target", "targettarget", "focus", "focustarget", "mouseover", "mouseovertarget",
	--[["nameplate1", "nameplate2", "nameplate3", "nameplate4", "nameplate5", "nameplate6", "nameplate7", "nameplate8", "nameplate9", "nameplate10",
	"nameplate11", "nameplate12", "nameplate13", "nameplate14", "nameplate15", "nameplate16", "nameplate17", "nameplate18", "nameplate19", "nameplate20",
	"nameplate21", "nameplate22", "nameplate23", "nameplate24", "nameplate25", "nameplate26", "nameplate27", "nameplate28", "nameplate29", "nameplate30",
	"nameplate31", "nameplate32", "nameplate33", "nameplate34", "nameplate35", "nameplate36", "nameplate37", "nameplate38", "nameplate39", "nameplate40",]]
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

function TrackerTest:Tick()
	self.tickCount = self.tickCount + 1

	-- Remove any relevant tracked units
	for guid, unit in pairs(self.trackedUnits) do
		if unit:ShouldRemove() then
			self:RemoveTrackedUnit(guid)
		end
	end

	-- Gather the Guids of all the relevant tracked units this tick
	for k, v in pairs(self.trackedUnitsThisTick) do self.trackedUnitsThisTick[k] = nil end
	for _, unitId in pairs(unitIdList) do
		local unitGuid = UnitGUID(unitId)
		if unitGuid ~= nil and not self.trackedUnitsThisTick[unitGuid] then
			local npcId = select(6, strsplit("-", unitGuid))

			if self.encounterNPCs[npcId] ~= nil then
				if self.encounterNPCPriority[npcId] == nil then error("No priority for npcId: " .. npcId) end
				if self.trackedUnits[unitGuid] == nil then
					local npcTrackingData = self.encounterNPCs[npcId]
					local prio = self.encounterNPCPriority[npcId]

					self.trackedUnits[unitGuid] = Private.TrackedUnit.New(unitGuid, unitId, npcId, prio, npcTrackingData)
					table.insert(self.trackedUnitsSorted, self.trackedUnits[unitGuid])
					table.sort(self.trackedUnitsSorted, sortFunction)
				else
					self.trackedUnits[unitGuid]:UpdateLastSeen(unitId)
				end
			end

			self.trackedUnitsThisTick[unitGuid] = true
		end
	end

	-- Clear flag for any units that are no longer actively tracked
	for guid, _ in pairs(self.trackedUnits) do
		if not self.trackedUnitsThisTick[guid] and self.trackedUnits[guid].active then
			self.trackedUnits[guid]:OnInactive()
		end
	end
end

function TrackerTest:GetTrackedUnits()
	return #self.trackedUnitsSorted
end

function TrackerTest:GetTrackedUnit(idx)
	return self.trackedUnitsSorted[idx]
end

-- Called when a unit has expired, some units will be removed entirely after being untracked for N seconds
function TrackerTest:RemoveTrackedUnit(unitGuid)
	self.trackedUnits[unitGuid] = nil
	for idx, unit in pairs(self.trackedUnitsSorted) do
		if unit:GetUnitGUID() == unitGuid then
			table.remove(self.trackedUnitsSorted, idx)
			break
		end
	end
end