
local AddonName, Private = ...
local BHB = LibStub("AceAddon-3.0"):GetAddon("BossHealthBar")

local AddonName, Private = ...
local HealthBar,prototype = {},{}
BHB.HealthBar = HealthBar

local ICON_LIST = {
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:",
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:",
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:",
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:",
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:",
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:",
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:",
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:",
}

function HealthBar:New(parent, width, height, resourceHeight)
	local frame = CreateFrame("Frame", "BossHealthBar", parent)
	for k,v in pairs(prototype) do frame[k] = v end -- Copy in prototype methods

	frame.baseW = width
	frame.baseH = height
	frame.baseResourceH = resourceHeight

	frame:SetWidth(frame.baseW)
	frame:SetHeight(frame.baseH) -- Height is later determined based on resource bar visibility

	local tex = frame:CreateTexture()
	tex:SetColorTexture(0, 0, 0, 1.0)
	tex:SetAllPoints()
	tex:SetAlpha(0.5)

	local bosshealth = CreateFrame("StatusBar", nil, frame)
	bosshealth:SetMinMaxValues(0, 1)
	bosshealth:SetPoint("BOTTOMLEFT", frame)
	bosshealth:SetPoint("TOPRIGHT", frame)
	bosshealth:SetStatusBarColor(1.0, 0.0, 0.0, 0.25)
	frame.hpbar = bosshealth

	local powerbar = CreateFrame("StatusBar", nil, frame)
	powerbar:SetMinMaxValues(0, 1)
	powerbar:SetPoint("BOTTOMLEFT", frame)
	powerbar:SetPoint("TOPRIGHT", frame, "BOTTOMLEFT")
	frame.powerbar = powerbar
	frame.powerbarHeight = BHB:GetResourceBarHeight() * height

	local overlay = CreateFrame("Frame", nil, frame.hpbar)
	overlay:SetAllPoints(true)
	overlay:SetFrameLevel(bosshealth:GetFrameLevel() + 5)
	frame.overlay = overlay

	local name = overlay:CreateFontString(nil, "OVERLAY")
	name:SetPoint("TOPLEFT", overlay, 4, 0)
	name:SetPoint("BOTTOMRIGHT", overlay, -60, 0)
	name:SetWordWrap(false)
	name:SetJustifyH("LEFT")
	name:SetJustifyV("MIDDLE")
	frame.bossname = name

	local hp = overlay:CreateFontString(nil, "OVERLAY")
	hp:SetPoint("TOPLEFT", overlay, -150, 0) -- Adjusted position
	hp:SetPoint("BOTTOMRIGHT", overlay, -4, 0)
	hp:SetWordWrap(false)
	hp:SetJustifyH("RIGHT")
	hp:SetJustifyV("MIDDLE")
	frame.hptext = hp

	-- Btns
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
	frame.clickbtn = {}
	for _, unitId in pairs(unitIdList) do
		local btn = CreateFrame("Button", "ProtClickBtn"..unitId, overlay, "SecureActionButtonTemplate")
		btn:SetAttribute("type", "target")
		btn:SetAttribute("unit", unitId)
		btn:SetPoint("BOTTOMLEFT", overlay)
		btn:SetPoint("TOPRIGHT", overlay, "BOTTOMLEFT")
		frame.clickbtn[unitId] = btn
	end

	frame:OnMediaUpdate()
	frame:Reset()
	frame:UpdateResourceBarPoints()

	return frame
end

function prototype:UpdateResourceBarPoints()
	local resourceHeight = self.haspowerbar and self.powerbarHeight or 0

	self.hpbar:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, resourceHeight)
	self.powerbar:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, resourceHeight)
end

function prototype:Reset()
	self.barActive = false
	self.targetGuid = nil

	-- RESET AFTER ENCOUNTER TODO
end

function prototype:SetHealth(unitHealth, unitMaxHealth)
	local healthDisplayOption = BHB.config.profile.healthDisplayOption
	local fraction = unitMaxHealth > 0 and unitHealth / unitMaxHealth or 0

	if healthDisplayOption == "Percentage" then
		-- Increase decimal precision under 10%/1%
		if fraction < 0.01 then
			self:SetHealthFractionText(fraction, format("%.2f%%", fraction * 100.0))
		elseif fraction < 0.1 then
			self:SetHealthFractionText(fraction, format("%.1f%%", fraction * 100.0))
		else
			self:SetHealthFractionText(fraction, format("%.0f%%", fraction * 100.0))
		end
	elseif healthDisplayOption == "PercentageDetailed" then
		self:SetHealthFractionText(fraction, format("%.2f%%", fraction * 100.0))
	elseif healthDisplayOption == "Remaining" then
		self:SetHealthFractionText(fraction, tostring(unitHealth))
	elseif healthDisplayOption == "TotalRemaining" then
		self:SetHealthFractionText(fraction, format("%d/%d", unitHealth, unitMaxHealth))
	end
	
	self:UpdateHPBarColor(fraction)
