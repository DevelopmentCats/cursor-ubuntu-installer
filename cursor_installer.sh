#!/bin/bash

# Cursor AI IDE Installer for Ubuntu 16.04+
# Handles version-specific requirements and provides graceful installation/upgrade options

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CURSOR_API_URL="https://www.cursor.com/api/download?platform=linux-x64&releaseTrack=stable"
ICON_URL="https://us1.discourse-cdn.com/flex020/uploads/cursor1/original/2X/a/a4f78589d63edd61a2843306f8e11bad9590f0ca.png"
INSTALL_DIR="/opt/cursor"
APPIMAGE_PATH="$INSTALL_DIR/cursor.appimage"
EXTRACTED_PATH="$INSTALL_DIR/cursor"
ICON_PATH="$INSTALL_DIR/cursor.png"
DESKTOP_ENTRY_PATH="/usr/share/applications/cursor.desktop"
VERSION_FILE="$INSTALL_DIR/version.txt"

# Global variables
INSTALLATION_METHOD=""
UBUNTU_VERSION=""
FUSE_INSTALLED=""
CURSOR_VERSION=""
CURSOR_DOWNLOAD_URL=""
INSTALLED_VERSION=""

# Function to print colored output
print_status() {
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

# Function to detect Ubuntu version
detect_ubuntu_version() {
    if command -v lsb_release >/dev/null 2>&1; then
        UBUNTU_VERSION=$(lsb_release -rs)
    elif [[ -f /etc/os-release ]]; then
        UBUNTU_VERSION=$(grep VERSION_ID /etc/os-release | cut -d'"' -f2)
    else
        print_warning "Cannot detect Ubuntu version, continuing with best-effort installation"
        UBUNTU_VERSION="unknown"
    fi
    
    print_status "Detected Ubuntu $UBUNTU_VERSION"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Function to get latest Cursor version info from API
get_cursor_version_info() {
    print_status "Fetching latest Cursor version information..."
    
    local api_response
    if ! api_response=$(curl -s "$CURSOR_API_URL"); then
        print_error "Failed to fetch version information from Cursor API"
        exit 1
    fi
    
    # Parse JSON response to extract version and download URL
    if command -v jq >/dev/null 2>&1; then
        CURSOR_VERSION=$(echo "$api_response" | jq -r '.version')
        CURSOR_DOWNLOAD_URL=$(echo "$api_response" | jq -r '.downloadUrl')
    else
        # Fallback parsing without jq
        CURSOR_VERSION=$(echo "$api_response" | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
        CURSOR_DOWNLOAD_URL=$(echo "$api_response" | grep -o '"downloadUrl":"[^"]*"' | cut -d'"' -f4)
    fi
    
    if [[ -z "$CURSOR_VERSION" ]] || [[ -z "$CURSOR_DOWNLOAD_URL" ]]; then
        print_error "Failed to parse version information from API response"
        exit 1
    fi
    
    print_success "Latest Cursor version: $CURSOR_VERSION"
}

# Function to get installed version
get_installed_version() {
    if [[ -f "$VERSION_FILE" ]]; then
        INSTALLED_VERSION=$(cat "$VERSION_FILE")
        print_status "Installed Cursor version: $INSTALLED_VERSION"
    else
        INSTALLED_VERSION=""
        print_status "No version information found for existing installation"
    fi
}

# Function to compare versions
version_compare() {
    local version1=$1
    local version2=$2
    
    # Simple version comparison (works for semantic versioning)
    if [[ "$version1" == "$version2" ]]; then
        return 0  # Equal
    fi
    
    # Use sort -V for version comparison
    if printf '%s\n%s\n' "$version1" "$version2" | sort -V -C 2>/dev/null; then
        return 1  # version1 < version2
    else
        return 2  # version1 > version2
    fi
}

# Function to check for existing installation
check_existing_installation() {
    local has_appimage=false
    local has_extracted=false
    local has_legacy=false
    local needs_update=false
    
    # Check for new installation paths
    if [[ -f "$APPIMAGE_PATH" ]]; then
        has_appimage=true
    fi
    
    if [[ -d "$EXTRACTED_PATH" ]]; then
        has_extracted=true
    fi
    
    # Check for legacy installation from old script (lowercase paths)
    if [[ -f "/opt/cursor.appimage" ]]; then
        has_legacy=true
        print_status "Found legacy Cursor installation at /opt/cursor.appimage"
    fi
    
    # Check for other potential legacy installations
    if [[ -f "/opt/Cursor.appimage" ]] || [[ -f "/opt/CURSOR.appimage" ]]; then
        has_legacy=true
        print_status "Found legacy Cursor installation with different casing"
    fi
    
    if [[ "$has_appimage" == true ]] || [[ "$has_extracted" == true ]] || [[ "$has_legacy" == true ]]; then
        print_status "Found existing Cursor installation"
        get_installed_version
        
        if [[ -n "$INSTALLED_VERSION" ]]; then
            version_compare "$INSTALLED_VERSION" "$CURSOR_VERSION"
            local compare_result=$?
            
            if [[ $compare_result -eq 0 ]]; then
                echo
                print_success "Cursor is already up to date (version $INSTALLED_VERSION)"
                echo -n "Do you want to reinstall anyway? (y/N): "
                read -r choice
                case ${choice,,} in
                    y|yes)
                        print_status "Proceeding with reinstallation..."
                        cleanup_existing
                        ;;
                    *)
                        print_status "Exiting without changes"
                        exit 0
                        ;;
                esac
            elif [[ $compare_result -eq 1 ]]; then
                echo
                print_warning "Update available: $INSTALLED_VERSION → $CURSOR_VERSION"
                echo -n "Do you want to update? (Y/n): "
                read -r choice
                case ${choice,,} in
                    n|no)
                        print_status "Skipping update"
                        exit 0
                        ;;
                    *)
                        print_status "Proceeding with update..."
                        cleanup_existing
                        ;;
                esac
            else
                echo
                print_warning "Installed version ($INSTALLED_VERSION) is newer than available ($CURSOR_VERSION)"
                echo -n "Do you want to downgrade? (y/N): "
                read -r choice
                case ${choice,,} in
                    y|yes)
                        print_status "Proceeding with downgrade..."
                        cleanup_existing
                        ;;
                    *)
                        print_status "Keeping current version"
                        exit 0
                        ;;
                esac
            fi
        else
            echo
            print_warning "Cursor is installed but version information is missing"
            echo -n "Do you want to reinstall with version tracking? (Y/n): "
            read -r choice
            case ${choice,,} in
                n|no)
                    print_status "Exiting without changes"
                    exit 0
                    ;;
                *)
                    print_status "Proceeding with reinstallation..."
                    cleanup_existing
                    ;;
            esac
        fi
    fi
}

