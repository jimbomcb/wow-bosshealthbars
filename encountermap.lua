local AddonName, Private = ...

-- Map encounter ID to NPCs
-- encounterMap has interger key representing encounter ID
-- data is:
--   - NPCs: Lua-style array via integer-indexed table , NPC ID for each boss character to track
-- https://wowpedia.fandom.com/wiki/DungeonEncounterID 
Private.knownMissingEncounters = { [1086] = "Faction Champions", [637] = "Faction Champions" }

Private.retailEncounterAliases = {

	-- ICC Classic to Retail (for testing)

	[1101] = 845,
	[1100] = 846,
	[1099] = 847,
	[1096] = 848,
	[1097] = 849,
	[1104] = 850,
	[1102] = 851,
	[1095] = 852,
	[1103] = 853,
	[1098] = 854,
	[1105] = 855,
	[1106] = 856,
}

Private.encounterMap = {
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

	[845] = { npcs = { -- Lord Marrowgar
		[1] = { id = 36612 }, -- Marrowgar
		[2] = { id = 38711, expireAfterDeath = 5.0, expireAfterTrackingLoss = 30.0 }, -- Bone Spike
	}},
	[846] = { npcs = { -- Lady Deathwhisper
		[1] = { id = 36855, resourceBar = true, priority = 10 }, -- Deathwhisper
		[2] = { id = 37890, expireAfterDeath = 1.0, expireAfterTrackingLoss = 10.0, priority = 5 }, -- Cult Fanatic
		[3] = { id = 37949, expireAfterDeath = 1.0, expireAfterTrackingLoss = 10.0, priority = 5 }, -- Cult Adherent
	}},
	[847] = { npcs = { -- Gunship
		}, bosses = {
		boss1 = {
			priority = 10
		},
		boss2 = {
			priority = 5
		},
	}},
	[848] = { npcs = { -- Deathbringer Saurfang
		[1] = { id = 37813, resourceBar = true }, -- Saurfang
		[2] = { id = 38508, expireAfterDeath = 5.0, expireAfterTrackingLoss = 10.0 }, -- BloodBeasts
	}},
	[849] = { npcs = { -- Festergut
		[1] = { id = 36626 }, -- Festergut
	}},
	[850] = { npcs = { -- Rotface
		[1] = { id = 36627 }, -- Rotface
		[2] = { id = 36899, expireAfterDeath = 0.0, expireAfterTrackingLoss = 10.0 }, -- Big Ooze
		[3] = { id = 36897, expireAfterDeath = 0.0, expireAfterTrackingLoss = 10.0 }, -- Little Ooze
	}},
	[851] = { npcs = { -- Putricide
		[1] = { id = 36678 }, -- Putricide
		[2] = { id = 37697, expireAfterDeath = 5.0, expireAfterTrackingLoss = 10.0 }, -- Volatile Ooze
		[3] = { id = 37562, expireAfterDeath = 5.0, expireAfterTrackingLoss = 10.0 }, -- Gas Cloud
	}},
	[852] = { npcs = { -- Blood Council
			--[1] = { id = 37972 }, -- Keleseth (L)
			--[2] = { id = 37970 }, -- Valanar (M)
			--[3] = { id = 37973 }, -- Taladram (R)
		}, bosses = {
		boss1 = {
			priority = 10
		},
		boss2 = {
			priority = 9
		},
		boss3 = {
			priority = 8
		},
	}},
	[853] = { npcs = { -- Queen Lanathel
		[1] = { id = 37955 }, -- Queen Lanathel
	}},
	[854] = { npcs = { -- Valithria
		[1] = { id = 36789 }, -- Valithria
	}},
	[855] = { npcs = { -- Sindragosa
		[1] = { id = 36853 }, -- Sindragosa
		--[2] = { id = 36980, expireAfterDeath = 5.0, expireAfterTrackingLoss = 10.0 }, -- Ice Tomb
	}},
	[856] = { npcs = { -- Lich King
		[1] = { id = 36597, priority = 100 }, -- Lich King
		[2] = { id = 39217, expireAfterTrackingLoss = 5.0, priority = 99 }, -- Terenas Menethil
		[3] = { id = 36633, expireAfterDeath = 0.0, expireAfterTrackingLoss = 10.0, priority = 80 }, -- Ice Orb
		[4] = { id = 36701, expireAfterDeath = 0.0, expireAfterTrackingLoss = 10.0, priority = 50 }, -- Raging Spirit
		[5] = { id = 36609, expireAfterDeath = 0.0, expireAfterTrackingLoss = 10.0, priority = 80 }, -- Val'kyr
		[7] = { id = 37698, expireAfterDeath = 0.0, expireAfterTrackingLoss = 10.0, priority = 20 }, -- Shambling Horror p1
	}},

	-- Test RFC
	[431] = { 
		[1] = { id = 11520 }
	},

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
			[11] = {
				id = 31273,
				expireAfterTrackingLoss = 5.0
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
			},
			[7] = {
				id = 29493
			},
			[8] = {
				id = 28989
			},
			[9] = {
				id = 32336
			},
			[10] = {
				id = 31080,
				resourceBar = true
			},
			[12] = {
				id = 31146
			},
			[13] = {
				id = 153285
			},
			[14] = {
				id = 32666
			},
			[15] = {
				id = 32185,
				expireAfterDeath = 10.0,
				expireAfterTrackingLoss = 10.0,
				priority = 	15
			},
			[16] = {
				id = 32180,
				expireAfterDeath = 10.0,
				expireAfterTrackingLoss = 10.0,
				priority = 15
			},
			[20] = {
				id = 26277,
				expireAfterDeath = 10.0,
				expireAfterTrackingLoss = 10.0,
				priority = 15
			},
			[19] = {
				id = 27925,
				priority = 	999
			},
			[17] = {
				id = 32186,
				expireAfterDeath = 10.0,
				expireAfterTrackingLoss = 10.0,
				priority = 	20
			},
			[18] = {
				id = 31304
			},
		}
	},
}