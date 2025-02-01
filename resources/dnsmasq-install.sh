#!/bin/bash

# Step 1: Install dnsmasq
echo "Installing dnsmasq..."
sudo apt update && sudo apt install -y dnsmasq

# Step 2: Update /etc/hosts with the correct hostname
echo "Ensuring /etc/hosts has the correct hostname..."
sudo sed -i "/127.0.1.1/d" /etc/hosts
echo "127.0.1.1 $(hostname)" | sudo tee -a /etc/hosts

# Step 3: Configure dnsmasq to listen on localhost and use upstream DNS
echo "Configuring dnsmasq..."
sudo bash -c "cat > /etc/dnsmasq.conf" <<EOF
listen-address=0.0.0.0
bind-interfaces
no-resolv
server=192.19.189.10
cache-size=1000
EOF

# Step 4: Stop and disable systemd-resolved
echo "Disabling systemd-resolved..."
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
sudo rm -f /etc/resolv.conf

# Step 5: Create /etc/resolv.conf pointing to dnsmasq
echo "Setting /etc/resolv.conf..."
echo "nameserver 127.0.0.1" | sudo tee /etc/resolv.conf

# Step 6: Restart dnsmasq
echo "Restarting dnsmasq..."
sudo systemctl restart dnsmasq
sudo systemctl enable dnsmasq

# Step 7: Verify dnsmasq service status
echo "Checking dnsmasq status..."
sudo systemctl status dnsmasq | grep Active

# Step 8: Test DNS resolution
echo "Testing DNS resolution..."
dig google.com

# Step 9: Optional - Check logs for errors
echo "Checking dnsmasq logs for errors..."
sudo tail -n 10 /var/log/syslog | grep dnsmasq

echo "dnsmasq setup complete!"
