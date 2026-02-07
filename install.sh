#!/bin/bash
#
# VoiceAPRS Installer
# Integrates APRS-IS messaging with AllStarLink text-to-speech
#
# Repository: https://github.com/ki9ng/voiceaprs
# License: MIT
#

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

clear
echo "============================================================"
echo "              VoiceAPRS Installer v1.0.1"
echo "============================================================"
echo ""
echo "Receive APRS messages and speak them on your AllStarLink node"
echo ""

if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run this installer as root or with sudo."
    print_info "The installer will prompt for sudo when needed."
    exit 1
fi

print_info "This installer will set up APRS-IS to AllStarLink TTS integration."
echo ""

# Check for required tools
print_info "Checking for required packages..."
REQUIRED_PACKAGES="direwolf netcat-openbsd"
MISSING_PACKAGES=""

for pkg in $REQUIRED_PACKAGES; do
    if ! dpkg -l | grep -q "^ii  $pkg "; then
        MISSING_PACKAGES="$MISSING_PACKAGES $pkg"
    fi
done

if [ -n "$MISSING_PACKAGES" ]; then
    print_warning "The following packages need to be installed:$MISSING_PACKAGES"
    read -p "Install missing packages now? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        print_info "Installing missing packages..."
        sudo apt-get update
        sudo apt-get install -y $MISSING_PACKAGES
        print_success "Packages installed successfully"
    else
        print_error "Required packages are missing. Installation cannot continue."
        exit 1
    fi
fi

# Check for GPS hardware
print_info "Checking for GPS hardware..."
USE_GPS=false

if ls /dev/ttyUSB* > /dev/null 2>&1 || ls /dev/ttyACM* > /dev/null 2>&1 || ls /dev/serial* > /dev/null 2>&1; then
    print_info "USB serial device(s) detected."
    echo ""
    read -p "Do you have a GPS dongle connected? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        USE_GPS=true
        
        if ! dpkg -l | grep -q "^ii  gpsd "; then
            print_info "Installing GPSD and related packages..."
            sudo apt-get install -y gpsd gpsd-clients
            print_success "GPSD installed successfully"
        else
            print_success "GPSD is already installed"
        fi
        
        print_info "Detecting GPS device..."
        GPS_DEVICE=""
        
        for device in /dev/ttyUSB0 /dev/ttyUSB1 /dev/ttyACM0 /dev/ttyACM1 /dev/serial0; do
            if [ -e "$device" ]; then
                print_info "Found potential GPS device: $device"
                GPS_DEVICE=$device
                break
            fi
        done
        
        if [ -z "$GPS_DEVICE" ]; then
            print_warning "Could not auto-detect GPS device."
            read -p "Enter GPS device path (e.g., /dev/ttyUSB0): " GPS_DEVICE
        fi
        
        print_info "Configuring GPSD..."
        sudo tee /etc/default/gpsd > /dev/null << GPSD_EOF
START_DAEMON="true"
GPSD_OPTIONS="-n"
DEVICES="$GPS_DEVICE"
USBAUTO="true"
GPSD_SOCKET="/var/run/gpsd.sock"
GPSD_EOF
        
        sudo systemctl enable gpsd
        sudo systemctl restart gpsd
        
        sleep 3
        
        print_info "Testing GPS connection..."
        if timeout 5 gpspipe -w -n 5 > /dev/null 2>&1; then
            print_success "GPS is working and receiving data"
            print_info "You can check GPS status anytime with: cgps -s"
        else
            print_warning "Could not verify GPS is working. You may need to configure it manually."
            print_info "Check GPS status with: cgps -s"
        fi
    else
        print_info "GPS will not be used. Position beacons will be disabled."
    fi
else
    print_info "No USB serial devices detected. GPS will not be used."
fi

