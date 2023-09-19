-- TODO
-- Timers move here

local AddonName, Private = ...

local TrackedUnit = {
	priority = 0
}
TrackedUnit.__index = TrackedUnit
Private.TrackedUnit = TrackedUnit

function TrackedUnit.New(unitGUID, unitId, npcId, priority, npcTrackingData)
	local self = setmetatable({
		unitGUID = unitGUID,
		npcId = npcId,
		priority = priority,
		creationTime = GetTime(),
		showPower = npcTrackingData.resourceBar ~= nil and npcTrackingData.resourceBar ~= false,
		expireAfterTrackingLoss = npcTrackingData.expireAfterTrackingLoss ~= nil and npcTrackingData.expireAfterTrackingLoss or nil,
		alive = UnitIsDeadOrGhost(unitId) == false,
		queuedExpiry = {
			death = nil,
			trackingLoss = nil
		}
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

	self:CancelExpiration("trackingLoss")
end

function TrackedUnit:OnInactive()
	self.active = false
	self.inactiveTime = GetTime()

	if self.expireAfterTrackingLoss ~= nil then
		self:QueueExpiration("trackingLoss", self.expireAfterTrackingLoss)
	end
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

function TrackedUnit:IsTracked()
	return self.active
end

function TrackedUnit:IsAlive()
	return self.alive
end

function TrackedUnit:GetName()
	return self.unitName
end

-- Return true to signal that this tracked unit should be cleaned up from the tracker entirely
-- Usually due to expiration
function TrackedUnit:ShouldRemove()
	for expiryType, expiryTime in pairs(self.queuedExpiry) do
		if expiryTime ~= nil and expiryTime < GetTime() then
			Private:DEBUG_PRINT("Expired " .. self.unitName .. " due to " .. expiryType)
			return true
		end
	end
end

-- Track an expiry time for this unit, if it's already queued then we'll just update the expiry time to the latest
function TrackedUnit:QueueExpiration(expiryType, expiryLength)
	Private:DEBUG_PRINT("Queued expiry for " .. self.unitName .. " due to " .. expiryType .. " in " .. expiryLength .. " seconds")
	self.queuedExpiry[expiryType] = GetTime() + expiryLength
end

-- Track an expiry time for this unit, if it's already queued then we'll just update the expiry time to the latest
function TrackedUnit:CancelExpiration(expiryType)
	if self.queuedExpiry[expiryType] ~= nil then
		Private:DEBUG_PRINT("Cancelling expiry for " .. self.unitName .. " due to " .. expiryType)
		self.queuedExpiry[expiryType] = nil
	end
end