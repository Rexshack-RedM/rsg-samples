------
------
RSG_SampleStore  = {}
RSG_SampleTimers = {}
------
RegisterNetEvent('rsg-samples:Sampled')
AddEventHandler('rsg-samples:Sampled', function(sampleResult)
    if Config.DebugClient then
        print('[rsg-samples] SampleResult:', sampleResult)
    end
end)
------
function RSG_CleanupTranq(animalID)
    PromptSetVisible(RSG_SampleStore[animalID], false)
    RSG_SampleTimers[animalID] = nil
end
------
function RSG_CheckPedIsNet(animalID)
    repeat
        NetworkRegisterEntityAsNetworked(animalID)
        Wait(100)
    until NetworkDoesNetworkIdExist(NetworkGetNetworkIdFromEntity(animalID))
    if Config.DebugClient then
        print(NetworkGetNetworkIdFromEntity(animalID), 'netID Registered for Sampled Ped')
    end
end
------
function RSG_StartTranq(animalID)
    if not UiPromptIsValid(RSG_SampleStore[animalID]) then
        if Config.DebugClient then
            print('[rsg-samples] No Prompt exists for Sampled Entity, Creating.')
        end
        local animalHash       = GetEntityModel(animalID)
        local animalpromptgroup = UiPromptGetGroupIdForTargetEntity(animalID)
        Citizen.CreateThread(function()
            RSG_SampleTimers[animalID] = GetGameTimer()
            local promptString = CreateVarString(10, 'LITERAL_STRING', locale('prompt_take_sample'))
            RSG_SampleStore[animalID] = PromptRegisterBegin()
            PromptSetControlAction(RSG_SampleStore[animalID], 0x956C2A0E)
            PromptSetText(RSG_SampleStore[animalID], promptString)
            PromptSetEnabled(RSG_SampleStore[animalID], true)
            PromptSetVisible(RSG_SampleStore[animalID], false)
            PromptSetHoldMode(RSG_SampleStore[animalID], Config.SampleHoldTime)   -- configurable hold time
            PromptSetGroup(RSG_SampleStore[animalID], animalpromptgroup)
            PromptRegisterEnd(RSG_SampleStore[animalID])
            if Config.DebugClient then
                print('[rsg-samples] Prompt created for entity:', animalID)
            end
        end)
    end
end
------
function RSG_EndTranq(animalID)
    SetPedConfigFlag(animalID, 580, 0)
    ClearPedTasks(animalID, 1, 0)
    ClearPedSecondaryTask(animalID)
    ClearPedTasksImmediately(animalID)
    local animalcoords = GetEntityCoords(animalID)
    TaskFleeCoord(animalID, animalcoords.x + 100, animalcoords.y + 100, animalcoords.z, 2, 0, -1.0, 5000, 0)
    RSG_CleanupTranq(animalID)
    if Config.DebugClient then
        print('[rsg-samples] RSG_EndTranq cleanup for:', animalID)
    end
end
------
-- Thread: detect sedated animals and create/clean sample prompts
Citizen.CreateThread(function()
    while true do
        local gamePool = GetGamePool('CPed')
        for _, animal in ipairs(gamePool) do
            if not IsPedAPlayer(animal) then
                if DoesEntityExist(animal) then
                    if IsEntityDead(animal) then
                        SetPedConfigFlag(animal, 580, 0)
                        if RSG_SampleStore[animal] ~= nil then
                            PromptDelete(RSG_SampleStore[animal])
                            RSG_SampleStore[animal] = nil
                        end
                        RSG_CleanupTranq(animal)
                    else
                        if GetPedConfigFlag(animal, 580, 1) then
                            if RSG_SampleTimers[animal] == nil then
                                RSG_CheckPedIsNet(animal)
                                RSG_StartTranq(animal)
                            end
                        end
                    end
                else
                    RSG_CleanupTranq(animal)
                end
            end
        end
        Citizen.Wait(1000)
    end
end)
------
-- Thread: show prompts in range, fire sampling event, and manage sedation timers
Citizen.CreateThread(function()
    while true do
        for animalID, animalPrompt in pairs(RSG_SampleStore) do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local animalcoords = GetEntityCoords(animalID)
            local dist = Vdist(animalcoords.x, animalcoords.y, animalcoords.z,
                               playerCoords.x, playerCoords.y, playerCoords.z)

            if dist < 2.0 then
                PromptSetVisible(RSG_SampleStore[animalID], true)
            else
                PromptSetVisible(RSG_SampleStore[animalID], false)
            end

            local completedP = UiPromptHasHoldModeCompleted(animalPrompt)
            if completedP then
                local animalHash = GetEntityModel(animalID)
                -- Remove from store IMMEDIATELY before yielding to next frame.
                -- Prevents the Wait(0) loop from firing TriggerServerEvent a
                -- second time while UiPromptSetEnabled hasn't taken effect yet.
                RSG_SampleStore[animalID]  = nil
                RSG_SampleTimers[animalID] = nil
                UiPromptSetEnabled(animalPrompt, 0)
                UiPromptSetVisible(animalPrompt, 0)
                PromptDelete(animalPrompt)
                SetPedQuality(animalID, -1)
                TriggerServerEvent('rsg-samples:SampleData', animalHash)
                if Config.DebugClient then
                    print('[rsg-samples] Sampling complete, hash:', animalHash)
                end
            end
        end

        -- Sedation timer — uses Config.AnimalCleanupTime
        local now = GetGameTimer()
        for animalID, animalSedatedAt in pairs(RSG_SampleTimers) do
            local timediff = now - animalSedatedAt
            if timediff > Config.AnimalCleanupTime then
                if Config.DebugClient then
                    print('[rsg-samples] Sedation expired for:', animalID, 'after', timediff, 'ms')
                end
                RSG_EndTranq(animalID)
            end
        end

        Citizen.Wait(0)
    end
end)