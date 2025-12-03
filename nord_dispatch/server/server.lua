local QBCore = exports['qb-core']:GetCoreObject()

------------------------------------------------------
-- FUNÇÃO DE DEBUG + LOG AO MESMO TEMPO
------------------------------------------------------
local function DispatchDebug(msg)
    if not Config.Dispatch_Logs_Enabled then return end
    print("^3[DISPATCH DEBUG]^0 " .. tostring(msg))
end

------------------------------------------------------
-- FUNÇÃO DE LOGS DO DISPATCH (RESPEITA A CONFIG)
------------------------------------------------------
local function SaveDispatchLog(incidentId, action, data)
    if not Config.Dispatch_Logs_Enabled then
        return -- Logs desligados → debug e BD OFF
    end

    DispatchDebug("Guardar log → " .. tostring(action))

    if not incidentId then
        DispatchDebug("ERRO: incidentId é nil!")
        return
    end

    local tableLogs = tostring(Config.DispatchLogsTable or "noctavia_mdt_dispatch_logs")

    exports.oxmysql:insert(
        ("INSERT INTO `%s` (incident_id, action, data, ts_created) VALUES (?, ?, ?, NOW())"):format(tableLogs),
        {
            incidentId,
            action,
            json.encode(data or {})
        }
    )
end

---------------------------------------------------------------------
-- FUNÇÃO: Converte "6h", "30m", "45s" → segundos
---------------------------------------------------------------------
local function ConvertRetention(str)
    if not str then return 6 * 3600 end

    local value, unit = str:match("(%d+)(%a)")
    value = tonumber(value)
    if not value then return 6 * 3600 end

    if unit == "s" then return value end
    if unit == "m" then return value * 60 end
    if unit == "h" then return value * 3600 end
    if unit == "d" then return value * 86400 end

    return 6 * 3600
end

---------------------------------------------------------------------
-- TABELA DO DISPATCH
---------------------------------------------------------------------
local tableDispatch = tostring(Config.DispatchTable or "noctavia_mdt_dispatch")
local allowedJobs    = Config.AllowedJobs or {}

---------------------------------------------------------------------
-- GERAR INCIDENT ID
---------------------------------------------------------------------
local function GenerateIncidentId()
    return math.random(111111, 999999)
end

---------------------------------------------------------------------
-- GUARDAR ALERTA → SÓ SE MDT ESTIVER ON
---------------------------------------------------------------------
local function SaveDispatchAlert(incidentId, alert)
    if not Config.Dispatch_MDT_Enabled then
        DispatchDebug("[MDT] OFF — alerta NÃO gravado na BD.")
        return
    end

    if not incidentId then 
        DispatchDebug("ERRO: incidentId é nil!")
        return 
    end

    alert = alert or {}

    local code     = alert.code     or "N/D"
    local title    = alert.title    or "Ocorrência"
    local street   = alert.street   or "Desconhecido"
    local coords   = json.encode(alert.coords or {})
    local info     = json.encode(alert.info   or {})
    local priority = alert.priority or 3

    exports.oxmysql:insert(
        ("INSERT INTO `%s` (dispatch_id, code, title, street, priority, coords, info, ts_created) VALUES (?, ?, ?, ?, ?, ?, ?, NOW())")
            :format(tableDispatch),
        { incidentId, code, title, street, priority, coords, info }
    )

    DispatchDebug("Alerta gravado na BD → " .. title)
end

---------------------------------------------------------------------
-- ENVIAR ALERTA PARA AS UNIDADES
---------------------------------------------------------------------
local function BroadcastDispatchToUnits(id, alertType, street, coords, info)
    for _, ply in pairs(QBCore.Functions.GetQBPlayers()) do
        local job = ply.PlayerData.job.name
        if allowedJobs[job] then
            TriggerClientEvent("myDispatch:ReceiveAlert", ply.PlayerData.source, {
                id     = id,
                type   = alertType,
                street = street,
                coords = coords,
                info   = info or {}
            })
        end
    end

    DispatchDebug("Alerta enviado para unidades → " .. alertType)
end

---------------------------------------------------------------------
-- ALERTA MANUAL
---------------------------------------------------------------------
RegisterNetEvent("myDispatch:SendAlert", function(alertType, extra)
    local src  = source
    local ped  = GetPlayerPed(src)
    if not ped then return end

    local cfg = Config.Alerts[alertType]
    if not cfg then return end

    local coords = GetEntityCoords(ped)
    local street = (extra and extra.street) or "Localização Desconhecida"
    local id     = GenerateIncidentId()

    local alert = {
        type   = alertType,
        code   = cfg.code,
        title  = cfg.title,
        street = street,
        coords = coords,
        info   = extra or {}
    }

    SaveDispatchAlert(id, alert)
    SaveDispatchLog(id, "manual_alert", alert)
    BroadcastDispatchToUnits(id, alertType, street, coords, alert.info)
end)

