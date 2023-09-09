local AddonName, Private = ...

local TrackerBase = {
}
Private.TrackerBase = TrackerBase

function TrackerBase:New(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function TrackerBase:Tick()
end

function TrackerBase:GetTrackedUnit(v)
	
end

function TrackerBase:GetTrackedUnits()
	return 0
end
