------------------------------------------------------
-- 0. VARIÁVEIS GLOBAIS
------------------------------------------------------
local activeAlerts = {}
local stealingCooldown = false
local activeAlertCoords = {}

local dispatchPopupActive = false
local lastDispatchCoords = nil
local dispatchPopupIncidentId = nil

local carTheftTrackingState = {
    active = false,
    incidentId = nil,
    expectedPlate = nil
}

------------------------------------------------------
-- 1. TRABALHOS PERMITIDOS (config.lua)
------------------------------------------------------
local function PlayerHasDispatchJob()
    local jobName = ClientFrameworkBridge.GetPlayerJobName()
    if not jobName then return false end
    return Config.AllowedJobs[jobName] == true
end

------------------------------------------------------
-- 2. MAPA DE TECLAS
------------------------------------------------------
local KeyMap = {
    ["E"] = 38, ["F"] = 23, ["G"] = 47, ["H"] = 74,
    ["Y"] = 246, ["X"] = 73, ["Z"] = 20,
    ["LEFTSHIFT"] = 21, ["LSHIFT"] = 21,
    ["LCONTROL"] = 36, ["LCTRL"] = 36,
    ["ENTER"] = 18, ["BACKSPACE"] = 177,
}

local dispatchKey = KeyMap[string.upper(Config.DispatchKey)] or 38


------------------------------------------------------
-- 3. FUNÇÃO: Nome da rua
------------------------------------------------------
local function GetCurrentStreet(coords)
    if not coords then return "Localização Desconhecida" end
    local h = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    return GetStreetNameFromHashKey(h) or "Localização Desconhecida"
end

local function NormalizePlate(plate)
    return tostring(plate or ""):gsub("%s+", ""):upper()
end


------------------------------------------------------
-- 4. RECEBER ALERTA (NUI + SOM + BLIP + TECLA)
------------------------------------------------------
RegisterNetEvent("nord_dispach:ReceiveAlert")
AddEventHandler("nord_dispach:ReceiveAlert", function(data)

    -- ✓ Segurança extra: cliente só vê se for trabalho permitido
    if not PlayerHasDispatchJob() then return end

    if not data or not data.type then return end

    local alert = Config.Alerts[data.type]
    if not alert then return end

    if not data.coords then
        print("[DISPATCH] ERRO: coords faltam no alerta.")
        return
    end

    dispatchPopupActive = true
    lastDispatchCoords = data.coords
    dispatchPopupIncidentId = data.id

    -- Enviar popup
    SendNUIMessage({
        action  = "openDispatch",
        icon    = alert.icon,
        title   = ("%s | %s"):format(alert.code, alert.title),
        desc    = data.street or "Localização Desconhecida",
        key     = Config.DispatchKey,
        id      = data.id,
        timeout = 5500
    })

    -- Som
    SendNUIMessage({
        action = "playSound",
        sound  = alert.sound or "noti_police_1"
    })

    -- Criar BLIP
    local blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
    SetBlipSprite(blip, alert.blip)
    SetBlipScale(blip, 1.35)
    SetBlipColour(blip, alert.color)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(alert.title)
    EndTextCommandSetBlipName(blip)

    PulseBlip(blip)

    activeAlerts[data.id] = blip
    activeAlertCoords[data.id] = data.coords

    -- remover após tempo
    SetTimeout((alert.timeout or 30) * 1000, function()
        if activeAlerts[data.id] then
            RemoveBlip(activeAlerts[data.id])
            activeAlerts[data.id] = nil
            activeAlertCoords[data.id] = nil

            if dispatchPopupIncidentId == data.id then
                dispatchPopupIncidentId = nil
            end
        end
    end)
end)

-- Compatibilidade legada
RegisterNetEvent("myDispatch:ReceiveAlert")
AddEventHandler("myDispatch:ReceiveAlert", function(data)
    TriggerEvent("nord_dispach:ReceiveAlert", data)
end)

