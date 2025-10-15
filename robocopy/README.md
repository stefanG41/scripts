# 🖼️ Robocopy Backup Scripts – Bilder Backup Automatisierung

Dieses Repository enthält drei Batch-Skripte für ein automatisiertes und manuelles Backup von `D:\Bilder` auf eine externe Festplatte (`E:\backup_bilder`).

---

## 📂 Dateienübersicht

| Datei | Zweck |
|-------|-------|
| **backup_bilder_auto.bat** | Automatisches Backup beim Systemstart – läuft nur einmal pro Tag. |
| **backup_bilder_interaktiv.bat** | Interaktive Version mit Menü und Try-Run-Funktion. |
| **create_task.cmd** | Erstellt automatisch eine geplante Windows-Aufgabe für das Auto-Backup. |

---

## ⚙️ Einrichtung

### 1. Ablage
Kopiere die Dateien nach:
```
D:\BackupScripts\
```

### 2. Geplante Aufgabe erstellen
Rechtsklick → **„Als Administrator ausführen“** auf `create_task.cmd`.

Das Skript erstellt automatisch die geplante Aufgabe **Backup_Bilder_Auto**, die beim Start des Computers ausgeführt wird.

- Läuft mit höchsten Rechten.
- Führt `backup_bilder_auto.bat` aus.
- Schreibt Logdateien in `D:\ROBOCOPY_LOG_FILES\`.
- Führt das Backup **nur einmal pro Tag** aus.

---

## 🧭 Interaktive Nutzung

Starte:
```
backup_bilder_interaktiv.bat
```

Du bekommst ein Menü:

```
[1] Nur neue Dateien kopieren (Ergänzung)
[2] Spiegeln (Achtung: löscht im Ziel!)
[3] Try Run (nur anzeigen, keine Dateien kopieren)
```

- Wenn du nichts auswählst, startet nach 10 Sekunden automatisch Option [1].
- Nach jedem Lauf erscheint eine **Zusammenfassung**:
  ```
  ===== Zusammenfassung =====
  Kopiert:   Dateien: 3   Ordner: 1
  Überspr.:  Dateien: 17  Ordner: 2
  Extras:    Dateien: 0   Ordner: 0
  Gesamt:    Dateien: 20  Ordner: 3
  ===========================
  ```

---

## 🧰 Logdateien

Alle Logs werden automatisch hier gespeichert:
```
D:\ROBOCOPY_LOG_FILES\
```

Beispiel:
```
robocopy_backup_2025-10-15_21-45.log
```

---

## 🔒 Sicherheit

- Das Skript prüft vor dem Start, ob **E:** (die externe HDD) verfügbar ist.  
- Wenn das Laufwerk fehlt, wird das Backup **abgebrochen** (Fehlercode 1).  
- Das Spiegeln (`/MIR`) **löscht** Dateien auf dem Ziel, die auf der Quelle nicht mehr existieren – **Vorsicht bei dieser Option!**

---

## 🧾 Robocopy Exitcodes

Robocopy gibt einen **Exitcode** (ErrorLevel) zurück.  
Werte ≤ 3 bedeuten „erfolgreich“ – höhere Werte weisen auf Fehler hin.

| Code | Bedeutung |
|------|------------|
| 0 | Keine Dateien kopiert – Quelle und Ziel identisch |
| 1 | Dateien erfolgreich kopiert |
| 2 | Extra Dateien oder Verzeichnisse im Ziel |
| 3 | Dateien kopiert + Extras vorhanden |
| ≥4 | Fehler oder fehlgeschlagene Kopiervorgänge |

---

## 🧩 Hinweise

- Standardpfade:
  - Quelle: `D:\Bilder`
  - Ziel: `E:\backup_bilder`
- Die Pfade kannst du oben in den `.bat`-Dateien ändern.
- Wenn du möchtest, kannst du das Ganze auch für andere Verzeichnisse duplizieren (z. B. `D:\Videos` → `E:\backup_videos`).

---

## 💡 Troubleshooting

| Problem | Ursache / Lösung |
|----------|------------------|
| **"E:\ nicht gefunden"** | Externe HDD nicht eingesteckt oder anderer Laufwerksbuchstabe. |
| **"Access denied"** | Task wurde ohne Administratorrechte erstellt – bitte als Admin ausführen. |
| **"Backup läuft mehrmals täglich"** | Datum-Check-Datei (`last_run_date.txt`) wurde gelöscht – optional wiederherstellen. |
| **Kein Log erzeugt** | Schreibrechte auf `D:\ROBOCOPY_LOG_FILES` prüfen. |

---

## 🧑‍💻 Autoren

Batch-Setup & Automatisierung von **ChatGPT GPT-5** 🤖  
Erstellt für ein robustes, wiederverwendbares Backup-System auf Windows-Basis.
