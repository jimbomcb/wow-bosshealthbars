local BHB = _G.BHB

local HealthBar,prototype = {},{}
BHB.HealthBar = HealthBar

ICON_LIST = {
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:",
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:",
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:",
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:",
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:",
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:",
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:",
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:",
}

function HealthBar:New(parent, width, height)
	local frame = CreateFrame("Frame", "BossHealthBar", parent)
	for k,v in pairs(prototype) do frame[k] = v end -- Copy in prototype methods

	frame:SetWidth(width)
	frame:SetHeight(height)

	local tex = frame:CreateTexture()
	tex:SetColorTexture(0, 0, 0, 1.0)
	tex:SetAllPoints()
	tex:SetAlpha(0.5)

	local bosshealth = CreateFrame("StatusBar", nil, frame)
	bosshealth:SetMinMaxValues(0, 1)
	bosshealth:SetPoint("TOPLEFT", 1, -1)
	bosshealth:SetPoint("BOTTOMRIGHT", -1, 1)
	frame.hpbar = bosshealth

	local overlay = CreateFrame("Frame", nil, bosshealth)
	overlay:SetAllPoints(true)
	overlay:SetFrameLevel(bosshealth:GetFrameLevel() + 5)
	frame.overlay = overlay

	local name = overlay:CreateFontString(nil, "OVERLAY")
	name:SetPoint("TOPLEFT", overlay, "TOPLEFT", 4, 0)
	name:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT", -60, 0)
	name:SetWordWrap(false)
	name:SetJustifyH("LEFT")
	name:SetJustifyV("MIDDLE")
	frame.bossname = name

	local hp = overlay:CreateFontString(nil, "OVERLAY")
	hp:SetPoint("TOPLEFT", overlay, "TOPRIGHT", -150, 0) -- Adjusted position
	hp:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT", -4, 0)
	hp:SetWordWrap(false)
	hp:SetJustifyH("RIGHT")
	hp:SetJustifyV("MIDDLE")
	frame.hptext = hp

	frame:OnMediaUpdate()
	frame:Reset()

	return frame
end

function prototype:Reset()
	self.barActive = false
	self.targetGuid = nil
	self.healthFrac = 1.0
	self.isTracked = false
	self.unitDead = false
	self.expiryTime = {}
	self.spawnIndex = 0
	--self.spawnTime = 0
	self.uniqueId = 0
	self.unitName = "Unknown"
	self.unitMarker = nil
	self:Hide()

	UpdateBarColor(self)
end

function prototype:SetHealth(unitHealth, unitMaxHealth)
	local healthDisplayOption = BHB.db.profile.healthDisplayOption
	local fraction = unitMaxHealth > 0 and unitHealth / unitMaxHealth or 0

	if healthDisplayOption == "Percentage" then
		-- Increase decimal precision under 10%/1%
		local precision = 0
		if fraction < 0.01 then
			precision = 2
		elseif fraction < 0.1 then
			precision = 1
		end
		self:SetHealthFractionText(fraction, format("%." .. precision .. "f%%", fraction * 100.0))
	elseif healthDisplayOption == "PercentageDetailed" then
		self:SetHealthFractionText(fraction, format("%.2f%%", fraction * 100.0))
	elseif healthDisplayOption == "Remaining" then
		self:SetHealthFractionText(fraction, tostring(unitHealth))
	elseif healthDisplayOption == "TotalRemaining" then
		self:SetHealthFractionText(fraction, format("%d/%d", unitHealth, unitMaxHealth))
	end
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

function prototype:GetUnitName()
	local unitName = self.unitNameBase

	-- Wrap boss names in *'s
	if self.bossId ~= nil then unitName = self.bossId .. ": " .. unitName end

	-- Wrap in marker icons
	local unitTexture = self.unitMarker ~= nil and ICON_LIST[self.unitMarker] .. "0|t" or nil
	if unitTexture ~= nil then unitName = unitTexture .. unitName .. unitTexture end

	return unitName
end

