Config = Config or {}

-- ON / OFF da integração do dispatch com o Nord MDT
Config.Dispatch_MDT_Enabled = true

-- Ativar/Desativar logs e debug do dispatch
Config.Dispatch_Logs_Enabled = false       -- true = logs + debug, false = nada

--------------------------------------------------------
-- 1. Tabelas da Base de Dados
--------------------------------------------------------
Config.DispatchTable      = "noctavia_mdt_dispatch"
Config.DispatchLogsTable  = "noctavia_mdt_dispatch_logs"

--------------------------------------------------------
-- 2. Interação com o Dispatch
--------------------------------------------------------
Config.DispatchKey = "E"             -- Tecla para marcar GPS no mapa
Config.DispatchAcceptButton = false  -- Mostrar botão "Aceitar Ocorrência"

--------------------------------------------------------
-- 3. Tempo de retenção dos registos na BD
-- Formatos aceites:
--    30s, 10m, 1h, 2h, 1d
--------------------------------------------------------
Config.DispatchRetention = "6h"

--------------------------------------------------------
-- 4. Jobs que RECEBEM alertas do dispatch
--------------------------------------------------------
Config.AllowedJobs = {
    police      = true,
    sheriff     = true,
    ambulance   = true,
    ems         = true,
    firefighter = true,
}

--------------------------------------------------------
-- 5. Tipos de alertas disponíveis no sistema
--------------------------------------------------------
Config.Alerts = {

    ----------------------------------------------------
    -- TIROS DISPARADOS
    ----------------------------------------------------
    ["shots_fired"] = {
        code     = "10-71",
        title    = "Tiros Disparados",
        icon     = "🔫",
        blip     = 110,
        color    = 1,
        timeout  = 60,
        priority = 2,
        sound    = "noti_police_1"
    },

    ----------------------------------------------------
    -- MORTES
    ----------------------------------------------------
    ["player_dead"] = {
        code     = "10-47",
        title    = "Indivíduo Ferido",
        icon     = "💀",
        blip     = 153,
        color    = 1,
        timeout  = 60,
        priority = 1,
        sound    = "noti_police_1"
    },

    ["officer_down"] = {
        code     = "10-99",
        title    = "Oficial Abatido",
        icon     = "🛑",
        blip     = 161,
        color    = 3,
        timeout  = 90,
        priority = 1,
        sound    = "noti_police_1"
    },

    ["medic_down"] = {
        code     = "10-52",
        title    = "Paramédico Abatido",
        icon     = "🚑",
        blip     = 80,
        color    = 1,
        timeout  = 90,
        priority = 1,
        sound    = "noti_police_1"
    },

    ----------------------------------------------------
    -- ROUBO DE VEÍCULO
    ----------------------------------------------------
    ["car_theft"] = {
        code     = "10-99",
        title    = "Roubo de Veículo",
        icon     = "🚗",
        blip     = 225,
        color    = 1,
        timeout  = 90,
        priority = 3,
        sound    = "noti_police_1"
    },

    ----------------------------------------------------
    -- VIOLÊNCIA FÍSICA (SOCOS / MELEE)
    ----------------------------------------------------
    ["physical_violence"] = {
        code     = "10-16",
        title    = "Violência Física",
        icon     = "👊",
        blip     = 280,
        color    = 1,
        timeout  = 90,
        priority = 2,
        sound    = "noti_police_1"
    },

    ----------------------------------------------------
    -- ACIDENTE AUTOMÓVEL
    ----------------------------------------------------
    ["car_accident"] = {
        code     = "10-50",
        title    = "Acidente Automóvel",
        icon     = "🚗",
        blip     = 225,
        color    = 47,
        timeout  = 120,
        priority = 1,
        sound    = "noti_police_1"
    },

    ----------------------------------------------------
    -- ASSALTO À MÃO ARMADA
    ----------------------------------------------------
    ["armed_robbery"] = {
        code     = "10-65",
        title    = "Assalto à Mão Armada",
        icon     = "🔪",
        blip     = 161,      -- ícone policial (suspeito armado)
        color    = 1,        -- vermelho
        timeout  = 120,      -- tempo do blip no mapa
        priority = 1,        -- muito importante
        sound    = "noti_police_1"
    },

}
