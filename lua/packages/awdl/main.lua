if (CLIENT) then return end

module( "automatic_workshop_dl", package.seeall )

local logger = GPM.Logger( "Automatic Workshop DL" )

do
        
    local addon_count = 0
    function GetCount()
        return addon_count
    end

    function Add( addon )
        addon_count = addon_count + 1
        resource.AddWorkshop( addon.wsid )
    end

end

do

    local ipairs = ipairs
    local game_MountGMA = game.MountGMA

    local folders = {
        "materials",
        "particles",
        "resource",
        "models",
        "sound",
        "maps"
    }

    function Start()
        game_ready.wait(function()
            logger:info( "Beginning of the processing of server addons." )

            if isfunction( resource.Clear ) then
                logger:info( "Cleaning old downloadables..." )
                resource.Clear()
                logger:info( "Success!" )
            end

            local addons = engine.GetAddons()
            local count = #addons

            local start_time = SysTime()
            if (count > 0) then
                logger:info( "Detected {1} addons, processing...", count )

                local current_map = game.GetMap()
                for num, addon in ipairs( addons ) do
                    if addon.downloaded and addon.mounted then
                        local ok, files = game_MountGMA( addon.file )
                        if (ok) then
                            if addon.tags:match( "map" ) then
                                for num, fl in ipairs( files ) do
                                    if fl:sub( #fl - 3, #fl ) == ".bsp" and fl:sub( 6, #fl - 4 ) == current_map then
                                        Add( addon )
                                        break
                                    end
                                end
                            else
                                for num, fl in ipairs( files ) do

                                    local have_resources = false
                                    for num, folder in ipairs( folders ) do
                                        if fl:StartWith( folder .. "/" ) then
                                            have_resources = true
                                            Add( addon )
                                            break
                                        end
                                    end

                                    if (have_resources) then break end

                                end
                            end
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
