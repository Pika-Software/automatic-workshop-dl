if file.Exists( "packages/glua_extensions/package.lua", "LUA" ) then
    import "packages/glua_extensions"
else
    import "https://raw.githubusercontent.com/Pika-Software/glua_extensions/main/glua_extensions.json"
end

local game_GetAddonFiles = game.GetAddonFiles
local string_StartsWith = string.StartsWith
local logger = gpm.Logger
local ipairs = ipairs

local contentFolders = {
    "materials",
    "particles",
    "resource",
    "models",
    "sound"
}

logger:Info( "Beginning processing content from the Steam Workshop." )

local currentMap = "maps/" .. game.GetMap() .. ".bsp"
local addons = {}

for _, addon in ipairs( engine.GetAddons() ) do
    if not addon.mounted then continue end

    local hasContent = false
    for _, filePath in ipairs( game_GetAddonFiles( addon.wsid ) ) do
        if hasContent then break end

        if filePath == currentMap then
            addon.ismap = true
            hasContent = true
            break
        end

        for _, folderName in ipairs( contentFolders ) do
            if not string_StartsWith( filePath, folderName ) then continue end
            hasContent = true
            break
        end

    end

    if not hasContent then continue end
    addons[ #addons + 1 ] = addon
end

local count = #addons
if count == 0 then
    logger:Warn( "No addons to process, cancelling..." )
    return
end

logger:Info( "Detected %s addons, processing...", count )
local resource_AddWorkshop = resource.AddWorkshop

for _, addon in ipairs( addons ) do
    resource_AddWorkshop( addon.wsid )
    logger:Debug( "+ %s %s (%s)", addon.ismap and "Map" or "Addon", addon.title, addon.wsid )
end

logger:Info( "%d addons successfully added to Workshop DL.", count )