local resourceName = GetCurrentResourceName()
local currentVersion = GetResourceMetadata(resourceName, "version", 0) or "0.0.0"
local missingEndpointWarned = false

local function logInfo(msg)
    print(("^5[%s][Update]^0 %s"):format(resourceName, msg))
end

local function logWarn(msg)
    print(("^3[%s][Update]^0 %s"):format(resourceName, msg))
end

local function trim(str)
    return (tostring(str or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function normalizeVersion(ver)
    local clean = trim(ver):lower():gsub("^v", "")
    return clean
end

local function parseVersionParts(ver)
    local parts = {}
    local clean = normalizeVersion(ver)

    for chunk in clean:gmatch("[^%.]+") do
        local n = tonumber(chunk:match("%d+")) or 0
        parts[#parts + 1] = n
    end

    while #parts < 3 do
        parts[#parts + 1] = 0
    end

    return parts
end

local function isLatestVersionNewer(current, latest)
    local a = parseVersionParts(current)
    local b = parseVersionParts(latest)

    local maxLen = math.max(#a, #b)
    for i = 1, maxLen do
        local av = a[i] or 0
        local bv = b[i] or 0

        if bv > av then return true end
        if bv < av then return false end
    end

    return false
end

local function decodeJsonSafe(str)
    local ok, decoded = pcall(function()
        return json.decode(str)
    end)

    if ok then
        return decoded
    end

    return nil
end

local function extractVersionFromBody(body)
    if not body or body == "" then
        return nil, nil
    end

    local decoded = decodeJsonSafe(body)
    if type(decoded) == "table" then
        local latest = decoded.version or decoded.latest or decoded.tag_name
        local changelog = decoded.changelog or decoded.url or decoded.html_url
        if latest then
            return tostring(latest), changelog and tostring(changelog) or nil
        end
    end

    local jsonVersion = body:match('"version"%s*:%s*"([^"]+)"')
    if jsonVersion then
        return jsonVersion, nil
    end

    local plain = trim((body:match("([^\r\n]+)") or ""))
    if plain:match("^v?%d+%.%d+%.?%d*") then
        return plain, nil
    end

    return nil, nil
end

local function performUpdateCheck(showNoUpdate)
    local updates = Config and Config.Updates or {}
    if updates.Enabled == false then
        return
    end

    local endpoint = trim(updates.VersionEndpoint or "")
    if endpoint == "" then
        if not missingEndpointWarned then
            missingEndpointWarned = true
            logWarn("VersionEndpoint não definido. Sistema de updates ativo, mas sem URL para verificar versão.")
        end
        return
    end

    PerformHttpRequest(endpoint, function(statusCode, body)
        if statusCode ~= 200 then
            logWarn(("Falha a verificar updates (HTTP %s)"):format(tostring(statusCode)))
            return
        end

        local latestVersion, changelogUrl = extractVersionFromBody(body)
        if not latestVersion then
            logWarn("Resposta de update inválida. Esperado JSON com 'version' ou texto simples com versão.")
            return
        end

        local current = normalizeVersion(currentVersion)
        local latest = normalizeVersion(latestVersion)

        if isLatestVersionNewer(current, latest) then
            logWarn(("Nova versão disponível: %s (instalada: %s)"):format(latest, current))
            if changelogUrl and changelogUrl ~= "" then
                logInfo(("Changelog/Download: %s"):format(changelogUrl))
            end
        elseif showNoUpdate then
            logInfo(("Já estás na versão mais recente: %s"):format(current))
        end
    end, "GET", "", {
        ["User-Agent"] = resourceName .. "-update-checker"
    })
end

RegisterCommand((Config.Updates and Config.Updates.CommandName) or "dispatch_update", function(src)
    if src ~= 0 then
        TriggerClientEvent("chat:addMessage", src, {
            args = { "nord_dispach", "Comando apenas disponível na consola do servidor." }
        })
        return
    end

    performUpdateCheck(true)
end, true)

exports("CheckForUpdates", function(showNoUpdate)
    performUpdateCheck(showNoUpdate == true)
end)

CreateThread(function()
    local updates = Config and Config.Updates or {}
    if updates.Enabled == false then
        return
    end

    if updates.CheckOnStart ~= false then
        Wait(2000)
        performUpdateCheck(false)
    end

    local intervalMinutes = tonumber(updates.CheckIntervalMinutes) or 180
    if intervalMinutes <= 0 then
        return
    end

    while true do
        Wait(intervalMinutes * 60 * 1000)
        performUpdateCheck(false)
    end
end)
