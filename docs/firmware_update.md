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
https://github.com/rcdev67/campermaid/releases/latest/download/level-manifest.json
https://github.com/rcdev67/campermaid/releases/latest/download/level-firmware.ota.bin
https://github.com/rcdev67/campermaid/releases/latest/download/level-firmware.ota.bin.md5
```

Das Produktpräfix `level-` trägt jede Datei, weil sich Level und Gas später ein
Release teilen.

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
4. **Release anlegen** mit dem Tag der Version, dann die vier Dateien
   anhängen: `level-firmware.ota.bin`, `level-firmware.ota.bin.md5`,
   `level-firmware.factory.bin`, `level-manifest.json`. Die Factory-Datei wird
   fürs Update nicht gebraucht — sie liegt bei, damit sich jede veröffentlichte
   Version ohne Bauen auf ein leeres Board bringen lässt.

Schritt 2 bis 4 nimmt `tools/veroeffentlichen.cmd` ab, samt Reihenfolge beim
Hochladen.

Ohne Release passiert nichts — weder in HACS noch an den Geräten. HACS folgt
seit dem ersten Tag ausschließlich Releases, nicht dem Branch.

## Aufbau des Manifests

Nach der ESP-Web-Tools-Spezifikation mit der OTA-Erweiterung:

```json
{
  "name": "CamperMaid Level",
  "version": "2.0.0",
  "builds": [
    {
      "chipFamily": "ESP32-C3",
      "ota": {
        "md5": "…32 Zeichen…",
        "path": "https://github.com/rcdev67/campermaid/releases/latest/download/level-firmware.ota.bin",
        "summary": "CamperMaid 2.0.0",
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

## Selbstbau mit eigenen Anpassungen

Wer die Firmware verändert hat — Gerätename, Pins, Achsvorzeichen —, sollte den
Update-Knopf stehen lassen, aber nicht drücken: Er holt den Werksstand und
ersetzt die Anpassungen kommentarlos. Der Weg dafür ist `esphome run` aus dem
eigenen Arbeitsstand, wie in [INSTALL.md](../INSTALL.md) beschrieben.

Die Einstellwerte im Gerät überstehen beide Wege. Verloren gehen sie beim
seriellen Aufspielen mit Löschen: Das räumt auch den Speicherbereich ab, in dem
Fahrzeugmaße und WLAN-Zugangsdaten liegen. Deshalb aktualisiert ein Gerät im
Einsatz über das Netz, nicht über das Kabel.
