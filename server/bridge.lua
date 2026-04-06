FrameworkBridge = FrameworkBridge or {}

local selectedFramework = string.lower(tostring((Config and Config.Framework) or "auto"))
local detectedFramework = "standalone"

local qbCoreObject = nil
local esxObject = nil

local function detectFramework()
    if selectedFramework ~= "auto" then
        if selectedFramework == "qbcore" or selectedFramework == "qb" then
            return "qbcore"
        end
        if selectedFramework == "esx" then
            return "esx"
        end
        return "standalone"
    end

    if GetResourceState("qb-core") == "started" then
        return "qbcore"
    end

    if GetResourceState("es_extended") == "started" then
        return "esx"
    end

    return "standalone"
end

local function safeGetQBCore()
    if qbCoreObject then
        return qbCoreObject
    end

    local ok, obj = pcall(function()
        return exports["qb-core"]:GetCoreObject()
    end)

    if ok and obj then
        qbCoreObject = obj
        return qbCoreObject
    end

    return nil
end

local function safeGetESX()
    if esxObject then
        return esxObject
    end

    if type(exports["es_extended"]) == "table" and exports["es_extended"].getSharedObject then
        local ok, obj = pcall(function()
            return exports["es_extended"]:getSharedObject()
        end)
        if ok and obj then
            esxObject = obj
            return esxObject
        end
    end

    if ESX then
        esxObject = ESX
        return esxObject
    end

    return nil
end

local function getPlayerJobName(source)
    if detectedFramework == "qbcore" then
        local qb = safeGetQBCore()
        if not qb then return nil end

        local player = qb.Functions.GetPlayer(source)
        if not player or not player.PlayerData or not player.PlayerData.job then
            return nil
        end

        return player.PlayerData.job.name
    end

    if detectedFramework == "esx" then
        local esx = safeGetESX()
        if not esx then return nil end

        local player = esx.GetPlayerFromId(source)
        if not player then return nil end

        if player.job and player.job.name then
            return player.job.name
        end

        if player.getJob then
            local job = player.getJob()
            return job and job.name or nil
        end

        return nil
    end

    return nil
end

local function getPlayersByAllowedJobs(allowedJobs)
    local recipients = {}
    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        if src then
            local jobName = getPlayerJobName(src)
            if jobName and allowedJobs[jobName] then
                recipients[#recipients + 1] = src
            end
        end
    end
    return recipients
end

FrameworkBridge.Name = detectedFramework
FrameworkBridge.GetPlayerJobName = getPlayerJobName
FrameworkBridge.GetPlayersByAllowedJobs = getPlayersByAllowedJobs

CreateThread(function()
    detectedFramework = detectFramework()
    FrameworkBridge.Name = detectedFramework

    if detectedFramework == "qbcore" then
        safeGetQBCore()
    elseif detectedFramework == "esx" then
        safeGetESX()
    end

    print(("^2[nord_dispach]^0 Framework bridge ativo: %s"):format(detectedFramework))
end)
