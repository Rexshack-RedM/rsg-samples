--------------------------------------------------------------------------------------------
-- RSG SAMPLES — Server Editable
-- RSG-Core import, animal map, and all server-side game logic.
--------------------------------------------------------------------------------------------
local RSGCore = exports['rsg-core']:GetCoreObject()

--------------------------------------------------------------------------------------------
-- BELOW ARE DEPENDENCIES. IF REMOVED, CODE WILL FAIL. EDIT, BUT DO NOT REMOVE THESE.
--------------------------------------------------------------------------------------------

-- Runtime featured animal (starts from config, can be changed live with /setfeatured)
local featuredAnimal = Config.FeaturedAnimal

--------------------------------------------------------------------------------------------
-- Animal Hash Map
-- Each entry: { name, reward, category, legendary }
-- Categories: 'Predator' | 'Bird' | 'Reptile' | 'Ungulate' | 'Small Game' | 'Exotic'
-- NOTE: Duplicate keys in the original script have been resolved below (last value wins).
--------------------------------------------------------------------------------------------
local hashToAnimalMap = {
    -- ===== PREDATORS =====
    [-1124266369] = { name = 'bear',                           reward = 500,  category = 'Predator',   legendary = false },
    [730092646]   = { name = 'american_black_bear',            reward = 400,  category = 'Predator',   legendary = false },
    [-1143398950] = { name = 'big_grey_wolf',                  reward = 650,  category = 'Predator',   legendary = false },
    [-885451903]  = { name = 'medium_grey_wolf',               reward = 400,  category = 'Predator',   legendary = false },
    [-829273561]  = { name = 'small_grey_wolf',                reward = 250,  category = 'Predator',   legendary = false },
    [-1392359921] = { name = 'legendary_onyx_wolf',            reward = 1500, category = 'Predator',   legendary = true  },
    [1654513481]  = { name = 'panther',                        reward = 400,  category = 'Predator',   legendary = false },
    [-1189368951] = { name = 'legendary_ghost_panther',        reward = 500,  category = 'Predator',   legendary = true  },
    [90264823]    = { name = 'cougar',                         reward = 350,  category = 'Predator',   legendary = false },
    [-1433814131] = { name = 'legendary_maza_cougar',          reward = 500,  category = 'Predator',   legendary = true  },
    [480688259]   = { name = 'coyote',                         reward = 200,  category = 'Predator',   legendary = false },
    [-1307757043] = { name = 'legendary_midnight_paw_coyote',  reward = 500,  category = 'Predator',   legendary = true  },

    -- ===== BIRDS =====
    [-1003616053] = { name = 'duck',                           reward = 100,  category = 'Bird',       legendary = false },
    [1459778951]  = { name = 'eagle',                          reward = 150,  category = 'Bird',       legendary = false },
    [831859211]   = { name = 'egret',                          reward = 120,  category = 'Bird',       legendary = false },
    [1104697660]  = { name = 'vulture',                        reward = 100,  category = 'Bird',       legendary = false },
    [-2011226991] = { name = 'wild_turkey',                    reward = 100,  category = 'Bird',       legendary = false },
    [-166054593]  = { name = 'wild_turkey_variant',            reward = 100,  category = 'Bird',       legendary = false },
    [-466687768]  = { name = 'red_footed_booby',               reward = 100,  category = 'Bird',       legendary = false },
    [-164963696]  = { name = 'herring_seagull',                reward = 80,   category = 'Bird',       legendary = false },
    [-1076508705] = { name = 'roseate_spoonbill',              reward = 120,  category = 'Bird',       legendary = false },
    [2023522846]  = { name = 'dominique_rooster',              reward = 100,  category = 'Bird',       legendary = false },
    [-2063183075] = { name = 'dominique_chicken',              reward = 100,  category = 'Bird',       legendary = false },
    [-575340245]  = { name = 'western_raven',                  reward = 90,   category = 'Bird',       legendary = false },
    [2079703102]  = { name = 'greater_prairie_chicken',        reward = 100,  category = 'Bird',       legendary = false },
    [1416324601]  = { name = 'ring_necked_pheasant',           reward = 100,  category = 'Bird',       legendary = false },
    [1265966684]  = { name = 'american_white_pelican',         reward = 120,  category = 'Bird',       legendary = false },
    [-1797450568] = { name = 'blue_yellow_macaw',              reward = 150,  category = 'Bird',       legendary = false },
    [1205982615]  = { name = 'californian_condor',             reward = 150,  category = 'Bird',       legendary = false },
    [-2073130256] = { name = 'double_crested_cormorant',       reward = 120,  category = 'Bird',       legendary = false },
    [723190474]   = { name = 'canada_goose',                   reward = 100,  category = 'Bird',       legendary = false },
    [-2145890973] = { name = 'ferruginous_hawk',               reward = 150,  category = 'Bird',       legendary = false },
    [1095117488]  = { name = 'great_blue_heron',               reward = 120,  category = 'Bird',       legendary = false },
    [386506078]   = { name = 'common_loon',                    reward = 120,  category = 'Bird',       legendary = false },
    [-861544272]  = { name = 'great_horned_owl',               reward = 150,  category = 'Bird',       legendary = false },
    [-564099192]  = { name = 'whooping_crane',                 reward = 120,  category = 'Bird',       legendary = false },

    -- ===== REPTILES =====
    [-407730502]  = { name = 'snapping_turtle',                reward = 120,  category = 'Reptile',    legendary = false },
    [-229688157]  = { name = 'water_snake',                    reward = 80,   category = 'Reptile',    legendary = false },
    [1464167925]  = { name = 'snake_fer_de_lance',             reward = 150,  category = 'Reptile',    legendary = false },
    [846659001]   = { name = 'black_tailed_rattlesnake',       reward = 120,  category = 'Reptile',    legendary = false },
    [545068538]   = { name = 'western_rattlesnake',            reward = 120,  category = 'Reptile',    legendary = false },
    [457416415]   = { name = 'gila_monster',                   reward = 150,  category = 'Reptile',    legendary = false },
    [-1854059305] = { name = 'green_iguana',                   reward = 150,  category = 'Reptile',    legendary = false },
    [-593056309]  = { name = 'desert_iguana',                  reward = 150,  category = 'Reptile',    legendary = false },
    [-2004866590] = { name = 'large_alligator',                reward = 400,  category = 'Reptile',    legendary = false },
    [-1295720802] = { name = 'alligator',                      reward = 350,  category = 'Reptile',    legendary = false },
    [-1892280447] = { name = 'alligator_swamp',                reward = 350,  category = 'Reptile',    legendary = false },
    [3360517226]  = { name = 'alligator_giant',                reward = 350,  category = 'Reptile',    legendary = false },
    [825523615]   = { name = 'alligator_pelt',                 reward = 300,  category = 'Reptile',    legendary = false },

    -- ===== UNGULATES =====
    -- FIXME: this key (-15687816381) is outside the signed 32-bit range GetEntityModel() returns (11 digits, max is ~10), so it can never match a real bighorn ped -- this entry is currently dead. Looks like a typo (one digit too many) in the original script; not guessing a replacement since it can't be verified from here. Get the real hash (e.g. print(GetEntityModel(ped)) while aiming at a bighorn in-game) and fix the key below.
    [-15687816381] = { name = 'bighorn',                        reward = 300,  category = 'Ungulate',   legendary = false }, -- BROKEN KEY, see FIXME above
    [-1963605336] = { name = 'buck',                           reward = 250,  category = 'Ungulate',   legendary = false },
    [1556473961]  = { name = 'bison',                          reward = 1200, category = 'Ungulate',   legendary = false },
    [195700131]   = { name = 'bull',                           reward = 150,  category = 'Ungulate',   legendary = false },
    [1110710183]  = { name = 'deer',                           reward = 200,  category = 'Ungulate',   legendary = false },
    [-2021043433] = { name = 'elk',                            reward = 300,  category = 'Ungulate',   legendary = false },
    [1755643085]  = { name = 'pronghorn_doe',                  reward = 200,  category = 'Ungulate',   legendary = false },
    [-1098441944] = { name = 'moose',                          reward = 400,  category = 'Ungulate',   legendary = false },
    [556355544]   = { name = 'angus_ox',                       reward = 300,  category = 'Ungulate',   legendary = false },
    [-50684386]   = { name = 'florida_cracker_cow',            reward = 300,  category = 'Ungulate',   legendary = false },
    [40345436]    = { name = 'merino_sheep',                   reward = 200,  category = 'Ungulate',   legendary = false },
    [-753902995]  = { name = 'alpine_goat',                    reward = 200,  category = 'Ungulate',   legendary = false },
    [1007418994]  = { name = 'berkshire_pig',                  reward = 200,  category = 'Ungulate',   legendary = false },
    [1751700893]  = { name = 'peccary_pig',                    reward = 200,  category = 'Ungulate',   legendary = false },

    -- ===== SMALL GAME =====
    [252669332]   = { name = 'american_red_fox',               reward = 180,  category = 'Small Game', legendary = false },
    [1458540991]  = { name = 'north_american_raccoon',         reward = 100,  category = 'Small Game', legendary = false },
    [-541762431]  = { name = 'black_tailed_jackrabbit',        reward = 80,   category = 'Small Game', legendary = false },
    [-1414989025] = { name = 'virginia_opossum',               reward = 90,   category = 'Small Game', legendary = false },
    [-1134449699] = { name = 'american_muskrat',               reward = 100,  category = 'Small Game', legendary = false },
    [759906147]   = { name = 'north_american_beaver',          reward = 150,  category = 'Small Game', legendary = false },
    [-1149999295] = { name = 'legendary_moon_beaver',          reward = 500,  category = 'Small Game', legendary = true  },
    [-1211566332] = { name = 'striped_skunk',                  reward = 90,   category = 'Small Game', legendary = false },
    [2028722809]  = { name = 'boar',                           reward = 200,  category = 'Small Game', legendary = false },
}

