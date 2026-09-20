--------------------------------------------------------------------------------------------
-- RSG SAMPLES — ox_target Leaderboard Zone + Map Blip
-- Adds an interaction point at Config.LeaderboardLocation where players can open the
-- Samples Leaderboard. Optionally adds a map blip to help players find the location.
--------------------------------------------------------------------------------------------

CreateThread(function()
    Wait(500) -- Allow ox_target to finish initialising

    -- ----------------------------------------
    -- ox_target sphere zone
    -- ----------------------------------------
    exports.ox_target:addSphereZone({
        coords  = Config.LeaderboardLocation.coords,
        radius  = Config.LeaderboardLocation.radius,
        debug   = Config.DebugClient,
        options = {
            {
                label    = locale('target_leaderboard'),
                icon     = 'fas fa-book-open',
                onSelect = function()
                    TriggerServerEvent('rsg-samples:requestLeaderboard')
                end,
            }
        }
    })

    if Config.DebugClient then
        print('[rsg-samples] ox_target zone added at', Config.LeaderboardLocation.coords)
    end

    -- ----------------------------------------
    -- Optional map blip
    -- RDR3 blip natives differ from FiveM; wrapped in pcall for safety.
    -- ----------------------------------------
    if Config.ShowBlip then
        local ok, err = pcall(function()
            local c    = Config.LeaderboardLocation.coords
            local blip = BlipAddForCoords(c.x, c.y, c.z)
            if not blip then return end

            if Config.BlipSprite and Config.BlipSprite ~= 0 then
                pcall(SetBlipSprite, blip, Config.BlipSprite, true)
            end
            pcall(SetBlipScale, blip, Config.BlipScale)

            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(Config.BlipLabel)
            EndTextCommandSetBlipName(blip)
        end)

        if Config.DebugClient then
            if ok then
                print('[rsg-samples] Map blip added for leaderboard location')
            else
                print('[rsg-samples] Blip setup error (non-fatal):', err)
            end
        end
    end
end)