# Function to cleanup existing installation
cleanup_existing() {
    print_status "Cleaning up existing installation..."
    
    # Clean up new installation paths (current script structure)
    [[ -d "$INSTALL_DIR" ]] && rm -rf "$INSTALL_DIR"
    [[ -f "$DESKTOP_ENTRY_PATH" ]] && rm -f "$DESKTOP_ENTRY_PATH"
    
    # Clean up legacy installation files (original script format - lowercase)
    [[ -f "/opt/cursor.appimage" ]] && rm -f "/opt/cursor.appimage"
    [[ -f "/opt/cursor.png" ]] && rm -f "/opt/cursor.png"
    
    # Clean up any mixed case variations that might exist
    [[ -f "/opt/Cursor.appimage" ]] && rm -f "/opt/Cursor.appimage"
    [[ -f "/opt/Cursor.png" ]] && rm -f "/opt/Cursor.png"
    [[ -f "/opt/CURSOR.appimage" ]] && rm -f "/opt/CURSOR.appimage"
    [[ -f "/opt/CURSOR.png" ]] && rm -f "/opt/CURSOR.png"
    
    # Clean up any old desktop entries that might exist
    [[ -f "/usr/share/applications/Cursor.desktop" ]] && rm -f "/usr/share/applications/Cursor.desktop"
    [[ -f "/usr/share/applications/cursor-ai.desktop" ]] && rm -f "/usr/share/applications/cursor-ai.desktop"
    
    # Remove alias from common shell rc files (both old and new format)
    for rc_file in /home/*/.bashrc /home/*/.zshrc /root/.bashrc /root/.zshrc; do
        if [[ -f "$rc_file" ]]; then
            # Remove new format aliases (with version comment)
            sed -i '/# Cursor alias/,/^$/d' "$rc_file" 2>/dev/null || true
            # Remove old format aliases (simple function without version comment)
            sed -i '/^function cursor()/,/^}$/d' "$rc_file" 2>/dev/null || true
            # Remove any standalone cursor alias lines
            sed -i '/alias cursor=/d' "$rc_file" 2>/dev/null || true
            # Remove legacy cursor aliases that might use /opt/cursor.appimage directly
            sed -i '/\/opt\/cursor\.appimage/d' "$rc_file" 2>/dev/null || true
        fi
    done
    
    print_success "Existing installation cleaned up"
}

