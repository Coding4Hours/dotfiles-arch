while true; do
  gum style --border normal --margin "1" --padding "1 2" --border-foreground 212 "Starting iwctl... " \
  "Use 'station wlan0 connect YOUR_SSID' to connect." \
  "Type 'exit' or 'quit' when you are done."

  iwctl

  gum spin --spinner dot --title "Pinging google.com... (Press Ctrl+C to stop)" -- \
  ping -c 5 google.com

  if gum confirm "Did you see actual ping output?"; then
    gum style --foreground 2 "✅ Ping successful. Network is configured."
    break
  else
    gum style --foreground 1 "🔁 Restarting the process..."
    sleep 2
  fi
done

bash .automated_script.sh