end

function prototype:SetHealthFractionText(fraction, text)
	self.healthFrac = fraction
	self.hptext:SetText(text)
	self.hpbar:SetValue(fraction)
end

function prototype:SetResource(unitPower, unitPowerMax)
	if not self.haspowerbar then return end
	local fraction = unitPowerMax > 0 and unitPower / unitPowerMax or 0
	self.powerbar:SetValue(fraction)
end

function prototype:IsActive()
	return self.barActive
end

--function prototype:GetUnitName()
--	local unitName = self.unitNameBase
--
--	-- Wrap boss names in *'s
--	if self.bossId ~= nil then unitName = self.bossId .. ": " .. unitName end
--
--	-- Wrap in marker icons
--	local unitTexture = self.unitMarker ~= nil and ICON_LIST[self.unitMarker] .. "0|t" or nil
--	if unitTexture ~= nil then unitName = unitTexture .. unitName .. unitTexture end
--
--	return unitName
--end


--function prototype:UpdateFrom(unitId)
--	-- Is there a dev-only assert we can use? 
--	if UnitGUID(unitId) ~= self.targetGuid then
--		error("Mismatch, bar was for "..self.targetGuid.." but unit is targeting " .. UnitGUID(unitId))
--		return
--	end
--
--	-- If the unit ID is boss1, boss2, boss3, boss4, ensure we have the correct latest ID
--	if unitId == "boss1" or unitId == "boss2" or unitId == "boss3" or unitId == "boss4" then
--		local bossId = tonumber(string.sub(unitId, 5))
--		if bossId ~= nil then
--			self.bossId = bossId
--			self.bossname:SetText(self:GetUnitName())
--		end
--	end
--
--	local regainedTracking = self.isTracked == false
--	self.isTracked = true
--	self.lastSeenUnitId = unitId
--	self:CancelCleanup("lost")
--
--	local unitDead = UnitIsDead(unitId)
--	if not self.unitDead and unitDead then
--		-- Died (but we somehow missed UNIT_DEATH)
--		self:OnDeath()
--	elseif self.unitDead and not unitDead then
--		-- Revived?
--		self.unitDead = false
--		self:CancelCleanup("death")
--	end
--
--	-- Update raid target icons around the target name
--	local unitMarker = GetRaidTargetIndex(unitId)
--	if unitMarker ~= self.unitMarker and BHB.config.profile.showTargetMarkerIcons then
--		-- Unit marker changed, nil = no icon
--		self.unitMarker = unitMarker
--		self.bossname:SetText(self:GetUnitName())
--	end
--
--	if not self.unitDead then
--		local unitHP, unitHPMax = UnitHealth(unitId), UnitHealthMax(unitId)
--		self:SetHealth(unitHP, unitHPMax)
--
--		-- Update resource value if applicable
--		if self.haspowerbar then
--			--if regainedTracking then UpdatePowerBarColor(self) end
--
--			local powerCur, powerMax = UnitPower(unitId), UnitPowerMax(unitId)
--			self:SetResource(powerCur, powerMax)
--		end
--	end
--end

--function prototype:IsTracked()
--	return self.isTracked
--end
--
--function prototype:LostTracking()
--	self.isTracked = false
--	--UpdatePowerBarColor(self)
--
--	if self.trackingSettings ~= nil and self.trackingSettings.expireAfterTrackingLoss ~= nil then
--		self:ScheduleCleanup("lost", self.trackingSettings.expireAfterTrackingLoss)
--	end
--
--	-- Prefix health with a ≈ to indicate that it's an approximate value based on last sighting (and help distinguish untracked at a glance)
--	--local curText = self.hptext:GetText()
--	--if string.sub(curText, 0, 1) ~= "≈" then self.hptext:SetText("≈" .. curText) end
--end

--function prototype:OnDeath()
--	self.unitDead = true
--	self:SetHealthFractionText(0.0, "DEAD")
--
--	-- Some units should clean up their bar n seconds after death
--	if self.trackingSettings ~= nil and self.trackingSettings.expireAfterDeath ~= nil then
--		self:ScheduleCleanup("death", self.trackingSettings.expireAfterDeath)
--	end
--end

