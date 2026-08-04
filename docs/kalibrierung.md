# Kalibrierung

Drei Dinge, in dieser Reihenfolge: **Achszuordnung** (welche Achse ist längs?),
**Vorzeichen** (welche Richtung ist positiv?), dann der **Nullpunkt**.

Die ersten beiden Schritte sind einmalig je Einbaulage und erfordern einen
neuen Flash. Der Nullpunkt wird per Knopfdruck gesetzt.

---

## 1. Achszuordnung prüfen (bei anderem Einbau)

Der MPU6050 misst auf drei Achsen. Welche davon die Längsneigung trägt, hängt
davon ab, **wie herum das Board eingebaut ist** — das lässt sich nicht durch ein
Vorzeichen korrigieren.

Test: Fahrzeug (oder Board) **vorne anheben**.

- Ändert sich **„Neigung Pitch"** → Zuordnung stimmt.
- Ändert sich stattdessen **„Neigung Roll"** → längs und quer sind vertauscht.
  In `esphome/campermaid-level.yaml` die beiden Werte tauschen und neu flashen:

```yaml
substitutions:
  axis_pitch: "y"   # vorher "x"
  axis_roll: "x"    # vorher "y"
```

Erlaubt sind nur `x` und `y` — `z` ist immer die Schwerkraftachse.

> Diese Zuordnung wird an **drei** Stellen benutzt (Pitch-Sensor, Roll-Sensor,
> Kalibrier-Button). Deshalb steht sie in den Substitutions und nicht im Code:
> würde eine der drei Stellen abweichen, liefen Anzeige und gespeicherter Offset
> auseinander — ein Fehler, der erst auf dem Stellplatz auffällt. Der Selbsttest
> in Schritt 3 schlägt genau dann an.

## 2. Vorzeichen prüfen

Die Konvention ist:

- **pitch > 0 = Front hoch**
- **roll > 0 = rechte Seite hoch**

Prüfen:

- **Vorne anheben** → Pitch muss **positiv** werden, die Blase Richtung „VORNE"
  wandern.
- **Rechte Seite anheben** → Roll muss **positiv** werden, Blase nach rechts.

Stimmt eine Richtung nicht, das jeweilige Vorzeichen umstellen und neu flashen:

```yaml
substitutions:
  pitch_sign: "-1"   # falls vorne/hinten vertauscht
  roll_sign: "-1"    # falls links/rechts vertauscht
```

Nach jeder Änderung an Zuordnung oder Vorzeichen **erneut kalibrieren**.

## 3. Nullpunkt setzen — mit Selbsttest

1. Fahrzeug so exakt wie möglich waagerecht stellen (Wasserwaage längs **und**
   quer). Alternativ eine bekannt ebene Fläche nutzen.
   → **Das ist in der Praxis die größte Fehlerquelle, nicht der Sensor.**
   Alles, was hier schiefsteht, steckt dauerhaft in allen späteren cm-Angaben.
2. Während des Drückens **nicht** im Fahrzeug bewegen.
3. Button **„Auf eben kalibrieren"** drücken.
4. **5 Sekunden warten.** Home Assistant prüft automatisch, ob beide Achsen
   danach wirklich bei ~0 stehen:
   - ✔ `Zuletzt kalibriert` zeigt **heute, HH:MM Uhr**, keine Meldung → fertig.
   - ✘ Meldung **„Kalibrierung hat nicht gegriffen"** → entweder wurde während
     des Drückens bewegt (einfach wiederholen), oder die Achszuordnung aus
     Schritt 1 passt nicht.
5. Danach noch ~1 Minute Strom lassen — die Offsets werden erst nach dem
   `flash_write_interval` dauerhaft gespeichert und überleben dann Neustarts.

---

## 4. Fahrzeugmaße eintragen

In den HA-Helfern:

- **Radstand** = Abstand Vorder-/Hinterachse (mm)
- **Spurweite** = Abstand linkes/rechtes Rad (mm)

Diese Maße bestimmen **zweierlei**:

1. die Anhebehöhe in der Anweisung — `Höhe = Maß × tan(Winkel)`;
2. **ab wann „eben" gilt.** Im Realitätsmodus wird die Toleranz in Zentimetern
   angegeben und über diese Maße in eine Gradzahl je Achse umgerechnet. Bei
   5 cm Toleranz, 3500 mm Radstand und 1800 mm Spurweite ergibt das 0,82° längs
   und 1,59° quer.

Grob falsche Maße verschieben also auch den Punkt, an dem das System „steht
eben, Stopp" sagt. Auf ±5 cm genau reicht völlig, geschätzte Fantasiewerte
nicht.

> Wer stattdessen mit einer festen Gradtoleranz arbeiten will, schaltet den
> **Präzisionsmodus** ein; dann gilt `CamperMaid Toleranz` für beide
> Achsen und die Fahrzeugmaße wirken nur noch auf die cm-Angabe.

## Wie lange hält eine Kalibrierung?

Solange das Gerät nicht bewegt wird, gilt sie unbegrenzt — der Nullpunkt liegt
im Flash und übersteht Stromausfall und Firmware-Update.

Eine Einschränkung gibt es dennoch: Der Nullpunkt eines Beschleunigungssensors
wandert mit der Temperatur, und ein Wohnmobil erlebt zwischen Winternacht und
Sommermittag 40 bis 50 Grad Unterschied. Wie stark sich das beim verbauten
Sensor auswirkt, misst das Gerät selbst mit — siehe
[drift_messung.md](drift_messung.md). Wer den Verdacht hat, dass die Anzeige
über die Jahreszeit wandert, findet dort die Werte, um es nachzuprüfen statt zu
vermuten.