# Function to try installing FUSE libraries
try_install_fuse() {
    print_status "Attempting to install FUSE libraries..."
    
    # Try libfuse3 first (newer version)
    if apt-get install -y libfuse3 2>/dev/null; then
        FUSE_INSTALLED="libfuse3"
        print_success "Successfully installed libfuse3"
        return 0
    fi
    
    # Try libfuse2t64 (Ubuntu 24.04+)
    if apt-get install -y libfuse2t64 2>/dev/null; then
        FUSE_INSTALLED="libfuse2t64"
        print_success "Successfully installed libfuse2t64"
        return 0
    fi
    
    # Try libfuse2 (older versions)
    if apt-get install -y libfuse2 2>/dev/null; then
        FUSE_INSTALLED="libfuse2"
        print_success "Successfully installed libfuse2"
        return 0
    fi
    
    print_warning "Could not install any FUSE library, will use extraction method"
    return 1
}

# Function to install dependencies
install_dependencies() {
    print_status "Installing dependencies..."
    
    # Update package list
    apt-get update -qq
    
    # Install curl if not present
    if ! command -v curl >/dev/null 2>&1; then
        print_status "Installing curl..."
        apt-get install -y curl
    fi
    
    # Install jq for better JSON parsing (optional)
    if ! command -v jq >/dev/null 2>&1; then
        if apt-get install -y jq 2>/dev/null; then
            print_status "Installed jq for better JSON parsing"
        else
            print_status "jq not available, using fallback JSON parsing"
        fi
    fi
    
    # Try to install FUSE libraries
    if try_install_fuse; then
        INSTALLATION_METHOD="appimage"
        print_status "Will use AppImage method with $FUSE_INSTALLED"
    else
        INSTALLATION_METHOD="extract"
        print_status "Will use extraction method (safer for newer Ubuntu versions)"
    fi
}

# Function to download Cursor AppImage
download_cursor() {
    print_status "Creating installation directory..."
    mkdir -p "$INSTALL_DIR"
    
    print_status "Downloading Cursor AppImage v$CURSOR_VERSION..."
    if ! curl -L "$CURSOR_DOWNLOAD_URL" -o "$APPIMAGE_PATH" --progress-bar; then
        print_error "Failed to download Cursor AppImage"
        exit 1
    fi
    
    chmod +x "$APPIMAGE_PATH"
    
    # Save version information
    echo "$CURSOR_VERSION" > "$VERSION_FILE"
    
    print_success "Cursor AppImage v$CURSOR_VERSION downloaded successfully"
}

# Function to download icon
download_icon() {
    print_status "Downloading Cursor icon..."
    if ! curl -L "$ICON_URL" -o "$ICON_PATH" --progress-bar; then
        print_warning "Failed to download icon, but continuing installation"
    else
        print_success "Icon downloaded successfully"
    fi
}

# Function to test AppImage execution
test_appimage_execution() {
    print_status "Testing AppImage execution..."
    
    # Make sure the AppImage has correct permissions
    chmod +x "$APPIMAGE_PATH"
    
    # Try to run the AppImage with --no-sandbox --version to see if it works
    # Using --version instead of --help as it's more reliable for testing
    print_status "Running test: $APPIMAGE_PATH --no-sandbox --version"
    if timeout 15s "$APPIMAGE_PATH" --no-sandbox --version >/dev/null 2>&1; then
        print_success "AppImage execution test successful"
        return 0
    else
        print_warning "AppImage execution test failed, falling back to extraction method"
        print_status "This is normal on newer Ubuntu versions and doesn't indicate an error"
        return 1
    fi
}

