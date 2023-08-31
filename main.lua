-- TODO:
-- Clickable bars
-- Resource bars (deathwhisper, Saurfang)
-- Default to Clean/Expressway
-- Targeted by N players
-- See how DBM does auto marking of blood beasts to get them to add in the same order (bind onto SUMMON combat log event)
-- TTK
-- MaxBars (max per NPC?)

local BossHealthBar = LibStub("AceAddon-3.0"):NewAddon("BossHealthBar", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0")
_G.BHB = BossHealthBar

local FEATURE_BossUnits = true
local DEBUG_PRINT = function (...)
	if BossHealthBar.db.profile.debugMode then
		print("BHB DEBUG:")
		print(...)
	end
end

local LSM = LibStub("LibSharedMedia-3.0")

local defaultSettings = {
	profile = {
		ver = 1,
		barLockState = "UNLOCKED", -- Valid: UNLOCKED, LOCKED, LOCKED_CLICKTHROUGH
		hideAnchorWhenLocked = false,
		growUp = false,
		barWidth = 260,
		barHeight = 22,
		resetBarsOnEncounterFinish = false,
		showTargetMarkerIcons = true,
		reverseOrder = false,
		barTexutre = "Blizzard",
		font = "Friz Quadrata TT",
		fontSize = 12,
		healthDisplayOption = "PercentageDetailed", -- Default: Percentage. Options: Percentage, PercentageDetailed, Remaining, TotalRemaining
		debugMode = false
	}
}

local options = {
	name = "Boss Health Bars",
	handler = BossHealthBar,
	type = "group",
	args = {
		generalsettings={
			order = 0,
			name = "General Settings",
			type = "group",
			args={
				desc = {
					name = "General Boss Health Bar configuration:",
					type = "description",
					order = 0,
				},
				resetBarsOnEncounterFinish = {
					order = 5,
					name = "Reset Bars on Encounter End",
					desc = "Clear any active health bars on encounter end? Otherwise health bars remain up until next encounter, which can be useful for determining your wipe percentage.",
					type = "toggle",
					set = function (info, val)
						BossHealthBar.db.profile.resetBarsOnEncounterFinish = val
						if val and not BossHealthBar.encounterActive then BossHealthBar:WaitingForEncounter() end -- We want the bars to hide after encounter, reset if we're not in encounter
					end,
					get = function (info)
						return BossHealthBar.db.profile.resetBarsOnEncounterFinish
					end,
					width = "full"
				},
				showTargetMarkerIcons = {
					order = 6,
					name = "Show Marker Icons",
					desc = "If enabled, wrap the name of units in their raid icon (skull, cross, etc).",
					type = "toggle",
					set = function (info, val)
						BossHealthBar.db.profile.showTargetMarkerIcons = val
					end,
					get = function (info)
						return BossHealthBar.db.profile.showTargetMarkerIcons
					end,
					width = "full"
				},
				healthDisplayOption = {
					type = "select",
					name = "Health Display Option",
					desc = "Choose how to display boss health.",
					order = 7,
					values = {
						Percentage = "Percentage (50%)",
						PercentageDetailed = "Percentage Detailed (50.00%)",
						Remaining = "Remaining (50000))",
						TotalRemaining = "Total/Remaining (500000/1000000)",
					},
					sorting = {
						[1] = "Percentage",
						[2] = "PercentageDetailed",
						[3] = "Remaining",
						[4] = "TotalRemaining",
					},
					get = function (info)
						return BossHealthBar.db.profile.healthDisplayOption
					end,
					set = function (info, val)
						BossHealthBar.db.profile.healthDisplayOption = val
					end,
					width = "full"
				},
			}
		},
		layoutsettings={
			order = 1,
			name = "Bar Layout/Style",
			type = "group",
			args={
				desc = {
					name = "Alter the positioning and sizes of the boss health bars:",
					type = "description",
					order = 0,
				},
				barLockState = {
					type = "select",
					name = "Bar Lock",
					desc = "How should the Boss Health Bar panel respond to mouse input?",
					order = 0,
					values = {
						UNLOCKED = "Unlocked",
						LOCKED = "Locked",
						LOCKED_CLICKTHROUGH = "Locked & Click-through"
					},
					sorting = {
						[1] = "UNLOCKED",
						[2] = "LOCKED",
						[3] = "LOCKED_CLICKTHROUGH"
					},
					get = "GetBarLockState",
					set = "SetBarLockState",
					width = "full"
				},
				hideAnchorWhenLocked = {
					order = 1,
					name = "Hide Anchor When Locked",
					desc = "When the bar is locked (or locked click-through), should the anchor be hidden outside of encounters?",
					type = "toggle",
					set = "SetHideAnchorWhenLocked",
					get = "GetHideAnchorWhenLocked",
					width = "full"
				},
				growUp = {
					order = 2,
					name = "Grow Up",
					desc = "Add new elements above the anchor instead of below when tracking multiple bosses",
					type = "toggle",
					set = "SetGrowUp",
					get = "GetGrowUp",
					width = "full"
				},
				reverseOrder = {
					order = 2,
					name = "Reverse Order",
					desc = "Reverse the order in which rows are sorted, usually the boss is at the top and any additional enemies are added below.",
					type = "toggle",
					set = "SetReverseOrder",
					get = "GetReverseOrder",
					width = "full"
				},
				barWidth = {
					order = 10,
					name = "Bar Width",
					desc = "Width of each boss health bar, Default: " .. tostring(defaultSettings.profile.barWidth),
					type = "range",
					softMin = 50,
					min = 160,
					softMax = 1000,
					step = 1,
					set = "SetBarWidth",
					get= "GetBarWidth",
					width = "full"
				},
				barHeight = {
					order = 11,
					name = "Bar Height",
					desc = "Height of each boss health bar, Default:  " .. tostring(defaultSettings.profile.barHeight),
					type = "range",
					min = 12,
					softMax = 75,
					step = 1,
					set = "SetBarHeight",
					get= "GetBarHeight",
					width = "full"
				},
				barTexture = {
					type = "select",
					name = "Bar Texture",
					order = 20,
					dialogControl = "LSM30_Statusbar",
					values = AceGUIWidgetLSMlists.statusbar,
					width = "full",
					set = "SetBarTexture",
					get= "GetBarTexture",
				},
				barFont = {
					type = "select",
					name = "Bar Font",
					order = 21,
					dialogControl = "LSM30_Font",
					values = AceGUIWidgetLSMlists.font,
					width = "0.5",
					set = "SetFont",
					get= "GetFont",
				},
				fontSize = {
					order = 22,
					name = "Font Size",
					desc = "Size of the boss name & health value. Default: " .. tostring(defaultSettings.profile.fontSize),
					type = "range",
					min = 1,
					softMax = 64,
					step = 1,
					set = "SetFontSize",
					get= "GetFontSize",
					width = "0.5"
				},
			}
		}
	}
}

-- Map encounter ID to NPCs
-- encounterMap has interger key representing encounter ID
-- data is:
--   - NPCs: Lua-style array via integer-indexed table , NPC ID for each boss character to track
-- https://wowpedia.fandom.com/wiki/DungeonEncounterID 
local knownMissingEncounters = { [1086] = "Faction Champions", [637] = "Faction Champions" }
local encounterMap = {
	-- Classic IDs:
	[744] = { npcs = { [1] = { id = 33113 } } }, -- Flame lev
	[745] = { npcs = { [1] = { id = 33118 } } }, -- Ignis
	[746] = { npcs = { [1] = { id = 33186 } } }, -- Razorscale
	[747] = { npcs = { [1] = { id = 33293 }, [2] = { id = 33329 } } }, -- XT
	[748] = { npcs = { [1] = { id = 32867 }, [2] = { id = 32927 }, [3] = { id = 32857 } } }, -- Iron Council
	[749] = { npcs = { [1] = { id = 32930 }, [2] = { id = 32934, expireAfterDeath = 30.0 }, [3] = { id = 32933, expireAfterDeath = 30.0 } } }, -- Kologarn
	[750] = { npcs = { [1] = { id = 33515 }, [2] = { id = 34035 } } }, -- Auriaya, Feral Defenders
	[751] = { npcs = { [1] = { id = 32845 } } }, -- Hodir
	[752] = { npcs = { [1] = { id = 32865 }, [2] = { id = 32872, expireAfterDeath = 30.0 }, [3] = { id = 32873, expireAfterDeath = 30.0 } } }, -- Thorim, Runic Colossus, Ancient Rune Giant
	[753] = { npcs = { [1] = { id = 32906 }, [2] = { id = 33203, expireAfterDeath = 30.0 }, [3] = { id = 33202, expireAfterDeath = 30.0 }, [4] = { id = 32919, expireAfterDeath = 30.0 }, [5] = { id = 32916, expireAfterDeath = 30.0 }, [6] = { id = 33228, expireAfterDeath = 5.0, expireAfterTrackingLoss = 15.0 } } }, -- Freya, Ancient Conservator, Ancient Water Spirit, Storm Lasher, Snap Lasher, Eonar's Gift
	[754] = { npcs = { [1] = { id = 33432, priority = 1 }, [2] = { id = 33651, priority = 2 }, [3] = { id = 33670, priority = 3 } } }, -- Mimiron: Leviathan, Body, Head
	[755] = { npcs = { [1] = { id = 33271 }, [2] = { id = 33524, expireAfterDeath = 10.0 } } }, -- Vezax, Animus
	[756] = { npcs = { [1] = { id = 33134, priority = -100, expireAfterTrackingLoss = 30.0 }, [2] = { id = 33288 }, [3] = { id = 33890 } } }, -- Yogg: Sara, Yogg, Brain
	[757] = { npcs = { [1] = { id = 32871 }, [2] = { id = 32955, expireAfterDeath = 10.0, expireAfterTrackingLoss = 10.0 } } }, -- Algalon, Collapsing Star


	-- Retail IDs (for testing the addon ahead of Ulduar release):
	[1132] = { npcs = { [1] = { id = 33113 } } }, -- Flame lev
	[1136] = { npcs = { [1] = { id = 33118 } } }, -- Ignis
	[1139] = { npcs = { [1] = { id = 33186 } } }, -- Razorscale
	[1142] = { npcs = { [1] = { id = 33293 }, [2] = { id = 33329 } } }, -- XT
	[1140] = { npcs = { [1] = { id = 32867 }, [2] = { id = 32927 }, [3] = { id = 32857 } } }, -- Iron Council
	[1137] = { npcs = { [1] = { id = 32930 }, [2] = { id = 32934, expireAfterDeath = 30.0 }, [3] = { id = 32933, expireAfterDeath = 30.0 } } }, -- Kologarn
	[1131] = { npcs = { [1] = { id = 33515 }, [2] = { id = 34035 } } }, -- Auriaya, Feral Defenders
	[1135] = { npcs = { [1] = { id = 32845 } } }, -- Hodir
	[1141] = { npcs = { [1] = { id = 32865 }, [2] = { id = 32872, expireAfterDeath = 30.0 }, [3] = { id = 32873, expireAfterDeath = 30.0 } } }, -- Thorim, Runic Colossus, Ancient Rune Giant
	[1133] = { npcs = { [1] = { id = 32906 }, [2] = { id = 33203, expireAfterDeath = 30.0 }, [3] = { id = 33202, expireAfterDeath = 30.0 }, [4] = { id = 32919, expireAfterDeath = 30.0 }, [5] = { id = 32916, expireAfterDeath = 30.0 }, [6] = { id = 33228, expireAfterDeath = 5.0, expireAfterTrackingLoss = 15.0 } } }, -- Freya, Ancient Conservator, Ancient Water Spirit, Storm Lasher, Snap Lasher, Eonar's Gift
	[1138] = { npcs = { [1] = { id = 33432, priority = 1 }, [2] = { id = 33651, priority = 2 }, [3] = { id = 33670, priority = 3 } } }, -- Mimiron: Leviathan, Body, Head
	[1134] = { npcs = { [1] = { id = 33271 }, [2] = { id = 33524, expireAfterDeath = 10.0 } } }, -- Vezax, Animus
	[1143] = { npcs = { [1] = { id = 33134, priority = -100, expireAfterTrackingLoss = 30.0 }, [2] = { id = 33288 }, [3] = { id = 33890 } } }, -- Yogg: Sara, Yogg, Brain
	[1130] = { npcs = { [1] = { id = 32871 }, [2] = { id = 32955, expireAfterDeath = 10.0, expireAfterTrackingLoss = 10.0 } } }, -- Algalon, Collapsing Star

	-- Naxx
	[1107] = { npcs = { [1] = { id = 15956 } } }, -- Anub
	[1108] = { npcs = { [1] = { id = 15932 } } }, -- Gluth
	[1109] = { npcs = { [1] = { id = 16060 } } }, -- Gothik
	[1110] = { npcs = { [1] = { id = 15953 } } }, -- Faer
	[1111] = { npcs = { [1] = { id = 15931 } } }, -- Grobb
	[1112] = { npcs = { [1] = { id = 15936 } } }, -- Heigan
	[1113] = { npcs = { [1] = { id = 16061 } } }, -- Raz
	[1114] = { npcs = { [1] = { id = 15990 } } }, -- KT
	[1115] = { npcs = { [1] = { id = 16011 }, [2] = { id = 16286, expireAfterDeath = 5.0, expireAfterTrackingLoss = 5.0 } } }, -- Loatheb, Spore
	[1116] = { npcs = { [1] = { id = 15952 }, [2] = { id = 16486, expireAfterDeath = 5.0, expireAfterTrackingLoss = 5.0 } } }, -- Maex, WebWrap
	[1117] = { npcs = { [1] = { id = 15954 } } }, -- Noth
	[1118] = { npcs = { [1] = { id = 16028 } } }, -- Patch
	[1119] = { npcs = { [1] = { id = 15989 } } }, -- Sapph
	[1120] = { npcs = { [1] = { id = 15928 }, [2] = { id = 15929, expireAfterDeath = 8.0 }, [3] = { id = 15930, expireAfterDeath = 8.0 } } }, -- Thadd
	[1121] = { npcs = { [1] = { id = 16064 }, [2] = { id = 30549 }, [3] = { id = 16065 }, [4] = { id = 16063 } } }, -- FourHoursemen: FrontLeft, FrontRight, BackLeft, BackRight

	-- Sartharion (Classic)
	[712] = { npcs = { [1] = { id = 28860 }, [2] = { id = 30452 }, [3] = { id = 30451 }, [4] = { id = 30449 } } }, -- Sartharion, Tenebron, Shadron, Vesperon

	-- EoE (Classic)
	[734] = { npcs = { [1] = { id = 28859 }, [2] = { id = 30084, expireAfterDeath = 15.0, expireAfterTrackingLoss = 15.0  } } }, -- Malygos, Power Spark,

	-- TOTC Retail/Classic IDs
	[1088] = { npcs = { -- Beasts
		[1] = { id = 34796, expireAfterDeath = 5.0, expireAfterTrackingLoss = 15.0 }, -- Gormok
		[2] = { id = 34800, expireAfterDeath = 5.0, expireAfterTrackingLoss = 5.0 }, -- Snobold
		[3] = { id = 35144, expireAfterDeath = 5.0, expireAfterTrackingLoss = 5.0 }, -- Acidmaw
		[4] = { id = 34799, expireAfterDeath = 5.0, expireAfterTrackingLoss = 5.0 }, -- Dreadscale
		[5] = { id = 34797 }, -- Icehowl
	}},
	[1087] = { npcs = { -- LORD JARAXXUS EREDAR LORD OF THE BURNING LEGION
		[1] = { id = 35458, expireAfterDeath = 3.0, expireAfterTrackingLoss = 1.0 }, -- Almighty Wilfred
		[2] = { id = 34780 }, -- Jaraxxus
		[3] = { id = 34825, expireAfterDeath = 1.0, expireAfterTrackingLoss = 5.0 }, -- Nether Portals
		[4] = { id = 34826, expireAfterDeath = 1.0, expireAfterTrackingLoss = 5.0 }, -- Mistress
		[5] = { id = 34813, expireAfterDeath = 1.0, expireAfterTrackingLoss = 5.0 }, -- Volcano
	}},
	-- Faction champions not included.
	[1089] = { npcs = { -- Twins
		[1] = { id = 34497 }, -- Fjola
		[2] = { id = 34496 }, -- Eydis
	}},
	[1085] = { npcs = { -- Anub
		[1] = { id = 34564 }, -- Anub
		[2] = { id = 34607, expireAfterDeath = 3.0, expireAfterTrackingLoss = 5.0 }, -- Burrower
	}},
	[629] = { npcs = { -- Beasts
		[1] = { id = 34796, expireAfterDeath = 5.0, expireAfterTrackingLoss = 15.0 }, -- Gormok
		[2] = { id = 34800, expireAfterDeath = 5.0, expireAfterTrackingLoss = 5.0 }, -- Snobold
		[3] = { id = 35144, expireAfterDeath = 5.0, expireAfterTrackingLoss = 5.0 }, -- Acidmaw
		[4] = { id = 34799, expireAfterDeath = 5.0, expireAfterTrackingLoss = 5.0 }, -- Dreadscale
		[5] = { id = 34797 }, -- Icehowl
	}},
	[633] = { npcs = { -- LORD JARAXXUS EREDAR LORD OF THE BURNING LEGION
		[1] = { id = 35458, expireAfterDeath = 3.0, expireAfterTrackingLoss = 1.0 }, -- Almighty Wilfred
		[2] = { id = 34780 }, -- Jaraxxus
		[3] = { id = 34825, expireAfterDeath = 1.0, expireAfterTrackingLoss = 5.0 }, -- Nether Portals
		[4] = { id = 34826, expireAfterDeath = 1.0, expireAfterTrackingLoss = 5.0 }, -- Mistress
		[5] = { id = 34813, expireAfterDeath = 1.0, expireAfterTrackingLoss = 5.0 }, -- Volcano
	}},
	-- Faction champions not included.
	[641] = { npcs = { -- Twins
		[1] = { id = 34497 }, -- Fjola
		[2] = { id = 34496 }, -- Eydis
	}},
	[645] = { npcs = { -- Anub
		[1] = { id = 34564 }, -- Anub
		[2] = { id = 34607, expireAfterDeath = 3.0, expireAfterTrackingLoss = 5.0 }, -- Burrower
	}},

	-- ICC

	[1095] = { npcs = { -- Blood Council
		[1] = { id = 37972 }, -- Keleseth (L)
		[2] = { id = 37970 }, -- Valanar (M)
		[3] = { id = 37973 }, -- Taladram (R)
	}},
	[1096] = { npcs = { -- Deathbringer Saurfang
		[1] = { id = 37813 }, -- Saurfang
		[2] = { id = 38508, expireAfterDeath = 5.0, expireAfterTrackingLoss = 10.0 }, -- BloodBeasts
	}},
	[1097] = { npcs = { -- Festergut
		[1] = { id = 36626 }, -- Festergut
		--[2] = { id = 36899, expireAfterDeath = 5.0, expireAfterTrackingLoss = 10.0 }, -- Big Ooze
		--[3] = { id = 36897, expireAfterDeath = 1.0, expireAfterTrackingLoss = 1.0 }, -- Little Ooze
	}},
	[1098] = { npcs = { -- Valithria
		[1] = { id = 36789 }, -- Saurfang
	}},
	[1099] = { npcs = { -- Gunship
	}},
	[1100] = { npcs = { -- Lady Deathwhisper
		[1] = { id = 36855 }, -- Deathwhisper
	}},
	[1101] = { npcs = { -- Lord Marrowgar
		[1] = { id = 36612 }, -- Marrowgar
		[2] = { id = 38711, expireAfterDeath = 5.0, expireAfterTrackingLoss = 10.0 }, -- Bone Spike
	}},
	[1102] = { npcs = { -- Putricide
		[1] = { id = 37697, expireAfterDeath = 5.0, expireAfterTrackingLoss = 10.0 }, -- Volatile Ooze
		[2] = { id = 36678 }, -- Putricide
		[3] = { id = 37562, expireAfterDeath = 5.0, expireAfterTrackingLoss = 10.0 }, -- Gas Cloud
	}},
	[1103] = { npcs = { -- Queen Lanathel
		[1] = { id = 37955 }, -- Queen Lanathel
	}},
	[1104] = { npcs = { -- Rotface
		[1] = { id = 36627 }, -- Rotface
	}},
	[1105] = { npcs = { -- Sindragosa
		[1] = { id = 36853 }, -- Sindragosa
		--[2] = { id = 36980, expireAfterDeath = 5.0, expireAfterTrackingLoss = 10.0 }, -- Ice Tomb
	}},
	[1106] = { npcs = { -- Lich King
		[1] = { id = 36597 }, -- Lich King
		[2] = { id = 36823, expireAfterTrackingLoss = 10.0 }, -- Terenas Menethil
		[3] = { id = 36824, expireAfterDeath = 5.0, expireAfterTrackingLoss = 10.0 }, -- Spirit Warden
		[4] = { id = 36609, expireAfterDeath = 5.0, expireAfterTrackingLoss = 10.0 }, -- Val'kyr
		[5] = { id = 36633, expireAfterDeath = 1.0, expireAfterTrackingLoss = 10.0 }, -- Ice Orb
	}},
	
	-- Debug encounter
	[0] = {
		npcs = {
			[1] = {
				id = 26316,
				expireAfterDeath = 5.0, -- Optional: Remove the health bar for this unit n seconds after death
				--priority = 25 -- Optional: Ordered high to low, uses npc array idx if no manual priority
			},
			[2] = {
				id = 26291
			}
		}
	},
	[1] = {
		npcs = {
			[1] = {
				id = 29724,
				expireAfterDeath = 3.0
			},
			[2] = {
				id = 29746,
				expireAfterTrackingLoss = 10.0
			}
		}
	},
	[2] = {
		npcs = {
			[1] = {
				id = 29724,
				expireAfterDeath = 3.0
			},
			[2] = {
				id = 31139,
				expireAfterTrackingLoss = 10.0
			},
			[3] = {
				id = 16128
			},
			[4] = {
				id = 31155
			},
			[5] = {
				id = 30115
			},
			[6] = {
				id = 30116
			}
		}
	},
}

local function GetIDFromGuid(guid)
	if string.sub(guid, 0, 8) ~= "Creature" and string.sub(guid, 0, 7) ~= "Vehicle" then return nil end
	-- Parse out NPC ID from [unitType]-0-[serverID]-[instanceID]-[zoneUID]-[ID]-[spawnUID]
	local npcID = select(6, strsplit("-", guid))
	return tonumber(npcID)
end

local function GetNPCInfo(unitID)
	local guid = UnitGUID(unitID)
	if guid == nil then return nil, nil end
	return guid, GetIDFromGuid(guid)
end

function BossHealthBar:OnInitialize()
	-- Settings
	self.db = LibStub("AceDB-3.0"):New("BossHealthBar", defaultSettings, true)
	self.db.RegisterCallback(self, "OnProfileChanged", function(db, newProfile) self:RefreshConfig("change") end)
	self.db.RegisterCallback(self, "OnProfileCopied", function(db, sourceProfile) self:RefreshConfig("copy") end)
	self.db.RegisterCallback(self, "OnProfileReset", function(db) self:RefreshConfig("reset") end)

	LibStub("AceConfig-3.0"):RegisterOptionsTable("BossHealthBar", options)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BossHealthBar", "Boss Health Bars")

	local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	LibStub("AceConfig-3.0"):RegisterOptionsTable("BossHealthBar_Profiles", profiles)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BossHealthBar_Profiles", "Profiles", "Boss Health Bars")

	self:RegisterEvent("ENCOUNTER_START", "OnEncounterStart")
	self:RegisterEvent("ENCOUNTER_END", "OnEncounterEnd")

	self:RegisterChatCommand("bhb", "OnSlashCommand")

	self.baseFrame = CreateFrame("Frame", "BossHealthBar", UIParent)
	self.baseFrame:SetWidth(self:GetBarWidth())
	self.baseFrame:SetHeight(self:GetBarHeight())
	self.baseFrame:SetClampedToScreen(true)
	self.baseFrame:SetMovable(true)

	self:UpdateBarLockState()
	self:RestorePosition() -- Restore saved position

	self.barPool = {} -- Pool of active bars given widgets are never destroyed
	self.boundCL = false -- Are we actively bound to the combat log events

	self.currentStatus = ""
	self.statusColorR = 0; self.statusColorG = 1; self.statusColorB = 0; self.statusColorA = 1

	-- Context menu
	self.contextMenu = CreateFrame("FRAME", nil, self.baseFrame, "UIDropDownMenuTemplate")
	do
		self.contextMenu:SetPoint("TOPLEFT", 0, -40)
		UIDropDownMenu_Initialize(self.contextMenu, DropdownInit_ContextMenu, "MENU")
		self.contextMenu:Hide()
	end

	-- Anchor bar
	self.anchorBar = self:CreateAnchor()
	self.anchorBar:SetPoint("TOPLEFT", 0, 0)

	-- Bind for media updates, any later-loading addons will call this
	LSM.RegisterCallback(self, "LibSharedMedia_SetGlobal", "OnMediaUpdate")
	LSM.RegisterCallback(self, "LibSharedMedia_Registered", "OnMediaUpdate")

	-- Either handle an encounter being in progress, otherwise wait for one to start
	if IsEncounterInProgress() then
		DEBUG_PRINT("Encounter already in progress, trying to find encounter ID...")
		self:TryFindActiveEncounter()
	else
		DEBUG_PRINT("No encounter in progress, waiting for start.")
		self:WaitingForEncounter()
	end

	if not FEATURE_BossUnits then
		DEBUG_PRINT("WARNING: BossUnits feature disabled, stock boss health bars will not be shown.")
	end
end

function BossHealthBar:OnMediaUpdate(event, mediatype, media)
	if 	(mediatype == LSM.MediaType.STATUSBAR and media == self:GetBarTexture()) or
		(mediatype == LSM.MediaType.FONT and media == self:GetFont()) then
		self:OnBarMediaUpdate()
	end
end

function BossHealthBar:WaitingForEncounter()
	self:UpdateStatus("Waiting for encounter...", 0, 0.5, 0, 1)

	self.encounterInfo = {
		trackedIDs = {},
		currentTargets = {},
		trackedUnits = {}
	}
	self.encounterActive = false
	self.encounterSize = 25
	self.npcCount = {}

	for idx, bar in pairs(self.barPool) do
		bar:Reset()
	end

	self:UpdateAnchorVisibility()
end

-- Called when we load in to an already active encounter, there's no API to detect encounter in progress that I see,
-- so we instead need to try determine based on our enounter to NPC mapping above (encounterMap)
function BossHealthBar:TryFindActiveEncounter()
	if (self.encounterSearchTick ~= nil) then return end -- Already searching

	self:UpdateStatus("Trying to find ongoing encounter ID", 1.0, 1.0, 0, 1)
	self.encounterSearchTick = self:ScheduleRepeatingTimer("TickEncounterSearch", 5.0) -- Tick in 5 seconds
end

function BossHealthBar:CancelActiveEncounterSearch()
	if self.encounterSearchTick ~= nil then
		DEBUG_PRINT("CancelActiveEncounterSearch")
		self:CancelTimer(self.encounterSearchTick)
		self.encounterSearchTick = nil
	end
end

function BossHealthBar:TickEncounterSearch()
	-- No ongoing encounter? Nothing to find.
	if not IsEncounterInProgress() then
		self:CancelActiveEncounterSearch()
		self:WaitingForEncounter()
		return
	end

	-- Encounter already active? Nothing to find.
	if self.encounterActive then
		self:CancelActiveEncounterSearch()
		return
	end

	local dungeonName, _, difficultyID, _, maxPlayers, _, _, _ = GetInstanceInfo()
	if dungeonName == nil then dungeonName = "Unknown" end
	if difficultyID == nil then difficultyID = 0 end
	if maxPlayers == nil then maxPlayers = 25 end

	-- We're in an active encounter and want to determine the encounter ID from a targeted NPC ID in the encounterMap
	local possibleTargets = { "target", "mouseover", "focus" }
	for i=1, maxPlayers do
		table.insert(possibleTargets, "raid" .. i .. "target")
	end

	for encounterID, encounterInfo in pairs(encounterMap) do
		for _, npcInfo in pairs(encounterInfo.npcs) do
			for _, target in pairs(possibleTargets) do
				local guid, npcID = GetNPCInfo(target)
				if npcID == npcInfo.id then
					self:OnEncounterStart(nil, encounterID, dungeonName, difficultyID, maxPlayers)
					return
				end
			end
		end
	end
	
	-- Unknown encounter, just try fall back to default boss frames
	self:OnEncounterStart(nil, -1, dungeonName, difficultyID, maxPlayers)
end

local anchorFontFlags = "OUTLINE"
local anchorFontStatusShrink = 4

function BossHealthBar:CreateAnchor()
	local baseBar = CreateFrame("Frame", "BossHealthBarBase", self.baseFrame)
	baseBar:SetAllPoints()

	local tex = baseBar:CreateTexture()
	tex:SetColorTexture(0, 0, 0, 1.0)
	tex:SetAllPoints()
	tex:SetAlpha(0.5)

	local baseBarHealth = CreateFrame("StatusBar", nil, baseBar)
	baseBarHealth:SetMinMaxValues(0,1)
	baseBarHealth:SetValue(1.0)
	baseBarHealth:SetPoint("TOPLEFT", baseBar, "TOPLEFT", 1, -1)
	baseBarHealth:SetPoint("BOTTOMRIGHT", baseBar, "BOTTOMRIGHT", -1, 1)
	baseBarHealth:SetStatusBarTexture(self:GetBarTextureMedia())
	baseBarHealth:SetStatusBarColor(self.statusColorR, self.statusColorG, self.statusColorB, self.statusColorA)
	baseBar.healthBar = baseBarHealth

	local overlay = CreateFrame("Frame", nil, baseBarHealth)
	overlay:SetAllPoints(true)
	overlay:SetFrameLevel(baseBarHealth:GetFrameLevel()+1)

	local name = overlay:CreateFontString(nil, "OVERLAY")
	name:SetPoint("TOPLEFT", baseBar, "TOPLEFT", 4, 0)
	name:SetPoint("BOTTOMRIGHT", baseBar, "BOTTOMRIGHT", - (floor(self.baseFrame:GetWidth() * 0.33)), 0)
	name:SetJustifyH("LEFT")
	name:SetJustifyV("MIDDLE")
	name:SetFont(self:GetFontMedia(), self:GetFontSize(), anchorFontFlags)
	name:SetWordWrap(false)
	name:SetText("Boss Health Bar")
	baseBar.nameText = name

	local status = overlay:CreateFontString(nil, "OVERLAY")
	status:SetPoint("TOPLEFT", baseBar, "TOPRIGHT", - (floor(self.baseFrame:GetWidth() * 0.33)), 0)
	status:SetPoint("BOTTOMRIGHT", baseBar, "BOTTOMRIGHT", -6, 0)
	status:SetFont(self:GetFontMedia(), self:GetFontSize() - anchorFontStatusShrink, anchorFontFlags)
	status:SetNonSpaceWrap(true)
	status:SetJustifyH("RIGHT")
	status:SetJustifyV("MIDDLE")
	status:SetText(self.currentStatus)
	baseBar.statusText = status

	return baseBar
end

function BossHealthBar:UpdateBarLockState()
	local lockMovement = self.db.profile.barLockState ~= "UNLOCKED"
	local lockClickthrough = self.db.profile.barLockState == "LOCKED_CLICKTHROUGH"

	if lockMovement then
		--self.baseFrame:SetMovable(false)
		self.baseFrame:EnableMouse(false)
		self.baseFrame:SetScript("OnDragStart", nil)
		self.baseFrame:SetScript("OnDragStop", nil)
		self.baseFrame:SetScript("OnMouseUp", nil)
	else
		--self.baseFrame:SetMovable(true)
		self.baseFrame:EnableMouse(true)
		self.baseFrame:RegisterForDrag("LeftButton")
		self.baseFrame:SetScript("OnDragStart", self.baseFrame.StartMoving)
		self.baseFrame:SetScript("OnDragStop", function()
			self.baseFrame:StopMovingOrSizing()
			BossHealthBar:SavePosition()
		end)
	end

	if lockClickthrough then
		self.baseFrame:SetScript("OnMouseUp", nil)
	else
		self.baseFrame:SetScript("OnMouseUp", function (self, button)
			if button == "RightButton" then
				BossHealthBar:ShowContextMenu()
			end
		end)
	end
end

function BossHealthBar:RefreshConfig(source)
	self:RestorePosition()

	-- TODO: Rethink how we apply settings given what needs to change switching profiles
	self:SetBarLockState(nil, self:GetBarLockState())
	self:SetGrowUp(nil, self:GetGrowUp())
	self:SetHideAnchorWhenLocked(nil, self:GetHideAnchorWhenLocked())
	self:OnSizeChanged()
end

function BossHealthBar:OnEnable()
end

function BossHealthBar:OnDisable()
end

function BossHealthBar:OnEncounterStart(_, encounterId, encounterName, difficultyID, groupSize)
	--print("BHB Dbg: Encounter " .. encounterId)
	DEBUG_PRINT("OnEncounterStart", _, encounterId, encounterName, difficultyID, groupSize)

	local encounterData = encounterMap[encounterId]
	if encounterData == nil then
		-- No encounter data, potentially untrackable encounter
		-- Clear existing encounter bars and update the status to signal we can't track this		
		local knownUntrackableName = knownMissingEncounters[encounterId]
		if knownUntrackableName ~= nil then
			self:WaitingForEncounter()
			self:UpdateStatus(format("Unable to track %s", knownUntrackableName), 0.5, 0.5, 0.5, 1.0)
			return
		end
	end

	self.encounterSize = groupSize
	self:InitForEncounter(encounterData)
end

function BossHealthBar:OnEncounterEnd(_, encounterId, encounterName, difficultyId, groupSize, success)
	DEBUG_PRINT("OnEncounterEnd", _, encounterId, encounterName, difficultyId, groupSize, success)
	if self.encounterActive then
		self:EndActiveEncounterDelayed()
	end
	
	-- Clear any ongoing but unresolved search for the current encounter
	self:CancelActiveEncounterSearch()
end

function BossHealthBar:OnSlashCommand(input)
	if input == "settings" or input == "options" or input == "" then
		LibStub("AceConfigDialog-3.0"):Open("BossHealthBar")
	elseif string.sub(input, 1, 5) == "debug" then
		local _, cmd, param1, param2 = strsplit(" ", input)
		if cmd == "start" then
			local encounterId = tonumber(param1)
			print("BHB Debug Start: Encounter " .. encounterId)

			self:OnEncounterStart(nil, encounterId, "debug", 0, 25)
		elseif cmd == "end" or cmd == "stop" then
			self:EndActiveEncounter()
			print("Encounter ended")
		elseif cmd == "toggle" then
			BossHealthBar.db.profile.debugMode = not BossHealthBar.db.profile.debugMode
		end
	else
		print("Unknown BHB command: " .. input)
	end
end

function BossHealthBar:ShowContextMenu()
	ToggleDropDownMenu(1, nil, self.contextMenu, "cursor", 3, -3)
end

function BossHealthBar:GetBarLockState()
	return self.db.profile.barLockState
end

function BossHealthBar:SetBarLockState(info, value)
	self.db.profile.barLockState = value
	self:UpdateBarLockState()
	self:UpdateAnchorVisibility()
end

function BossHealthBar:SetGrowUp(info, state)
	self.db.profile.growUp = state

	-- Perform the order change
	self:SortActiveBars()
end

function BossHealthBar:GetGrowUp(info)
	return self.db.profile.growUp
end

function BossHealthBar:SetReverseOrder(info, state)
	self.db.profile.reverseOrder = state

	-- Perform the order change
	self:SortActiveBars()
end

function BossHealthBar:GetReverseOrder(info)
	return self.db.profile.reverseOrder
end

function BossHealthBar:SetHideAnchorWhenLocked(info, state)
	BossHealthBar.db.profile.hideAnchorWhenLocked = state
	BossHealthBar:UpdateAnchorVisibility()
end

function BossHealthBar:GetHideAnchorWhenLocked(info)
	return BossHealthBar.db.profile.hideAnchorWhenLocked
end

function BossHealthBar:SetBarWidth(info, width)
	self.db.profile.barWidth = width
	self:OnSizeChanged()
end

function BossHealthBar:GetBarWidth(info)
	if self.db.profile.barWidth == nil then return defaultSettings.profile.barWidth end
	return self.db.profile.barWidth
end

function BossHealthBar:SetBarHeight(info, height)
	self.db.profile.barHeight = height
	self:OnSizeChanged()
end

function BossHealthBar:GetBarHeight(info)
	if self.db.profile.barHeight == nil then return defaultSettings.profile.barHeight end
	return self.db.profile.barHeight
end

function BossHealthBar:OnSizeChanged()
	-- Update relative frame sizes
	local saneW = max(10, self:GetBarWidth())
	local saneH = max(10, self:GetBarHeight())
	self.baseFrame:SetWidth(saneW)
	self.baseFrame:SetHeight(saneH)
	self.anchorBar:SetWidth(saneW)
	self.anchorBar:SetHeight(saneH)

	-- TODO: Can we better handle the layout of the frame to not require this? Still figuring out the frame setup	
	self.anchorBar.nameText:SetPoint("BOTTOMRIGHT", self.anchorBar, "BOTTOMRIGHT", - (floor(self.baseFrame:GetWidth() * 0.33)), 0)
	self.anchorBar.statusText:SetPoint("TOPLEFT", self.anchorBar, "TOPRIGHT", - (floor(self.baseFrame:GetWidth() * 0.33)), 0)

	-- Pooled bars
	for idx, bar in pairs(self.barPool) do
		bar:SetWidth(saneW)
		bar:SetHeight(saneH)
	end

	-- Re-sort given change in vertical offset
	self:SortActiveBars()
end

function BossHealthBar:SavePosition()
	local point, relativeTo, relativePoint, xOfs, yOfs = self.baseFrame:GetPoint(1)
	self.db.profile.hasPos = true
	self.db.profile.rootPoint = point
	self.db.profile.rootX = xOfs
	self.db.profile.rootY = yOfs
end

function BossHealthBar:RestorePosition()
	self.baseFrame:ClearAllPoints()

	if self.db.profile.hasPos ~= nil and self.db.profile.hasPos then
		self.baseFrame:SetPoint(self.db.profile.rootPoint, "UIParent", self.db.profile.rootX, self.db.profile.rootY)
	else
		-- Store initial position
		self.baseFrame:SetPoint("TOP", 0, -100)
		self:SavePosition()
	end
end

function BossHealthBar:SetBarTexture(info, texture)
	self.db.profile.barTexutre = texture
	self:OnBarMediaUpdate()
end

function BossHealthBar:GetBarTexture()
	return self.db.profile.barTexutre
end

function BossHealthBar:GetBarTextureMedia()
	return LSM:Fetch("statusbar", self:GetBarTexture())
end

function BossHealthBar:SetFont(info, font)
	self.db.profile.font = font
	self:OnBarMediaUpdate()
end

function BossHealthBar:GetFont()
	return self.db.profile.font
end

function BossHealthBar:GetFontMedia()
	return LSM:Fetch("font", self:GetFont())
end

function BossHealthBar:SetFontSize(info, size)
	self.db.profile.fontSize = size
	self:OnBarMediaUpdate()
end

function BossHealthBar:GetFontSize(info)
	return self.db.profile.fontSize
end

function BossHealthBar:OnBarMediaUpdate()
	-- Update existing bars
	local newBarTexture = self:GetBarTextureMedia()
	local newFont = self:GetFontMedia()
	self.anchorBar.healthBar:SetStatusBarTexture(newBarTexture)
	self.anchorBar.nameText:SetFont(newFont, self:GetFontSize(), anchorFontFlags)
	self.anchorBar.statusText:SetFont(newFont, math.max(1, self:GetFontSize() - anchorFontStatusShrink), anchorFontFlags)

	for idx, bar in pairs(self.barPool) do
		bar:OnMediaUpdate()
	end
end

function BossHealthBar:UpdateAnchorVisibility()
	-- Always hide anchor when there's active encounter bars
	if self:HasActiveBar() then
		self.anchorBar:Hide()
		return
	end

	-- Always show if there's no active encounter bars but we're in an encounter
	if self.encounterActive then
		self.anchorBar:Show()
		return
	end

	-- Not in an encounter, so hide when locked if desired, otherwise show
	if self.db.profile.barLockState ~= "UNLOCKED" and self.db.profile.hideAnchorWhenLocked then
		self.anchorBar:Hide()
	else
		self.anchorBar:Show()
	end
end

function DropdownInit_ContextMenu()
	local barLocked = BossHealthBar:GetBarLockState() == "LOCKED"

	local info = UIDropDownMenu_CreateInfo()
	info.text = "Bar Lock"
	info.arg1 = (barLocked and "UNLOCKED" or "LOCKED")
	info.checked = barLocked
	info.func = function(info, arg1) BossHealthBar:SetBarLockState(nil, arg1) end
	UIDropDownMenu_AddButton(info)

	local info = UIDropDownMenu_CreateInfo()
	info.text = "Hide Anchor While Locked"
	info.arg1 = not BossHealthBar.db.profile.hideAnchorWhenLocked
	info.checked = BossHealthBar.db.profile.hideAnchorWhenLocked
	info.func = function(info, arg1)
		BossHealthBar.db.profile.hideAnchorWhenLocked = arg1
		BossHealthBar:UpdateAnchorVisibility()
	end
	UIDropDownMenu_AddButton(info)

	local info = UIDropDownMenu_CreateInfo()
	info.text = "Settings"
	info.notCheckable = true
	info.func = function() LibStub("AceConfigDialog-3.0"):Open("BossHealthBar") end
	UIDropDownMenu_AddButton(info)

	-- Option to clear the data for any encounters that are no longer active, resetting to anchor only
	local showResetButton = not BossHealthBar.encounterActive and BossHealthBar:HasActiveBar()

	--[[local info = UIDropDownMenu_CreateInfo()
	info.text = "Clear Previous Encounter"
	info.notCheckable = true
	info.func = function() BossHealthBar:WaitingForEncounter() end
	info.opacity = 0.1
	UIDropDownMenu_AddButton(info);]]--

	local info = UIDropDownMenu_CreateInfo()
	info.text = "Cancel"
	info.notCheckable = true
	info.func = function() CloseDropDownMenus() end
	UIDropDownMenu_AddButton(info)
end

function BossHealthBar:InitForEncounter(encounterData) -- encounterData is null in the event we don't have an encounterMap entry
	-- In the rare case that a new encounter starts while our old encounter has a pending shutdown, do cleanup
	if self.encounterActive then
		if self.endEncounterDelay ~= nil then self:CancelTimer(self.endEncounterDelay) end
		self:EndActiveEncounter()
	end

	-- Reset all bars
	for idx, bar in pairs(self.barPool) do
		bar:Reset()
	end

	-- Hook onto CLEU for UNIT_KILLED
	if not self.boundCL then
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "OnActiveEncounterCLEU")
		self.boundCL = true
	end

	-- print("BHB New Encounter: " .. tostring(encounterData))
	self.encounterActive = true
	self.encounterInfo = {
		trackedIDs = {},
		currentTargets = {},
		trackedUnits = {}
	}
	self.npcCount = {}

	self:UpdateStatus("Seeking targets...", 0.5, 0.5, 0.5, 1.0)

	if encounterData ~= nil then
		local npcIdx = 1
		while encounterData.npcs[npcIdx] ~= nil do
			local npcData = encounterData.npcs[npcIdx]
			self.encounterInfo.trackedIDs[npcData.id] = npcData
	
			-- If there's no specific priority, use the definition order 
			if self.encounterInfo.trackedIDs[npcData.id].priority == nil then
				self.encounterInfo.trackedIDs[npcData.id].priority = 0 - npcIdx
			end
	
			npcIdx = npcIdx + 1
		end
	end

	self.encounterTick = self:ScheduleRepeatingTimer("TickActiveEncounter", 1/8) -- Tick at 8hz for hp check (todo: expose to settings)
	self:TickActiveEncounter()
	self:UpdateAnchorVisibility()
