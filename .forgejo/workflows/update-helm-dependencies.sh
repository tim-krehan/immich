#!/bin/bash

# Path to your Chart.yaml
CHART_FILE="charts/immich/Chart.yaml"

# Check if yq is installed
if ! command -v yq &> /dev/null; then
    echo "📦 Installing yq..."
    sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
    sudo chmod +x /usr/bin/yq
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "📦 Installing jq..."
    sudo apt-get install jq
fi

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "📦 Installing helm..."
    apt-get install curl gpg apt-transport-https --yes
    curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
    apt-get update && apt-get install helm
    rm -rf /var/lib/apt/lists/* /etc/apt/sources.list.d/helm-stable-debian.list /usr/share/keyrings/helm.gpg
fi

# Extract dependencies and add repos
echo "🔍 Extracting Helm dependencies from $CHART_FILE..."
yq '.dependencies[]' "$CHART_FILE" --output-format json -I0 | yq --input-format json '. | "\(.name) \(.repository)"' | while read -r name repo; do
    # Check if repo is already added
    echo "➕ Adding Helm repo '$name' from $repo..."
    if ! helm repo add "$name" "$repo"; then
        echo "⚠️ Warning: Failed to add repo '$name'. Continuing anyway..."
    fi
done
echo "Listing all configured Helm Repositories..."
helm repo list
echo "🔄 Updating Helm repositories..."
helm repo update

echo "✅ All dependencies added and updated."