RegisterNetEvent("nord_dispach:UpdateTrackedAlert")
AddEventHandler("nord_dispach:UpdateTrackedAlert", function(id, coords)
    if not id or not coords then return end

    local blip = activeAlerts[id]
    if not blip then return end

    SetBlipCoords(blip, coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
    activeAlertCoords[id] = coords

    if dispatchPopupIncidentId == id then
        lastDispatchCoords = coords
    end
end)

-- Compatibilidade legada
RegisterNetEvent("myDispatch:UpdateTrackedAlert")
AddEventHandler("myDispatch:UpdateTrackedAlert", function(id, coords)
    TriggerEvent("nord_dispach:UpdateTrackedAlert", id, coords)
end)

RegisterNetEvent("nord_dispach:StartCarTheftTracking")
AddEventHandler("nord_dispach:StartCarTheftTracking", function(incidentId, expectedPlate)
    if not incidentId then return end

    carTheftTrackingState.active = true
    carTheftTrackingState.incidentId = incidentId
    carTheftTrackingState.expectedPlate = NormalizePlate(expectedPlate)

    CreateThread(function()
        local startedAt = GetGameTimer()
        local lostTicks = 0

        while carTheftTrackingState.active and carTheftTrackingState.incidentId == incidentId do
            Wait(2000)

            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)

            if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
                local plateNow = NormalizePlate(GetVehicleNumberPlateText(veh))
                local expect = carTheftTrackingState.expectedPlate

                if expect == "" or plateNow == expect then
                    local coords = GetEntityCoords(veh)

                    TriggerServerEvent("nord_dispach:UpdateCarTheftTracker", incidentId, {
                        street = GetCurrentStreet(coords),
                        coords = coords
                    })

                    lostTicks = 0
                else
                    lostTicks = lostTicks + 1
                end
            else
                lostTicks = lostTicks + 1
            end

            if lostTicks >= 5 or (GetGameTimer() - startedAt) > 180000 then
                TriggerServerEvent("nord_dispach:StopCarTheftTracker", incidentId)
                break
            end
        end

        if carTheftTrackingState.incidentId == incidentId then
            carTheftTrackingState.active = false
            carTheftTrackingState.incidentId = nil
            carTheftTrackingState.expectedPlate = nil
        end
    end)
end)

-- Compatibilidade legada
RegisterNetEvent("myDispatch:StartCarTheftTracking")
AddEventHandler("myDispatch:StartCarTheftTracking", function(incidentId, expectedPlate)
    TriggerEvent("nord_dispach:StartCarTheftTracking", incidentId, expectedPlate)
end)


------------------------------------------------------
-- 5. DETEÇÃO DE ROUBO DE VEÍCULO
------------------------------------------------------
CreateThread(function()
    while true do
        Wait(250)

        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped) then goto continue end

        if IsPedTryingToEnterALockedVehicle(ped) and not stealingCooldown then
            
            stealingCooldown = true

            local veh = GetVehiclePedIsTryingToEnter(ped)

            if veh ~= 0 then
                local coords = GetEntityCoords(ped)

                TriggerServerEvent("nord_dispach:CarTheftAlert", {
                    plate  = GetVehicleNumberPlateText(veh),
                    model  = GetDisplayNameFromVehicleModel(GetEntityModel(veh)),
                    street = GetCurrentStreet(coords),
                    coords = coords
                })
            end

            SetTimeout(15000, function()
                stealingCooldown = false
            end)
        end

        ::continue::
    end
end)

------------------------------------------------------
-- 5.B — DETEÇÃO DE TIRO — PRIMEIRO DISPARO
------------------------------------------------------
local shootingCooldown = false
local wasShooting = false

CreateThread(function()
    while true do
        Wait(0)

        local ped = PlayerPedId()
        local isShooting = IsPedShooting(ped)

        -- 🔥 Ativa APENAS no PRIMEIRO tiro (transição de false → true)
        if isShooting and not wasShooting and not shootingCooldown then

            shootingCooldown = true

            local coords = GetEntityCoords(ped)
            local s1 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
            local street = GetStreetNameFromHashKey(s1)

            TriggerServerEvent("nord_dispach:ShotsFiredAuto", {
                street = street or "Localização Desconhecida",
                coords = coords
            })

            -- ⏱️ Cooldown para evitar spam
            SetTimeout(5000, function()
                shootingCooldown = false
            end)
        end

        wasShooting = isShooting
    end
end)

------------------------------------------------------
-- 9. ALERTA AUTOMÁTICO → PLAYER MORREU + CAUSA DA MORTE
------------------------------------------------------
local deathCooldown = false
local wasDead = false