# Check for ASL-TTY
print_info "Checking for ASL-TTY..."
if [ ! -f "/usr/bin/asl-tts" ]; then
    print_warning "ASL-TTY is not installed."
    print_info "ASL-TTY is required for text-to-speech on AllStarLink nodes."
    echo ""
    read -p "Install ASL-TTY now? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        print_info "Installing ASL-TTY..."
        
        # Clone to home directory to avoid temp directory permission issues
        cd ~
        
        # Remove old clone if it exists
        rm -rf asl3-tts
        
        # Disable credential prompting for this clone
        GIT_TERMINAL_PROMPT=0 git clone https://github.com/AllStarLink/asl3-tts.git 2>&1
        if [ $? -eq 0 ] && [ -d "asl3-tts" ]; then
            cd asl3-tts
            sudo make install
            if [ $? -eq 0 ]; then
                cd ~
                rm -rf asl3-tts
                print_success "ASL-TTY installed successfully"
            else
                print_error "ASL-TTY installation failed during make install"
                cd ~
                read -p "Continue without ASL-TTY? [y/N] " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    print_error "Installation cancelled."
                    exit 1
                fi
            fi
        else
            print_error "Failed to clone ASL-TTY repository."
            print_info "The repository may not exist or network issues occurred."
            print_info "You can install ASL-TTY manually later if needed."
            read -p "Continue without ASL-TTY? [y/N] " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_error "Installation cancelled."
                exit 1
            fi
        fi
    else
        print_error "ASL-TTY is required. Installation cannot continue."
        exit 1
    fi
else
    print_success "ASL-TTY is already installed"
fi

echo ""
print_info "Please provide your configuration details:"
echo ""

while true; do
    read -p "Enter your callsign (e.g., KI9NG): " CALLSIGN
    CALLSIGN=$(echo "$CALLSIGN" | tr '[:lower:]' '[:upper:]')
    if [[ $CALLSIGN =~ ^[A-Z0-9]+$ ]]; then
        break
    else
        print_error "Invalid callsign. Please use only letters and numbers."
    fi
done

while true; do
    read -p "Enter SSID for APRS-IS (e.g., 10): " SSID
    if [[ $SSID =~ ^[0-9]{1,2}$ ]] && [ "$SSID" -ge 0 ] && [ "$SSID" -le 15 ]; then
        break
    else
        print_error "Invalid SSID. Please enter a number between 0 and 15."
    fi
done

FULL_CALLSIGN="${CALLSIGN}-${SSID}"

print_info "Get your APRS-IS passcode from: https://apps.magicbug.co.uk/passcode/"
while true; do
    read -p "Enter your APRS-IS passcode for $CALLSIGN: " PASSCODE
    if [[ $PASSCODE =~ ^[0-9]{1,5}$ ]]; then
        break
    else
        print_error "Invalid passcode. Please enter a valid numeric passcode."
    fi
done

while true; do
    read -p "Enter your AllStarLink node number: " NODE_NUMBER
    if [[ $NODE_NUMBER =~ ^[0-9]+$ ]]; then
        break
    else
        print_error "Invalid node number. Please enter a numeric value."
    fi
done

read -p "Enter beacon comment (default: 'AllStar Node $NODE_NUMBER'): " BEACON_COMMENT
if [ -z "$BEACON_COMMENT" ]; then
    BEACON_COMMENT="AllStar Node $NODE_NUMBER"
fi

echo ""
print_info "Configuration Summary:"
echo "  Callsign:     $FULL_CALLSIGN"
echo "  Passcode:     $PASSCODE"
echo "  Node Number:  $NODE_NUMBER"
echo "  Beacon Text:  $BEACON_COMMENT"
echo ""
read -p "Is this correct? [Y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ -n $REPLY ]]; then
    print_error "Installation cancelled."
    exit 1
fi

print_info "Creating configuration files..."

if [ "$USE_GPS" = true ]; then
sudo tee /etc/direwolf.conf > /dev/null << EOF
# VoiceAPRS Configuration
# Generated by VoiceAPRS installer

MYCALL $FULL_CALLSIGN
ADEVICE null null
GPSD

IGSERVER noam.aprs2.net
IGLOGIN $FULL_CALLSIGN $PASSCODE

SMARTBEACONING 45 120 3 90 10 20 255
TBEACON sendto=IG delay=1 every=30 symbol="car" comment="$BEACON_COMMENT"

IGTXLIMIT 6 10
LOGDIR /var/log/direwolf
EOF
else
sudo tee /etc/direwolf.conf > /dev/null << EOF
# VoiceAPRS Configuration
# Generated by VoiceAPRS installer

