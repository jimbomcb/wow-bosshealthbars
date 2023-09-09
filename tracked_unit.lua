-- TODO
-- Timers move here

local AddonName, Private = ...

local TrackedUnit = {
	priority = 0
}
TrackedUnit.__index = TrackedUnit
Private.TrackedUnit = TrackedUnit

function TrackedUnit.New(unitGUID, unitId, npcId, priority, showPower)
	local self = setmetatable({
		unitGUID = unitGUID,
		npcId = npcId,
		priority = priority,
		creationTime = GetTime(),
		showPower = showPower,
		alive = UnitIsDeadOrGhost(unitId) == false,
	}, TrackedUnit)
	self:UpdateLastSeen(unitId)
	return self
end

function TrackedUnit:UpdateLastSeen(unitId)
	self.unitId = unitId
	self.active = true
	self.activeTime = GetTime()

	self.unitName = UnitName(unitId)
	self.hpCurrent = UnitHealth(unitId)
	self.hpMax = UnitHealthMax(unitId)
	self.alive = UnitIsDeadOrGhost(unitId) == false

	if self.showPower then
		self.powerCurrent = UnitPower(unitId)
		self.powerMax = UnitPowerMax(unitId)
		self.powerFraction = self.powerCurrent / self.powerMax
		self.powerType, self.powerToken, self.powerR, self.powerG, self.powerB = UnitPowerType(unitId)
		if self.powerR == nil then
			self.powerR, self.powerG, self.powerB = GetPowerBarColor(self.powerType)
		end
	end
end

function TrackedUnit:OnInactive()
	self.active = false
	self.inactiveTime = GetTime()
end

function TrackedUnit:GetPriority()
	return self.priority
end

function TrackedUnit:GetCreationTime()
	return self.creationTime
end

function TrackedUnit:GetUnitGUID()
	return self.unitGUID
end

function TrackedUnit:IsActive()
	return self.active
end

function TrackedUnit:IsAlive()
	return self.alive
end

function TrackedUnit:GetName()
	return self.unitName
end