--function prototype:ScheduleCleanup(key, seconds)
--	local newExpireTime = GetTime() + seconds
--	if self.expiryTime[key] == nil or newExpireTime < self.expiryTime[key] then
--		self.expiryTime[key] = newExpireTime -- New time or sooner than prior
--	end
--end
--
--function prototype:CancelCleanup(key)
--	self.expiryTime[key] = nil
--end
--
--function prototype:HasExpired()
--	for k, v in pairs(self.expiryTime) do
--		if v ~= nil and GetTime() > v then
--			-- Hit an expiry
--			return true
--		end
--	end
--	return false
--end

function prototype:OnMediaUpdate()
	local fontMedia = BHB:GetFontMedia()
	local fontSize = BHB:GetFontSize()
	self.hpbar:SetStatusBarTexture(BHB:GetBarTextureMedia())
	self.powerbar:SetStatusBarTexture(BHB:GetBarTextureMedia())
	self.bossname:SetFont(fontMedia, fontSize, "OUTLINE")
	self.hptext:SetFont(fontMedia, fontSize, "OUTLINE")
end

function prototype:UpdateHPBarColor(healthFrac)
	if self:IsActive() then
		self.hpbar:SetStatusBarColor(healthFrac > 0.5 and ((1.0 - healthFrac) * 2.0) or 1.0, healthFrac > 0.5 and 1.0 or (healthFrac * 2.0), 0.0, 1.0)
	else
		self.hpbar:SetStatusBarColor(0.75, 0.75, 0.75, 0.5) -- TODO: Expose to settings
	end
end

function prototype:UpdatePowerBarColor(r, g, b)
	if self.haspowerbar then
		self.powerbarColorR = r
		self.powerbarColorG = g
		self.powerbarColorB = b

		if self.barActive then
			self.powerbar:SetStatusBarColor(r, g, b, 1.0)
		else
			self.powerbar:SetStatusBarColor(0.5 + (r * 0.5), 0.5 + (g * 0.5), 0.5 + (b * 0.5), 0.5)
		end
	end
end

-- 
function prototype:UpdateTrackedUnit(trackedUnit)
	if self.currentUnit ~= trackedUnit:GetUnitGUID() then
		-- Represented unit for this bar changed
		self.currentUnit = trackedUnit:GetUnitGUID()

		-- Resource bar
		if self.haspowerbar ~= trackedUnit.showPower then
			self.haspowerbar = trackedUnit.showPower
			self:UpdateResourceBarPoints()

			if self.haspowerbar then
				self.powerR = trackedUnit.powerR
				self.powerG = trackedUnit.powerG
				self.powerB = trackedUnit.powerB

				self:UpdatePowerBarColor(self.powerR, self.powerG, self.powerB)
			end
		end
	end

	if self.barActive ~= trackedUnit:IsActive() then
		self.barActive = trackedUnit:IsActive()

		if self.haspowerbar then
			self:UpdatePowerBarColor(self.powerbarColorR, self.powerbarColorG, self.powerbarColorB)
		end
	end

	self:SetActiveClickBtn(self.barActive and trackedUnit.unitId or nil)

	---- TODO MOVE DEATH TO UNIT
	--if not self.unitDead and UnitIsDead(trackedUnit.unitId) then
	--	-- Died (but we somehow missed UNIT_DEATH)
	--	self:OnDeath()
	--elseif self.unitDead and not UnitIsDead(trackedUnit.unitId) then
	--	-- Revived?
	--	self.unitDead = false
	--	self:CancelCleanup("death")
	--end

	if trackedUnit:IsAlive() then
		self.bossname:SetText(trackedUnit:GetName())

		self:SetHealth(trackedUnit.hpCurrent, trackedUnit.hpMax)

		if self.barActive then
			self:SetResource(trackedUnit.powerCurrent, trackedUnit.powerMax)
		end
	end
end

function prototype:SetActiveClickBtn(unitId)
	if self.activeClickButtonUnitId == unitId then return end
	self.activeClickButtonUnitId = unitId

	-- Enable button clicking for the relevant unit id only
	if self.clickbtnactive ~= nil then self.clickbtnactive:SetPoint("TOPRIGHT", self.overlay, "BOTTOMLEFT", 0, 0) end

	if unitId ~= nil and self.clickbtn[unitId] ~= nil then
		self.clickbtn[unitId]:SetPoint("BOTTOMLEFT", self.overlay, 0, 1)
		self.clickbtn[unitId]:SetPoint("TOPRIGHT", self.overlay, 0, -1)
		self.clickbtnactive = self.clickbtn[unitId]
	end
end

function prototype:BHB_RESOURCE_SIZE_CHANGED()
	-- Changes in the resource proportion will update the resource anchor points
	self.powerbarHeight = BHB:GetResourceBarHeight() * BHB:GetBarHeight()

	if self.haspowerbar then
		self:UpdateResourceBarPoints()
	end
end