--------------------------------------------------------------------------------------------
-- Helper: send an ox_lib notify to a player
--------------------------------------------------------------------------------------------
local templateToType = {
    ERROR         = 'error',
    INFO          = 'inform',
    SUCCESS       = 'success',
    TIP_CASH      = 'success',
    REWARD_MONEY  = 'success',
}

local function Notify(src, options, template)
    options.type = options.type or templateToType[template] or 'inform'
    TriggerClientEvent('ox_lib:notify', src, options)
end

--------------------------------------------------------------------------------------------
-- RSG_ServerSampleHandler
-- Called by server/tagging.lua for every sampling event.
--
-- SECURITY NOTES:
-- The client picks *when* to fire this event and *which* animal hash to send — RedM gives us
-- no reliable server-side way to verify the player was actually next to a sedated animal, so
-- this event can be spammed with any hash by a modified client. What we CAN and DO close here:
--   1. A per-citizenid in-flight lock, so two overlapping calls for the same player can never
--      both pass the "have they collected this already" check before either one is written to
--      the DB (previously: SELECT-then-async-INSERT, which raced and paid out duplicate/
--      first-discovery/milestone rewards if the same event was fired twice within ~one DB
--      round trip).
--   2. An atomic `INSERT IGNORE`, so the duplicate check and the insert can't be TOCTOU'd even
--      without the lock (defense in depth).
--   3. A server-side cooldown (Config.SampleCooldown), so a single player can't hammer this
--      event faster than a legitimate hold-to-sample ever could.
--------------------------------------------------------------------------------------------
local processingPlayers = {}
local lastSampleAt      = {}