end

function BossHealthBar:EndActiveEncounter()
	self.endEncounterDelay = nil

	if self.boundCL then
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self.boundCL = false
	end

	self.encounterActive = false
	self:UpdateAnchorVisibility()

	if self.encounterTick ~= nil then
		self:CancelTimer(self.encounterTick)
		self.encounterTick = nil
	end

	-- Clear the tracked state of any still tracked bars
	for _, npcBar in pairs(self.encounterInfo.trackedUnits) do
		if not npcBar:HasExpired() and npcBar:IsTracked() then
			npcBar:LostTracking()
		end
	end

	-- Reset full state if user wants
	if self.db.profile.resetBarsOnEncounterFinish then
		self:WaitingForEncounter()
	end
end

-- Delayed ending that gives a brief window for the CLEU UNIT_DEATH to be received, it often doesn't otherwise
function BossHealthBar:EndActiveEncounterDelayed()
	self.endEncounterDelay = self:ScheduleTimer("EndActiveEncounter", 2.0)
end

-- Filter UNIT_DIED to the individual rows for their specific behaviour
function BossHealthBar:OnActiveEncounterCLEU()
	local ts, event, _, _, _, _, _, destGuid, _, _, _ = CombatLogGetCurrentEventInfo()
	if event ~= "UNIT_DIED" then return end
	local trackedUnitBar = self.encounterInfo.trackedUnits[destGuid]
	if trackedUnitBar ~= nil then
		trackedUnitBar:OnDeath()
	end
