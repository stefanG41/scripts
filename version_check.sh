#!/bin/bash

# Aktuelle Versionen
current_wave_version="v2.8.1"
current_longhorn_version="v1.6.1"
current_metallb_version="v0.14.4"
current_helm_version="v3.14.3"

# URLs der GitHub-Releases
wave_url="https://api.github.com/repos/weaveworks/weave/releases/latest"
longhorn_url="https://api.github.com/repos/longhorn/longhorn/releases/latest"
metallb_url="https://api.github.com/repos/metallb/metallb/releases/latest"
helm_url="https://api.github.com/repos/helm/helm/releases/latest"

# Funktionen zum Abrufen der neuesten Versionen
get_latest_version() {
    curl -s $1 | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}

# Abrufen der neuesten Versionen
latest_wave_version=$(get_latest_version $wave_url)
latest_longhorn_version=$(get_latest_version $longhorn_url)
latest_metallb_version=$(get_latest_version $metallb_url)
latest_helm_version=$(get_latest_version $helm_url)

# Anzeigen der aktuellen und neuesten Versionen
echo "Weave Net:"
echo "Aktuelle Version: $current_wave_version"
echo "Neueste Version: $latest_wave_version"
echo
echo "Longhorn:"
echo "Aktuelle Version: $current_longhorn_version"
echo "Neueste Version: $latest_longhorn_version"
echo
echo "MetalLB:"
echo "Aktuelle Version: $current_metallb_version"
echo "Neueste Version: $latest_metallb_version"
echo
echo "Helm:"
echo "Aktuelle Version: $current_helm_version"
echo "Neueste Version: $latest_helm_version"
