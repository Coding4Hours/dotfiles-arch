# Get the wireless device name, exit if not found
d=$(iwctl device list | awk '/station/ {print $1; exit}')
if [ -z "$d" ]; then
  gum style --foreground 9 "Error: No wireless station device found."
  exit 1
fi

# Set up a trap to handle Ctrl+C during the ping command
# This function will be called when the user interrupts the ping
handle_interrupt() {
  # The 'gum confirm' command will replace the terminated ping process
  # We use a global variable to communicate the result back to the main loop
  if gum confirm "Did the connection work?"; then
    USER_CONFIRMED_SUCCESS=true
  else
    USER_CONFIRMED_SUCCESS=false
  fi
}

# Main loop that continues until the user confirms a working connection
while true; do
  # --- Network Selection ---
  gum spin --spinner dot --title "Scanning for networks..." -- iwctl station "$d" scan
  
  # Get the list of networks, clean up the output, and remove duplicates
  mapfile -t networks < <(iwctl station "$d" get-networks | awk 'NR > 4 {print $2}' | sort -u)
  
  # Present choices to the user, including a manual entry option
  s=$(gum choose "${networks[@]}" "Manually Enter SSID")
  
  # If manual entry is chosen, prompt for the SSID
  if [[ "$s" == "Manually Enter SSID" ]]; then
    s=$(gum input --placeholder "SSID")
  fi
  
  # Exit if no SSID was chosen or entered
  if [ -z "$s" ]; then
    gum style --foreground 9 "No network selected. Exiting."
    exit 0
  fi
  
  # --- Connection Attempt ---
  p=$(gum input --password --placeholder "Passphrase for $s")
  
  # Try to connect
  if ! gum spin --spinner dot --title "Connecting to $s..." -- iwctl station "$d" connect "$s" --passphrase "$p"; then
    gum style --foreground 9 "Connection failed. Please try again."
    sleep 2
    continue # Go back to the start of the loop
  fi
  
  # --- Ping and Confirmation ---
  gum style --bold --foreground 10 "Connection established! Starting ping..."
  echo "Press Ctrl+C to stop the ping and confirm the connection."
  sleep 1
  
  # Set the trap to call our function ONLY for the next command (the ping)
  trap handle_interrupt SIGINT
  
  # Reset confirmation status before the ping
  USER_CONFIRMED_SUCCESS=false
  
  # Start a continuous ping. This command will run until Ctrl+C is pressed.
  ping google.com
  
  # After ping is interrupted, disable the trap to prevent it from firing again
  trap - SIGINT
  
  # Check the result from the handle_interrupt function
  if [ "$USER_CONFIRMED_SUCCESS" = true ]; then
    break # Exit the main 'while' loop
  else
    gum style --foreground 9 "Connection not confirmed. Restarting process..."
    iwctl station "$d" disconnect >/dev/null 2>&1
    sleep 2
  fi
done

gum style --bold --padding "1 2" --border double --border-foreground 10 "Success! Internet connection confirmed."

bash .automated_script.sh
