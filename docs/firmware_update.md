# Software-Aktualisierung

**GitHub ist die einzige Quelle** — für Firmware, Integration und Karte
gleichermaßen. Es gibt keinen zweiten Weg und keinen eigenen Server.

| Was | Weg | Wo sichtbar |
|---|---|---|
| Integration + Lovelace-Karte | HACS aus dem GitHub-Release | HACS, Einstellungen → Updates |
| Firmware, mit Home Assistant | Update-Entität, prüft alle 12 h | Einstellungen → System → Updates |
| Firmware, ohne Home Assistant | Knopf auf der Geräteseite, Reiter *Technik* | Geräteseite |

Beide Betriebsarten laufen auf **derselben** Firmware und bekommen deshalb
dieselben Aktualisierungen — auch die visuellen. Die Geräteoberfläche steckt
über `js_include` in der Firmware, sie reist bei jedem Update mit.

## Feste Adressen

Alles hängt an `releases/latest/download/…`. GitHub löst das selbst auf die
neueste Veröffentlichung auf, die Adressen ändern sich also **nie**:

```
https://github.com/rcdev67/campermaid/releases/latest/download/manifest.json
https://github.com/rcdev67/campermaid/releases/latest/download/level-firmware.ota.bin
https://github.com/rcdev67/campermaid/releases/latest/download/level-firmware.ota.bin.md5
```

Sie stehen fest in [`campermaid-level.yaml`](../esphome/level/campermaid-level.yaml)
und müssen bei einer neuen Version **nicht** angefasst werden.

## Eine neue Version veröffentlichen

1. **Version erhöhen.** Die Firmware-Version steht an **einer** Stelle:
   `firmware_version` in den `substitutions` von
   [`hardware.yaml`](../esphome/level/hardware.yaml).
   Von dort zieht sie sich in `esphome.project.version` und in die
   angezeigte Fassung. Der Wert im Release-Manifest muss **zeichengleich**
   sein — die Prüfung im Gerät vergleicht die Zeichenketten:

   ```cpp
   #ifdef ESPHOME_PROJECT_VERSION
       info->current_version = ESPHOME_PROJECT_VERSION;
   ```

   Weicht das Manifest ab, meldet das Gerät dauerhaft „Update verfügbar" —
   auch direkt nach dem Aktualisieren.

   Getrennt davon: `manifest.json` der Home-Assistant-Integration.
2. **Firmware bauen.** Es muss die **`level-firmware.ota.bin`** sein. Die
   Factory-Datei ist für OTA ausdrücklich nicht verwendbar — sie enthält
   Bootloader und Partitionstabelle und wird abgewiesen.
3. **MD5-Summe bilden** und als eigene Datei ablegen:
   ```powershell
   (Get-FileHash .\level-firmware.ota.bin -Algorithm MD5).Hash.ToLower() | Out-File -Encoding ascii level-firmware.ota.bin.md5
   ```
4. **Release anlegen** mit dem Tag der Version, dann die drei Dateien
   anhängen: `level-firmware.ota.bin`, `level-firmware.ota.bin.md5`, `manifest.json`.

Ohne Release passiert nichts — weder in HACS noch an den Geräten. HACS folgt
seit dem ersten Tag ausschließlich Releases, nicht dem Branch.

## Aufbau des Manifests

Nach der ESP-Web-Tools-Spezifikation mit der OTA-Erweiterung:

```json
{
  "name": "CamperMaid",
  "version": "1.14.0",
  "builds": [
    {
      "chipFamily": "ESP32-C3",
      "ota": {
        "md5": "…32 Zeichen…",
        "path": "https://github.com/rcdev67/campermaid/releases/latest/download/level-firmware.ota.bin",
        "summary": "Fahrzeugmaße im Gerät, Update von Hand ohne Home Assistant",
        "release_url": "https://github.com/rcdev67/campermaid/releases/latest"
      }
    }
  ]
}
```

`path` steht bewusst als vollständige Adresse: Beginnt der Wert mit `http`,
nimmt das Gerät ihn unverändert. Relative Angaben würden hier scheitern, weil
GitHub den Download auf einen anderen Rechner umleitet.

**Pflichtfelder:** `name`, `version`, `builds[].chipFamily`,
`builds[].ota.md5`, `builds[].ota.path`. `summary` und `release_url` sind
optional, werden dem Nutzer aber angezeigt — ohne sie steht da nur eine
Nummer ohne Erklärung.

Stimmt die MD5-Summe nicht, verweigert das Gerät die Installation. Das ist die
einzige Sicherung gegen eine halb übertragene Datei — also niemals eine alte
Summe stehen lassen.

## Verschlüsselung

`http_request:` prüft das Zertifikat von GitHub (Voreinstellung). Scheitert
der Handschlag auf dem Gerät, lässt sich `verify_ssl: false` setzen — dann
entfällt aber die Echtheitsprüfung, und ein Angreifer im selben Netz könnte
eigene Firmware unterschieben. Die MD5-Summe hilft dagegen nicht, sie stammt
aus derselben Quelle. Erst versuchen, dann abschalten, nicht umgekehrt.

## Warum der Selbstbau-Weg kein automatisches Update hat

[`campermaid-level-komplett.yaml`](../esphome/level/campermaid-level-komplett.yaml)
enthält bewusst weder `update:` noch den Update-Knopf. Wer diese Datei
einfügt, hat sie in aller Regel angepasst — Gerätename, Pins, Achsvorzeichen.
Ein automatisches Update würde diese Anpassungen kommentarlos durch den
Werksstand ersetzen. Selbstbaür aktualisieren über das ESPHome-Dashboard,
das sie ohnehin benutzen.
