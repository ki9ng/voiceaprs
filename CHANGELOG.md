# Changelog

All notable changes to this project will be documented in this file.

## [1.0.1] - 2026-01-31

### Changed
- Project renamed to VoiceAPRS
- Improved TTS pronunciation by spacing callsign letters (K I 9 N G instead of KI9NG)
- All file names and service names updated to voiceaprs prefix
- Removed emojis and non-ASCII characters from all documentation
- Cleaned up installer output for better readability
- Updated user agent in APRS-IS login to VoiceAPRS 1.0.1
- **Replaced Python ACK sender with pure bash/netcat implementation**
- **Removed Python3 dependency - significantly reduces installation size (from ~259MB to ~15MB)**
- ACK sender now uses netcat for APRS-IS connection instead of Python sockets

### Technical
- Message processor: /usr/local/bin/voiceaprs-process-message.sh
- ACK sender: /usr/local/bin/voiceaprs-send-ack.sh (changed from .py to .sh)
- Service: voiceaprs-monitor.service
- Log file: /var/log/voiceaprs-messages.log
- Sudoers: /etc/sudoers.d/voiceaprs
- Required packages: direwolf, netcat-openbsd (Python3 no longer required)

## [1.0.0] - 2026-01-31

### Added
- Initial release
- Automated installer script with interactive prompts
- APRS-IS message reception via Direwolf
- Text-to-speech integration with AllStarLink using ASL-TTY
- Automatic message acknowledgment to prevent retransmissions
- GPS support with automatic detection and configuration
- Smart beaconing for mobile stations with GPS
- Fixed position beaconing for stations without GPS
- Comprehensive logging of received messages
- systemd service integration for automatic startup
- Sudo configuration for ASL-TTS without password prompts
- Example configuration files for various use cases
- Uninstall script
- Complete documentation

### Security
- APRS-IS passcode stored securely in config files
- Sudo access limited to specific ASL-TTS command only
- Service runs as non-root user

---

For more details on each release, see the GitHub Releases page.
