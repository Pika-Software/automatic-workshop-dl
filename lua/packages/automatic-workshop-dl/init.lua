install( "packages/glua-extensions", "https://github.com/Pika-Software/glua-extensions" )

local resource_AddWorkshop = resource.AddWorkshop
local logger = gpm.Logger
local string = string
local ipairs = ipairs
local engine = engine

logger:Info( "Beginning processing content from the Steam Workshop." )

local mapExtensions = {
    ["bsp"] = true,
    ["nav"] = true,
    ["ain"] = true
}

local currentMap = game.GetMap()
local addons = {}

for _, addon in ipairs( engine.GetAddons() ) do
    if not addon.mounted then continue end

    local tags = {}
    for _, tag in ipairs( string.Split( addon.tags, "," ) ) do
        tags[ #tags + 1 ] = string.lower( tag )
    end

    local isMap = table.HasIValue( tags, "map" )

    for _, filePath in ipairs( engine.GetAddonFiles( addon.wsid ) ) do
        local extension = string.GetExtensionFromFilename( filePath )
        if extension == "lua" then continue end

        if mapExtensions[ extension ] then
            if string.Replace( string.GetFileFromFilename( filePath ), extension, "" ) == currentMap then
                addons[ #addons + 1 ] = addon
                addon.ismap = true
                break
            end

            if isMap then
                break
            end

            continue
        end

        addons[ #addons + 1 ] = addon
        break
    end
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