CreateThread(function()
    while true do
        Wait(500)

        local ped = PlayerPedId()
        local isDead = IsEntityDead(ped)

        if isDead and not wasDead and not deathCooldown then

            deathCooldown = true

            -- Coord e Rua
            local coords = GetEntityCoords(ped)
            local s1 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
            local street = GetStreetNameFromHashKey(s1)

            -- Job do jogador
            local job = ClientFrameworkBridge.GetPlayerJobName() or "unemployed"

            ------------------------------------------------------
            -- CAUSA DA MORTE
            ------------------------------------------------------
            local causeHash = GetPedCauseOfDeath(ped)
            local cause = "Causa desconhecida"

            if IsWeaponValid(causeHash) then
                -- armas
                if IsMeleeWeapon(causeHash) then
                    cause = "Arma branca"
                else
                    cause = "Arma de fogo"
                end

            elseif WasPedHitByVehicle(ped) then
                cause = "Atropelamento / Veículo"

            elseif HasPedBeenDamagedByExplosion(ped) then
                cause = "Explosão"

            elseif HasEntityBeenDamagedByAnyPed(ped) then
                cause = "Agressão física"

            elseif HasEntityBeenDamagedByAnyVehicle(ped) then
                cause = "Atropelamento"

            -- 🔥 CORREÇÃO IMPORTANTE — DETETAR QUEDA / IMPACTO
            elseif IsPedRagdoll(ped) or HasEntityCollidedWithAnything(ped) then
                cause = "Queda / impacto"

            else
                cause = "Queda / impacto"
            end


            TriggerServerEvent("nord_dispach:PlayerDeathAlert", {
                street = street,
                coords = coords,
                job    = job,
                cause  = cause,
                victim = GetPlayerServerId(PlayerId())
            })

            SetTimeout(15000, function()
                deathCooldown = false
            end)
        end

        wasDead = isDead
    end
end)

------------------------------------------------------
-- ALERTA AUTOMÁTICO → VIOLÊNCIA FÍSICA
------------------------------------------------------
local violenceCooldown = false

CreateThread(function()
    while true do
        Wait(150)

        local ped = PlayerPedId()

        -- Está a atacar (soco)
        if IsPedInMeleeCombat(ped) and not violenceCooldown then

            violenceCooldown = true

            local coords = GetEntityCoords(ped)
            local s1 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
            local street = GetStreetNameFromHashKey(s1)

            TriggerServerEvent("nord_dispach:PhysicalViolenceAlert", {
                street = street or "Localização Desconhecida",
                coords = coords
            })

            -- 15 segundos de cooldown
            SetTimeout(15000, function()
                violenceCooldown = false
            end)
        end
    end
end)

------------------------------------------------------
-- ALERTA AUTOMÁTICO → ACIDENTE AUTOMÓVEL (SENSÍVEL)
------------------------------------------------------
local accidentCooldown = false
local lastVel = 0.0
local lastVehHealth = 0

CreateThread(function()
    while true do
        Wait(150)

        local ped = PlayerPedId()

        if not IsPedInAnyVehicle(ped, false) then
            lastVel = 0.0
            lastVehHealth = 0
            goto continue
        end

        local veh = GetVehiclePedIsIn(ped, false)
        if veh == 0 then goto continue end

        -- Velocidade (km/h)
        local vel = GetEntitySpeed(veh) * 3.6
        local delta = lastVel - vel

        -- Saúde real do veículo
        local vehHealth = GetVehicleEngineHealth(veh)  -- 💥 MELHOR QUE GetEntityHealth
        if lastVehHealth == 0 then lastVehHealth = vehHealth end

        local healthDelta = lastVehHealth - vehHealth

        -- Não contar impactos parado
        if vel < 8.0 then
            lastVel = vel
            lastVehHealth = vehHealth
            goto continue
        end

        -- 🚨 CONDIÇÕES DE ACIDENTE
        local hitSpeedDrop = delta > 12        -- mais sensível
        local wasMovingFast = lastVel > 25     -- mais sensível
        local healthImpact = healthDelta > 10  -- antes 30 → 3x mais sensível

        if not accidentCooldown then

            if (HasEntityCollidedWithAnything(veh) and hitSpeedDrop and wasMovingFast)
            or (healthImpact and lastVel > 15) then -- impacto brusco agora funciona

                accidentCooldown = true

                local coords = GetEntityCoords(ped)
                local s1 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
                local street = GetStreetNameFromHashKey(s1)

                TriggerServerEvent("nord_dispach:CarAccidentAlert", {
                    street = street or "Localização Desconhecida",
                    coords = coords
                })

                SetTimeout(6000, function()
                    accidentCooldown = false
                end)
            end
        end

        -- atualizar histórico
        lastVel = vel
        lastVehHealth = vehHealth

        ::continue::
    end
end)



