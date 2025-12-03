# 📡 Nord Dispatch System — Nord Lab  
Sistema de Dispatch Inteligente para FiveM (QBCore / ESX)

---

## 📌 Descrição Geral

O **Nord Dispatch System**, desenvolvido pela **Nord Lab**, é um sistema leve, rápido e profissional de gestão de **alertas automáticos** e **incidentes in-game**.

Criado para complementar qualquer MDT ou funcionar isoladamente, o dispatch fornece:

- Alertas claros
- Sons personalizados
- Localização do incidente no mapa
- Integração com scripts externos
- Compatibilidade QBCore 100%
- ESX Em desenvolvimento
- Para uma melhor performance a nivel de gestao e aconcelhavel o uso do mdt

Foi concebido para máxima:

- **Simplicidade**  
- **Velocidade**  
- **Realismo sem sobrecarregar UI**  
- **Compatibilidade total** com qualquer servidor RP  

---

## ✨ Funcionalidades Principais

### 🔔 Alertas Automáticos

O dispatch recebe e exibe alertas de:

- Tiros disparados  
- Roubo de veículo  
- Carjacking  
- Assalto a loja/banco  
- Jogador ferido / inconsciente  
- Paramédico abatido  
- Oficial abatido  
- Acidentes de viação  
- Alertas customizados enviados via evento  

Cada alerta inclui:

- Tipo do incidente  
- Descrição  
- Coordenadas  
- Som específico  
- Prioridade  
- Tempo desde o alerta  

---

### 🗺️ Localização no Mapa

O dispatch mostra **apenas o incidente** no mapa:

- Marcador no local do alerta  
- Zoom automático  
- Ícone correspondente ao tipo do alerta  

> ❗ **Não** mostra unidades, patrulhas ou agentes — essas funções pertencem ao MDT.

---

### 🔊 Sistema de Notificações

- Notificação visual por alerta  
- Sons customizados por tipo  
- Stack de múltiplos alertas  
- Destaque por prioridade  
- Fade automático  
- Limpeza automática de alertas antigos  

---

### 🎨 Interface do Dispatch

- Layout moderno estilo CAD real  
- Painel minimalista  
- Visualização rápida de cada alerta  
- Cores organizadas por categoria  
- Modo escuro  
- Animações suaves  
- UI adaptável a qualquer resolução  

---

### 🛡️ Segurança

- Anti-spam de alertas
- Validação de coordenadas
- Proteção contra triggers maliciosos
- Throttles individuais por jogador

### 💼 Créditos

- Desenvolvido por: Nord Lab
- Produzido para: Noctavia Roleplay
- UI Design: Nord OS Team
- Discord: https://discord.gg/9ZxKB4cs8p
## 🧩 Integração com Scripts Externos

Qualquer script pode enviar alertas para o dispatch:

### ➤ Enviar alerta personalizado
```lua
TriggerEvent("nord_dispatch:add", {
    type    = "custom",
    msg     = "Atividade suspeita detectada",
    coords  = vector3(100.2, -203.5, 54.1),
    priority = 2
})