function RSG_ServerSampleHandler(src, sampleHash)
    local player = RSGCore.Functions.GetPlayer(src)
    if not player then
        if Config.DebugServer then print('[rsg-samples] RSG_ServerSampleHandler: player not found for src', src) end
        return { success = false, message = 'Player not found' }
    end

    sampleHash = tonumber(sampleHash)
    local citizenid = player.PlayerData.citizenid

    -- Cooldown — reject anything faster than a real sample could ever complete
    local now = GetGameTimer()
    if lastSampleAt[citizenid] and (now - lastSampleAt[citizenid]) < Config.SampleCooldown then
        if Config.DebugServer then print('[rsg-samples] Cooldown block for', citizenid) end
        return { success = false, message = 'cooldown' }
    end

    -- In-flight lock — prevents two concurrent calls for the same player from both slipping
    -- past the duplicate check before either write lands
    if processingPlayers[citizenid] then
        if Config.DebugServer then print('[rsg-samples] Concurrent sample rejected for', citizenid) end
        return { success = false, message = 'busy' }
    end
    processingPlayers[citizenid] = true
    lastSampleAt[citizenid]      = now

    local ok, result = pcall(function()
        local animalData = hashToAnimalMap[sampleHash] or { name = 'unknown_animal', reward = 100, category = 'Exotic', legendary = false }
        local animalName = animalData.name
        local reward      = animalData.reward

        -- Apply featured animal multiplier
        local isFeatured = (animalName == featuredAnimal and featuredAnimal ~= '')
        if isFeatured then
            reward = reward * Config.FeaturedMultiplier
        end

        if Config.StoreSampleData then
            -- Atomic dedupe: INSERT IGNORE relies on the UNIQUE KEY(citizenid, sample_id) to
            -- reject a repeat in the same statement that records it — no separate SELECT that
            -- something else can race against.
            local insertId = MySQL.insert.await(
                'INSERT IGNORE INTO player_samples (citizenid, sample_id) VALUES (?, ?)',
                { citizenid, animalName }
            )
            if not insertId or insertId == 0 then
                Notify(src, { description = locale('already_collected') }, 'ERROR')
                if Config.DebugServer then print('[rsg-samples] Already collected:', animalName, 'for', citizenid) end
                return { success = false, message = 'already_collected' }
            end

            -- First discovery check — runs AFTER our own insert is committed, so a count of 1
            -- reliably means we were first even if another player's discovery of a different
            -- animal happens at the same moment.
            local firstDiscoveryCount = MySQL.scalar.await(
                'SELECT COUNT(*) FROM player_samples WHERE sample_id = ?',
                { animalName }
            )
            if firstDiscoveryCount == 1 and Config.FirstDiscoveryBonus > 0 then
                player.Functions.AddMoney('cash', Config.FirstDiscoveryBonus)
                Notify(src, {
                    title       = locale('ui_title'),
                    description = string.format(locale('first_discovery'), animalName, Config.FirstDiscoveryBonus),
                    icon        = 'star',
                    duration    = 7000,
                }, 'REWARD_MONEY')
                if Config.DebugServer then print('[rsg-samples] First discovery bonus awarded for:', animalName) end
            end

            -- Milestone reward check
            local totalCount = MySQL.scalar.await(
                'SELECT COUNT(*) FROM player_samples WHERE citizenid = ?',
                { citizenid }
            )
            local milestone = Config.MilestoneRewards[totalCount]
            if milestone then
                player.Functions.AddMoney('cash', milestone.bonus)
                Notify(src, {
                    description = string.format(locale('milestone_reached'), milestone.label, milestone.bonus),
                    icon        = 'awards_set_a_009',
                    duration    = 7000,
                }, 'REWARD_MONEY')
                if Config.DebugServer then print('[rsg-samples] Milestone reached:', milestone.label, 'for', citizenid) end
            end
        end

        -- Award base (or multiplied) cash
        player.Functions.AddMoney('cash', reward)

        if isFeatured then
            Notify(src, {
                description = string.format(locale('sample_featured'), animalName, reward, Config.FeaturedMultiplier),
                icon        = 'toast_mp_animal',
                duration    = 6000,
            }, 'REWARD_MONEY')
        else
            Notify(src, {
                description = string.format(locale('sample_collected'), animalName, reward),
                icon        = 'toast_mp_animal',
            }, 'TIP_CASH')
        end

        if Config.DebugServer then
            print('[rsg-samples] Sampled:', animalName, 'src:', src, 'reward: $' .. reward,
                  isFeatured and '(FEATURED x' .. Config.FeaturedMultiplier .. ')' or '')
        end

        return { success = true, animal = animalName, reward = reward }
    end)

    processingPlayers[citizenid] = nil

    if not ok then
        if Config.DebugServer then print('[rsg-samples] ERROR in RSG_ServerSampleHandler:', result) end
        return { success = false, message = 'error' }
    end

    return result
