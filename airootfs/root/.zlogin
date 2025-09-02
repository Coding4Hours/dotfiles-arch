d=$(iwctl device list | awk '/station/ {print $1; exit}')
s=$(gum input --placeholder "SSID")
p=$(gum input --password --placeholder "Passphrase")

until iwctl station "$d" connect "$s" --passphrase "$p" &>/dev/null && ping -c 1 google.com &>/dev/null && gum confirm "Internet is working?"; do
  gum style --foreground 9 "Connection failed. Retrying in 3 seconds..."
  sleep 3
done

gum style --bold --foreground 10 "Success! Internet connection confirmed."

bash .automated_script.sh
