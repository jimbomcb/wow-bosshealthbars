
local AddonName, Private = ...
local BHB = LibStub("AceAddon-3.0"):GetAddon("BossHealthBar")

local Anchor,prototype = {},{}
BHB.Anchor = Anchor
function Anchor:New()
	local frame = CreateFrame("Frame", "BossHealthBarAnchor", UIParent)
	for k,v in pairs(prototype) do frame[k] = v end -- Copy in prototype methods

	frame:SetClampedToScreen(true)
	--frame:SetMovable(true)
   -- frame:SetUserPlaced(true)

	--local tex = frame:CreateTexture()
	--tex:SetColorTexture(0, 0, 0, 0.25)
	--tex:SetAllPoints()
	--tex:SetAlpha(1)

    frame:UpdateDragInput()
    frame:Initialize()

	return frame
end

function prototype:UpdateDragInput()
	local locked = BHB:GetBarLocked()
	if locked == false then
		self:SetMovable(true)
		self:EnableMouse(true)

		self:SetScript("OnMouseDown", function(self, button)
			if button == "LeftButton" and not self.isMoving then
				self:StartMoving()
				self.isMoving = true
			end
		end)

		self:SetScript("OnMouseUp", function(self, button)
			if button == "LeftButton" and self.isMoving then
				self:StopMovingOrSizing()
				self.isMoving = false
				BHB:SaveAnchorPosition(self)
			elseif button == "RightButton" then
				BHB:ShowContextMenu()
			end
		end)
	else
		self:SetMovable(false)
		self:EnableMouse(false)
		
		self:SetScript("OnMouseDown", nil)
		self:SetScript("OnMouseUp", nil)
	end
end

function prototype:Initialize()
	self.bars = {}
	self.createdBars = 0
    self.maxBars = BHB:GetMaxBars()
	self.regenRestoreQueued = {}
	self.inEncounter = false
	
	-- Initial media settings
	self:OnBarMediaUpdate()
	
    self:BHB_SIZE_CHANGED() -- Initial size
    self:BHB_MAXBARS_CHANGED()
	self:BHB_SCALE_CHANGED() -- Initial scale

	self:InitChildBars()
end

function prototype:BHB_SIZE_CHANGED()
	if InCombatLockdown() then
		if not self.regenRestoreQueued["BHB_SIZE_CHANGED"] then
			BHB:Print("Cannot resize bars in combat, will resize after combat.")
			self.regenRestoreQueued["BHB_SIZE_CHANGED"] = true
		end
		return
	end

	self:SetWidth(BHB:GetBarWidth())
	self:SetHeight(BHB:GetBarHeight() * self.maxBars)

	-- Resize any bars
	for i=1, self.createdBars do
		self.bars[i]:SetWidth(BHB:GetBarWidth())
		self.bars[i]:SetHeight(BHB:GetBarHeight())
		self.bars[i]:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -BHB:GetBarHeight() * (i-1))
	end

	-- A change in the bar height means that the final calculated resource bar height changes as well
	BHB:SendMessage("BHB_RESOURCE_SIZE_CHANGED")
end

function prototype:BHB_MAXBARS_CHANGED()
	if InCombatLockdown() then
		if not self.regenRestoreQueued["BHB_MAXBARS_CHANGED"] then
			BHB:Print("Cannot resize bars in combat due to protected target button functions, will resize after combat.")
			self.regenRestoreQueued["BHB_MAXBARS_CHANGED"] = true
		end
		return
	end

    self.maxBars = BHB:GetMaxBars()
	self:SetHeight(BHB:GetBarHeight() * self.maxBars)
	self:InitChildBars() -- Ensure we have any active bars
end

function prototype:BHB_SCALE_CHANGED()
	if InCombatLockdown() then
		if not self.regenRestoreQueued["BHB_SCALE_CHANGED"] then
			BHB:Print("Cannot rescale bars in combat, will resize after combat.")
			self.regenRestoreQueued["BHB_SCALE_CHANGED"] = true
		end
		return
	end

	self:SetScale(BHB:GetScale())
end

function prototype:BHB_LOCK_STATE_CHANGED()
	self:UpdateDragInput()