end

local targetedUnitArray = {}
function BossHealthBar:TickActiveEncounter()
	local overallSeenNPCs = {} -- All NPC Guid to IDs that we saw this tick, anything not here is considered missing/untracked
	local hadBarInvalidation = false

	-- Maintain a set of bars for any "boss" units, a feature that was added in the ICC patch for things that aren't a unit like the gunship
	local trackedBossGuids = {} -- The list of known boss NPCs
	if select(4, GetBuildInfo()) > 30402 and FEATURE_BossUnits then
		for i=1, 4 do
			local unitId = "boss" .. i
			local npcGuid, npcID = GetNPCInfo(unitId)
			if npcGuid ~= nil and npcID ~= nil then
				-- Ensure that a bar exists for this boss
				if self.encounterInfo.trackedUnits[npcGuid] == nil then
					-- Newly tracked unit
					-- Don't newly track a dead NPC
					if not UnitIsDead(unitId) then
						overallSeenNPCs[npcGuid] = npcID

						local npcCount = self.npcCount[npcID] ~= nil and self.npcCount[npcID] or 1
						self.npcCount[npcID] = npcCount + 1

						-- Try and find the tracking settings for an NPC of this ID, but it could be nil
						local trackingSettings = self.encounterInfo.trackedIDs[npcID]

						local newBar = self:GetNewBar()
						newBar:Activate(npcGuid, unitId, trackingSettings, npcCount, i)
						newBar:Show()

						self.encounterInfo.trackedUnits[npcGuid] = newBar
						self:UpdateAnchorVisibility()
						hadBarInvalidation = true
					end
				else
					-- Already tracked unit, update (if not updated this tick)
					if (overallSeenNPCs[npcGuid] == nil) then
						overallSeenNPCs[npcGuid] = npcID
						self.encounterInfo.trackedUnits[npcGuid]:UpdateFrom(unitId)
					end
				end
			end
		end
	end

	-- Set targetedUnitArray to nil, repopulate any still valid targeted, focused, mouseover'd, raidtargeted NPCs
	for k in pairs(targetedUnitArray) do
		targetedUnitArray[k] = nil
	end

	local unitGuid = UnitGUID("target")
	if unitGuid ~= nil and targetedUnitArray[unitGuid] == nil then targetedUnitArray[unitGuid] = "target" end

	unitGuid = UnitGUID("targettarget")
	if unitGuid ~= nil and targetedUnitArray[unitGuid] == nil then targetedUnitArray[unitGuid] = "targettarget" end

	unitGuid = GetNPCInfo("focus")
	if unitGuid ~= nil and targetedUnitArray[unitGuid] == nil then targetedUnitArray[unitGuid] = "focus" end

	unitGuid = UnitGUID("focustarget")
	if unitGuid ~= nil and targetedUnitArray[unitGuid] == nil then targetedUnitArray[unitGuid] = "focustarget" end

	unitGuid = GetNPCInfo("mouseover")
	if unitGuid ~= nil and targetedUnitArray[unitGuid] == nil then targetedUnitArray[unitGuid] = "mouseover" end

	unitGuid = GetNPCInfo("mouseovertarget")
	if unitGuid ~= nil and targetedUnitArray[unitGuid] == nil then targetedUnitArray[unitGuid] = "mouseovertarget" end

	-- Iterate nameplates
	for _, nameplateUnitId in pairs({ "nameplate1", "nameplate2", "nameplate3", "nameplate4", "nameplate5", "nameplate6", "nameplate7", "nameplate8", "nameplate9", "nameplate10",
		"nameplate11", "nameplate12", "nameplate13", "nameplate14", "nameplate15", "nameplate16", "nameplate17", "nameplate18", "nameplate19", "nameplate20",
		"nameplate21", "nameplate22", "nameplate23", "nameplate24", "nameplate25", "nameplate26", "nameplate27", "nameplate28", "nameplate29", "nameplate30",
		"nameplate31", "nameplate32", "nameplate33", "nameplate34", "nameplate35", "nameplate36", "nameplate37", "nameplate38", "nameplate39", "nameplate40"
	}) do
		unitGuid = GetNPCInfo(nameplateUnitId)
		if unitGuid ~= nil and targetedUnitArray[unitGuid] == nil then targetedUnitArray[unitGuid] = nameplateUnitId end
	end

	-- Iterate the n raid players targets
	for i=1, self.encounterSize do
		unitGuid = GetNPCInfo("raid" .. i .. "target")
		if unitGuid ~= nil and targetedUnitArray[unitGuid] == nil then targetedUnitArray[unitGuid] = "raid" .. i .. "target" end
	end

	-- Find desired NPCs to track from our target set
	for npcGuid, sourceUnitId in pairs(targetedUnitArray) do
		local npcID = GetIDFromGuid(npcGuid)
		if npcID ~= nil and self.encounterInfo.trackedIDs[npcID] ~= nil then

			-- NPC currently targeted by unitID 'v' is an npc of interest
			if self.encounterInfo.trackedUnits[npcGuid] == nil then
				-- Newly tracked unit
				-- Don't newly track a dead NPC
				if not UnitIsDead(sourceUnitId) then
					overallSeenNPCs[npcGuid] = npcID

					local npcCount = self.npcCount[npcID] ~= nil and self.npcCount[npcID] or 1
					self.npcCount[npcID] = npcCount + 1

					--if npcCount == 2 then
						-- TODO: This is the second instance of an NPC with the same ID, find the previous bar and append #1
					--end

					local trackingSettings = self.encounterInfo.trackedIDs[npcID]
					local newBar = self:GetNewBar()
					newBar:Activate(npcGuid, sourceUnitId, trackingSettings, npcCount, nil)
					newBar:Show()

					self.encounterInfo.trackedUnits[npcGuid] = newBar
					self:UpdateAnchorVisibility()
					hadBarInvalidation = true
				end
			else
				-- Already tracked unit, update (if not updated this tick)
				if (overallSeenNPCs[npcGuid] == nil) then
					overallSeenNPCs[npcGuid] = npcID
					self.encounterInfo.trackedUnits[npcGuid]:UpdateFrom(sourceUnitId)
				end
			end
		end
	end

	local expiredBars = {}
	for npcGuid, npcBar in pairs(self.encounterInfo.trackedUnits) do
		if npcBar:HasExpired() then
			-- Bar expiration
			npcBar:Reset()
			expiredBars[npcGuid] = true
			hadBarInvalidation = true
		elseif overallSeenNPCs[npcGuid] == nil and npcBar:IsTracked() then
			-- Signal tracking lost for anything that wasn't present in this scan
			npcBar:LostTracking()
		end
	end

	if next(expiredBars) ~= nil then
		-- todo: We've cleaned up bars, reorder
		for npcGuid, _ in pairs(expiredBars) do
			self.encounterInfo.trackedUnits[npcGuid] = nil
		end

		self:UpdateAnchorVisibility()
	end

	if hadBarInvalidation then
		self:SortActiveBars()
	end
