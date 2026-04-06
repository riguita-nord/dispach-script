ClientFrameworkBridge = ClientFrameworkBridge or {}

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

local function getPlayerJobName()
    if detectedFramework == "qbcore" then
        local qb = safeGetQBCore()
        if not qb then return nil end

        local playerData = qb.Functions.GetPlayerData()
        if not playerData or not playerData.job then
            return nil
        end

        return playerData.job.name
    end

    if detectedFramework == "esx" then
        local esx = safeGetESX()
        if not esx then return nil end

        if esx.PlayerData and esx.PlayerData.job and esx.PlayerData.job.name then
            return esx.PlayerData.job.name
        end

        local data = esx.GetPlayerData and esx.GetPlayerData() or nil
        if data and data.job then
            return data.job.name
        end

        return nil
    end

    return nil
end

ClientFrameworkBridge.Name = detectedFramework
ClientFrameworkBridge.GetPlayerJobName = getPlayerJobName

CreateThread(function()
    detectedFramework = detectFramework()
    ClientFrameworkBridge.Name = detectedFramework

    if detectedFramework == "qbcore" then
        safeGetQBCore()
    elseif detectedFramework == "esx" then
        safeGetESX()
    end
end)
