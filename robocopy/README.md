# 💾 Robocopy Backup System – Automatisch & Interaktiv

Dieses Projekt automatisiert das Backup von **D:\Bilder** auf eine externe Festplatte **E:\backup_bilder**
mithilfe von **Robocopy**.  
Es kombiniert eine automatische Sicherung beim Systemstart mit einer manuellen, interaktiven Option.

---

## 🧩 Dateien

| Datei | Beschreibung |
|-------|---------------|
| `backup_bilder_hybrid_v5_no_calls.bat` | Hauptskript – kombiniert automatischen und manuellen Modus (mit Popups & Logfiles) |
| `create_task.cmd` | Erstellt eine geplante Aufgabe „Backup_Bilder_Auto“ beim Systemstart |
| `delete_task.cmd` | Entfernt alle zugehörigen geplanten Backup-Aufgaben |
| `D:\ROBOCOPY_LOG_FILES\` | Ablageort für alle Logdateien |

---

## ⚙️ Funktionsweise

### 🔁 Automatischer Modus
Wird das Skript **ohne Parameter** ausgeführt, startet es automatisch beim Systemstart:

1. Wartet bis zu **2 Minuten** auf die externe HDD `E:\`.
2. Zeigt ein **Popup**, falls die HDD noch nicht verbunden ist.
3. Führt ein **inkrementelles Backup** (nur neue Dateien) durch.
4. Schreibt ein Log in `D:\ROBOCOPY_LOG_FILES\robocopy_backup_YYYY-MM-DD_HH-MM.log`.
5. Führt **maximal einmal pro Tag** ein Backup aus.

Beispiel (für geplanten Task):
```cmd
cmd.exe /c "D:\BackupScripts\backup_bilder_hybrid_v5_no_calls.bat"
```

---

### 🧭 Manueller Modus
Wenn das Skript mit dem Parameter `manual` gestartet wird, erscheint ein Menü:

```cmd
D:\BackupScripts\backup_bilder_hybrid_v5_no_calls.bat manual
```

**Optionen:**
1. Ergänzung (nur neue Dateien)
2. Spiegeln (löscht überflüssige Dateien)
3. Try Run (Trockenlauf, zeigt nur Änderungen)

Nach jeder Ausführung folgt eine **Zusammenfassung** mit:
- Kopierten Dateien/Ordnern
- Übersprungenen Dateien
- Extras (nicht passende Dateien)
- Gesamtstatistik

---

## 🪟 Popups

- Beim Start:  
  💡 *„Bitte HDD E: einschalten/verbinden. Es wird bis zu 2 Minuten gewartet…“*
- Wenn nach 2 Minuten keine HDD erkannt wurde:  
  ❌ *„FEHLER: Keine HDD gefunden. Kein Backup durchgeführt!“*

Diese Popups erscheinen auch, wenn das Skript im Hintergrund (über den Taskplaner) läuft.

---

## 🗓️ Aufgabenplanung

### 🔧 Aufgabe erstellen
Führe als **Administrator** aus:
```cmd
create_task.cmd
```
Erstellt:
- Task: `Backup_Bilder_Auto`
- Trigger: Beim Systemstart (1 Minute Verzögerung)
- Aktion: Startet das Backup automatisch
- Sichtbar (zeigt Popups, wenn Benutzer angemeldet ist)

### 🧹 Aufgabe löschen
Führe als **Administrator** aus:
```cmd
delete_task.cmd
```
Entfernt:
- `Backup_Bilder_Auto`
- `Backup_Bilder_Auto_Silent` (optional)

---

## 📁 Logs & Status

- Logdateien liegen in `D:\ROBOCOPY_LOG_FILES`
- Beispiel:
  ```
  D:\ROBOCOPY_LOG_FILES\robocopy_backup_2025-10-15_19-47.log
  ```
- Jede Ausführung enthält eine Datum-/Zeitmarke und Robocopy-Statistik.

---

## 💡 Hinweise

- Wenn du die HDD austauschst oder den Buchstaben änderst, passe `DST=` im Skript an.  
- Das Skript ist kompatibel mit **deutschem und englischem Robocopy-Output**.  
- Mit `set DEBUG=1` am Anfang des Skripts bleibt das Fenster nach Abschluss geöffnet.

---

**Autor:** Automatisiertes Setup via ChatGPT (2025)  
**Kompatibel mit:** Windows 10 / 11  
