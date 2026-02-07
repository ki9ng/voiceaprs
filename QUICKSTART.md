# Quick Start Guide

Get up and running with VoiceAPRS in under 10 minutes.

## Prerequisites

- Raspberry Pi (or Linux system) with internet connection
- AllStarLink node configured and working
- Amateur radio license and callsign
- APRS-IS passcode (get from https://apps.magicbug.co.uk/passcode/)

## Installation (5 minutes)

### One-Line Installation

```bash
wget https://github.com/ki9ng/voiceaprs/archive/refs/heads/master.tar.gz && tar -xzf master.tar.gz && cd voiceaprs-master && chmod +x install.sh && ./install.sh
```

This downloads, extracts, and runs the installer - no git required!

The installer will ask for:
- Callsign: Your call (e.g., KI9NG)
- SSID: Number 0-15 (suggest 10 for gateway)
- Passcode: Get from https://apps.magicbug.co.uk/passcode/
- Node Number: Your AllStarLink node number
- Beacon Text: Optional comment for beacons

GPS Users: If you have a USB GPS dongle, say YES when prompted.

### Step 4: Wait for Services to Start

The installer will:
- Install dependencies
- Configure Direwolf
- Set up message monitoring
- Start services

## Testing (2 minutes)

### Send Yourself a Test Message

1. Go to https://aprs.fi
2. Search for your callsign (e.g., KI9NG-10)
3. Click "Send message" button
4. Type a test message: "Hello World"
5. Click "Send message"

### What Should Happen

Within 30 seconds:
1. Your AllStarLink node should speak: "A P R S message from [sender]. Hello World"
2. Message logged to /var/log/voiceaprs-messages.log
3. Acknowledgment sent back to sender

### Check if It Worked

```bash
# Watch message log
sudo tail -f /var/log/voiceaprs-messages.log

# Check services are running
sudo systemctl status direwolf
sudo systemctl status voiceaprs-monitor
```

## Troubleshooting

### No audio on node?

```bash
# Test TTS directly
sudo /usr/bin/asl-tts -n YOUR_NODE_NUMBER -t "Test message"
```

### Not receiving messages?

```bash
# Check Direwolf connection
sudo tail -f /var/log/direwolf/direwolf_console.log | grep "connected"

# Should see: "Now connected to IGate server..."
```

### Services not running?

```bash
# Restart everything
sudo systemctl restart direwolf voiceaprs-monitor

# Check status
sudo systemctl status direwolf voiceaprs-monitor
```

## What's Next?

- Track your station: Visit aprs.fi to see your beacons
- Mobile operation: Add GPS for position tracking
- Customize beacons: Edit /etc/direwolf.conf
- View all messages: sudo tail -f /var/log/voiceaprs-messages.log

## Quick Commands

```bash
# View live messages
sudo tail -f /var/log/voiceaprs-messages.log

# Restart services
sudo systemctl restart direwolf voiceaprs-monitor

# Check what's happening
sudo journalctl -u voiceaprs-monitor -f

# Uninstall
./uninstall.sh
```

## Need Help?

Check the full README.md for detailed documentation or open an issue on GitHub.

73
