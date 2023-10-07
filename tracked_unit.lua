-- TODO
-- Timers move here

local AddonName, Private = ...

local TrackedUnit = {
	priority = 0
}
TrackedUnit.__index = TrackedUnit
Private.TrackedUnit = TrackedUnit

local ICON_LIST = {
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t",
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:0|t",
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t",
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:0|t",
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:0|t",
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:0|t",
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t",
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t",
}

function TrackedUnit.New(unitGUID, unitId, npcId, priority, npcTrackingData)
	local self = setmetatable({
		unitGUID = unitGUID,
		npcId = npcId,
		priority = priority,
		creationTime = GetTime(),
		showPower = npcTrackingData.resourceBar ~= nil and npcTrackingData.resourceBar ~= false,
		expireAfterTrackingLoss = npcTrackingData.expireAfterTrackingLoss ~= nil and npcTrackingData.expireAfterTrackingLoss or nil,
		expireAfterDeath = npcTrackingData.expireAfterDeath ~= nil and npcTrackingData.expireAfterDeath or nil,
		alive = UnitIsDeadOrGhost(unitId) == false,
		queuedExpiry = {
			death = nil,
			trackingLoss = nil
		},
		auras = {},
		activeAuras = 0,
		marker = nil
	}, TrackedUnit)
	self:UpdateLastSeen(unitId, true)
	return self
end

local _, icon, duration, expirationTime, spellId, timeMod
-- Called each tick with a potentially new unitId who has our data. isActive is true unless the encounter itself has ended and this is the final tick
function TrackedUnit:UpdateLastSeen(unitId, isActive)
	self.unitId = unitId

	if isActive then
		self.active = true
		self.activeTime = GetTime()
	end

	self.unitName = UnitName(unitId)
	self.hpCurrent = UnitHealth(unitId)
	self.hpMax = UnitHealthMax(unitId)

	-- Update live state
	if self.alive and UnitIsDeadOrGhost(unitId) then
		self:OnDied()
	elseif not self.alive and not UnitIsDeadOrGhost(unitId) then
		self:OnRevived()
	end
	
	self.marker = GetRaidTargetIndex(unitId)

	if self.showPower then
		self.powerCurrent = UnitPower(unitId)
		self.powerMax = UnitPowerMax(unitId)
		self.powerFraction = self.powerCurrent / self.powerMax
		self.powerType, self.powerToken, self.powerR, self.powerG, self.powerB = UnitPowerType(unitId)
		if self.powerR == nil then
			self.powerR, self.powerG, self.powerB = GetPowerBarColor(self.powerType)
		end
	end

	-- Scan in any player applied harmful auras
	self.activeAuras = 1
	while true do
		_, icon, _, _, duration, expirationTime, _, _, _, spellId, _, _, _, _, timeMod = UnitAura(unitId, self.activeAuras, "PLAYER|HARMFUL")
		if spellId == nil then break end

		if self.auras[self.activeAuras] == nil then
			self.auras[self.activeAuras] = {
				icon = icon,
				duration = duration,
				expirationTime = expirationTime,
				spellId = spellId,
				timeMod = timeMod
			}
		else
			self.auras[self.activeAuras].icon = icon
			self.auras[self.activeAuras].duration = duration
			self.auras[self.activeAuras].expirationTime = expirationTime
			self.auras[self.activeAuras].spellId = spellId
			self.auras[self.activeAuras].timeMod = timeMod
		end
	
		self.activeAuras = self.activeAuras + 1
	end

	self.activeAuras = self.activeAuras - 1 -- Final sum of auras is the last index we scanned minus one

	self:CancelExpiration("trackingLoss")
end

-- No longer active during an encounter
function TrackedUnit:OnInactive()
	self.active = false
	self.inactiveTime = GetTime()

	if self.expireAfterTrackingLoss ~= nil then
		self:QueueExpiration("trackingLoss", self.expireAfterTrackingLoss)
	end
end

-- Triggered on end of tracked encounter, no more ticks
function TrackedUnit:OnEnd()
	self.active = false

	-- Clear any other possible timers (other than death based ones)
	for expiryType, expiryTime in pairs(self.queuedExpiry) do
		if expiryType ~= "death" and expiryTime ~= nil then
			Private:DEBUG_PRINT("Cancelling expiry for " .. self.unitName .. " due to " .. expiryType .. " on encounter end")
			self.queuedExpiry[expiryType] = nil
		end
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
	if self.marker == nil or ICON_LIST[self.marker] == nil then return self.unitName end
	return ICON_LIST[self.marker] .. self.unitName .. ICON_LIST[self.marker]
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
	if expiryLength == nil then return end
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

-- Clear any auras that have passed their expiration time, shifting any remaining auras down to fill the gap
function TrackedUnit:TickAuras()
	local now = GetTime()
	local aura = nil

	for i=1, self.activeAuras do
		aura = self.auras[i]
		if aura ~= nil and aura.expirationTime ~= nil and aura.expirationTime < now then
			-- Shift all auras down one, overwriting the expired aura
			for j=i, self.activeAuras - 1 do
				self.auras[j] = self.auras[j + 1]
			end
			self.auras[self.activeAuras] = nil
			self.activeAuras = self.activeAuras - 1
		end
	end
end

-- Clear any cached marker, used when we know that this unit can no longer have this marker (because we see it elsewhere)
function TrackedUnit:ClearMarker()
	self.marker = nil
end

-- CLEU has got a UNIT_DEAD event for this specific tracked unit
function TrackedUnit:OnDied()
	if self.alive == false then return end

	Private:DEBUG_PRINT("Unit died: " .. self.unitName .. " (" .. self.unitGUID .. ")")
	self.alive = false
	
	if self.expireAfterDeath ~= nil then
		self:QueueExpiration("death", self.expireAfterDeath)
	end

	-- Clear any tracked auras
	self.auras = {}
end

-- Unit was dead but we're tracking them as alive again
function TrackedUnit:OnRevived()
	if self.alive then return end

	Private:DEBUG_PRINT("Unit revived: " .. self.unitName .. " (" .. self.unitGUID .. ")")
	self.alive = true
end