end

function BossHealthBar:HasActiveBar()
	--if not self.encounterActive then return false end -- Disabled, we don't invalidate this until the next encounter starts
	if self.encounterInfo ~= nil then
		for npcGuid, npcBar in pairs(self.encounterInfo.trackedUnits) do
			if npcBar:IsActive() then
				return true
			end
		end
	end
	return false
end

function BossHealthBar:GetNewBar()
	local lastIdx = 0
	for idx, bar in pairs(self.barPool) do
		if not bar:IsActive() then return bar end
		lastIdx = idx
	end

	local baseBar =_G.BHB.HealthBar:New(self.baseFrame, self:GetBarWidth(), self:GetBarHeight())
	self.barPool[lastIdx + 1] = baseBar
	return baseBar
end

function BossHealthBar:SortActiveBars()
	local activeBars = {}
	local activeBarIdx = 1
	for idx, bar in pairs(self.barPool) do
		if bar:IsActive() then
			activeBars[activeBarIdx] = bar
			activeBarIdx = activeBarIdx + 1
		end
	end

	table.sort(activeBars, function(a,b)
		local prioA = a:GetPriority()
		local prioB = b:GetPriority()
		if prioA ~= prioB then return prioA > prioB end
		-- Fall back to bar spawn order
		return a:GetBarUID() < b:GetBarUID()
	end)

	local barVerticalOffset = (self:GetBarHeight() * (self.db.profile.growUp and 1 or -1))
	for k, v in ipairs(activeBars) do
		local individualBarIndex = self.db.profile.reverseOrder and ((#(activeBars) - k)) or (k - 1) -- Invert index if we're reversing sort order
		v:SetPoint("TOPLEFT", 0, individualBarIndex * barVerticalOffset)
	end
end

function BossHealthBar:UpdateStatus(msg, r, g, b, a)
	self.currentStatus = msg
	if self.anchorBar ~= nil then
		self.anchorBar.statusText:SetText(msg)
		if r ~= nil then
			self.anchorBar.healthBar:SetStatusBarColor(r, g, b, a)
		end
	end
end