# Cursor AI IDE Installer for Ubuntu

A comprehensive installation script that optimally installs Cursor AI IDE on Ubuntu versions 16.04 through 25.04+, with intelligent version detection and graceful handling of existing installations.

## 🚨 Important Notes for Ubuntu 24.04+ Users

**Ubuntu 25.04+**: Installing `libfuse2t64` has been **removed from the repositories** and can break your desktop environment. This script uses the **extraction method** for safety.

**Ubuntu 24.04**: While `libfuse2t64` is available, it can cause **system instability** and login issues. This script uses the **extraction method** by default for safety.

## 🎯 Features

- **Version-aware installation**: Automatically detects Ubuntu version and chooses the optimal installation method
- **Graceful existing installation handling**: Detects existing installations and provides user options
- **Safe extraction method**: Uses AppImage extraction for Ubuntu 24.04+ to avoid FUSE-related issues
- **Complete desktop integration**: Creates proper `.desktop` files with MIME type associations
- **Shell integration**: Adds `cursor` command to bash and zsh
- **Colored output**: Clear, informative installation progress
- **Error handling**: Robust error handling with informative messages

## 🔧 Installation Methods by Ubuntu Version

| Ubuntu Version | Method | Reasoning |
|----------------|--------|-----------|
| 25.04+ | **Extract** | `libfuse2` removed from repos, can break system |
| 24.04 | **Extract** | `libfuse2t64` can cause desktop environment issues |
| 22.04 | AppImage* | `libfuse2` works but extraction fallback available |
| 16.04-20.04 | AppImage* | Standard `libfuse2` method |

*Falls back to extraction method if FUSE installation fails

## 🚀 Quick Start

### Prerequisites
- Ubuntu 16.04 or later
- `sudo` privileges
- Internet connection

### Installation

1. **Download the script:**
   ```bash
   curl -O https://raw.githubusercontent.com/yourusername/cursor-ubuntu-installer/main/cursor_installer.sh
   chmod +x cursor_installer.sh
   ```

2. **Run the installer:**
   ```bash
   sudo ./cursor_installer.sh
   ```

3. **Launch Cursor:**
   - From Applications menu: Search for "Cursor AI IDE"
   - From terminal: `cursor` (after restarting terminal)
   - Direct execution: See installation summary for exact path

## 📋 What the Script Does

### For All Ubuntu Versions:
1. **Detects Ubuntu version** using `lsb_release` or `/etc/os-release`
2. **Checks for existing installations** and provides user options
3. **Downloads latest Cursor AppImage** from official source
4. **Downloads official Cursor icon** for proper integration
5. **Creates desktop entry** with proper MIME type associations
6. **Adds shell aliases** to bash and zsh configurations
7. **Updates desktop database** for immediate menu integration

### Additional for Ubuntu 24.04+:
1. **Extracts AppImage** to avoid FUSE requirements
2. **Fixes permissions** including chrome-sandbox
3. **Uses extracted executable** for launching

## 🛠️ Installation Locations

- **Install directory**: `/opt/cursor/`
- **AppImage** (22.04 and below): `/opt/cursor/cursor.appimage`
- **Extracted files** (24.04+): `/opt/cursor/cursor/`
- **Desktop entry**: `/usr/share/applications/cursor.desktop`
- **Icon**: `/opt/cursor/cursor.png` or within extracted directory

## 🔄 Existing Installation Handling

The script intelligently detects existing installations and provides options:

```
⚠️  [WARNING] Cursor AI IDE is already installed!
Choose an option:
1) Reinstall (remove existing and install fresh)
2) Exit without changes
Enter your choice [1-2]:
```

This ensures you never accidentally break an existing setup.

## 🐛 Troubleshooting

### Common Issues and Solutions

#### 1. "Package 'libfuse2t64' has no installation candidate" (Ubuntu 24.04+)
**Solution**: This is expected behavior. The script automatically uses the extraction method.

#### 2. Cursor won't launch from desktop/menu
**Solutions**:
- Try launching from terminal: `cursor`
- Check if running: `ps aux | grep cursor`
- Try direct execution with the path shown in installation summary

#### 3. "The SUID sandbox helper binary was found, but is not configured correctly"
**Solution**: This is automatically handled by the script using the `--no-sandbox` flag and proper permission setup.

#### 4. Desktop environment breaks after installation (Ubuntu 24.04)
**Prevention**: This script uses the extraction method specifically to avoid this issue.
**Recovery** (if using other installation methods):
```bash
sudo apt install ubuntu-desktop-minimal
```

#### 5. Icon not showing in menu
**Solutions**:
- Log out and back in
- Run: `sudo update-desktop-database /usr/share/applications/`
- Run: `sudo gtk-update-icon-cache -f /usr/share/icons/hicolor/`

### Manual Launch Methods

If automatic launching fails, you can manually launch Cursor:

**For extraction method (Ubuntu 24.04+):**
```bash
/opt/cursor/cursor/AppRun --no-sandbox
```

**For AppImage method (Ubuntu 22.04 and below):**
```bash
/opt/cursor/cursor.appimage --no-sandbox
```

## 🧹 Uninstallation

To completely remove Cursor AI IDE:

```bash
# Remove installation directory
sudo rm -rf /opt/cursor

# Remove desktop entry
sudo rm -f /usr/share/applications/cursor.desktop

# Remove shell aliases (manually edit these files)
nano ~/.bashrc  # Remove lines between "# Cursor alias" and closing brace
nano ~/.zshrc   # Remove lines between "# Cursor alias" and closing brace

# Update desktop database
sudo update-desktop-database /usr/share/applications/
```

## 🔍 Technical Details

### Why Different Methods?

1. **Ubuntu 25.04+**: The FUSE library has been completely removed from repositories to push towards newer containerization methods.

2. **Ubuntu 24.04**: While `libfuse2t64` is available, it has known conflicts with the desktop environment that can cause login loops.

3. **Ubuntu 22.04 and below**: Standard FUSE implementation works reliably.

### Extraction Method Benefits

- **No FUSE dependency**: Eliminates the primary source of compatibility issues
- **Proper sandboxing**: Manually fixes chrome-sandbox permissions
- **System safety**: Cannot break desktop environment
- **Performance**: Often faster startup than FUSE-mounted AppImages

### Security Considerations

- **Sudo requirement**: Needed for system-wide installation in `/opt/`
- **No-sandbox flag**: Required for Electron apps on many Linux systems
- **Permission fixes**: Script properly sets ownership and permissions

## 📚 References

This installer is based on extensive research of current best practices:

- [It's FOSS AppImage Guide](https://itsfoss.com/cant-run-appimage-ubuntu/)
- [Ubuntu Community Discussions](https://discourse.ubuntu.com/t/appimages-are-not-opening/61609)
- [Cursor Forum Installation Issues](https://forum.cursor.com/t/cursor-install-ubuntu-24-04/4838)
- [AppImage GitHub Issues](https://github.com/AppImage/AppImageKit/issues/1389)

## 🤝 Contributing

Contributions are welcome! Please ensure any changes maintain compatibility across all supported Ubuntu versions.

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## ⚠️ Disclaimer

This script is not officially associated with Cursor AI. Use at your own risk. Always backup your system before running installation scripts. 