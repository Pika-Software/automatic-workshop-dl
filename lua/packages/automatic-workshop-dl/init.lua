import( gpm.LuaPackageExists( "packages/glua-extensions" ) and "packages/glua-extensions" or "https://raw.githubusercontent.com/Pika-Software/glua-extensions/main/package.json" )

local resource_AddWorkshop = resource.AddWorkshop
local game_GetAddonFiles = game.GetAddonFiles
local logger = gpm.Logger
local string = string
local ipairs = ipairs

logger:Info( "Beginning processing content from the Steam Workshop." )

local currentMap = "maps/" .. game.GetMap() .. ".bsp"
local addons = {}

for _, addon in ipairs( engine.GetAddons() ) do
    if not addon.mounted then continue end

    local files = game_GetAddonFiles( addon.wsid )
    local blocked = false

    for _, tag in ipairs( string.Split( addon.tags, "," ) ) do
        if string.lower( tag ) == "map" then
            local isCurrentMap = false
            for _, filePath in ipairs( files ) do
                if filePath ~= currentMap then continue end
                isCurrentMap = true
                break
            end

            blocked = not isCurrentMap
            break
        end
    end

    if blocked then continue end
    local hasContent = false

    for _, filePath in ipairs( files ) do
        if filePath == currentMap then
            addon.ismap = true
            hasContent = true
            break
        end

        if string.StartsWith( filePath, "lua" ) or string.match( filePath, "^maps/.+%.bsp" ) then continue end
        hasContent = true
        break
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

for _, addon in ipairs( addons ) do
    resource_AddWorkshop( addon.wsid )
    logger:Debug( "+ %s %s (%s)", addon.ismap and "Map" or "Addon", addon.title, addon.wsid )
end

logger:Info( "%d addons successfully added to Workshop DL.", count )