# Function to extract AppImage
extract_appimage() {
    print_status "Extracting AppImage for safer execution..."
    
    cd "$INSTALL_DIR"
    if ! "$APPIMAGE_PATH" --appimage-extract >/dev/null 2>&1; then
        print_error "Failed to extract AppImage"
        exit 1
    fi
    
    # Move extracted contents to clean directory name
    mv squashfs-root "$EXTRACTED_PATH"
    
    # Fix permissions
    chown -R root:root "$EXTRACTED_PATH"
    find "$EXTRACTED_PATH" -type d -exec chmod 755 {} \;
    chmod 4755 "$EXTRACTED_PATH/chrome-sandbox" 2>/dev/null || true
    
    # Remove original AppImage to save space
    rm -f "$APPIMAGE_PATH"
    
    print_success "AppImage extracted successfully"
}

# Function to create desktop entry
create_desktop_entry() {
    print_status "Creating desktop entry..."
    
    if [[ "$INSTALLATION_METHOD" == "extract" ]]; then
        EXEC_PATH="$EXTRACTED_PATH/AppRun"
        ICON_ENTRY="$EXTRACTED_PATH/cursor.png"
        
        # Use extracted icon if available, fallback to downloaded one
        if [[ ! -f "$ICON_ENTRY" ]] && [[ -f "$ICON_PATH" ]]; then
            ICON_ENTRY="$ICON_PATH"
        fi
    else
        EXEC_PATH="$APPIMAGE_PATH"
        ICON_ENTRY="$ICON_PATH"
    fi
    
    # Verify executable and icon exist before creating desktop entry
    if [[ ! -f "$EXEC_PATH" ]]; then
        print_error "Executable not found at $EXEC_PATH"
        return 1
    fi
    
    # Ensure the applications directory exists
    mkdir -p "/usr/share/applications"
    
    cat > "$DESKTOP_ENTRY_PATH" <<EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=Cursor AI IDE
Comment=AI-powered code editor (v$CURSOR_VERSION)
Terminal=false
Exec=$EXEC_PATH --no-sandbox %F
Icon=$ICON_ENTRY
Categories=Development;IDE;TextEditor;
StartupWMClass=Cursor
StartupNotify=true
MimeType=text/plain;text/x-chdr;text/x-csrc;text/x-c++hdr;text/x-c++src;text/x-java;text/x-dsrc;text/x-pascal;text/x-perl;text/x-python;application/x-php;application/x-httpd-php3;application/x-httpd-php4;application/x-httpd-php5;application/x-ruby;text/x-tcl;text/x-tex;application/x-sh;text/x-dtd;text/x-javascript;application/json;text/x-markdown;text/xml;text/css;text/html;text/x-sql;application/x-yaml;
EOL
    
    chmod 644 "$DESKTOP_ENTRY_PATH"
    
    # Verify the desktop entry was created successfully
    if [[ -f "$DESKTOP_ENTRY_PATH" ]]; then
        print_success "Desktop entry created at $DESKTOP_ENTRY_PATH"
        print_status "Desktop entry executable: $EXEC_PATH"
        print_status "Desktop entry icon: $ICON_ENTRY"
    else
        print_error "Failed to create desktop entry"
        return 1
    fi
}

