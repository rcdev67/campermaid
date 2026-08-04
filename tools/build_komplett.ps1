# ============================================================================
#  Erzeugt campermaid-level-komplett.yaml aus
#  esphome/level/hardware.yaml.
#
#      pwsh ./build_komplett.ps1
#
#  Der Baustein liegt im Unterordner campermaid/, damit das ESPHome-Dashboard
#  ihn nicht als eigenes Gerät auflistet - es liest nur die oberste Ebene.
#
#  Warum generiert: die Messlogik soll an genau EINER Stelle stehen. Die
#  Komplettdatei ist nur die Einfügevariante für Leute, die nichts kopieren
#  und nichts zusammenfügen wollen - sie darf deshalb keine zweite,
#  handpflegte Kopie der Sensorik sein.
# ============================================================================

$ErrorActionPreference = 'Stop'
$here = Join-Path (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) 'esphome\level'

$source = Join-Path $here 'hardware.yaml'
$target = Join-Path $here 'campermaid-level-komplett.yaml'
if (-not (Test-Path $source)) { throw "Quelle fehlt: $source" }

$lines = Get-Content $source -Encoding UTF8

# Der Hardware-Teil beginnt bei web_server: - davor stehen nur Kopf,
# Substitutionen und die beiden Blöcke, die hier eigene Werte bekommen.
$start = ($lines | Select-String -Pattern '^web_server:' | Select-Object -First 1).LineNumber
if (-not $start) { throw "Startmarke 'web_server:' nicht gefunden." }
$body = $lines[($start - 1)..($lines.Count - 1)]

# Substitutionsblock übernehmen (zwischen 'substitutions:' und der nächsten
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
#  Änderungen an der Messlogik dort machen und neu bauen.
#
#  ZUM EINFÜGEN GEDACHT: im ESPHome Device Builder ein neues Gerät anlegen,
#  dann in der erzeugten Datei ALLES markieren, löschen und diese Datei
#  komplett einfügen. Nichts weiter - kein Kopieren von Dateien, kein
#  Eintrag in der secrets.yaml, kein Zusammenfügen von Blöcken.
#
#  Vorausgesetzt werden nur wifi_ssid und wifi_password in der secrets.yaml.
#  Die legt ESPHome bei der Ersteinrichtung selbst an; wenn in deiner
#  Gerätedatei "!secret wifi_ssid" stand, sind sie vorhanden.
#
#  Bewusst weggelassen: API-Verschlüsselung und OTA-Passwort. Beides ist in
#  ESPHome optional, und beides wäre ein Wert, den jeder einzeln erzeugen und
#  eintragen müsste. Wer das möchte, ergänzt es später im ESPHome-Editor:
#
#      api:
#        encryption:
#          key: "<32 Byte Base64>"
#      ota:
#        - platform: esphome
#          password: "<eigenes Passwort>"
#
#  Ohne diese Zeilen ist das Gerät im eigenen Netz erreichbar wie jedes
#  andere ESPHome-Gerät ohne Verschlüsselung. Für ein Nivelliergerät im
#  Wohnmobil ist das vertretbar - für Türöffner wäre es das nicht.
# ============================================================================

substitutions:
  # Gerätename - bestimmt auch die Entity-Namen in Home Assistant.
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
