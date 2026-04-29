#!/bin/bash

# Version 0.3, 2026APR29

# define the additional WHAT is this notification about
WHAT=" - Updates found"

# Do not touch below

. /root/scripts/functions/send_server_updates_notification_email_tg

# Define the output file and temporary files
OUTPUT_FILE="/tmp/current_server_updates_notification"
APT_TEMP_FILE="/tmp/server-temp_upgrade.txt"
FLATPAK_TEMP_FILE="/tmp/server-temp_flatpak_upgrade.txt"

# Ensure OUTPUT_FILE is empty or create it if it doesn't exist
> $OUTPUT_FILE

write_section_header() {
    local label="$1"
    echo "Server: [ $(hostname) ] $label updates:" >> $OUTPUT_FILE
    echo "..." >> $OUTPUT_FILE
}

# --- APT check ---
apt-get update

# Simulate an upgrade and filter out upgradable packages, excluding kept-back packages
apt-get upgrade -s | grep '^Inst' | cut -d ' ' -f 2 > $APT_TEMP_FILE

if [ -s $APT_TEMP_FILE ]; then
    APT_OUTPUT=$(cat $APT_TEMP_FILE)
    if [[ ! -z "$APT_OUTPUT" ]]; then
        write_section_header "apt"
        echo "$APT_OUTPUT" >> $OUTPUT_FILE
        echo "" >> $OUTPUT_FILE
    fi
else
    echo "No apt updates, or only kept-back packages are available."
fi

# --- Flatpak check ---
if command -v flatpak >/dev/null 2>&1; then
    # Refresh remote metadata and list pending updates by ref (application ID)
    flatpak remote-ls --updates --columns=ref 2>/dev/null > $FLATPAK_TEMP_FILE

    if [ -s $FLATPAK_TEMP_FILE ]; then
        FLATPAK_OUTPUT=$(cat $FLATPAK_TEMP_FILE)
        if [[ ! -z "$FLATPAK_OUTPUT" ]]; then
            write_section_header "flatpak"
            echo "$FLATPAK_OUTPUT" >> $OUTPUT_FILE
            echo "" >> $OUTPUT_FILE
        fi
    else
        echo "No flatpak updates available."
    fi
else
    echo "flatpak not installed; skipping flatpak update check."
fi

# Clean up: Remove the temporary files
rm -f $APT_TEMP_FILE $FLATPAK_TEMP_FILE

# Check and send email
send_server_updates_notification_email_tg

echo "Updates check complete. Results saved in $OUTPUT_FILE"
