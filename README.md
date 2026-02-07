# VoiceAPRS

Receive APRS messages via APRS-IS and have them spoken on your AllStarLink node using text-to-speech.

## Features

- Text-to-Speech Integration: APRS messages are spoken on your AllStarLink node
- APRS-IS Gateway: Connects to APRS-IS network (no radio required)
- Automatic Acknowledgments: Sends ACKs to prevent message retransmission
- GPS Smart Beaconing: Optional GPS integration with intelligent beacon timing
- Message Logging: All received messages are logged for reference
- Easy Installation: Automated installer handles all configuration

## Requirements

- Raspberry Pi (or other Linux system) running Debian/Ubuntu
- AllStarLink node (local or remote)
- Valid amateur radio callsign
- APRS-IS passcode (get from https://apps.magicbug.co.uk/passcode/)
- Internet connection
- (Optional) USB GPS dongle for position beaconing

## Quick Start

### One-Line Installation

```bash
wget https://github.com/ki9ng/voiceaprs/archive/refs/heads/master.tar.gz && tar -xzf master.tar.gz && cd voiceaprs-master && chmod +x install.sh && ./install.sh
```

This will download the latest version, extract it, and run the installer.

Alternatively, if you have git configured:
```bash
git clone https://github.com/ki9ng/voiceaprs.git && cd voiceaprs && chmod +x install.sh && ./install.sh
```

### What the Installer Does

The installer will:
- Check for and install required dependencies (Direwolf, Python3, netcat)
- Detect and configure GPS hardware if present
- Install GPSD if GPS is detected
- Install ASL-TTY if not already present
- Prompt you for configuration details (callsign, passcode, node number)
- Set up Direwolf for APRS-IS
- Configure message monitoring and TTS
- Enable and start all services

### 3. Test

Send an APRS message to your callsign using:
- aprs.fi (click on your station, then "Send message")
- APRSdroid mobile app
- Any other APRS messaging client

You should hear the message spoken on your AllStarLink node.

## Configuration

During installation, you will be prompted for:

| Parameter | Description | Example |
|-----------|-------------|---------|
| Callsign | Your amateur radio callsign | KI9NG |
| SSID | APRS SSID (0-15) | 10 |
| Passcode | APRS-IS passcode for your callsign | 12345 |
| Node Number | Your AllStarLink node number | 604011 |
| Beacon Comment | Text sent with position beacons | AllStar Node 604011 |

### APRS-IS Passcode

Get your passcode from: https://apps.magicbug.co.uk/passcode/

Important: Use your base callsign (without SSID) when generating the passcode.

### Recommended SSIDs

Common APRS SSID conventions:
- -9: Mobile station
- -10: Internet gateway
- -5: Other tracker
- -7: Handheld
- -1 to -15: General use

## GPS Support

The installer will automatically detect USB GPS dongles and offer to configure them.

Supported GPS devices:
- Most USB GPS receivers (BU-353, VK-162, etc.)
- Devices that appear as /dev/ttyUSB* or /dev/ttyACM*

If GPS is configured:
- Smart beaconing will be enabled (beacons based on speed and direction)
- Your position will be transmitted and visible on aprs.fi

Without GPS:
- Status beacons will be sent periodically (no position data)

## Usage

### Monitoring

Watch for incoming messages:
```bash
sudo tail -f /var/log/voiceaprs-messages.log
```

View Direwolf console output:
```bash
sudo tail -f /var/log/direwolf/direwolf_console.log
```

### Service Management

Check service status:
```bash
sudo systemctl status direwolf
sudo systemctl status voiceaprs-monitor
```

Restart services:
```bash
sudo systemctl restart direwolf voiceaprs-monitor
```

Stop services:
```bash
sudo systemctl stop direwolf voiceaprs-monitor
```

View service logs:
```bash
sudo journalctl -u direwolf -f
sudo journalctl -u voiceaprs-monitor -f
```

### Manual Configuration

All configuration files are stored in standard locations:

- Direwolf Config: /etc/direwolf.conf
- Message Processor: /usr/local/bin/voiceaprs-process-message.sh
- ACK Sender: /usr/local/bin/voiceaprs-send-ack.sh
- Services: /etc/systemd/system/direwolf.service and voiceaprs-monitor.service
- Message Log: /var/log/voiceaprs-messages.log
- Direwolf Logs: /var/log/direwolf/

After making manual changes:
```bash
sudo systemctl daemon-reload
sudo systemctl restart direwolf voiceaprs-monitor
```

## Troubleshooting

### No messages received

1. Check that Direwolf is connected to APRS-IS:
   ```bash
   sudo tail -f /var/log/direwolf/direwolf_console.log | grep "Now connected"
   ```

2. Verify your APRS-IS credentials:
   ```bash
   sudo cat /etc/direwolf.conf | grep IGLOGIN
   ```

3. Test with aprs.fi - send a message and watch the logs

### TTS not working

1. Verify ASL-TTY is installed:
   ```bash
   which asl-tts
   ```

2. Test TTS manually:
   ```bash
   sudo /usr/bin/asl-tts -n YOUR_NODE_NUMBER -t "Test message"
   ```

3. Check sudo permissions:
   ```bash
   sudo cat /etc/sudoers.d/voiceaprs
   ```

4. Check the message monitor logs:
   ```bash
   sudo journalctl -u voiceaprs-monitor -f
   ```

### Messages received but not spoken

1. Check that the callsign matches in the script:
   ```bash
   grep MY_CALLSIGN /usr/local/bin/voiceaprs-process-message.sh
   ```

2. Verify message format in logs:
   ```bash
   sudo tail -f /var/log/voiceaprs-messages.log
   ```

3. Test the processing script manually:
   ```bash
   echo '[0] TEST>APRS,TCPIP*::YOUR-CALL:Test message{1' | /usr/local/bin/voiceaprs-process-message.sh
   ```

### GPS not working

1. Check GPS device is connected:
   ```bash
   ls -l /dev/ttyUSB* /dev/ttyACM*
   ```

2. Test GPS with cgps:
   ```bash
   cgps -s
   ```

3. Check GPSD status:
   ```bash
   sudo systemctl status gpsd
   gpsmon
   ```

4. Restart GPSD:
   ```bash
   sudo systemctl restart gpsd
   ```

### Acknowledgments not sent

1. Check script permissions:
   ```bash
   ls -l /usr/local/bin/voiceaprs-send-ack.sh
   ```

2. Test ACK script manually:
   ```bash
   /usr/local/bin/voiceaprs-send-ack.sh YOUR-CALL PASSCODE TEST-CALL "ack1"
   ```

3. Check for network connectivity to APRS-IS:
   ```bash
   nc -zv rotate.aprs2.net 14580
   ```

## Uninstallation

To completely remove VoiceAPRS and all components it installed:

```bash
# Stop and disable services
sudo systemctl stop direwolf voiceaprs-monitor
sudo systemctl disable direwolf voiceaprs-monitor

# Remove service files
sudo rm -f /etc/systemd/system/direwolf.service
sudo rm -f /etc/systemd/system/voiceaprs-monitor.service
sudo systemctl daemon-reload

# Remove scripts and config
sudo rm -f /usr/local/bin/voiceaprs-process-message.sh
sudo rm -f /usr/local/bin/voiceaprs-send-ack.sh
sudo rm -f /etc/direwolf.conf
sudo rm -f /etc/sudoers.d/voiceaprs

# Remove logs
sudo rm -rf /var/log/direwolf
sudo rm -f /var/log/voiceaprs-messages.log

# Remove the cloned repository
cd ~
rm -rf voiceaprs

# Remove installed packages (if you don't need them for other purposes)
sudo apt remove direwolf netcat-openbsd
sudo apt autoremove

# If you installed GPSD for GPS support
sudo systemctl stop gpsd
sudo systemctl disable gpsd
sudo rm -f /etc/default/gpsd
sudo apt remove gpsd gpsd-clients
sudo apt autoremove
```

Note: ASL-TTY will NOT be removed as it may be used by other AllStarLink applications. If you need to remove ASL-TTY, refer to its documentation.

## How It Works

1. Direwolf connects to the APRS-IS network and logs all traffic to console
2. voiceaprs-monitor service tails the Direwolf console log and filters for APRS messages
3. voiceaprs-process-message.sh parses each message to extract sender, recipient, and text
4. If the message is addressed to your callsign:
   - The message is logged to /var/log/voiceaprs-messages.log
   - An acknowledgment is sent back via voiceaprs-send-ack.py (if message has an ID)
   - The message is spoken on your AllStarLink node via asl-tts

## Message Format

APRS messages received will be in the format:
```
[timestamp] SENDER>APRS,TCPIP*,qAC,SERVER::YOUR-CALL:Message text{ID
```

Spoken messages will be:
```
"A P R S message from S E N D E R. Message text"
```

The callsign is spelled out letter by letter for better TTS clarity.

## Advanced Configuration

### Custom Beacon Symbols

Edit /etc/direwolf.conf and change the symbol parameter in the TBEACON or PBEACON line.

Common symbols:
- car - Car (default)
- jeep - Jeep
- truck - Truck
- van - Van
- house - House/Fixed Station
- /[ - Jogger
- /b - Bike

See full list: http://www.aprs.org/symbols.html

### Adjust Beacon Intervals

For GPS-enabled systems (SMARTBEACONING):
```
SMARTBEACONING fast_speed fast_rate slow_speed slow_rate turn_time turn_angle turn_slope
```

For fixed stations (PBEACON):
```
PBEACON sendto=IG delay=1 every=60 symbol="house" comment="Fixed Station"
```

### Message Filtering

To ignore messages from certain senders, edit /usr/local/bin/voiceaprs-process-message.sh and add a filter after extracting SENDER:

```bash
if [[ "$SENDER" == "SPAM-CALL" ]]; then
   exit 0
fi
```

## Privacy and Security

- APRS-IS Passcode: Keep your passcode private. It is stored in plaintext in /etc/direwolf.conf
- Message Visibility: All APRS messages are public and can be viewed by anyone on the APRS network
- Location Data: If using GPS, your position will be transmitted and visible on aprs.fi and other APRS tracking sites

## Contributing

Contributions are welcome. Please submit pull requests or open issues on GitHub.

When reporting bugs, please include:
- Your operating system and version
- Direwolf version: direwolf -v
- Relevant log files
- Steps to reproduce the issue

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Credits

- Direwolf: Software TNC/APRS by WB2OSZ - https://github.com/wb2osz/direwolf
- ASL-TTY: AllStarLink Text-to-Speech - https://github.com/AllStarLink/ASL-TTS
- AllStarLink: Amateur Radio VoIP Network - https://www.allstarlink.org

## Author

Created by KI9NG

## Support

For support, open an issue on GitHub: https://github.com/ki9ng/voiceaprs/issues

## Changelog

### Version 1.0.1 (2026-01-31)
- Improved TTS pronunciation by spacing callsign letters (A P R S instead of APRS)
- Renamed project to VoiceAPRS
- Cleaned up installer output
- Updated all file names and service names to voiceaprs
- Removed emojis and non-ASCII characters from all files

### Version 1.0.0 (2026-01-31)
- Initial release
- APRS-IS message reception with TTS
- Automatic acknowledgments
- GPS smart beaconing support
- Automated installer with GPS detection

---

73
