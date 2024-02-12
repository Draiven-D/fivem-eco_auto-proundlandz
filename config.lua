Config = {}
Config.ItemUse = "autofarm"
Config.Zones = {
	mine = {
		Routine = false,
		Auto = true,
		IsControl = false,
		MiniGame = false,
		Dist = 40.0,
		Dist2 = 30.0,
		Item = "crystal",
		PropName = "likemod_rock_anim_props",
		Count = {1,3},
		Dict = "melee@large_wpn@streamed_core",
		Anim =  "ground_attack_on_spot_body",
		PropAnim = {
			model = `prop_tool_pickaxe`,
			bone = 28422,
			coords = { x = -0.007, y = -0.07, z = 0.001 },
			rotation = { x = 80.0, y = 0.0, z = 180.0 }
		},
		Harvest = {
			coords = vector3(2950.1030, 2795.4456, 40.8154),
			name = '<font face="THSarabunNew">เหมือง</font>',
			color = 47,
			sprite = 175,
			radius = 0.0
		},
		Storage = {
			coords = vector3(2954.5649, 2816.5686, 42.3597),
			state = 11
		},
		Extra = true,
		ExtraItem = {"pink_shards","black_shards"},
		Rate = 20,
		-- Process = {
		-- 	coords = vector3(2626.8650, 2932.3315, 40.4228),
		-- 	name = '<font face="THSarabunNew">โพเสจเหมือง</font>',
		-- 	color = 47,
		-- 	sprite = 318,
		-- 	radius = 0.0
		-- },
		-- ProcessAll = true,
		-- ProcessUse = 1,
		-- ProcessDuration = 20000,
		-- ProcessItem = {
		-- 	{ name = "copper", rate = 100, count = 1 },
		-- 	{ name = "iron", rate = 80, count = 1 },
		-- 	{ name = "gold", rate = 60, count = 1 },
		-- 	{ name = "diamond", rate = 30, count = 1 }
		-- },
	},
	-- elu_ori = {
	-- 	Routine = false,
	-- 	Auto = false,
	-- 	IsControl = true,
	-- 	MiniGame = true,
	-- 	Necessary = "shovel",
	-- 	NecessaryText = "คุณไม่มีพลั่วเสริมแกร่ง",
	-- 	Text = "[~r~E~s~] เพื่อขุดแร่พิเศษ",
	-- 	Dist = 40.0,
	-- 	Dist2 = 30.0,
	-- 	Item = "oridecon",
	-- 	Item2 = "elunium",
	-- 	PropName = "crystals_props_v3_2",
	-- 	Count = {1,1},
	-- 	Dict = "melee@large_wpn@streamed_core",
	-- 	Anim =  "ground_attack_on_spot_body",
	-- 	PropAnim = {
	-- 		model = `prop_tool_pickaxe`,
	-- 		bone = 28422,
	-- 		coords = { x = -0.007, y = -0.07, z = 0.001 },
	-- 		rotation = { x = 80.0, y = 0.0, z = 180.0 }
	-- 	},
	-- 	Harvest = {
	-- 		coords = vector3(-2902.0547, 3093.9272, 2.1414),
	-- 		name = '<font face="THSarabunNew">แร่พิเศษ</font>',
	-- 		color = 46,
	-- 		sprite = 304,
	-- 		radius = 0.0
	-- 	},
	-- 	Storage = {
	-- 		coords = vector3(-2868.4524, 3096.7556, 3.2002),
	-- 		state = 16
	-- 	},
	-- 	Extra = true,
	-- 	ExtraItem = {"orb"},
	-- 	Rate = 15,
	-- },
	-- holywater = {
	-- 	Routine = true,
	-- 	Show = false,
	-- 	Time = {
	-- 		{06,00},
	-- 		{08,00},
	-- 		{10,00},
	-- 		{12,00},
	-- 		{14,00},
	-- 		{16,00},
	-- 		{18,00},
	-- 		{20,00},
	-- 		{23,00},
	-- 		{00,00}
	-- 	},
	-- 	Remaining = 20, -- min
	-- 	Auto = false,
	-- 	IsControl = true,
	-- 	MiniGame = false,
	-- 	Text = "[~r~E~s~] เพื่อเก็บน้ำมนต์",
	-- 	Dist = 90.0,
	-- 	Dist2 = 80.0,
	-- 	Item = "holywater",
	-- 	PropName = "likemod_chest_anim_props",
	-- 	Count = {1,2},
	-- 	Dict = "custom@pickfromground",
	-- 	Anim =  "pickfromground",
	-- 	PropAnim = nil,
	-- 	Harvest = {
	-- 		coords = vector3(1252.8342, 3094.9897, 39.8796),
	-- 		name = '<font face="THSarabunNew">น้ำมนต์</font>',
	-- 		color = 0,
	-- 		sprite = 313,
	-- 		radius = 0.0
	-- 	},
	-- 	Storage = {},
	-- 	Extra = false,
	-- 	ExtraItem = {},
	-- 	Rate = 0
	-- }
}