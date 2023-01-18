local BHB = _G.BHB

local HealthBar,prototype = {},{}
BHB.HealthBar = HealthBar

local temp_font = "Fonts\\FRIZQT__.TTF" -- TODO: Expose to settings

function HealthBar:New(parent, width, height)
	local frame = CreateFrame("Frame", "BossHealthBar", parent)
	for k,v in pairs(prototype) do frame[k] = v end -- Copy in prototype methods

	frame:SetWidth(width)
	frame:SetHeight(height)

    local tex = frame:CreateTexture();
    tex:SetColorTexture(0, 0, 0, 1.0)
    tex:SetAllPoints();
    tex:SetAlpha(0.5);

	local bosshealth = CreateFrame("StatusBar", nil, frame)
	bosshealth:SetMinMaxValues(0,1)
	bosshealth:SetPoint("TOPLEFT",1,-1)
	bosshealth:SetPoint("BOTTOMRIGHT",-1,1)
    bosshealth:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
	frame.hpbar = bosshealth

	local overlay = CreateFrame("Frame", nil, bosshealth)
	overlay:SetAllPoints(true)
	overlay:SetFrameLevel(bosshealth:GetFrameLevel()+5)

    local name = overlay:CreateFontString(nil, "OVERLAY")
    name:SetPoint("LEFT", 4, 0)
    name:SetFont(temp_font, 12, "OUTLINE")
	frame.bossname = name

    local hp = overlay:CreateFontString(nil, "OVERLAY")
    hp:SetPoint("RIGHT", -4, 0)
    hp:SetFont(temp_font, 12, "OUTLINE")
	frame.hptext = hp

	frame:Reset()

	return frame
end

function prototype:Reset()
	self.barActive = false
	self.targetGuid = nil
	self.healthFrac = 1.0
	self.hasName = false
	self.isTracked = false
	self.unitDead = false
	self.expiryTime = {}
    self.spawnIndex = 0
    --self.spawnTime = 0
	self.uniqueId = 0
	self:Hide()

	UpdateBarColor(self)
end

function prototype:SetName(txt, isPlaceholder)
	self.hasName = not isPlaceholder
	self.bossname:SetText(txt)
end

function prototype:HasName()
	return self.hasName
end

function prototype:SetHealth(unitHealth, unitMaxHealth)
	local fraction = unitHealth / unitMaxHealth

	-- Increase decimal precision under 10%/1%
	local precision = 0
	if fraction < 0.01 then
		precision = 2
	elseif fraction < 0.1 then
		precision = 1
	end
	self:SetHealthFractionText(fraction, format("%." .. precision .. "f%%", fraction * 100.0))
end

function prototype:SetHealthFractionText(fraction, text)
	self.healthFrac = fraction
	self.hptext:SetText(text)
	self.hpbar:SetValue(fraction)
	UpdateBarColor(self)
end

function prototype:SetActive(isActive)
	if self.barActive ~= isActive then
		self.barActive = isActive
		UpdateBarColor(self)
	end
end

function prototype:IsActive()
	return self.barActive
end

-- Captured an NPC of interest with the given Guid, currently targeted by sourceUnitId (may change)
function prototype:Activate(npcGuid, sourceUnitId, trackingSettings, uniqueId)
	self:SetActive(true)
	self.targetGuid = npcGuid
	self.isTracked = true
	self.trackingSettings = trackingSettings
	self.uniqueId = uniqueId

	-- Track spawn time
	-- local _, _, _, _, _, _, spawnUID = strsplit("-", npcGuid)
    -- local spawnEpoch = GetServerTime() - (GetServerTime() % 2^23)
    -- local spawnEpochOffset = bit.band(tonumber(string.sub(spawnUID, 5), 16), 0x7fffff)
    -- self.spawnIndex = bit.rshift(bit.band(tonumber(string.sub(spawnUID, 1, 5), 16), 0xffff8), 3)
    -- self.spawnTime = spawnEpoch + spawnEpochOffset

	local unitName = UnitName(sourceUnitId)
	-- Disabled as I think this might cause more confusion than it's worth
	-- Because the # might not be identical between raid players, and someone calling "attack #3" would be different for different players
	--[[if self.uniqueId > 1 then
		self.bossname:SetText(format("%s #%d", unitName, self.uniqueId))
	else
		self.bossname:SetText(unitName)
	end]]--
	self.bossname:SetText(unitName)

	self:UpdateFrom(sourceUnitId)
end

function prototype:AppendNameUID()
	self.bossname:SetText(format("%s #%d", self.bossName:GetText(), self.uniqueId))
end

function prototype:UpdateFrom(unitId)
	-- Is there a dev-only assert we can use? 
	if UnitGUID(unitId) ~= self.targetGuid then
		error("Mismatch, bar was for "..self.targetGuid.." but unit is targeting " .. UnitGUID(unitId))
		return
	end
	
	self.isTracked = true
	self:CancelCleanup("lost")

	local unitDead = UnitIsDead(unitId)
	if not self.unitDead and unitDead then
		-- Died (but we somehow missed UNIT_DEATH)
		self:OnDeath()
	elseif self.unitDead and not unitDead then
		-- Revived?
		self.unitDead = false
		self:CancelCleanup("death")
	end

	if not self.unitDead then
		local unitHP, unitHPMax = UnitHealth(unitId), UnitHealthMax(unitId)
		self:SetHealth(unitHP, unitHPMax)
	end
end

function prototype:IsTracked()
	return self.isTracked
end

function prototype:LostTracking()
	self.isTracked = false
	UpdateBarColor(self)

	if self.trackingSettings.expireAfterTrackingLoss ~= nil then
		self:ScheduleCleanup("lost", self.trackingSettings.expireAfterTrackingLoss)
	end
end

function prototype:OnDeath()
	self.unitDead = true
	self:SetHealthFractionText(0.0, "DEAD")

	-- Some units should clean up their bar n seconds after death
	if self.trackingSettings.expireAfterDeath ~= nil then
		self:ScheduleCleanup("death", self.trackingSettings.expireAfterDeath)
	end
end

function prototype:ScheduleCleanup(key, seconds)
	local newExpireTime = GetTime() + seconds
	if self.expiryTime[key] == nil or newExpireTime < self.expiryTime[key] then
		self.expiryTime[key] = newExpireTime -- New time or sooner than prior
	end
end

function prototype:CancelCleanup(key)
	self.expiryTime[key] = nil
end

function prototype:HasExpired()
	for k, v in pairs(self.expiryTime) do
		if v ~= nil and GetTime() > v then
			-- Hit an expiry
			return true
		end
	end
	return false
end

function prototype:GetPriority()
	return self.trackingSettings.priority
end

--[[function prototype:GetSpawnTime()
	return self.spawnTime, self.spawnIndex
end]]--

function prototype:GetBarUID()
	return self.uniqueId
end

function UpdateBarColor(element)
	if element.isTracked then
		local r, g, b = element.healthFrac > 0.5 and ((1.0 - element.healthFrac) * 2.0) or 1.0, element.healthFrac > 0.5 and 1.0 or (element.healthFrac * 2.0), 0.0
		element.hpbar:SetStatusBarColor(r, g, b)
	else
		element.hpbar:SetStatusBarColor(0.75, 0.75, 0.75) -- TODO: Expose to settings
	end
end