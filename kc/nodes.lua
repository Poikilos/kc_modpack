-- tiles: +Y, -Y, +X, -X, +Z, -Z. In English: top, bottom, right, left, back, front.  - http://dev.minetest.net/minetest.register_node
minetest.register_node("kc:tooling_station", {
	description = "Tooling Station",
	tiles = {"kc_tooling_station_top.png", "kc_tooling_station_bottom.png", "kc_tooling_station_sides.png",
		"kc_tooling_station_sides.png", "kc_tooling_station_back.png", "kc_tooling_station_front.png"},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {choppy = 3, oddly_breakable_by_hand = 2, flammable = 3},
	sounds = default.node_sound_wood_defaults(),
})
