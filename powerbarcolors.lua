-- Based on the stock UI UnitFrame.lua colors from some retail version but should be good for wotlk

BHBPowerColors = {}
BHBPowerColors["MANA"] =				{ r = 0.00, g = 0.00, b = 1.00, atlasElementName="Mana", hasClassResourceVariant = true }
BHBPowerColors["RAGE"] =				{ r = 1.00, g = 0.00, b = 0.00, fullPowerAnim=true, atlasElementName="Rage" }
BHBPowerColors["FOCUS"] =			{ r = 1.00, g = 0.50, b = 0.25, fullPowerAnim=true, atlasElementName="Focus" }
BHBPowerColors["ENERGY"] =			{ r = 1.00, g = 1.00, b = 0.00, fullPowerAnim=true, atlasElementName="Energy", hasClassResourceVariant = true }
BHBPowerColors["COMBO_POINTS"] =		{ r = 1.00, g = 0.96, b = 0.41 }
BHBPowerColors["RUNES"] =			{ r = 0.50, g = 0.50, b = 0.50 }
BHBPowerColors["RUNIC_POWER"] =		{ r = 0.00, g = 0.82, b = 1.00, fullPowerAnim=true, atlasElementName="RunicPower" }
BHBPowerColors["SOUL_SHARDS"] =		{ r = 0.50, g = 0.32, b = 0.55 }
BHBPowerColors["LUNAR_POWER"] =		{ r = 0.30, g = 0.52, b = 0.90, atlas="_Druid-LunarBar" }
BHBPowerColors["HOLY_POWER"] =		{ r = 0.95, g = 0.90, b = 0.60 }
BHBPowerColors["MAELSTROM"] =		{ r = 0.00, g = 0.50, b = 1.00, atlas = "_Shaman-MaelstromBar", fullPowerAnim=true }
BHBPowerColors["INSANITY"] =			{ r = 0.40, g = 0.00, b = 0.80, atlas = "_Priest-InsanityBar"}
BHBPowerColors["CHI"] =				{ r = 0.71, g = 1.00, b = 0.92 }
BHBPowerColors["ARCANE_CHARGES"] =	{ r = 0.10, g = 0.10, b = 0.98 }
BHBPowerColors["FURY"] =				{ r = 0.788, g = 0.259, b = 0.992, atlas = "_DemonHunter-DemonicFuryBar", fullPowerAnim=true }
BHBPowerColors["PAIN"] =				{ r = 255/255, g = 156/255, b = 0, atlas = "_DemonHunter-DemonicPainBar", fullPowerAnim=true }
-- vehicle colors
BHBPowerColors["AMMOSLOT"] = 		{ r = 0.80, g = 0.60, b = 0.00 }
BHBPowerColors["FUEL"] = 			{ r = 0.0, g = 0.55, b = 0.5 }
-- alternate power bar colors
BHBPowerColors["STAGGER"] = { {r = 0.52, g = 1.0, b = 0.52}, {r = 1.0, g = 0.98, b = 0.72}, {r = 1.0, g = 0.42, b = 0.42},}
BHBPowerColors["EBON_MIGHT"] = { r = 0.9, g = 0.55, b = 0.3, atlas = "Unit_Evoker_EbonMight_Fill" }

-- these are mostly needed for a fallback case (in case the code tries to index a power token that is missing from the table,
-- it will try to index by power type instead)
BHBPowerColors[0] = BHBPowerColors["MANA"]
BHBPowerColors[1] = BHBPowerColors["RAGE"]
BHBPowerColors[2] = BHBPowerColors["FOCUS"]
BHBPowerColors[3] = BHBPowerColors["ENERGY"]
BHBPowerColors[4] = BHBPowerColors["CHI"]
BHBPowerColors[5] = BHBPowerColors["RUNES"]
BHBPowerColors[6] = BHBPowerColors["RUNIC_POWER"]
BHBPowerColors[7] = BHBPowerColors["SOUL_SHARDS"]
BHBPowerColors[8] = BHBPowerColors["LUNAR_POWER"]
BHBPowerColors[9] = BHBPowerColors["HOLY_POWER"]
BHBPowerColors[11] = BHBPowerColors["MAELSTROM"]
BHBPowerColors[13] = BHBPowerColors["INSANITY"]
BHBPowerColors[17] = BHBPowerColors["FURY"]
BHBPowerColors[18] = BHBPowerColors["PAIN"]

function GetBHBPowerColors(powerType)
	return BHBPowerColors[powerType].r, BHBPowerColors[powerType].g, BHBPowerColors[powerType].b
end