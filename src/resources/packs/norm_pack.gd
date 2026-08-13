class_name NormPack
extends Object

static var map_packs: Array = []


static func init_vanilla(p_installation: NormalityInstallation) -> void:
	var das_packs: Array = p_installation.get_das_packs()
	var map_infos: Array = p_installation.get_map_infos(das_packs)
	
	var vanilla_map_pack: Dictionary = {
		"name": p_installation.name,
		"maps": [],
		"vanilla": p_installation,
		"normality": true,
	}
	map_packs.append(vanilla_map_pack)
	
	for map_info: Dictionary in map_infos:
		map_info["map_pack"] = vanilla_map_pack
		vanilla_map_pack.maps.append(Map.new(map_info))
