# Contributing to VoiceAPRS

Thank you for considering contributing to this project.

## How to Contribute

### Reporting Bugs

If you find a bug, please open an issue on GitHub with:
- A clear, descriptive title
- Your operating system and version
- Direwolf version (direwolf -v)
- Steps to reproduce the issue
- Expected behavior vs actual behavior
- Relevant log files or error messages

### Suggesting Enhancements

Enhancement suggestions are welcome. Please open an issue with:
- A clear description of the enhancement
- Use cases and benefits
- Any implementation ideas you may have

### Pull Requests

1. Fork the repository
2. Create a new branch for your feature (git checkout -b feature/AmazingFeature)
3. Make your changes
4. Test thoroughly
5. Commit your changes (git commit -m 'Add some AmazingFeature')
6. Push to the branch (git push origin feature/AmazingFeature)
7. Open a Pull Request

### Code Style

- Use clear, descriptive variable names
- Comment complex logic
- Follow existing code formatting
- Test on Raspberry Pi OS or Debian-based systems

### Testing

Before submitting a PR:
- Test the installer on a fresh system
- Verify all services start correctly
- Test message reception and TTS functionality
- Check that GPS functionality works (if applicable)

## Development Setup

```bash
git clone https://github.com/ki9ng/voiceaprs.git
cd voiceaprs

# Test the installer
chmod +x install.sh
./install.sh
```

## Questions?

Feel free to open an issue for any questions about contributing.

## Code of Conduct

Be respectful and constructive in all interactions.

73
