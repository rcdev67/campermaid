# ============================================================================
#  Erzeugt campermaid-level-komplett.yaml aus
#  esphome/level/hardware.yaml.
#
#      pwsh ./build_komplett.ps1
#
#  Der Baustein liegt im Unterordner campermaid/, damit das ESPHome-Dashboard
#  ihn nicht als eigenes Geraet auflistet - es liest nur die oberste Ebene.
#
#  Warum generiert: die Messlogik soll an genau EINER Stelle stehen. Die
#  Komplettdatei ist nur die Einfuegevariante fuer Leute, die nichts kopieren
#  und nichts zusammenfuegen wollen - sie darf deshalb keine zweite,
#  handpflegte Kopie der Sensorik sein.
# ============================================================================

$ErrorActionPreference = 'Stop'
$here = Join-Path (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) 'esphome\level'

$source = Join-Path $here 'hardware.yaml'
$target = Join-Path $here 'campermaid-level-komplett.yaml'
if (-not (Test-Path $source)) { throw "Quelle fehlt: $source" }

$lines = Get-Content $source -Encoding UTF8

# Der Hardware-Teil beginnt bei web_server: - davor stehen nur Kopf,
# Substitutionen und die beiden Bloecke, die hier eigene Werte bekommen.
$start = ($lines | Select-String -Pattern '^web_server:' | Select-Object -First 1).LineNumber
if (-not $start) { throw "Startmarke 'web_server:' nicht gefunden." }
$body = $lines[($start - 1)..($lines.Count - 1)]

# Substitutionsblock uebernehmen (zwischen 'substitutions:' und der naechsten
# Zeile, die am Zeilenanfang beginnt).
$subStart = ($lines | Select-String -Pattern '^substitutions:' | Select-Object -First 1).LineNumber
$subLines = @()
for ($i = $subStart; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^\S') { break }
    $subLines += $lines[$i]
}

$header = @'
# ============================================================================
#  CamperMaid Level - Komplettfassung (GENERIERT - nicht editieren)
# ----------------------------------------------------------------------------
#  Erzeugt von build_komplett.ps1 aus hardware.yaml.
#  Aenderungen an der Messlogik dort machen und neu bauen.
#
#  ZUM EINFUEGEN GEDACHT: im ESPHome Device Builder ein neues Geraet anlegen,
#  dann in der erzeugten Datei ALLES markieren, loeschen und diese Datei
#  komplett einfuegen. Nichts weiter - kein Kopieren von Dateien, kein
#  Eintrag in der secrets.yaml, kein Zusammenfuegen von Bloecken.
#
#  Vorausgesetzt werden nur wifi_ssid und wifi_password in der secrets.yaml.
#  Die legt ESPHome bei der Ersteinrichtung selbst an; wenn in deiner
#  Geraetedatei "!secret wifi_ssid" stand, sind sie vorhanden.
#
#  Bewusst weggelassen: API-Verschluesselung und OTA-Passwort. Beides ist in
#  ESPHome optional, und beides waere ein Wert, den jeder einzeln erzeugen und
#  eintragen muesste. Wer das moechte, ergaenzt es spaeter im ESPHome-Editor:
#
#      api:
#        encryption:
#          key: "<32 Byte Base64>"
#      ota:
#        - platform: esphome
#          password: "<eigenes Passwort>"
#
#  Ohne diese Zeilen ist das Geraet im eigenen Netz erreichbar wie jedes
#  andere ESPHome-Geraet ohne Verschluesselung. Fuer ein Nivelliergeraet im
#  Wohnmobil ist das vertretbar - fuer Tueroeffner waere es das nicht.
# ============================================================================

substitutions:
  # Geraetename - bestimmt auch die Entity-Namen in Home Assistant.
  device_name: campermaid-level
  friendly_name: CamperMaid Level
'@ -split "`r?`n"

$boilerplate = @'

esphome:
  name: ${device_name}
  friendly_name: ${friendly_name}
  comment: CamperMaid Level - ESP32-C3 + MPU-6050 + OLED

esp32:
  board: esp32-c3-devkitm-1
  flash_size: 4MB
  framework:
    type: esp-idf

logger:
  level: INFO

api:

ota:
  - platform: esphome

wifi:
  ssid: !secret wifi_ssid
  password: !secret wifi_password
  reboot_timeout: 10min
  ap:
    ssid: "CamperMaid"

captive_portal:

'@ -split "`r?`n"

$out = $header + $subLines + $boilerplate + $body
[IO.File]::WriteAllText($target, ($out -join "`n"), (New-Object System.Text.UTF8Encoding($false)))

Write-Host "Geschrieben: $target"
Write-Host ("Zeilen: {0}" -f $out.Count)
