# Verkabelung

Alle Geräte hängen an **einem** I²C-Bus. Das OLED ist auf dem Board bereits fest
mit GPIO5/GPIO6 verbunden; der MPU6050 kommt einfach parallel dazu.

## MPU6050 (GY-521) → ESP32-C3-OLED-Board

| GY-521 | Board            | Hinweis                                   |
|--------|------------------|-------------------------------------------|
| VCC    | **5V** (falls vorhanden), sonst 3V3 | GY-521 hat eigenen 3,3-V-LDO |
| GND    | GND              | gemeinsame Masse — zwingend               |
| SDA    | **GPIO5**        | derselbe Pin wie das OLED                 |
| SCL    | **GPIO6**        | derselbe Pin wie das OLED                 |
| AD0    | offen lassen     | → Adresse 0x68                            |
| XDA / XCL / INT | offen lassen |                                       |

## ESP32-C3 — freie/gesperrte Pins (wichtig!)

Der C3 ist **nicht** wie ein klassischer ESP32:

- **GPIO0/1** = 32-kHz-Quarz → für I²C unbrauchbar
- **GPIO2/8/9** = Strapping (Boot) · **GPIO11** = VDD_SPI · **GPIO12–17** = Flash
- **GPIO18/19** = USB · **GPIO20/21** = UART0 (Log)
- **frei nutzbar:** GPIO4, 5, 6, 7, 10

## Kontrolle per Log

Nach dem Flashen im ESPHome-Log auf den I²C-Scan achten:

```
Found device at address 0x3C   ← OLED
Found device at address 0x68   ← MPU6050
```

Fehlt **0x68**: SDA/SCL testweise tauschen, GND prüfen, Lötstellen am GY-521
kontrollieren. Eine andere Adresse als 0x68/0x69 ist **nie** der MPU6050.
