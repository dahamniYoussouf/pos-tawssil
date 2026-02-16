# Windows Launch Guide - POS Tawsil

This guide covers all methods to launch the POS Tawsil application on Windows, with comprehensive error handling and troubleshooting.

## ✅ Pre-Launch Verification

Before launching, run the test script to verify everything is configured correctly:

```powershell
.\test_windows_launch.ps1
```

This will check:
- ✅ Project structure
- ✅ Flutter installation
- ✅ Dependencies
- ✅ Code analysis
- ✅ Windows build configuration
- ✅ Manifest settings
- ✅ Database initialization
- ✅ Launch scripts

## 🚀 Launch Methods

### Method 1: Comprehensive Launcher (Recommended)

The `launch_windows.ps1` script provides the most comprehensive launch experience with detailed diagnostics:

```powershell
.\launch_windows.ps1 debug      # Debug mode (default)
.\launch_windows.ps1 release    # Release mode
.\launch_windows.ps1 build-only # Build only, don't launch
.\launch_windows.ps1 clean-build # Clean and rebuild
```

**Features:**
- ✅ Automatic dependency resolution
- ✅ Build verification
- ✅ Runtime file checks
- ✅ Detailed error messages
- ✅ Exit code diagnostics
- ✅ Antivirus detection warnings

### Method 2: Simple Launcher

The `run_windows.ps1` script is a simpler launcher that runs the executable from the correct directory:

```powershell
.\run_windows.ps1 debug    # Debug mode (default)
.\run_windows.ps1 release  # Release mode
```

**Features:**
- ✅ Sets correct working directory
- ✅ Builds if executable not found
- ✅ Runs from executable directory

### Method 3: Flutter CLI

Direct Flutter command for development:

```powershell
flutter run -d windows
```

**Features:**
- ✅ Hot reload support
- ✅ Debug console output
- ✅ Development mode

### Method 4: VS Code Tasks

If using VS Code/Cursor, use the built-in tasks:

1. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
2. Type "Tasks: Run Task"
3. Select one of:
   - **POS: Run Web (normal)** - Launch web version
   - **POS: Run Web (debug)** - Launch web version with debug
   - **POS: Run Windows (exe)** - Launch Windows executable
   - **POS: Flutter run -d windows** - Direct Flutter command

## 🔧 Configuration Files

### VS Code Settings (`.vscode/settings.json`)

Configured for optimal Windows development:
- PowerShell as default terminal
- ConPTY enabled for better terminal support
- Execution policy bypass for automation

### Windows Manifest (`windows/runner/runner.exe.manifest`)

Configured with:
- `asInvoker` execution level (no admin required)
- DPI awareness (PerMonitorV2)
- Windows 10/11 compatibility

### Main Entry Point (`windows/runner/main.cpp`)

Configured to:
- Set working directory to executable directory
- Attach to console for debugging
- Initialize COM for plugins

## 🐛 Troubleshooting

### Issue: "Access is denied"

**Causes:**
1. Windows Defender/Antivirus blocking the executable
2. Missing runtime files (DLLs, data folder)
3. Incorrect working directory

**Solutions:**

1. **Add Windows Defender Exclusion:**
   - Windows Security → Virus & threat protection → Manage settings
   - Exclusions → Add exclusion → Folder
   - Add: `C:\Users\<YourUser>\...\pos_tawsil\build`

2. **Check Protection History:**
   - Windows Security → Protection history
   - Look for `pos_tawsil.exe`, `flutter_windows.dll`, or `print_usb_plugin.dll`
   - If found, click "Allow" or "Restore"

3. **Verify Runtime Files:**
   ```powershell
   # Check if these exist:
   build\windows\x64\runner\Debug\pos_tawsil.exe
   build\windows\x64\runner\Debug\flutter_windows.dll
   build\windows\x64\runner\Debug\data\
   ```

4. **Rebuild:**
   ```powershell
   flutter clean
   flutter pub get
   flutter build windows --debug
   ```

### Issue: Exit Code 259

**Meaning:** Process still active or blocked

**Solutions:**
1. Kill any existing `pos_tawsil.exe` processes:
   ```powershell
   Get-Process pos_tawsil -ErrorAction SilentlyContinue | Stop-Process -Force
   ```

2. Check antivirus software
3. Restart computer if issue persists

### Issue: Exit Code 3221225786

**Meaning:** Legacy console mode issue

**Solutions:**
1. Open `cmd.exe` from Start menu
2. Right-click title bar → Properties
3. Options tab → Uncheck "Use legacy console"
4. Restart VS Code/Cursor

### Issue: Terminal Won't Launch in VS Code/Cursor

See `TROUBLESHOOTING_WINDOWS.md` section "Terminal launch failures" for detailed steps.

Quick fixes:
1. Disable compatibility mode for VS Code/Cursor
2. Disable legacy console in cmd.exe
3. Add antivirus exclusions for node-pty files
4. Use Tasks instead (Terminal → Run Task)

### Issue: Build Fails

**Common causes:**
1. Missing Visual Studio Build Tools
2. Missing Windows SDK
3. Insufficient disk space
4. Antivirus blocking build process

**Solutions:**

1. **Check Flutter Doctor:**
   ```powershell
   flutter doctor -v
   ```

2. **Install Visual Studio Build Tools:**
   - Download from: https://visualstudio.microsoft.com/downloads/
   - Select "Desktop development with C++"
   - Include Windows 10/11 SDK

3. **Check Disk Space:**
   ```powershell
   Get-PSDrive C | Select-Object Used,Free
   ```

4. **Add Build Folder to Antivirus Exclusions**

## 📋 Launch Checklist

Before launching, ensure:

- [ ] Flutter is installed and in PATH
- [ ] Visual Studio Build Tools installed
- [ ] Windows SDK installed
- [ ] Dependencies resolved (`flutter pub get`)
- [ ] Code compiles (`flutter analyze` - warnings OK)
- [ ] Build folder excluded from antivirus
- [ ] No existing `pos_tawsil.exe` processes running

## 🎯 Quick Start

**First time setup:**
```powershell
cd pos_tawsil
.\test_windows_launch.ps1    # Verify setup
.\launch_windows.ps1 debug   # Build and launch
```

**Subsequent launches:**
```powershell
.\run_windows.ps1 debug      # Quick launch
# OR
flutter run -d windows       # Development mode
```

## 📚 Additional Resources

- **TROUBLESHOOTING_WINDOWS.md** - Detailed troubleshooting guide
- **README_RUN.md** - General run guide
- **VS Code Terminal Troubleshooting:** https://aka.ms/vscode-troubleshoot-terminal-launch

## ✅ Verification

After launching successfully, you should see:
1. Application window opens
2. Login screen appears
3. No error dialogs
4. Database initializes (first run may take a moment)

If you encounter any issues not covered here, check `TROUBLESHOOTING_WINDOWS.md` for detailed solutions.
