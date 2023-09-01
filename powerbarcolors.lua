-- Based on the stock UI UnitFrame.lua colors

PowerBarColor = {};
PowerBarColor["MANA"] =				{ r = 0.00, g = 0.00, b = 1.00, atlasElementName="Mana", hasClassResourceVariant = true };
PowerBarColor["RAGE"] =				{ r = 1.00, g = 0.00, b = 0.00, fullPowerAnim=true, atlasElementName="Rage" };
PowerBarColor["FOCUS"] =			{ r = 1.00, g = 0.50, b = 0.25, fullPowerAnim=true, atlasElementName="Focus" };
PowerBarColor["ENERGY"] =			{ r = 1.00, g = 1.00, b = 0.00, fullPowerAnim=true, atlasElementName="Energy", hasClassResourceVariant = true };
PowerBarColor["COMBO_POINTS"] =		{ r = 1.00, g = 0.96, b = 0.41 };
PowerBarColor["RUNES"] =			{ r = 0.50, g = 0.50, b = 0.50 };
PowerBarColor["RUNIC_POWER"] =		{ r = 0.00, g = 0.82, b = 1.00, fullPowerAnim=true, atlasElementName="RunicPower" };
PowerBarColor["SOUL_SHARDS"] =		{ r = 0.50, g = 0.32, b = 0.55 };
PowerBarColor["LUNAR_POWER"] =		{ r = 0.30, g = 0.52, b = 0.90, atlas="_Druid-LunarBar" };
PowerBarColor["HOLY_POWER"] =		{ r = 0.95, g = 0.90, b = 0.60 };
PowerBarColor["MAELSTROM"] =		{ r = 0.00, g = 0.50, b = 1.00, atlas = "_Shaman-MaelstromBar", fullPowerAnim=true };
PowerBarColor["INSANITY"] =			{ r = 0.40, g = 0.00, b = 0.80, atlas = "_Priest-InsanityBar"};
PowerBarColor["CHI"] =				{ r = 0.71, g = 1.00, b = 0.92 };
PowerBarColor["ARCANE_CHARGES"] =	{ r = 0.10, g = 0.10, b = 0.98 };
PowerBarColor["FURY"] =				{ r = 0.788, g = 0.259, b = 0.992, atlas = "_DemonHunter-DemonicFuryBar", fullPowerAnim=true };
PowerBarColor["PAIN"] =				{ r = 255/255, g = 156/255, b = 0, atlas = "_DemonHunter-DemonicPainBar", fullPowerAnim=true };
-- vehicle colors
PowerBarColor["AMMOSLOT"] = 		{ r = 0.80, g = 0.60, b = 0.00 };
PowerBarColor["FUEL"] = 			{ r = 0.0, g = 0.55, b = 0.5 };
-- alternate power bar colors
PowerBarColor["STAGGER"] = { {r = 0.52, g = 1.0, b = 0.52}, {r = 1.0, g = 0.98, b = 0.72}, {r = 1.0, g = 0.42, b = 0.42},};
PowerBarColor["EBON_MIGHT"] = { r = 0.9, g = 0.55, b = 0.3, atlas = "Unit_Evoker_EbonMight_Fill" };

-- these are mostly needed for a fallback case (in case the code tries to index a power token that is missing from the table,
-- it will try to index by power type instead)
PowerBarColor[0] = PowerBarColor["MANA"];
PowerBarColor[1] = PowerBarColor["RAGE"];
PowerBarColor[2] = PowerBarColor["FOCUS"];
PowerBarColor[3] = PowerBarColor["ENERGY"];
PowerBarColor[4] = PowerBarColor["CHI"];
PowerBarColor[5] = PowerBarColor["RUNES"];
PowerBarColor[6] = PowerBarColor["RUNIC_POWER"];
PowerBarColor[7] = PowerBarColor["SOUL_SHARDS"];
PowerBarColor[8] = PowerBarColor["LUNAR_POWER"];
PowerBarColor[9] = PowerBarColor["HOLY_POWER"];
PowerBarColor[11] = PowerBarColor["MAELSTROM"];
PowerBarColor[13] = PowerBarColor["INSANITY"];
PowerBarColor[17] = PowerBarColor["FURY"];
PowerBarColor[18] = PowerBarColor["PAIN"];

function GetPowerBarColor(powerType)
	return PowerBarColor[powerType];
end