end

--------------------------------------------------------------------------------------------
-- Build (and cache) the locale table sent to the NUI
-- Locales are static at runtime, so this only actually gets built once per resource start
-- instead of on every /samplesmenu, /samplecert, and leaderboard interaction.
--------------------------------------------------------------------------------------------
local cachedLang = nil

local function RSG_BuildLang()
    if cachedLang then return cachedLang end

    local keys = {
        'ui_title','ui_subtitle','ui_tab_samples','ui_tab_leaderboard','ui_tab_stats','ui_close',
        'ui_field_guide','ui_search_guide','ui_find_collector',
        'ui_progress_label','ui_total_rewards','ui_search_samples','ui_load_more',
        'ui_no_samples','ui_reward','ui_collected_on','ui_legendary','ui_featured',
        'cat_all','cat_predator','cat_bird','cat_reptile','cat_ungulate','cat_small_game','cat_exotic',
        'ui_top_collectors','ui_search_collectors','ui_no_collectors','ui_samples_count','ui_rank_prefix',
        'ui_global_stats','ui_total_all','ui_rarest_animal','ui_rarest_sub',
        'ui_weekly_top','ui_weekly_sub','ui_no_weekly','ui_no_stats',
        'ui_featured_now','ui_featured_mult','ui_no_featured',
        'cert_title','cert_subtitle','cert_back','cert_issued_to','cert_completion','cert_total_rewards',
        'cert_legendary_count','cert_featured_animal','cert_issued_date',
        'cert_close','cert_signed','cert_footer',
    }
    local t = {}
    for _, k in ipairs(keys) do
        t[k] = locale(k)
    end
    cachedLang = t
    return t
