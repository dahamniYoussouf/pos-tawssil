# Windows "Access is denied" – Troubleshooting

## What we found (code-level)

1. **Startup flow**  
   `main()` → `initDatabase()` (sqflite FFI) → `runApp()` → `SyncService` / `OrderProvider` → `LoginScreen`.  
   No early file/USB access before the first frame.

2. **Working directory**  
   The Windows runner now sets the process **working directory** to the **executable directory** in `main.cpp` (before creating the Dart project).  
   This ensures `data`, plugin paths, and any CWD‑dependent logic resolve correctly when you run from Explorer, PowerShell, or `flutter run`.

3. **Manifest**  
   `runner.exe.manifest` includes `requestedExecutionLevel level="asInvoker"` so the app runs as the current user (no implicit elevation).

4. **`print_usb` plugin**  
   - Used for USB/local printing.  
   - Windows implementation uses **Windows GDI** (e.g. `EnumPrintersW`, `OpenPrinter`), not raw USB.  
   - The plugin is **always loaded** at startup (it’s linked).  
   - **Windows Defender / antivirus often block or restrict unsigned plugin DLLs** (especially ones related to printers/USB).  
   - That can prevent the process from starting and show **"Access is denied"** or "Windows cannot access the file" **before** any Dart code runs.

5. **Database path**  
   `sqflite` uses `getDatabasesPath()` (path_provider). DB is opened **lazily** on first use, not at exe launch.  
   So DB path is unlikely to cause "Access is denied" at startup.

## Fixes applied in code

- **`windows/runner/runner.exe.manifest`**  
  - Added `trustInfo` with `requestedExecutionLevel level="asInvoker"`.

- **`windows/runner/main.cpp`**  
  - Set working directory to the exe directory via `GetModuleFileNameW` + `SetCurrentDirectoryW` before creating the Flutter project.

- **`run_windows.ps1`**  
  - Launcher that builds (if needed), `cd`s into `Debug` or `Release`, then runs `pos_tawsil.exe`.  
  - Use this when running the app outside `flutter run`.

## If you still get "Access is denied"

### 1. Windows Defender / antivirus

- **Protection history**  
  - Windows Security → Virus & threat protection → Protection history.  
  - Check for **pos_tawsil.exe**, **flutter_windows.dll**, or **print_usb_plugin.dll** blocked or quarantined.  
  - If found → **Allow** / **Restore**.

- **Exclusions** (requires admin)  
  - Windows Security → Virus & threat protection → Manage settings → Exclusions → Add exclusion → **Folder**.  
  - Add:
    ```
    C:\Users\<You>\...\pos_tawsil\build
    ```
  - Replace `<You>` and path with your actual project path.

### 2. Run the app correctly

- **Option A – Launcher (recommended)**  
  From `pos_tawsil`:
  ```powershell
  .\run_windows.ps1        # debug
  .\run_windows.ps1 release
  ```

- **Option B – Manual**  
  - Open File Explorer → go to  
    `pos_tawsil\build\windows\x64\runner\Debug`  
    (or `Release`).  
  - Double‑click **pos_tawsil.exe**.  
  - Do **not** move the exe; keep it with `data`, `flutter_windows.dll`, and the plugin DLLs.

- **Option C – `flutter run`**  
  ```powershell
  cd pos_tawsil
  flutter run -d windows
  ```
  If you see "The flutter tool cannot access the file or directory", the same Defender/AV block usually applies; fix exclusions first.

### 3. Run as Administrator (quick test only)

- Right‑click **pos_tawsil.exe** → **Run as administrator**.  
- If it runs only like this, something (e.g. policy, AV) is restricting normal user execution.  
- Prefer fixing exclusions over always using admin.

### 4. Test without `print_usb` (isolate the plugin)

If you’ve added exclusions and it still fails:

1. **Temporarily remove `print_usb`**  
   - In `pubspec.yaml`, comment or remove:
     ```yaml
     # print_usb: ^0.0.3
     ```
2. **Stub USB usage in code**  
   - In `local_print_service.dart`, `usb_printer_scanner.dart`, etc., guard or remove `PrintUsb` usage so the app runs without the plugin.  
3. Run:
   ```powershell
   flutter pub get
   flutter run -d windows
   ```
4. If the exe **runs** without `print_usb`, the block is very likely **print_usb_plugin.dll** (or its loading).  
5. Re‑add `print_usb`, restore code, **add Defender/AV exclusion** for the `build` folder, then try again.

### 5. Work / school PC (e.g. Azure AD)

- **AppLocker** or similar may block unsigned apps.  
- Try the steps above; if it still fails, ask IT to allow:
  - `pos_tawsil.exe`, or  
  - Execution from `...\pos_tawsil\build`.  
- Or run on a **personal machine** to confirm.

## Terminal launch failures (VS Code / Cursor)

If the **Integrated Terminal** won’t open in VS Code or Cursor when working on the POS, use the official guide:  
**[Troubleshoot Terminal launch failures](https://aka.ms/vscode-troubleshoot-terminal-launch)**.

### Quick checks (Windows)

1. **Compatibility mode**  
   Right‑click the VS Code / Cursor executable → **Properties** → **Compatibility** → **uncheck** “Run this program in compatibility mode”.

2. **Legacy console**  
   Open **cmd.exe** from Start → right‑click title bar → **Properties** → **Options** → **uncheck** “Use legacy console”.

3. **Anti‑virus and node-pty**  
   Exclude these from scanning (replace `{install_path}` with your VS Code/Cursor install path):
   ```
   {install_path}\resources\app\node_modules.asar.unpacked\node-pty\build\Release\winpty.dll
   {install_path}\resources\app\node_modules.asar.unpacked\node-pty\build\Release\winpty-agent.exe
   {install_path}\resources\app\node_modules.asar.unpacked\node-pty\build\Release\conpty.node
   {install_path}\resources\app\node_modules.asar.unpacked\node-pty\build\Release\conpty_console_list.node
   ```

4. **Terminal exit codes**  
   If you see an exit code (e.g. **259**, **3221225786**), search for your shell (e.g. “PowerShell”) plus the code; the [aka.ms guide](https://aka.ms/vscode-troubleshoot-terminal-launch) has more detail.

### POS-specific: run without Integrated Terminal

If the terminal still won’t launch:

- **Use Tasks (no terminal needed to start):**  
  **Terminal** → **Run Task** → choose **POS: Run Web (normal)**, **POS: Run Web (debug)**, or **POS: Run Windows (exe)**.  
  These use `-ExecutionPolicy Bypass` and the correct `pos_tawsil` working directory.

- **Use an external terminal:**  
  Open **Windows PowerShell** or **cmd**, then:
  ```powershell
  cd path\to\tawssil-back-you\pos_tawsil
  .\run_pos.ps1 normal
  # or: .\run_windows.ps1 debug
  ```
  If scripts are blocked by execution policy:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\run_pos.ps1 normal
  ```

### Workspace terminal settings

The repo’s **`.vscode/settings.json`** configures:

- **PowerShell** as the default Windows terminal profile  
- **ConPTY** enabled  
- **Automation profile** with `-ExecutionPolicy Bypass` for tasks  

Don’t override these unless you know they cause your issue. Use **@modified** in Settings to spot changes.

## Summary

- **Code changes:** working directory set in `main.cpp`, `asInvoker` in manifest, `run_windows.ps1` launcher.  
- **Most likely cause:** Defender/AV blocking **print_usb_plugin.dll** (or the exe) before startup.  
- **Practical fix:** add an exclusion for the `build` folder and use `run_windows.ps1` or run the exe from its `Debug`/`Release` folder.