-- Captured an NPC of interest with the given Guid, currently targeted by sourceUnitId (may change)
function prototype:Activate(npcGuid, sourceUnitId, trackingSettings, uniqueId, bossId)
	self:SetActive(true)
	self.targetGuid = npcGuid
	self.isTracked = true
	self.trackingSettings = trackingSettings
	self.uniqueId = uniqueId
	self.bossId = bossId -- Nil if not a boss, or int

	-- Track spawn time
	-- local _, _, _, _, _, _, spawnUID = strsplit("-", npcGuid)
	-- local spawnEpoch = GetServerTime() - (GetServerTime() % 2^23)
	-- local spawnEpochOffset = bit.band(tonumber(string.sub(spawnUID, 5), 16), 0x7fffff)
	-- self.spawnIndex = bit.rshift(bit.band(tonumber(string.sub(spawnUID, 1, 5), 16), 0xffff8), 3)
	-- self.spawnTime = spawnEpoch + spawnEpochOffset

	self.unitNameBase = UnitName(sourceUnitId)
	-- Disabled as I think this might cause more confusion than it's worth
	-- Because the # might not be identical between raid players, and someone calling "attack #3" would be different for different players
	--[[if self.uniqueId > 1 then
		self.bossname:SetText(format("%s #%d", unitName, self.uniqueId))
	else
		self.bossname:SetText(unitName)
	end]]--

	self.bossname:SetText(self:GetUnitName())
	self:UpdateFrom(sourceUnitId)
end

--function prototype:AppendNameUID()
-- 	self.bossname:SetText(format("%s #%d", self.bossName:GetText(), self.uniqueId))
--end

function prototype:UpdateFrom(unitId)
	-- Is there a dev-only assert we can use? 
	if UnitGUID(unitId) ~= self.targetGuid then
		error("Mismatch, bar was for "..self.targetGuid.." but unit is targeting " .. UnitGUID(unitId))
		return
	end

	-- If the unit ID is boss1, boss2, boss3, boss4, ensure we have the correct latest ID
	if unitId == "boss1" or unitId == "boss2" or unitId == "boss3" or unitId == "boss4" then
		local bossId = tonumber(string.sub(unitId, 5))
		if bossId ~= nil then
			self.bossId = bossId
			self.bossname:SetText(self:GetUnitName())
		end
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

	-- Update raid target icons around the target name
	local unitMarker = GetRaidTargetIndex(unitId)
	if unitMarker ~= self.unitMarker and BHB.db.profile.showTargetMarkerIcons then
		-- Unit marker changed, nil = no icon
		self.unitMarker = unitMarker
		self.bossname:SetText(self:GetUnitName())
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

	if self.trackingSettings ~= nil and self.trackingSettings.expireAfterTrackingLoss ~= nil then
		self:ScheduleCleanup("lost", self.trackingSettings.expireAfterTrackingLoss)
	end

	-- Prefix health with a ≈ to indicate that it's an approximate value based on last sighting (and help distinguish untracked at a glance)
	--local curText = self.hptext:GetText()
	--if string.sub(curText, 0, 1) ~= "≈" then self.hptext:SetText("≈" .. curText) end
end

function prototype:OnDeath()
	self.unitDead = true
	self:SetHealthFractionText(0.0, "DEAD")

	-- Some units should clean up their bar n seconds after death
	if self.trackingSettings ~= nil and self.trackingSettings.expireAfterDeath ~= nil then
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
	-- Bosses have separate priority so that they're always the first (based on their boss id)
	if self.bossId ~= nil then return -100 - self.bossId end

	if self.trackingSettings ~= nil then return self.trackingSettings.priority end
	return 1
end

--[[function prototype:GetSpawnTime()
	return self.spawnTime, self.spawnIndex
end]]--

function prototype:GetBarUID()
	return self.uniqueId
end

function prototype:OnMediaUpdate()
	local fontMedia = BHB:GetFontMedia()
	local fontSize = BHB:GetFontSize()
	self.hpbar:SetStatusBarTexture(BHB:GetBarTextureMedia())
	self.bossname:SetFont(fontMedia, fontSize, "OUTLINE")
	self.hptext:SetFont(fontMedia, fontSize, "OUTLINE")

	--local healthWidth = floor(BHB:GetBarWidth() * 0.33)
	--self.bossname:SetPoint("BOTTOMRIGHT", self.overlay, "BOTTOMRIGHT", -healthWidth, 0)
	--self.hptext:SetPoint("TOPLEFT", self.bossname, "TOPRIGHT", 4, 0) -- Adjusted position
end

function UpdateBarColor(element)
	if element.isTracked then
		local r, g, b = element.healthFrac > 0.5 and ((1.0 - element.healthFrac) * 2.0) or 1.0, element.healthFrac > 0.5 and 1.0 or (element.healthFrac * 2.0), 0.0
		element.hpbar:SetStatusBarColor(r, g, b)
	else
		element.hpbar:SetStatusBarColor(0.75, 0.75, 0.75) -- TODO: Expose to settings
	end
end