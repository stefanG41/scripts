#!/bin/bash
# Skript: update_cleanup_osupgrade_auto.sh
# Funktion: Systemaktualisierung, Bereinigung, OS-Upgrade (mit allen Rückfragen automatisch mit "ja" beantwortet)
# und anschließender automatischer Neustart (nach 30 Sekunden Wartezeit).

echo "Starte Update- und Upgrade-Prozess – alle Fragen werden automatisch mit 'ja' beantwortet."

# 1. System aktualisieren
echo "Aktualisiere Paketlisten und installiere verfügbare Updates..."
sudo apt update && sudo apt upgrade -y

# 2. Alte Pakete und Paketcache bereinigen
echo "Entferne veraltete Pakete und bereinige den Cache..."
sudo apt autoremove -y && sudo apt autoclean

# 3. Prüfe, ob ein OS-Upgrade verfügbar ist
echo "Prüfe auf ein verfügbares OS-Upgrade..."
upgrade_check=$(sudo do-release-upgrade -c 2>&1)

if echo "$upgrade_check" | grep -qi "No new release found"; then
    echo "Kein neues OS-Upgrade verfügbar."
elif echo "$upgrade_check" | grep -qi "New release"; then
    echo "Es wurde ein neues OS-Upgrade gefunden."
    echo "Das Upgrade wird jetzt automatisch durchgeführt (alle Rückfragen werden mit 'ja' beantwortet)."
    # Das non-interaktive Frontend sorgt dafür, dass alle Eingaben automatisch mit "ja" beantwortet werden.
    sudo do-release-upgrade -f DistUpgradeViewNonInteractive
    echo "OS-Upgrade abgeschlossen."

    # 4. Automatischer Neustart
    echo "Das System wird in 30 Sekunden automatisch neu gestartet."
    sleep 30
    sudo reboot
else
    echo "Unerwartete Ausgabe bei der Upgrade-Prüfung:"
    echo "$upgrade_check"
fi
