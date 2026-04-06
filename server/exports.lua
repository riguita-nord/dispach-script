-- Exports públicos para scripts externos criarem alertas no dispatch.

local function CreateDispatchAlert(alertType, data)
    if type(alertType) ~= "string" or alertType == "" then
        return false, "alertType inválido"
    end

    data = data or {}

    TriggerEvent("nord_dispach:ExternalAlert", alertType, {
        street = data.street,
        coords = data.coords,
        info   = data.info or {}
    })

    return true
end

exports("CriarAlertaDispatch", CreateDispatchAlert)
exports("CreateDispatchAlert", CreateDispatchAlert)

-- Atalhos úteis para tipos já existentes no config.
exports("DispatchShotsFired", function(data)
    return CreateDispatchAlert("shots_fired", data)
end)

exports("DispatchCarTheft", function(data)
    return CreateDispatchAlert("car_theft", data)
end)

exports("DispatchPhysicalViolence", function(data)
    return CreateDispatchAlert("physical_violence", data)
end)

exports("DispatchCarAccident", function(data)
    return CreateDispatchAlert("car_accident", data)
end)

exports("DispatchArmedRobbery", function(data)
    return CreateDispatchAlert("armed_robbery", data)
end)
