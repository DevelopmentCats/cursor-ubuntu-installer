# 🚀 Cursor AI IDE Installer for Ubuntu

A smart, safe installer for **Cursor AI IDE** that works perfectly on **Ubuntu 16.04 through 25.04+** with automatic version detection and intelligent installation methods.

## ✨ Features

- 🔍 **Auto-detects Ubuntu version** and chooses the safest installation method
- 🛡️ **Safe for Ubuntu 24.04+** - uses extraction method to avoid system issues
- 🔄 **Handles existing installations** with upgrade/reinstall options
- 🎨 **Complete desktop integration** - appears in applications menu with proper icon
- 💻 **Terminal integration** - adds `cursor` command to your shell
- 📊 **Smart dependency management** - only installs what's needed
- 🎯 **Version tracking** - knows when updates are available

## 🚨 Ubuntu 24.04+ Users

This script uses the **extraction method** for Ubuntu 24.04+ to avoid FUSE-related system instability. This is the safest and recommended approach.

## 🚀 Quick Installation

### One-line install:
```bash
curl -fsSL https://raw.githubusercontent.com/DevelopmentCats/cursor-ubuntu-installer/main/cursor_installer.sh | sudo bash
```

### Or download and run:
```bash
curl -O https://raw.githubusercontent.com/DevelopmentCats/cursor-ubuntu-installer/main/cursor_installer.sh
chmod +x cursor_installer.sh
sudo ./cursor_installer.sh
```

## 🎯 How to Launch

After installation, launch Cursor in any of these ways:

- **Applications Menu**: Search for "Cursor AI IDE"
- **Terminal**: Type `cursor` (restart terminal first)
- **With files**: `cursor filename.js` or `cursor /path/to/project`

## 🔧 Installation Methods

| Ubuntu Version | Method | Reason |
|---|---|---|
| **25.04+** | Extract | FUSE removed from repositories |
| **24.04** | Extract | Avoids desktop environment conflicts |
| **22.04 & older** | AppImage | Standard FUSE works reliably |

## 📁 Installation Locations

- **Program**: `/opt/cursor/`
- **Desktop Entry**: `/usr/share/applications/cursor.desktop`
- **Terminal Command**: `cursor` (added to your shell)

## 🔄 Updates & Reinstalls

Simply run the script again! It will:
- ✅ Detect your current version
- ✅ Offer to update if newer version available
- ✅ Clean up old installations properly
- ✅ Preserve your settings and extensions

## 🧹 Uninstall

```bash
# Remove Cursor completely
sudo rm -rf /opt/cursor
sudo rm -f /usr/share/applications/cursor.desktop

# Remove terminal command (edit these files to remove cursor function)
nano ~/.bashrc
nano ~/.zshrc
```

## 🛠️ Requirements

- Ubuntu 16.04 or later
- `sudo` privileges  
- Internet connection

## ⚡ What Makes This Script Special

- **Zero configuration** - just run and go
- **Version-aware** - different strategies for different Ubuntu versions
- **Non-destructive** - asks before making changes
- **Robust** - handles edge cases and existing installations
- **Clean** - proper desktop integration that actually works

## 🤝 Contributing

Found an issue? Have a suggestion? Contributions welcome!

## 📝 License

MIT License - Use freely!

---
*This installer is community-maintained and not officially associated with Cursor AI.* 