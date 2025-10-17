# 💾 Robocopy Backup System – Profil & Bilder

Dieses Projekt enthält zwei separate **Backup-Jobs** für Windows, um das Benutzerprofil und den Bilder‑Ordner getrennt zu sichern.
Beide Skripte sind so benannt, dass sie auf mehreren PCs synchron gehalten werden können (z. B. über GitHub‑Sync oder automatisierte Aufgabenplanung).

---

## 🧩 Dateien

| Datei                 | Beschreibung                                                                               |
| --------------------- | ------------------------------------------------------------------------------------------ |
| `backup_profile.cmd`  | Sichert das gesamte Benutzerprofil **ohne** den Ordner *Bilder* (`%USERPROFILE%\Pictures`) |
| `backup_pictures.cmd` | Sichert **nur** den Ordner *Bilder* (`%USERPROFILE%\Pictures`)                             |

> Beide Skripte sind **SAFE‑Backups**: Es werden keine Dateien im Ziel gelöscht.

---

## ⚙️ Funktionsweise

### 🧱 `backup_profile.cmd`

1. Liest `%USERPROFILE%` als Quelle ein.
2. Nutzt `robocopy` mit Standard‑Optionen:

   ```cmd
   robocopy "%USERPROFILE%" "D:\Backup_Profil\%USERNAME%" /E /COPY:DAT /DCOPY:T /R:2 /W:2 /FFT /XN /XO /XJ /MT:8 ^
     /XD "%USERPROFILE%\Pictures" ^
     /LOG+:"D:\Backup_Profil\%USERNAME%\_logs\backup_profile.log" /TEE
   ```
3. Erstellt ein Logfile mit Zeitstempel.
4. Führt keine Löschungen durch.

### 🖼️ `backup_pictures.cmd`

1. Liest `%USERPROFILE%\Pictures` als Quelle ein.
2. Nutzt dieselben Optionen wie oben (ohne Ausschluss):

   ```cmd
   robocopy "%USERPROFILE%\Pictures" "D:\Backup_Pictures\%USERNAME%" /E /COPY:DAT /DCOPY:T /R:2 /W:2 /FFT /XN /XO /XJ /MT:8 ^
     /LOG+:"D:\Backup_Pictures\%USERNAME%\_logs\backup_pictures.log" /TEE
   ```
3. Trennt so die Bildsicherung vom restlichen Profil.

---

## 🗓️ Aufgabenplanung

### 🔧 Aufgabe erstellen

Um die Jobs automatisch auszuführen, werden zwei geplante Aufgaben empfohlen:

```cmd
schtasks /Create /TN "Backup_Profile" /TR "C:\Scripts\robocopy\backup_profile.cmd" ^
  /SC DAILY /ST 18:30 /RL HIGHEST

schtasks /Create /TN "Backup_Pictures" /TR "C:\Scripts\robocopy\backup_pictures.cmd" ^
  /SC WEEKLY /D SUN /ST 19:00 /RL HIGHEST
```

* **`Backup_Profile`**: täglich / werktags
* **`Backup_Pictures`**: wöchentlich (z. B. Sonntag)

> ⚠️ Die Tasknamen müssen exakt den Skriptnamen entsprechen, damit der Git‑Sync korrekt funktioniert.

### 🧹 Aufgabe löschen

Falls nötig:

```cmd
schtasks /Delete /TN "Backup_Profile" /F
schtasks /Delete /TN "Backup_Pictures" /F
```

---

## 📁 Logs & Status

* Logdateien befinden sich in Unterordnern `_logs` im jeweiligen Zielpfad.
* Beispiel:

  ```
  D:\Backup_Profil\USERNAME\_logs\backup_profile.log
  D:\Backup_Pictures\USERNAME\_logs\backup_pictures.log
  ```
* Logs werden mit `/LOG+` **append** geschrieben (alten Verlauf behalten).
* `/TEE` zeigt Fortschritt gleichzeitig in der Konsole.

---

## 💡 Hinweise

* Skripte sind universell einsetzbar – keine Registry‑ oder Pfadabhängigkeit.
* Keine Löschungen → sicher für Desktop‑/Laptop‑Umgebungen.
* Kompatibel mit **Windows 10 / 11**.
* Optional: Anpassung des Zielpfads (`DST=`) bei anderen Laufwerksbuchstaben.
* Falls „(RESOLVED)“-Ordner auftauchen, stammen sie von Git‑Merges, **nicht** von diesen Skripten.

---

**Autor:** Automatisiertes Setup via ChatGPT (2025)
**Kompatibel mit:** Windows 10 / 11