end

function prototype:BHB_REVERSE_CHANGED()
end

function prototype:BHB_RESOURCE_SIZE_CHANGED()
	for i=1, self.createdBars do
		self.bars[i]:BHB_RESOURCE_SIZE_CHANGED()
	end
end

-- Called when we want to forcefully clear any current active state, resetting to a game boot state
function prototype:ResetState()
	for i=1, self.createdBars do
		self.bars[i]:Reset()
	end

	-- Restore any relevant button visiblity state
	self:UpdateBarVisibility()
end

function prototype:OnBarMediaUpdate()
	self.fontMedia = BHB:GetFontMedia()
	self.barTextureMedia = BHB:GetBarTextureMedia()
	self.fontSize = BHB:GetFontSize()

	for i=1, self.createdBars do
		if self.bars[i] ~= nil then
			self.bars[i]:SetBarMedia(self.fontMedia, self.fontSize, self.barTextureMedia)
		end
	end
end

function prototype:OnRegenDisabled()
end

function prototype:OnRegenEnabled()
	-- Re-enable any queued regen events
	for k,v in pairs(self.regenRestoreQueued) do
		-- Execute the function named K on self
		Private:DEBUG_PRINT("Restoring " .. k)
		self[k](self)
	end
end

function prototype:OnEncounterStart()
	if self.inEncounter == true then return end
	self.inEncounter = true

	-- Hide any inactive buttons in the encounter
	self:UpdateBarVisibility()
end

function prototype:OnEncounterEnd()
	if self.inEncounter == false then return end
	self.inEncounter = false

	-- Optionally reset the encounter state on encounter end
	if BHB:GetResetOnEncounterEnd() then
		self:ResetState()
	end
end

function prototype:InitChildBars()
	-- Remove anything beyond the old max bars
	for i=self.createdBars, self.maxBars + 1, -1 do
		if self.bars[i] ~= nil then
			self.bars[i]:Hide()
			self.bars[i] = nil
		end
	end

	-- Create any new required bars
	for i=self.createdBars + 1, self.maxBars do
		if self.bars[i] == nil then
			self.bars[i] = self:InitChildBar(i)
			self.bars[i]:Show()
		end
	end

	self.createdBars = self.maxBars
end

function prototype:InitChildBar(i)
	local offsetIdx = i - 1
	local bar = BHB.HealthBar:New(i, self, BHB:GetBarWidth(), BHB:GetBarHeight(), 0, self.fontMedia, self.fontSize, self.barTextureMedia)
	bar:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -BHB:GetBarHeight() * offsetIdx)
	return bar
end

function prototype:UpdateFromTracker(tracker)
	local trackedUnits = tracker:GetTrackedUnits()

	-- Default order will be bar 1, 2, 3 etc. Reverse order will start from maxbar reverse.
	for i=1, self.maxBars do
		local trackedUnitIndex = BHB:GetReverseOrder() and self.maxBars - i + 1 or i
		local trackedUnit = tracker:GetTrackedUnit(trackedUnitIndex)
		local bar = self.bars[i]

		if trackedUnit ~= nil then
			bar:UpdateTrackedUnit(trackedUnit)

			-- Ensure that any newly active bar is shown
			if bar:IsShown() == false then 
				bar:Show()
			end
		elseif bar:IsActive() then
			Private:DEBUG_PRINT("No tracked unit for bar " .. i .. ", hiding bar.")
			bar:Reset()

			-- Hide the inactive button if we're in an ongoing encounter
			if self.inEncounter == true then
				bar:Hide()
			end
		end
	end
end

function prototype:UpdateBarVisibility()
	-- When we're in an encounter we always want to hide any empty healthbars
	if self.inEncounter then
		for i=1, self.maxBars do
			if self.bars[i]:IsActive() == false and self.bars[i]:IsShown() then
				self.bars[i]:Hide()
			end
		end
	else
		-- When we're not in an encounter we want to show all the bars
		for i=1, self.maxBars do
			if self.bars[i]:IsShown() == false then
				self.bars[i]:Show()
			end
		end
	end
end