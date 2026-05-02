#!/bin/bash
# gen_bucket.sh

# This script generates the Scoop bucket manifest for the File Conversor application.

set -Eeuo pipefail # Exit on error, undefined variable, or error in a pipeline

# trap errors and print a message
trap 'echo "Error occurred at line $LINENO while executing: $BASH_COMMAND"' ERR

VERSION_SEMVER=$(echo "$VERSION" | sed 's/^v//') # Remove leading 'v' if present

OUTPUT_BUCKET="bucket/${APP_NAME}.json"

INSTALLER_NAME="file_conversor-${VERSION}-Win_x64-Installer.exe"
RELEASE_URL="${HOMEPAGE}/releases/download/${VERSION}"

echo "Generating manifest ..."
echo
echo "  ENV: "
echo "    APP_NAME: ${APP_NAME}"
echo "    VERSION: ${VERSION}"
echo "    DESCRIPTION: ${DESCRIPTION}"
echo "    LICENSE: ${LICENSE}"
echo "    HOMEPAGE: ${HOMEPAGE}"
echo "    CHECKSUMS_FILE: ${CHECKSUMS_FILE}"
echo "    INSTALLER_NAME: ${INSTALLER_NAME}"
echo 

echo "  1. Downloading checksums ..."
CHECKSUM_HASH=$(curl -sL "${RELEASE_URL}/${CHECKSUMS_FILE}" | grep "$INSTALLER_NAME" | awk '{print $1}')
echo "      CHECKSUM_HASH: ${CHECKSUM_HASH}"
echo

echo "  2. Creating manifest JSON file at ${OUTPUT_BUCKET} ..."
mkdir -p $(dirname "$OUTPUT_BUCKET")
cat > "$OUTPUT_BUCKET" <<EOL
{
    "version": "${VERSION_SEMVER}",
    "description": "${DESCRIPTION}",
    "homepage": "${HOMEPAGE}",
    "license": "${LICENSE}",
    "url": "${RELEASE_URL}/${INSTALLER_NAME}",
    "hash": "${CHECKSUM_HASH}",    
    "bin": [
        "${APP_NAME}.bat"
    ],
    "pre_install": [
        "\$exePath = Get-ChildItem -Path \"\$dir\" -Filter *-Installer.exe  | Select-Object -ExpandProperty FullName",
        "Start-Process -FilePath \"\$exePath\" -ArgumentList \"/DIR=\$dir\", \"/CURRENTUSER\", \"/SUPPRESSMSGBOXES\", \"/VERYSILENT\", \"/NORESTART\", \"/SP-\" -Wait",
        "if (!(Test-Path \"\$dir\\\\file_conversor*\")) {throw \"Install failed: executable file_conversor not found\"}",
        "Remove-Item -Path \"\$exePath\""
    ],
    "pre_uninstall": [
        "\$exePath = Get-ChildItem -Path \"\$dir\" -Filter unins000.exe  | Select-Object -ExpandProperty FullName",
        "Start-Process -FilePath \"\$exePath\" -ArgumentList \"/SUPPRESSMSGBOXES\", \"/VERYSILENT\", \"/NORESTART\", \"/SP-\" -Wait",
        "if (Test-Path \"\$dir\\\\file_conversor*\") {throw \"Uninstall failed: executable still exists\"}"
    ],
    "checkver": {
        "github": "${HOMEPAGE}"
    },
    "autoupdate": {
        "url": "${HOMEPAGE}/releases/download/v\$version/file_conversor-v\$version-Win_x64-Installer.exe",
        "hash": {
            "url": "${HOMEPAGE}/releases/download/v\$version/checksum.sha256"
        }
    }
}
EOL
echo

echo "  3. Manifest content:"
cat "$OUTPUT_BUCKET"

echo
echo "Generated manifest ... Done!"
echo