
local AddonName, Private = ...
local BHB = LibStub("AceAddon-3.0"):GetAddon("BossHealthBar")

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

function HealthBar:New(idx, parent, width, height, resourceHeight, fontMedia, fontSize, barMedia)
	local frame = CreateFrame("Frame", "BossHealthBar", parent)
	for k,v in pairs(prototype) do frame[k] = v end -- Copy in prototype methods

	frame.barIndex = idx
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

	frame.auraIcons = {}
	frame.auraIconsVisible = 0
	frame.auraIconsMax = 10
	for i=1,frame.auraIconsMax do
		local auraframe = CreateFrame("Frame", "Debuff" .. idx .. "AuraFrame" .. i, frame.overlay)
		auraframe:SetSize(BHB:GetBarHeight(), BHB:GetBarHeight())
		auraframe:SetPoint("RIGHT", frame.overlay, "LEFT", -((i - 1) * BHB:GetBarHeight()), 0)
		auraframe:Hide()

		local auraicon = auraframe:CreateTexture("Debuff" .. idx .. "AuraTex" .. i, "OVERLAY")
		auraicon:SetAllPoints()
		auraframe.icon = auraicon

		local auracooldown = CreateFrame("Cooldown", "Debuff" .. idx .. "AuraCooldown" .. i, auraframe, "CooldownFrameTemplate")
		auracooldown:SetAllPoints()

		auracooldown:SetReverse(true)
		auracooldown:SetHideCountdownNumbers(false)

		auraframe.cooldown = auracooldown

		frame.auraIcons[i] = auraframe
	end

	frame:SetBarMedia(fontMedia, fontSize, barMedia)
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
	self:SetActive(false)
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
end

function prototype:SetHealthFractionText(fraction, text)
	self.healthFrac = fraction
	self.hptext:SetText(text)
	self.hpbar:SetValue(fraction)

	self:UpdateHPBarColor()
end

function prototype:SetResource(unitPower, unitPowerMax)
	if not self.haspowerbar then return end
	local fraction = unitPowerMax > 0 and unitPower / unitPowerMax or 0
	self.powerbar:SetValue(fraction)
end

-- Overall bar active state, an inactive bar is not representing anything
function prototype:IsActive()
	return self.barActive
end

function prototype:SetActive(isActive)
	if self.barActive == isActive then return end
	self.barActive = isActive

	if isActive then
		Private:DEBUG_PRINT("Bar " .. self.barIndex .. " activated")
	else
		Private:DEBUG_PRINT("Bar " .. self.barIndex .. " deactivated")
		self.unitTracked = false
		self:ResetBarVisualState()
	end
end

-- A unit might have a last-known health value but is not currently tracked, the bar will be active but not tracked
function prototype:IsTrackingUnit()
	return self.unitTracked
end

-- Called on boot and when we want to reset the bar visual state
function prototype:ResetBarVisualState()
	self.bossname:SetText("Boss Health Bar #" .. self.barIndex)
	self:SetHealthFractionText(1.0)

	-- Reset aura icons
	for i=1, self.auraIconsVisible do
		self.auraIcons[i]:Hide()
	end
	self.auraIconsVisible = 0
end

function prototype:SetBarMedia(fontMedia, fontSize, barTexture)
	self.hpbar:SetStatusBarTexture(barTexture)
	self.powerbar:SetStatusBarTexture(barTexture)
	self.bossname:SetFont(fontMedia, fontSize, "OUTLINE")
	self.hptext:SetFont(fontMedia, fontSize, "OUTLINE")
end

function prototype:UpdateHPBarColor()
	if self:IsTrackingUnit() then
		self.hpbar:SetStatusBarColor(self.healthFrac > 0.5 and ((1.0 - self.healthFrac) * 2.0) or 1.0, self.healthFrac > 0.5 and 1.0 or (self.healthFrac * 2.0), 0.0, 1.0)
	else
		self.hpbar:SetStatusBarColor(0.75, 0.75, 0.75, 0.5) -- TODO: Expose to settings
	end
end

function prototype:UpdatePowerBarColor(r, g, b)
	if self.haspowerbar then
		self.powerbarColorR = r
		self.powerbarColorG = g
		self.powerbarColorB = b

		if self:IsTrackingUnit() then
			self.powerbar:SetStatusBarColor(r, g, b, 1.0)
		else
			self.powerbar:SetStatusBarColor(0.5 + (r * 0.5), 0.5 + (g * 0.5), 0.5 + (b * 0.5), 0.5)
		end
	end
end

function prototype:UpdateTrackedUnit(trackedUnit)
	-- Activate if not active
	if not self:IsActive() then
		self:SetActive(true)
	end

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

	if self.unitTracked ~= trackedUnit:IsTracked() then
		self.unitTracked = trackedUnit:IsTracked()
		self:UpdateHPBarColor()

		if self.haspowerbar then
			self:UpdatePowerBarColor(self.powerbarColorR, self.powerbarColorG, self.powerbarColorB)
		end
	end

	if trackedUnit:IsAlive() then
		self.bossname:SetText(trackedUnit:GetName())

		self:SetHealth(trackedUnit.hpCurrent, trackedUnit.hpMax)

		if self.unitTracked then
			self:SetResource(trackedUnit.powerCurrent, trackedUnit.powerMax)
		end
	else
		self:SetHealthFractionText(0, "DEAD")
	end

	-- Aura updates
	trackedUnit:TickAuras()

	for i=1, trackedUnit.activeAuras do
		if i > self.auraIconsMax then
			break
		end

		if i > self.auraIconsVisible and i <= self.auraIconsMax then
			self.auraIcons[i]:Show()
			self.auraIconsVisible = i
		end

		self.auraIcons[i].icon:SetTexture(trackedUnit.auras[i].icon)
		self.auraIcons[i].cooldown:SetCooldown(trackedUnit.auras[i].expirationTime - trackedUnit.auras[i].duration,
			trackedUnit.auras[i].duration,
			trackedUnit.auras[i].timeMod)
	end

	-- Hide anything beyond the active aura list if we're scaling down
	if self.auraIconsVisible > trackedUnit.activeAuras then
		for i=trackedUnit.activeAuras + 1, self.auraIconsVisible do
			self.auraIcons[i]:Hide()
		end
		self.auraIconsVisible = trackedUnit.activeAuras
	end
end

function prototype:BHB_RESOURCE_SIZE_CHANGED()
	-- Changes in the resource proportion will update the resource anchor points
	self.powerbarHeight = BHB:GetResourceBarHeight() * BHB:GetBarHeight()

	if self.haspowerbar then
		self:UpdateResourceBarPoints()
	end
end