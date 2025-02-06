#!/bin/bash
# Skript zum Aktualisieren, Aufräumen, OS-Upgrade und anschließender Reboot-Abfrage

# Systemaktualisierung
echo "Systemaktualisierung startet ..."
sudo apt update && sudo apt upgrade -y

# Bereinigung nicht mehr benötigter Pakete und Paketcache
echo "Bereinige alte Pakete und den Paketcache ..."
sudo apt autoremove -y && sudo apt autoclean

# Überprüfe, ob ein OS-Upgrade verfügbar ist
echo "Prüfe, ob ein OS-Upgrade verfügbar ist ..."
upgrade_check=$(sudo do-release-upgrade -c 2>&1)

if echo "$upgrade_check" | grep -qi "No new release found"; then
    echo "Kein neues OS-Upgrade verfügbar."
elif echo "$upgrade_check" | grep -qi "New release"; then
    echo "Ein neues OS-Upgrade ist verfügbar."

    # Benutzerabfrage für OS-Upgrade mit Timeout von 30 Sekunden
    read -t 30 -p "Möchtest du das OS-Upgrade jetzt durchführen? (y/n): " choice

    # Falls kein Input erfolgt
    if [ $? -gt 128 ]; then
        echo -e "\nKeine Eingabe innerhalb von 30 Sekunden. OS-Upgrade wird abgebrochen."
    else
        case "$choice" in
            y|Y)
                echo "Starte OS-Upgrade ..."
                sudo do-release-upgrade
                echo "OS-Upgrade abgeschlossen."

                # Nach dem Upgrade: Abfrage für einen Reboot mit Timeout von 30 Sekunden
                read -t 30 -p "Möchtest du nun das System neu starten? (y/n): " reboot_choice
                if [ $? -gt 128 ]; then
                    echo -e "\nKeine Eingabe innerhalb von 30 Sekunden. Reboot wird abgebrochen."
                else
                    case "$reboot_choice" in
                        y|Y)
                            echo "System wird neu gestartet ..."
                            sudo reboot
                            ;;
                        *)
                            echo "Reboot wurde abgebrochen. Bitte starte dein System manuell neu, um alle Änderungen zu übernehmen."
                            ;;
                    esac
                fi
                ;;
            *)
                echo "OS-Upgrade wurde abgebrochen."
                ;;
        esac
    fi
else
    # Unerwartete Ausgabe der Upgrade-Prüfung
    echo "Die Upgrade-Prüfung lieferte ein unerwartetes Ergebnis:"
    echo "$upgrade_check"
fi
