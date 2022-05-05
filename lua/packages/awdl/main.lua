if (CLIENT) then return end

module( "automatic_workshop_dl", package.seeall )

local logger = GPM.Logger( "Automatic Workshop DL" )

local addon_count = 0
function GetCount()
    return addon_count
end

do
    local resource_AddWorkshop = resource.AddWorkshop
    function Add( addon, title )
        addon_count = addon_count + 1
        resource_AddWorkshop( addon.wsid )
    end
end

do

    local ipairs = ipairs
    local game_MountGMA = game.MountGMA

    function Start()
        game_ready.wait(function()
            logger:info( "Beginning of the processing of server addons." )

            local addons = engine.GetAddons()
            local count = #addons

            local start_time = SysTime()
            if (count > 0) then
                logger:info( "Detected {1} addons, processing...", count )

                local current_map = game.GetMap()
                for num, addon in ipairs( addons ) do
                    if addon.downloaded and addon.mounted then
                        if addon.tags:match( "map" ) then
                            local ok, files = game_MountGMA( addon.file )
                            if (ok) then
                                for num, fl in ipairs( files ) do
                                    if fl:sub( #fl - 3, #fl ) == ".bsp" and fl:sub( 6, #fl - 4 ) == current_map then
                                        Add( addon, true )
                                        break
                                    end
                                end
                            end
                        else
                            Add( addon, false )
                        end
                    end
                end

                logger:info( "{1} addons successfully added to Workshop DL.", GetCount() )
            else
                logger:info( "Detected {1} addons, processing is not required.", count )
            end

        end)

        if game_ready.isReady() then return end
        logger:info( "Waiting for the server to be ready..." )
    end

end

if CreateConVar("sv_workshop_dl", "1", FCVAR_ARCHIVE, " - Enables automatic adding addons to Workshop DL.", 0, 1):GetBool() then
    Start()
end
