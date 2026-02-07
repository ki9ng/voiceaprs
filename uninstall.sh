#!/bin/bash
#
# VoiceAPRS Uninstaller
#

set -e

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
echo "              VoiceAPRS Uninstaller"
echo "============================================================"
echo ""

print_warning "This will remove VoiceAPRS integration."
echo ""
echo "The following will be removed:"
echo "  - Direwolf and message monitor services"
echo "  - VoiceAPRS processing scripts"
echo "  - Configuration files"
echo "  - Log files (optional)"
echo ""
print_info "The following will NOT be removed:"
echo "  - Direwolf package"
echo "  - GPSD package"
echo "  - ASL-TTY"
echo ""
read -p "Are you sure you want to continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Uninstallation cancelled."
    exit 0
fi

print_info "Stopping services..."
sudo systemctl stop direwolf 2>/dev/null || true
sudo systemctl stop voiceaprs-monitor 2>/dev/null || true

print_info "Disabling services..."
sudo systemctl disable direwolf 2>/dev/null || true
sudo systemctl disable voiceaprs-monitor 2>/dev/null || true

print_info "Removing service files..."
sudo rm -f /etc/systemd/system/direwolf.service
sudo rm -f /etc/systemd/system/voiceaprs-monitor.service
sudo systemctl daemon-reload
print_success "Service files removed"

print_info "Removing scripts..."
sudo rm -f /usr/local/bin/voiceaprs-process-message.sh
sudo rm -f /usr/local/bin/voiceaprs-send-ack.sh
print_success "Scripts removed"

print_info "Removing configuration files..."
sudo rm -f /etc/direwolf.conf
sudo rm -f /etc/sudoers.d/voiceaprs
print_success "Configuration files removed"

echo ""
read -p "Remove log files? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Removing log files..."
    sudo rm -rf /var/log/direwolf
    sudo rm -f /var/log/voiceaprs-messages.log
    print_success "Log files removed"
else
    print_info "Log files preserved in /var/log/direwolf and /var/log/voiceaprs-messages.log"
fi

echo ""
read -p "Remove the voiceaprs directory? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Removing voiceaprs directory..."
    cd ~
    rm -rf voiceaprs
    print_success "Repository directory removed"
fi

if [ -f "/etc/default/gpsd" ]; then
    echo ""
    read -p "Remove GPSD configuration and package? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Removing GPSD..."
        sudo systemctl stop gpsd 2>/dev/null || true
        sudo systemctl disable gpsd 2>/dev/null || true
        sudo rm -f /etc/default/gpsd
        sudo apt remove -y gpsd gpsd-clients
        sudo apt autoremove -y
        print_success "GPSD removed"
    fi
fi

echo ""
read -p "Remove installed packages (direwolf, netcat-openbsd)? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_warning "This will remove Direwolf and netcat-openbsd"
    print_warning "Only do this if you are not using these packages for anything else"
    read -p "Are you sure? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Removing packages..."
        sudo apt remove -y direwolf netcat-openbsd
        sudo apt autoremove -y
        print_success "Packages removed"
    fi
fi

echo ""
print_success "Uninstallation complete"
echo ""
print_info "ASL-TTY was not modified and remains installed."
print_info "If you need to remove ASL-TTY, refer to its documentation."
echo ""
echo "73"