# Function to create shell alias
create_shell_alias() {
    print_status "Adding cursor alias to shell configuration..."
    
    if [[ "$INSTALLATION_METHOD" == "extract" ]]; then
        EXEC_PATH="$EXTRACTED_PATH/AppRun"
    else
        EXEC_PATH="$APPIMAGE_PATH"
    fi
    
    local alias_block="
# Cursor alias (v$CURSOR_VERSION)
function cursor() {
    \"$EXEC_PATH\" --no-sandbox \"\$@\" > /dev/null 2>&1 & disown
}
"
    
    # Add alias to existing users' shell configurations
    for user_home in /home/*; do
        if [[ -d "$user_home" ]]; then
            local username=$(basename "$user_home")
            
            # Add to .bashrc if it exists
            if [[ -f "$user_home/.bashrc" ]]; then
                if ! grep -q "# Cursor alias" "$user_home/.bashrc" 2>/dev/null; then
                    echo "$alias_block" >> "$user_home/.bashrc"
                    chown "$username:$username" "$user_home/.bashrc" 2>/dev/null || true
                fi
            fi
            
            # Add to .zshrc if it exists
            if [[ -f "$user_home/.zshrc" ]]; then
                if ! grep -q "# Cursor alias" "$user_home/.zshrc" 2>/dev/null || true; then
                    echo "$alias_block" >> "$user_home/.zshrc"
                    chown "$username:$username" "$user_home/.zshrc" 2>/dev/null || true
                fi
            fi
        fi
    done
    
    print_success "Shell alias added (restart terminal or run 'source ~/.bashrc' to use 'cursor' command)"
}

# Function to update desktop database
update_desktop_database() {
    print_status "Updating desktop database and application menu..."
    
    # Update desktop database
    if command -v update-desktop-database >/dev/null 2>&1; then
        if update-desktop-database /usr/share/applications/ 2>/dev/null; then
            print_status "Desktop database updated successfully"
        else
            print_warning "Failed to update desktop database, but continuing"
        fi
    else
        print_warning "update-desktop-database not found, application may not appear immediately"
    fi
    
    # Update icon cache if available
    if command -v gtk-update-icon-cache >/dev/null 2>&1; then
        if gtk-update-icon-cache -f /usr/share/icons/hicolor/ 2>/dev/null; then
            print_status "Icon cache updated"
        fi
    fi
    
    # Force refresh GNOME shell cache if running GNOME
    if command -v gnome-shell >/dev/null 2>&1 && pgrep -f gnome-shell >/dev/null; then
        print_status "Refreshing GNOME application cache..."
        # Signal GNOME to refresh applications
        killall -SIGUSR1 gnome-shell 2>/dev/null || true
    fi
    
    # Update MIME database if available
    if command -v update-mime-database >/dev/null 2>&1; then
        update-mime-database /usr/share/mime/ 2>/dev/null || true
    fi
    
    print_success "Application menu refresh completed"
}

# Function to display installation summary
display_summary() {
    echo
    print_success "Cursor AI IDE installation completed successfully!"
    echo
    echo "Installation details:"
    echo "  • Version: $CURSOR_VERSION"
    echo "  • Method: $INSTALLATION_METHOD"
    echo "  • Ubuntu version: $UBUNTU_VERSION"
    if [[ -n "$FUSE_INSTALLED" ]]; then
        echo "  • FUSE library: $FUSE_INSTALLED"
    fi
    if [[ "$INSTALLATION_METHOD" == "extract" ]]; then
        echo "  • Location: $EXTRACTED_PATH"
    else
        echo "  • Location: $APPIMAGE_PATH"
    fi
    echo "  • Desktop entry: $DESKTOP_ENTRY_PATH"
    echo "  • Version file: $VERSION_FILE"
    echo
    echo "How to launch:"
    echo "  • From applications menu: Search for 'Cursor AI IDE'"
    echo "    (If not visible immediately, try logging out/in or restarting)"
    echo "  • From terminal: Run 'cursor' command (after restarting terminal)"
    if [[ "$INSTALLATION_METHOD" == "extract" ]]; then
        echo "  • Direct execution: $EXTRACTED_PATH/AppRun --no-sandbox"
    else
        echo "  • Direct execution: $APPIMAGE_PATH --no-sandbox"
    fi
    echo
    echo "Troubleshooting:"
    echo "  • If app doesn't appear in menu, try: sudo update-desktop-database"
    echo "  • For GNOME: Press Alt+F2, type 'r', and press Enter to restart shell"
    echo "  • Check desktop entry exists: ls -la $DESKTOP_ENTRY_PATH"
    echo
    echo "To update in the future, simply run this script again!"
    echo
    if [[ "$INSTALLATION_METHOD" == "extract" ]]; then
        print_warning "Note: Used extraction method for maximum compatibility and safety."
    fi
}

# Main installation function
main() {
    echo "========================================="
    echo "  Cursor AI IDE Installer for Ubuntu"
    echo "  Supports Ubuntu 16.04+"
    echo "========================================="
    echo
    
    check_root
    detect_ubuntu_version
    get_cursor_version_info
    check_existing_installation
    install_dependencies
    download_cursor
    download_icon
    
    # If using AppImage method, test it first
    if [[ "$INSTALLATION_METHOD" == "appimage" ]]; then
        if ! test_appimage_execution; then
            print_status "Switching to extraction method due to AppImage execution issues..."
            INSTALLATION_METHOD="extract"
        fi
    fi
    
    # Extract if using extraction method
    if [[ "$INSTALLATION_METHOD" == "extract" ]]; then
        extract_appimage
    fi
    
    create_desktop_entry
    create_shell_alias
    update_desktop_database
    display_summary
}

# Run main function
main "$@"