end

--------------------------------------------------------------------------------------------
-- Fetch global stats for the Stats tab
--------------------------------------------------------------------------------------------
local function RSG_FetchGlobalStats()
    local totalRow = MySQL.scalar.await('SELECT COUNT(*) FROM player_samples')

    local rarestRow = MySQL.query.await([[
        SELECT sample_id, COUNT(DISTINCT citizenid) AS collectors
        FROM player_samples
        GROUP BY sample_id
        ORDER BY collectors ASC
        LIMIT 1
    ]])

    local weeklyRow = MySQL.query.await([[
        SELECT p.name, COUNT(ps.sample_id) AS cnt
        FROM player_samples ps
        JOIN players p ON ps.citizenid = p.citizenid
        WHERE ps.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
        GROUP BY p.citizenid, p.name
        ORDER BY cnt DESC
        LIMIT 1
    ]])

    return {
        totalCollected  = totalRow or 0,
        rarestAnimal    = rarestRow and rarestRow[1] and rarestRow[1].sample_id or nil,
        rarestCount     = rarestRow and rarestRow[1] and rarestRow[1].collectors or 0,
        weeklyTopName   = weeklyRow and weeklyRow[1] and weeklyRow[1].name or nil,
        weeklyTopCount  = weeklyRow and weeklyRow[1] and weeklyRow[1].cnt or 0,
        featuredAnimal  = featuredAnimal,
        featuredMult    = Config.FeaturedMultiplier,
    }
end

