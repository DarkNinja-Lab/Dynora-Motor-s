# Dynora CarDealer - Update v0.5.1

## ÄNDERUNGEN IN DIESEM UPDATE

### 1. Lila Chat-Nachrichten mit "[Dynora Motor´s]" Prefix
Alle Chat-Nachrichten vom CarDealer verwenden jetzt:
- **Prefix:** `[Dynora Motor´s]`
- **Farbe:** Lila (Color(157, 78, 221) - Theme Primary)

**Betroffene Dateien:**
- `sv_main.lua` - Hauptsystem-Nachrichten
- `sv_insurance.lua` - Versicherungs-Nachrichten
- `sv_tuning.lua` - Tuning-Nachrichten
- `sv_sellplayer.lua` - Verkaufs-Nachrichten
- `sv_testdrive.lua` - Testfahrt-Nachrichten
- `sv_spawnpoints.lua` - Spawnpoint-Nachrichten
- `sv_security.lua` - Security-Nachrichten
- `init(1).lua` - Police NPC Nachrichten

### 2. Admin-Menü per Chat Command (!admin_cardealer)
**WICHTIG:** Das Admin-Menü ist jetzt **NICHT MEHR** über einen Button im Hauptmenü erreichbar!

**Neuer Zugriff:**
- Chat Command: `!admin_cardealer` oder `/admin_cardealer`
- Console Command: `cardealer_admin` (optional)

**Berechtigungen (SAM):**
- `cardealer_admin` - Erlaubt Zugriff auf das Admin-Menü
- `manage_cardealer` - Alternative Permission

**Fallback:** Wenn SAM nicht installiert ist, wird auf die Standard-UserGroups geprüft:
- admin
- superadmin
- owner
- developer

### 3. SAM Admin Permissions Support
Das System unterstützt jetzt SAM (Server Administration Mod) Permissions:

```lua
-- In SAM registrierte Permissions:
- "cardealer_admin"      -- CarDealer Admin-Menü
- "manage_cardealer"     -- CarDealer Verwaltung
```

**Dateien mit SAM-Support:**
- `sv_security.lua` - `MyCarDealer.IsAdmin()` Funktion
- `cl_admin.lua` - Client-seitiger Permission-Check
- `cl_menu.lua` - Chat Command Handler
- `init(2).lua` - Server-seitiger Chat Command

---

## VERBESSERUNGSVORSCHLÄGE FÜR DIE ZUKUNFT

### 1. Performance-Optimierungen
```lua
-- Caching für Fahrzeug-Lookups
MyCarDealer.VehicleCache = {}
function MyCarDealer.GetVehicleFast(id)
    if MyCarDealer.VehicleCache[id] then
        return MyCarDealer.VehicleCache[id]
    end
    -- ... normaler Lookup
end
```

### 2. Bessere Fehlerbehandlung
- Mehr `pcall()` für kritische Funktionen
- Bessere SQL-Fehler-Logging
- User-freundliche Fehlermeldungen

### 3. QoL Features
- **Fahrzeug-Suche** im Inventar (nach Name, Kategorie)
- **Sortierung** im Inventar (Preis, Datum, Name)
- **Fahrzeug-Vorschau** vor dem Kauf (3D-Viewer)
- **Statistiken** (gefahrene KM, Unfälle, etc.)

### 4. Mehr LVS-Features
- **Tuning-Teile speichern** (Turbo, Kompressor, etc.) -- BUG -- > 
- **Kilometerzähler** pro Fahrzeug
- **Schadenssystem** (mit Repair-Option)
- **Kraftstoffverbrauch** (realistischer)

### 5. UI/UX Verbesserungen
- **Dark Mode** Option
- **Animationen** (Fade-In/Out, Slide)
- **Tooltips** für alle Buttons
- **Keyboard Shortcuts** (ESC zum Schließen, etc.)

### 6. Sicherheit
- **Rate Limiting** für alle Net Messages
- **Anti-Cheat** Integration (optional)
- **Logging** für alle Aktionen (Discord Webhook)

### 7. Konfigurierbarkeit
- **Mehr Config-Optionen** (Preise, Cooldowns, etc.)
- **Mehrere Spawnpoint-Sets** (für verschiedene Kategorien)
- **Job-Locking** für Kategorien (nicht nur einzelne Fahrzeuge)

### 8. Integrationen
- **Discord Webhook** für Logs
- **PointShop 2** Integration (Fahrzeuge als Items)
- **DarkRP Job-Integration** (Job-Abhängige Preise)

---

## INSTALLATION

### Neue Dateien einspielen:
1. Alle `.lua` Dateien aus dem `output` Ordner in `addons/cardealer/lua/cardealer/` kopieren
2. Server neustarten oder `lua_refresh` ausführen

### SAM Permissions einrichten (optional):
```lua
-- In SAM Admin Menü:
1. Permissions → Add Permission
2. Name: "cardealer_admin"
3. Description: "CarDealer Admin Menü Zugriff"
4. Default: false

5. Rank zuweisen (z.B. superadmin)
```

---

## BEFEHLSÜBERSICHT

### Spieler-Befehle:
- `!admin_cardealer` - Admin-Menü öffnen (nur mit Permission)
- `cardealer_open` - CarDealer Menü öffnen (Console)
- `cardealer_store_vehicle` - Fahrzeug einparken (Console)

### Admin-Befehle:
- `cardealer_addspawn <name>` - Spawnpoint hinzufügen
- `cardealer_removespawn <id>` - Spawnpoint entfernen
- `cardealer_listspawns` - Alle Spawnpoints anzeigen
- `cardealer_nearestspawn` - Nächsten Spawnpoint anzeigen
- `cardealer_teleportspawn <id>` - Zu Spawnpoint teleportieren
- `cardealer_spawn` - NPC spawnen

---

## SUPPORT

Bei Problemen oder Fragen:
- Prüfe die Server-Console auf Fehlermeldungen
- Stelle sicher, dass alle Dateien korrekt hochgeladen wurden
- Überprüfe die SAM Permissions (falls verwendet)

---

**Version:** 0.5.1
**Author:** DarkNinja, ChiHydra
**Datum:** 2026-03-23