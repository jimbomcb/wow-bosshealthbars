local BHB = _G.BHB

local HealthBar,prototype = {},{}
BHB.HealthBar = HealthBar

local temp_font = "Fonts\\FRIZQT__.TTF" -- TODO: Expose to settings

function HealthBar:New(parent)
	local frame = CreateFrame("Frame", "BossHealthBar", parent)
	for k,v in pairs(prototype) do frame[k] = v end -- Copy in prototype methods

	frame:SetWidth(220)
	frame:SetHeight(22)

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
    name:SetFont(temp_font, 12)
    name:SetShadowColor(0, 0, 0, 1)
    name:SetShadowOffset(-1, 1)
	frame.bossname = name

    local hp = overlay:CreateFontString(nil, "OVERLAY")
    hp:SetPoint("RIGHT", -4, 0)
    hp:SetFont(temp_font, 12)
    hp:SetShadowColor(0, 0, 0, 1)
    hp:SetShadowOffset(-1, 1)
	frame.hptext = hp

	frame:Reset()

	return frame
end

function prototype:Reset()
	self.healthFrac = 1.0
	self.barActive = false
	self.hasName = false
	self:SetHealthFractionText(1.0, "Scanning...")
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
	self:SetHealthFractionText(fraction, tostring(math.floor(fraction * 100)) .. "%")
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

function UpdateBarColor(element)
	if element.barActive then
		local r, g, b = element.healthFrac > 0.5 and ((1.0 - element.healthFrac) * 2.0) or 1.0, element.healthFrac > 0.5 and 1.0 or (element.healthFrac * 2.0), 0.0
		element.hpbar:SetStatusBarColor(r, g, b)
	else
		element.hpbar:SetStatusBarColor(0.8, 0.8, 0.8)
	end
end