--------------------------------------------------------------------------------------------
-- Build and send all menu data to a player
-- viewMode: 'menu' (default) | 'certificate'
--------------------------------------------------------------------------------------------
local function RSG_SendSamplesMenu(source, viewMode)
    local player = RSGCore.Functions.GetPlayer(source)
    if not player then return end

    local citizenid  = player.PlayerData.citizenid
    local charinfo   = player.PlayerData.charinfo
    local playerName = (charinfo and (charinfo.firstname .. ' ' .. charinfo.lastname))
                       or player.PlayerData.name
                       or 'Unknown'

    -- Player's collected samples
    local playerSamples  = MySQL.query.await(
        'SELECT sample_id, created_at FROM player_samples WHERE citizenid = ?',
        { citizenid }
    )
    local collectedSamples = {}
    for _, row in ipairs(playerSamples) do
        collectedSamples[row.sample_id] = { collected = true, created_at = row.created_at }
    end

    -- Top 10 leaderboard
    local topCollectors = MySQL.query.await([[
        SELECT p.citizenid, p.name, COUNT(ps.sample_id) AS sample_count
        FROM player_samples ps
        JOIN players p ON ps.citizenid = p.citizenid
        GROUP BY p.citizenid, p.name
        ORDER BY sample_count DESC
        LIMIT 10
    ]])
    local rankedCollectors = {}
    for i, row in ipairs(topCollectors) do
        table.insert(rankedCollectors, {
            rank         = i,
            citizenid    = row.citizenid,
            name         = row.name,
            sample_count = row.sample_count,
        })
    end

    TriggerClientEvent('rsg-samples:openSamplesMenu', source, {
        viewMode         = viewMode or 'menu',
        allSamples       = hashToAnimalMap,
        collectedSamples = collectedSamples,
        topCollectors    = rankedCollectors,
        globalStats      = RSG_FetchGlobalStats(),
        currentCitizenId = citizenid,
        playerName       = playerName,
        featuredAnimal   = featuredAnimal,
        featuredMultiplier = Config.FeaturedMultiplier,
        lang             = RSG_BuildLang(),
    })

    if Config.DebugServer then
        print('[rsg-samples] RSG_SendSamplesMenu → src:', source, 'mode:', viewMode or 'menu')
    end
end

--------------------------------------------------------------------------------------------
-- Command: /samplesmenu — open the full collector UI
--------------------------------------------------------------------------------------------
RSGCore.Commands.Add('samplesmenu', locale('cmd_samplesmenu'), {}, false, function(source)
    RSG_SendSamplesMenu(source, 'menu')
end)

--------------------------------------------------------------------------------------------
-- Command: /samplecert — open just the certificate overlay
--------------------------------------------------------------------------------------------
RSGCore.Commands.Add('samplecert', locale('cmd_samplecert'), {}, false, function(source)
    RSG_SendSamplesMenu(source, 'certificate')
end)

--------------------------------------------------------------------------------------------
-- Command: /setfeatured [animal_name] — admin only
-- Requires:  add_ace group.admin rsg-samples.admin allow  in server.cfg
-- Usage:     /setfeatured bear     sets featured animal to 'bear'
--            /setfeatured          clears the featured animal
--------------------------------------------------------------------------------------------
RSGCore.Commands.Add('setfeatured', locale('cmd_setfeatured'), {
    { name = 'animal', help = 'Animal name (leave blank to clear)' }
}, false, function(source, args)
    if not IsPlayerAceAllowed(tostring(source), 'rsg-samples.admin') then
        Notify(source, { description = locale('no_permission') }, 'ERROR')
        return
    end

    local newAnimal = args[1] and args[1]:lower() or ''
    featuredAnimal  = newAnimal

    if newAnimal ~= '' then
        Notify(source, {
            description = string.format(locale('featured_set'), newAnimal),
            icon        = 'star',
        }, 'SUCCESS')
    else
        Notify(source, { description = locale('featured_cleared') }, 'INFO')
    end

    if Config.DebugServer then
        print('[rsg-samples] featuredAnimal set to:', featuredAnimal, 'by src:', source)
    end
end)

--------------------------------------------------------------------------------------------
-- Event: rsg-samples:requestLeaderboard (triggered by ox_target zone in client/target.lua)
--------------------------------------------------------------------------------------------
RegisterNetEvent('rsg-samples:requestLeaderboard')
AddEventHandler('rsg-samples:requestLeaderboard', function()
    local src = source
    RSG_SendSamplesMenu(src, 'menu')
    if Config.DebugServer then
        print('[rsg-samples] requestLeaderboard from src:', src)
    end
end)

--------------------------------------------------------------------------------------------
-- Event: rsg-samples:closeUI (optional server-side hook)
--------------------------------------------------------------------------------------------
RegisterNetEvent('rsg-samples:closeUI')
AddEventHandler('rsg-samples:closeUI', function()
    if Config.DebugServer then
        print('[rsg-samples] closeUI from src:', source)
    end
end)