---------------------------------------------------------------------
-- ALERTAS AUTOMÁTICOS
---------------------------------------------------------------------
local function HandleAutoAlert(alertName, data)
    if not data or not data.coords then return end

    local cfg = Config.Alerts[alertName]
    if not cfg then return end

    local id = GenerateIncidentId()

    local alertData = {
        type     = alertName,
        code     = cfg.code,
        title    = cfg.title,
        street   = data.street or "Localização Desconhecida",
        coords   = data.coords,
        priority = cfg.priority or 2,
        info     = data.info or {}
    }

    SaveDispatchAlert(id, alertData)
    SaveDispatchLog(id, "auto_alert", alertData)
    BroadcastDispatchToUnits(id, alertName, alertData.street, data.coords, alertData.info)
end

RegisterNetEvent("myDispatch:CarTheftAlert",         function(data) HandleAutoAlert("car_theft",         data) end)
RegisterNetEvent("myDispatch:ShotsFiredAuto",        function(data) HandleAutoAlert("shots_fired",       data) end)
RegisterNetEvent("myDispatch:PhysicalViolenceAlert", function(data) HandleAutoAlert("physical_violence", data) end)
RegisterNetEvent("myDispatch:CarAccidentAlert",      function(data) HandleAutoAlert("car_accident",      data) end)
RegisterNetEvent("myDispatch:ArmedRobberyAlert",     function(data) HandleAutoAlert("armed_robbery",     data) end)

---------------------------------------------------------------------
-- ALERTA → PLAYER DOWN / OFFICER DOWN / MEDIC DOWN
---------------------------------------------------------------------
RegisterNetEvent("myDispatch:PlayerDeathAlert", function(data)
    if not data or not data.coords then return end

    local job = tostring(data.job or "unemployed")
    local alertType = "player_dead"

    if job == "police" or job == "sheriff" then
        alertType = "officer_down"
    elseif job == "ambulance" or job == "ems" then
        alertType = "medic_down"
    end

    local cfg = Config.Alerts[alertType]
    if not cfg then return end

    local id = GenerateIncidentId()

    local alertData = {
        type     = alertType,
        code     = cfg.code,
        title    = cfg.title,
        street   = data.street or "Desconhecido",
        coords   = data.coords,
        priority = cfg.priority or 1,
        info     = {
            job    = job,
            cause  = data.cause or "Desconhecida",
            victim = data.victim
        }
    }

    SaveDispatchAlert(id, alertData)
    SaveDispatchLog(id, "player_down", alertData)
    BroadcastDispatchToUnits(id, alertType, alertData.street, alertData.coords, alertData.info)
end)

---------------------------------------------------------------------
-- UNIDADE A CAMINHO / ACEITA INCIDENTE
---------------------------------------------------------------------
RegisterNetEvent("myDispatch:UnitResponding", function(id)
    local src = source
    local coords = GetEntityCoords(GetPlayerPed(src))

    TriggerClientEvent("myDispatch:UnitGoingToIncident", -1, id, coords)

    SaveDispatchLog(id, "unit_responding", {
        unit   = GetPlayerName(src),
        coords = coords
    })
end)

RegisterNetEvent("myDispatch:UnitAccept", function(id)
    local src = source
    local coords = GetEntityCoords(GetPlayerPed(src))

    TriggerClientEvent("myDispatch:UnitGoingToIncident", -1, id, coords)

    SaveDispatchLog(id, "unit_accepted", {
        unit   = GetPlayerName(src),
        coords = coords
    })
end)

---------------------------------------------------------------------
-- MDT → LISTA DE DISPATCHES
---------------------------------------------------------------------
lib.callback.register("MDT:GetDispatchHistory", function()
    if not Config.Dispatch_MDT_Enabled then
        DispatchDebug("MDT OFF — histórico não carregado.")
        return {}
    end

    return exports.oxmysql:executeSync(
        ("SELECT * FROM `%s` ORDER BY ts_created DESC LIMIT 200"):format(tableDispatch)
    ) or {}
end)

---------------------------------------------------------------------
-- LIMPEZA AUTOMÁTICA
---------------------------------------------------------------------
CreateThread(function()

    if not Config.Dispatch_MDT_Enabled then
        DispatchDebug("MDT OFF — limpeza automática DESATIVADA.")
        return
    end

    local retentionSec = ConvertRetention(Config.DispatchRetention)
    local retentionMs  = retentionSec * 1000

    DispatchDebug("Limpeza automática ativa (" .. retentionSec .. " segundos)")

    while true do
        Wait(retentionMs)

        exports.oxmysql:execute(
            ("DELETE FROM `%s` WHERE ts_created <= (NOW() - INTERVAL %d SECOND)")
                :format(tableDispatch, retentionSec),
            {},
            function(affected)
                DispatchDebug("Removidos " .. tostring(affected or 0) .. " despachos")
                SaveDispatchLog(0, "auto_cleanup", { removed = affected or 0 })
            end
        )
    end
end)
