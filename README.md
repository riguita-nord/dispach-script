# 📡 Nord Dispatch System — Nord Lab  
Intelligent Dispatch System for FiveM (QBCore / ESX)

---

## 📌 General Description

The **Nord Dispatch System**, developed by **Nord Lab**, is a lightweight, fast, and professional system for handling **automatic alerts** and **in-game incidents**.

Designed to complement any MDT or run independently, the dispatch provides:

- Clear alert visualization  
- Custom sounds  
- Incident location on the map  
- Integration with external scripts  
- Full QBCore compatibility (100%)  
- ESX support currently in development  
- For best performance and management features, using an MDT is recommended  

Built with a focus on:

- **Simplicity**  
- **Speed**  
- **Realism without clutter**  
- **Full compatibility** with any RP server  

---

## ✨ Main Features

### 🔔 Automatic Alerts

The dispatch receives and displays alerts for:

- Shots fired  
- Vehicle theft  
- Carjacking  
- Store/bank robbery  
- Injured/unconscious player  
- Downed paramedic  
- Downed officer  
- Traffic accidents  
- Custom alerts triggered via events  

Each alert includes:

- Incident type  
- Description  
- Coordinates  
- Dedicated sound  
- Priority level  
- Time since the alert triggered  

---

### 🗺️ Map Location

The dispatch shows **only the incident** on the map:

- Marker at the alert location  
- Automatic zoom  
- Icon based on alert type  

> ❗ **Does NOT** show units, patrols, or officers — these features belong to the MDT.

---

### 🔊 Notification System

- Visual alert notifications  
- Custom sounds per alert type  
- Supports multiple alerts at the same time  
- Priority-based highlighting  
- Automatic fade-out  
- Automatic cleanup of old alerts  

---

### 🎨 Dispatch Interface

- Modern CAD-style layout  
- Minimalist panel  
- Quick incident overview  
- Color-coded categories  
- Dark mode  
- Smooth animations  
- Responsive UI for all screen sizes  

---

### 🛡️ Security

- Anti-spam alert protection  
- Coordinate validation  
- Protection against malicious triggers  
- Per-player throttles  

---

### 💼 Credits

- Developed by: **Nord Lab**  
- Created for: **Noctavia Roleplay**  
- UI Design: **Nord OS Team**  
- Discord: https://discord.gg/9ZxKB4cs8p  

---

## 🧩 Integration With External Scripts

Any script can send alerts to the dispatch:

### ➤ Send a custom alert
```lua
TriggerEvent("nord_dispatch:add", {
    type    = "custom",
    msg     = "Suspicious activity detected",
    coords  = vector3(100.2, -203.5, 54.1),
    priority = 2
})