MYCALL $FULL_CALLSIGN
ADEVICE null null

IGSERVER noam.aprs2.net
IGLOGIN $FULL_CALLSIGN $PASSCODE

PBEACON sendto=IG delay=1 every=60 symbol="car" comment="$BEACON_COMMENT"

IGTXLIMIT 6 10
LOGDIR /var/log/direwolf
EOF
fi

print_success "Created /etc/direwolf.conf"

sudo mkdir -p /var/log/direwolf
sudo chown $USER:$USER /var/log/direwolf
print_success "Created log directory"

sudo tee /usr/local/bin/voiceaprs-process-message.sh > /dev/null << 'SCRIPT_EOF'
#!/bin/bash
# VoiceAPRS Message Processor
# Processes incoming APRS messages and speaks them on ASL node

NODE_NUMBER="__NODE_NUMBER__"
MY_CALLSIGN="__CALLSIGN__"
APRS_PASSCODE="__PASSCODE__"

read -r line

if echo "$line" | grep -q "::"; then
   SENDER=$(echo "$line" | sed -n 's/.*\] \([^>]*\)>.*/\1/p')
   TOCALL=$(echo "$line" | sed -n 's/.*::\([^ ]*\) *.*/\1/p' | sed 's/ *$//')
   MESSAGE=$(echo "$line" | sed -n 's/.*::[^:]*:\([^{]*\).*/\1/p' | sed 's/^ *//' | sed 's/ *$//')
   MSG_ID=$(echo "$line" | sed -n 's/.*{\([0-9A-Za-z]\+\).*/\1/p')
   
   if [ "$TOCALL" = "$MY_CALLSIGN" ]; then
      echo "$(date): From $SENDER: $MESSAGE (ID: $MSG_ID)" >> /var/log/voiceaprs-messages.log
      
      if [ -n "$MSG_ID" ]; then
         ACK_MSG="ack${MSG_ID}"
         /usr/local/bin/voiceaprs-send-ack.sh "$MY_CALLSIGN" "$APRS_PASSCODE" "$SENDER" "$ACK_MSG" >> /var/log/voiceaprs-messages.log 2>&1
         echo "$(date): Sent ACK to $SENDER for message $MSG_ID" >> /var/log/voiceaprs-messages.log
      fi
      
      # Format sender callsign with spaces between each character for better TTS pronunciation
      SENDER_SPACED=$(echo "$SENDER" | sed 's/\(.\)/\1 /g' | sed 's/ $//')
      TEXT="A P R S message from ${SENDER_SPACED}. ${MESSAGE}"
      sudo /usr/bin/asl-tts -n "$NODE_NUMBER" -t "$TEXT" 2>&1 | logger -t voiceaprs
   fi
fi
SCRIPT_EOF

sudo sed -i "s/__NODE_NUMBER__/$NODE_NUMBER/g" /usr/local/bin/voiceaprs-process-message.sh
sudo sed -i "s/__CALLSIGN__/$FULL_CALLSIGN/g" /usr/local/bin/voiceaprs-process-message.sh
sudo sed -i "s/__PASSCODE__/$PASSCODE/g" /usr/local/bin/voiceaprs-process-message.sh

sudo chmod +x /usr/local/bin/voiceaprs-process-message.sh
print_success "Created message processing script"

sudo tee /usr/local/bin/voiceaprs-send-ack.sh > /dev/null << 'BASH_EOF'
#!/bin/bash
# VoiceAPRS ACK Sender (pure bash/netcat implementation)
# Usage: voiceaprs-send-ack.sh <mycall> <passcode> <to_call> <message>

