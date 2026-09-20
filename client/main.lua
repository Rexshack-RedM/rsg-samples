--------------------------------------------------------------------------------------------
-- RSG SAMPLES — Client Editable
-- RSG-Core import and all client-facing logic you are allowed to customise freely.
--------------------------------------------------------------------------------------------
local RSGCore = exports['rsg-core']:GetCoreObject()

--------------------------------------------------------------------------------------------
-- BELOW ARE DEPENDENCIES. IF REMOVED, CODE WILL FAIL. EDIT, BUT DO NOT REMOVE THESE.
--------------------------------------------------------------------------------------------

-- Called when the server confirms a sample was added to the player's inventory.
-- TagHashId = animal name string, quantity = amount awarded (usually 1).
function RSG_ClientInventoryAdd(TagHashId, quantity)
    lib.notify({
        title       = locale('ui_title'),
        description = string.format(locale('sample_collected'), TagHashId, quantity),
        icon        = 'toast_mp_animal',
        duration    = 5000,
        type        = 'success',
    })

    if Config.DebugClient then
        print('[rsg-samples] RSG_ClientInventoryAdd:', TagHashId, 'x' .. quantity)
    end
end

-- Called when an animal revive event fires via taglistener.js.
function RSG_ClientReviveHandler(ReviveData)
    lib.notify({
        description = locale('revived'),
        type        = 'success',
    })

    if Config.DebugClient then
        print('[rsg-samples] RSG_ClientReviveHandler:', ReviveData)
    end
end

-- taglistener.js fires this as a local client event (no server round trip needed for a
-- cosmetic notification). Previously this was emitNet'd to a server event that had no
-- handler, so the revive notification never actually fired - this wires it back up.
AddEventHandler('rsg-samples:ReviveData', function(ReviveData)
    RSG_ClientReviveHandler(ReviveData)
end)

--------------------------------------------------------------------------------------------
-- Server-triggered item add (for inventory bridge scripts)
--------------------------------------------------------------------------------------------
RegisterNetEvent('rsg-samples:client:addItemToInventory')
AddEventHandler('rsg-samples:client:addItemToInventory', function(item, quantity)
    RSG_ClientInventoryAdd(item, quantity)
    if Config.DebugClient then
        print('[rsg-samples] addItemToInventory:', item, quantity)
    end
end)

--------------------------------------------------------------------------------------------
-- Open the Samples NUI
-- viewMode = 'menu'        → open the main tabbed clipboard UI
-- viewMode = 'certificate' → skip the main UI, jump straight to the certificate overlay
--------------------------------------------------------------------------------------------
RegisterNetEvent('rsg-samples:openSamplesMenu')
AddEventHandler('rsg-samples:openSamplesMenu', function(data)
    if Config.DebugClient then
        print('[rsg-samples] openSamplesMenu, viewMode:', data.viewMode or 'menu')
    end

    local action = (data.viewMode == 'certificate') and 'openCertificate' or 'openSamplesMenu'

    SendNUIMessage({
        action           = action,
        allSamples       = data.allSamples,
        collectedSamples = data.collectedSamples,
        topCollectors    = data.topCollectors,
        globalStats      = data.globalStats,
        currentCitizenId = data.currentCitizenId,
        playerName       = data.playerName,
        featuredAnimal   = data.featuredAnimal,
        featuredMultiplier = data.featuredMultiplier,
        lang             = data.lang,
    })

    SetNuiFocus(true, true)
end)

--------------------------------------------------------------------------------------------
-- NUI close callback — released by JS when the user closes any overlay
--------------------------------------------------------------------------------------------
RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    if Config.DebugClient then
        print('[rsg-samples] NUI focus released')
    end
    cb('ok')
end)