------------------------------------------------------
-- ALERTA AUTOMÁTICO → ASSALTO À MÃO ARMADA
------------------------------------------------------
local robberyCooldown = false

CreateThread(function()
    while true do
        Wait(200)

        if robberyCooldown then goto continue end

        local ped = PlayerPedId()

        -- Verificar se está a apontar arma
        if IsPlayerFreeAiming(PlayerId()) then

            -- Detetar ped alvo (inclui jogadores)
            local hit, target = GetEntityPlayerIsFreeAimingAt(PlayerId())

            if hit and target and DoesEntityExist(target) then
                local targetPed = target

                -- só se o alvo for humano
                if IsPedAPlayer(targetPed) or IsPedHuman(targetPed) then

                    robberyCooldown = true

                    local coords = GetEntityCoords(ped)
                    local s1 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
                    local street = GetStreetNameFromHashKey(s1)

                    TriggerServerEvent("nord_dispach:ArmedRobberyAlert", {
                        street = street,
                        coords = coords
                    })

                    SetTimeout(15000, function()
                        robberyCooldown = false
                    end)
                end
            end
        end

        ::continue::
    end
end)


------------------------------------------------------
-- FUNÇÕES EXTRA PARA DETEÇÃO DE TIPOS DE ARMA
------------------------------------------------------
function IsMeleeWeapon(hash)
    local meleeList = {
        "WEAPON_BAT", "WEAPON_KNIFE", "WEAPON_MACHETE", "WEAPON_HAMMER",
        "WEAPON_BOTTLE", "WEAPON_CROWBAR", "WEAPON_DAGGER", "WEAPON_HATCHET",
        "WEAPON_GOLFCLUB", "WEAPON_UNARMED", "WEAPON_NIGHTSTICK", "WEAPON_WRENCH"
    }
    for _, w in ipairs(meleeList) do
        if GetHashKey(w) == hash then return true end
    end
    return false
end


------------------------------------------------------
-- 6. UNIDADE A CAMINHO
------------------------------------------------------
RegisterNetEvent("nord_dispach:UnitGoingToIncident")
AddEventHandler("nord_dispach:UnitGoingToIncident", function(id, unitCoords)
    if not unitCoords then return end

    local blip = AddBlipForCoord(unitCoords.x, unitCoords.y, unitCoords.z)
    SetBlipSprite(blip, 1)
    SetBlipScale(blip, 0.9)
    SetBlipColour(blip, 38)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Unidade em Resposta")
    EndTextCommandSetBlipName(blip)

    SendNUIMessage({
        action = "playSound",
        sound  = "noti_police_2"
    })

    SetTimeout(30000, function()
        RemoveBlip(blip)
    end)
end)

-- Compatibilidade legada
RegisterNetEvent("myDispatch:UnitGoingToIncident")
AddEventHandler("myDispatch:UnitGoingToIncident", function(id, unitCoords)
    TriggerEvent("nord_dispach:UnitGoingToIncident", id, unitCoords)
end)


------------------------------------------------------
-- 7. TECLA PARA IR AO LOCAL DA OCORRÊNCIA
------------------------------------------------------
CreateThread(function()
    while true do
        if dispatchPopupActive and lastDispatchCoords then
            
            if IsControlJustPressed(0, dispatchKey) then
                SetNewWaypoint(lastDispatchCoords.x, lastDispatchCoords.y)
                PlaySoundFrontend(-1, "WAYPOINT_SET", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
            end

            Wait(0)
        else
            Wait(200)
        end
    end
end)


------------------------------------------------------
-- 8. NUI: POPUP FECHOU
------------------------------------------------------
RegisterNUICallback("popupClose", function(_, cb)
    dispatchPopupActive = false
    lastDispatchCoords = nil
    dispatchPopupIncidentId = nil
    cb("ok")
end)