if [ $# -ne 4 ]; then
    echo "Usage: voiceaprs-send-ack.sh <mycall> <passcode> <to_call> <message>" >&2
    exit 1
fi

MYCALL="$1"
PASSCODE="$2"
TO_CALL="$3"
MESSAGE="$4"

SERVER="rotate.aprs2.net"
PORT="14580"

# Pad callsign to 9 characters
TO_CALL_PADDED=$(printf "%-9s" "$TO_CALL")

# Create APRS-IS login string
LOGIN="user ${MYCALL} pass ${PASSCODE} vers VoiceAPRS 1.0.1"

# Create APRS packet
PACKET="${MYCALL}>APRS,TCPIP*::${TO_CALL_PADDED}:${MESSAGE}"

# Send to APRS-IS using netcat
{
    echo "$LOGIN"
    sleep 1
    echo "$PACKET"
    sleep 0.5
} | nc -w 3 "$SERVER" "$PORT" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "Sent: $MESSAGE to $TO_CALL"
    exit 0
else
    echo "Failed to send message" >&2
    exit 1
fi
BASH_EOF

sudo chmod +x /usr/local/bin/voiceaprs-send-ack.sh
print_success "Created ACK sender script"

sudo tee /etc/systemd/system/direwolf.service > /dev/null << EOF
[Unit]
Description=Direwolf APRS iGate
After=network.target

[Service]
Type=simple
User=$USER
ExecStart=/usr/bin/direwolf -c /etc/direwolf.conf -L /var/log/direwolf/direwolf.log
StandardOutput=append:/var/log/direwolf/direwolf_console.log
StandardError=append:/var/log/direwolf/direwolf_console.log
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

print_success "Created Direwolf systemd service"

sudo tee /etc/systemd/system/voiceaprs-monitor.service > /dev/null << EOF
[Unit]
Description=VoiceAPRS Message Monitor
After=direwolf.service network.target

[Service]
Type=simple
ExecStart=/bin/bash -c 'tail -F /var/log/direwolf/direwolf_console.log 2>/dev/null | grep --line-buffered "::" | while read line; do echo "\$line" | /usr/local/bin/voiceaprs-process-message.sh; done'
Restart=always
RestartSec=10
User=$USER
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

print_success "Created VoiceAPRS monitor service"

print_info "Configuring sudo access for asl-tts..."
SUDOERS_FILE="/etc/sudoers.d/voiceaprs"
sudo tee "$SUDOERS_FILE" > /dev/null << EOF
$USER ALL=(ALL) NOPASSWD: /usr/bin/asl-tts
EOF
sudo chmod 0440 "$SUDOERS_FILE"
print_success "Configured sudo access"

sudo touch /var/log/voiceaprs-messages.log
sudo chown $USER:$USER /var/log/voiceaprs-messages.log
print_success "Created message log file"

print_info "Enabling and starting services..."
sudo systemctl daemon-reload
sudo systemctl enable direwolf.service
sudo systemctl enable voiceaprs-monitor.service
sudo systemctl start direwolf.service
sudo systemctl start voiceaprs-monitor.service

sleep 2
if systemctl is-active --quiet direwolf.service; then
    print_success "Direwolf service is running"
else
    print_error "Direwolf service failed to start"
    sudo systemctl status direwolf.service
fi

if systemctl is-active --quiet voiceaprs-monitor.service; then
    print_success "VoiceAPRS monitor is running"
else
    print_error "VoiceAPRS monitor failed to start"
    sudo systemctl status voiceaprs-monitor.service
fi

echo ""
echo "============================================================"
echo "              Installation Complete"
echo "============================================================"
echo ""
print_success "VoiceAPRS has been installed successfully"
echo ""
print_info "Your system is configured to:"
echo "  - Beacon to APRS-IS as $FULL_CALLSIGN"
echo "  - Receive APRS messages addressed to $FULL_CALLSIGN"
echo "  - Speak received messages on AllStarLink node $NODE_NUMBER"
echo "  - Send acknowledgments to prevent message retransmission"
echo ""
print_info "Useful commands:"
echo "  - View live messages: sudo tail -f /var/log/voiceaprs-messages.log"
echo "  - Check Direwolf status: sudo systemctl status direwolf"
echo "  - Check monitor status: sudo systemctl status voiceaprs-monitor"
echo "  - View Direwolf console: sudo tail -f /var/log/direwolf/direwolf_console.log"
echo "  - Restart services: sudo systemctl restart direwolf voiceaprs-monitor"
echo ""
print_info "Test by sending an APRS message to $FULL_CALLSIGN via aprs.fi"
echo ""
print_info "For issues or updates, visit: https://github.com/ki9ng/voiceaprs"
echo ""
echo "73"
