---@type dreamwork
local dreamwork = _G.dreamwork

assert( dreamwork, "Failed to load 'automatic-workshop-dl', dreamwork is missing!" )

---@type dreamwork.std
local std = dreamwork.std

local logger = std.console.Logger( {
    title = "automatic-workshop-dl@0.1.0",
    color = std.Color( 50, 150, 255 ),
    interpolation = false
} )

if game.SinglePlayer() then
	logger:error( "Silly! It's useless in singleplayer, let me turn if off for you ;p" )
	return
end

logger:info( "//> --- [ Let It Roll! ] --- //>" )

local awdl_smart_maps = std.console.Variable( {
	name = "awdl_smart_maps",
	default = true,
	description = "Enable smart map sending (only send maps that are loaded in the game)",
	type = "boolean"
} )

local awdl_smart_gamemodes = std.console.Variable( {
	name = "awdl_smart_gamemodes",
	default = true,
	description = "Enable smart gamemode sending (only send gamemodes that are loaded in the game)",
	type = "boolean"
} )

local string = std.string
local string_split = string.split
local string_lower = string.lower
local string_format = string.format

local path = std.path
local path_getExtension = path.getExtension

local file = _G.file
local file_Find = file.Find
local file_Exists = file.Exists

local bit = std.bit
local bit_bor = bit.bor

local resource_AddWorkshop = _G.resource.AddWorkshop

local tag_names = {
	[ "gamemode" ] = "gamemodes",
	[ "navmesh" ] = "navigation mesh",
	[ "weapon" ] = "weapons",
	[ "vehicle" ] = "vehicles",
	[ "npc" ] = "npcs",
	[ "entity" ] = "entites",
	[ "tool" ] = "tools",
	[ "effects" ] = "effects",
	[ "servercontent" ] = "server content",
	[ "materials" ] = "materials",
	[ "particle" ] = "effects",
	[ "model" ] = "models",
	[ "sound" ] = "sounds",
	[ "scene" ] = "scenes",
	[ "localization" ] = "localization",
	[ "fonts" ] = "fonts",
	[ "shader" ] = "shaders",
	[ "map" ] = "maps",
}

---@type table<string, boolean>
local resource_extensions = {
	[ "mdl" ] = true,
	[ "vtx" ] = true,
	[ "phy" ] = true,
	[ "ani" ] = true,
	[ "vvd" ] = true,
	[ "wav" ] = true,
	[ "mp3" ] = true,
	[ "ogg" ] = true,
	[ "vmt" ] = true,
	[ "vtf" ] = true,
	[ "png" ] = true,
	[ "jpg" ] = true,
	[ "jpeg" ] = true,
	[ "raw" ] = true,
	[ "ttf" ] = true,
	[ "pcf" ] = true,
	[ "vcd" ] = true,
	[ "properties" ] = true
}

---@type table<string, string[]>
local gamemode_cache = {}

setmetatable( gamemode_cache, {
	__index = function( _, addon_mount )
		local _, gamemodes = file_Find( "gamemodes/*", addon_mount )
		return gamemodes
	end,
	__mode = "kv"
} )


