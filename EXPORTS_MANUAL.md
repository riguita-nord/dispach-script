# Dispatch Exports Manual

Este manual mostra como usar os exports do recurso `nord_dispach` em scripts externos.

## Requisitos

- O recurso `nord_dispach` tem de estar iniciado.
- O script que chama os exports deve correr no lado servidor.
- O `alertType` deve existir em `Config.Alerts` no `config.lua`.
- Configura `Config.Framework` no `config.lua` para `auto`, `qbcore`, `esx` ou `standalone`.

## Export de ativacao global

Ativa ou desativa todos os alertas de dispatch.

### AtivarAlertas

```lua
exports['nord_dispach']:AtivarAlertas(true)   -- ativa
exports['nord_dispach']:AtivarAlertas(false)  -- desativa
```

### ActivateAlerts (alias)

```lua
exports['nord_dispach']:ActivateAlerts(true)
```

Retorno: `boolean` com o estado final (`true` ou `false`).

## Export generico para criar alerta

### CriarAlertaDispatch

```lua
local ok, err = exports['nord_dispach']:CriarAlertaDispatch('shots_fired', {
    street = 'Vespucci Blvd',
    coords = vector3(120.5, -300.2, 45.1),
    info = {
        arma = 'Pistol',
        suspeitos = 2
    }
})

if not ok then
    print('Falha ao criar alerta: ' .. tostring(err))
end
```

### CreateDispatchAlert (alias)

```lua
exports['nord_dispach']:CreateDispatchAlert('car_theft', {
    street = 'Alta St',
    coords = { x = 215.0, y = -810.0, z = 30.0 },
    info = { placa = '12-AB-34' }
})
```

Parametros:
- `alertType` (string): tipo do alerta, por exemplo `shots_fired`, `car_theft`, etc.
- `data.street` (string, opcional): nome da rua/local.
- `data.coords` (vector3 ou table `{ x, y, z }`, obrigatorio): coordenadas do incidente.
- `data.info` (table, opcional): informacao extra para o alerta.

Retorno:
- `true` quando enviado com sucesso.
- `false, "alertType inválido"` quando o tipo for invalido.

## Exports de atalho

Estes exports chamam internamente o export generico com tipos predefinidos.

### DispatchShotsFired

```lua
exports['nord_dispach']:DispatchShotsFired({
    street = 'Strawberry Ave',
    coords = vector3(250.0, -1020.0, 29.2)
})
```

### DispatchCarTheft

```lua
exports['nord_dispach']:DispatchCarTheft({
    street = 'Elgin Ave',
    coords = vector3(300.0, -900.0, 29.2),
    info = { modelo = 'Sultan', placa = 'AA11BB' }
})
```

### DispatchPhysicalViolence

```lua
exports['nord_dispach']:DispatchPhysicalViolence({
    street = 'Innocence Blvd',
    coords = vector3(450.0, -990.0, 30.6)
})
```

### DispatchCarAccident

```lua
exports['nord_dispach']:DispatchCarAccident({
    street = 'Olympic Fwy',
    coords = vector3(760.0, -650.0, 27.8),
    info = { gravidade = 'alta' }
})
```

### DispatchArmedRobbery

```lua
exports['nord_dispach']:DispatchArmedRobbery({
    street = 'Paleto Blvd',
    coords = vector3(-110.0, 6460.0, 31.5),
    info = { estabelecimento = '24/7' }
})
```

## Lista de tipos de alerta disponiveis atualmente

Com base no `config.lua` atual:
- `shots_fired`
- `player_dead`
- `officer_down`
- `medic_down`
- `car_theft`
- `physical_violence`
- `car_accident`
- `armed_robbery`

## Dicas rapidas

- Se nenhum alerta aparecer, valida se os jobs de destino estao permitidos em `Config.AllowedJobs`.
- Se estiveres a testar e nao funcionar, confirma que os alertas globais estao ativos (`AtivarAlertas(true)`).
- Mantem os nomes dos `alertType` iguais aos definidos em `Config.Alerts`.