---@param directory string
---@param addon_mount string
local function is_directory_not_empty( directory, addon_mount )
	local files, directories = file_Find( directory .. "/*", addon_mount )
	if ( #files + #directories ) ~= 0 then
		return true
	end

	local gamemodes = gamemode_cache[ addon_mount ]

	for i = 1, #gamemodes, 1 do
		local gamemode_files, gamemode_directories = file_Find( string_format( "gamemodes/%s/content/%s/*", gamemodes[ i ], directory ), addon_mount )
		if ( #gamemode_files + #gamemode_directories ) ~= 0 then
			return true
		end
	end

	return false
end

local contents_info = {
	{ 2, "map" }, -- maps
	{ 4, "model" }, -- models
	{ bit_bor( 4, 8 ), "model" }, -- models
	{ 8, "materials" }, -- materials
	{ bit_bor( 8, 16 ), "particle" }, -- particles
	{ 16, "particle" }, -- particles
	{ 32, "sound" }, -- sound
	{ 64, "scene" }, -- scenes
	{ 128, "localization" }, -- localization
	{ 256, "fonts" }, -- fonts
	{ 512, "shader" }, -- shaders
	{ 1024, "navmesh" } -- navmesh
}

local content = 0

---@param addon_info dreamwork.engine.AddonInfo
local function perform_addon( addon_info )
	if not ( addon_info.downloaded and addon_info.mounted ) then return end

	local tags, tag_count = string_split( addon_info.tags, ",", false )
	local addon_type

	for i = 1, tag_count, 1 do
		local tag = string_lower( tags[ i ] )
		if tag_names[ tag ] ~= nil then
			addon_type = tag
			break
		end
	end

	local addon_mount = addon_info.title

	if addon_type == "gamemode" then
		local gamemodes = gamemode_cache[ addon_mount ]
		for i = 1, #gamemodes, 1 do
			local gamemode_name = string_lower( gamemodes[ i ] )
			local gamemode_folder = "gamemodes/" .. gamemode_name

			if file_Exists( string_format( "%s/%s.txt", gamemode_folder, gamemode_name ), addon_mount ) then
				local _, content_dirs = file_Find( string_format( "%s/content/*", gamemode_folder ), addon_mount )
				if #content_dirs ~= 0 then
					goto addon_processed
				end

				break
			end
		end

		addon_type = nil
	elseif addon_type == "map" then
		local maps = file_Find( "maps/*.*", addon_mount )
		local bsp_count, nav_count = 0, 0

		if #maps == 0 then
			local gamemodes = gamemode_cache[ addon_mount ]
			for i = 1, #gamemodes, 1 do
				local gamemode_maps = file_Find( string_format( "gamemodes/%s/content/maps/*", gamemodes[ i ] ), addon_mount )
				for j = 1, #gamemode_maps, 1 do
					local extension = path_getExtension( gamemode_maps[ j ] )
					if extension == "bsp" then
						bsp_count = bsp_count + 1
					elseif extension == "nav" or extension == "ain" then
						nav_count = nav_count + 1
					end
				end
			end
		else
			for i = 1, #maps, 1 do
				local extension = path_getExtension( maps[ i ] )
				if extension == "bsp" then
					bsp_count = bsp_count + 1
				elseif extension == "nav" or extension == "ain" then
					nav_count = nav_count + 1
				end
			end
		end

		if bsp_count == 0 then
			if nav_count == 0 then
				addon_type = nil
			else
				addon_type = "navmesh"
				goto addon_processed
			end
		else
			goto addon_processed
		end
	end

	content = 0

	do

		local maps = file_Find( "maps/*", addon_mount )
		if #maps == 0 then
			local gamemodes = gamemode_cache[ addon_mount ]
			local bsp_count, nav_count = 0, 0

			for i = 1, #gamemodes, 1 do
				local gamemode_maps = file_Find( string_format( "gamemodes/%s/content/maps/*.*", gamemodes[ i ] ), addon_mount )
				for j = 1, #gamemode_maps, 1 do
					local extension = path_getExtension( gamemode_maps[ j ] )
					if extension == "bsp" then
						bsp_count = bsp_count + 1
					elseif extension == "nav" or extension == "ain" then
						nav_count = nav_count + 1
					end
				end
			end

			if bsp_count == 0 then
				if nav_count ~= 0 then
					content = bit_bor( content, 1024 )
				end
			else
				content = bit_bor( content, 2 )
			end
		else
			content = bit_bor( content, 2 )
		end

	end

	if addon_info.models > 0 or is_directory_not_empty( "models", addon_mount ) then
		content = bit_bor( content, 4 )
	end

	if is_directory_not_empty( "materials", addon_mount ) then
		content = bit_bor( content, 8 )
	end

	if is_directory_not_empty( "particles", addon_mount ) then
		content = bit_bor( content, 16 )
	end

	if is_directory_not_empty( "sound", addon_mount ) then
		content = bit_bor( content, 32 )
	end

	if is_directory_not_empty( "scenes", addon_mount ) then
		content = bit_bor( content, 64 )
	end

	if is_directory_not_empty( "resource/localization", addon_mount ) then
		content = bit_bor( content, 128 )
	end

	do

		local fonts = file_Find( "resource/fonts/*.ttf", addon_mount )
		if #fonts == 0 then
			local gamemodes = gamemode_cache[ addon_mount ]
			for i = 1, #gamemodes, 1 do
				local gamemode_fonts = file_Find( string_format( "gamemodes/%s/content/resource/fonts/*.ttf", gamemodes[ i ] ), addon_mount )
				if #gamemode_fonts ~= 0 then
					content = bit_bor( content, 256 )
					break
				end
			end
		else
			content = bit_bor( content, 256 )
		end

	end

	if is_directory_not_empty( "shaders", addon_mount ) then
		content = bit_bor( content, 512 )
	end

	if content == 0 then
		logger:warn( "Addon '%s' has no content, skipping...", addon_mount )
		return nil
	end

	for i = 1, #contents_info, 1 do
		local content_info = contents_info[ i ]
		if content == content_info[ 1 ] then
			addon_type = content_info[ 2 ]
			goto addon_processed
		end
	end

	addon_type = "servercontent"

	::addon_processed::

	if addon_type == "gamemode" and awdl_smart_gamemodes.value then
		local current_gamemode = engine.ActiveGamemode()
		local gamemodes = gamemode_cache[ addon_mount ]
		local is_valid = false

		for i = 1, #gamemodes, 1 do
			if gamemodes[ i ] == current_gamemode then
				is_valid = true
				break
			end
		end

		if not is_valid then
			logger:warn( "Addon '%s' contains gamemode that not equals to active one, skipping...", addon_mount )
			return
		end
	end

	if addon_type == "map" and awdl_smart_maps.value and game.GetMap() ~= addon_mount then
		logger:warn( "Addon '%s' contains map that not equals to active one, skipping...", addon_mount )
		return
	end

	logger:info( "Addon '%s' contains %s and will be added to player's WorkshopDL queue.", addon_info.title, tag_names[ addon_type ] or "unknown" )
	resource_AddWorkshop( addon_info.wsid )
end

for i = 1, dreamwork.engine.AddonCount, 1 do
	perform_addon( dreamwork.engine.AddonList[ i ] )
end

---@param addon_info dreamwork.engine.AddonInfo
---@param is_mounted boolean
dreamwork.engine.hookCatch( "AddonMounted", function( addon_info, is_mounted )
	if not is_mounted then return end
	perform_addon( addon_info )
end )
