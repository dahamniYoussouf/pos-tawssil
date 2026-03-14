# Envoie un fichier binaire en RAW vers une imprimante Windows par nom.
# Usage: .\print-raw-windows.ps1 -PrinterName "xprinter 2" -FilePath "C:\...\file.bin"
# Exit: 0 = OK, 1 = erreur

param(
  [Parameter(Mandatory=$true)][string]$PrinterName,
  [Parameter(Mandatory=$true)][string]$FilePath
)

$ErrorActionPreference = "Stop"
if (-not (Test-Path -LiteralPath $FilePath)) { Write-Error "Fichier introuvable: $FilePath"; exit 1 }

$code = @'
using System;
using System.Runtime.InteropServices;
[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct DOCINFOW { public string pDocName; public string pOutputFile; public string pDataType; }
public class RawPrinter {
  [DllImport("winspool.Drv", EntryPoint = "OpenPrinterW", SetLastError = true, CharSet = CharSet.Unicode)]
  public static extern bool OpenPrinter(string pPrinterName, out IntPtr phPrinter, IntPtr pDefault);
  [DllImport("winspool.Drv", EntryPoint = "ClosePrinter", SetLastError = true)]
  public static extern bool ClosePrinter(IntPtr hPrinter);
  [DllImport("winspool.Drv", EntryPoint = "StartDocPrinterW", SetLastError = true, CharSet = CharSet.Unicode)]
  public static extern bool StartDocPrinter(IntPtr hPrinter, int Level, ref DOCINFOW pDocInfo);
  [DllImport("winspool.Drv", EntryPoint = "EndDocPrinter", SetLastError = true)]
  public static extern bool EndDocPrinter(IntPtr hPrinter);
  [DllImport("winspool.Drv", EntryPoint = "StartPagePrinter", SetLastError = true)]
  public static extern bool StartPagePrinter(IntPtr hPrinter);
  [DllImport("winspool.Drv", EntryPoint = "EndPagePrinter", SetLastError = true)]
  public static extern bool EndPagePrinter(IntPtr hPrinter);
  [DllImport("winspool.Drv", EntryPoint = "WritePrinter", SetLastError = true)]
  public static extern bool WritePrinter(IntPtr hPrinter, IntPtr pBytes, int dwCount, out int dwWritten);

  public static bool SendRaw(string printerName, byte[] data) {
    IntPtr hPrinter = IntPtr.Zero;
    try {
      if (!OpenPrinter(printerName, out hPrinter, IntPtr.Zero)) return false;
      DOCINFOW di; di.pDocName = "Tawsil"; di.pOutputFile = null; di.pDataType = "RAW";
      if (!StartDocPrinter(hPrinter, 1, ref di)) return false;
      if (!StartPagePrinter(hPrinter)) return false;
      int written;
      var h = GCHandle.Alloc(data, GCHandleType.Pinned);
      try {
        if (!WritePrinter(hPrinter, h.AddrOfPinnedObject(), data.Length, out written)) return false;
      } finally { h.Free(); }
      EndPagePrinter(hPrinter);
      EndDocPrinter(hPrinter);
      return true;
    } finally { if (hPrinter != IntPtr.Zero) ClosePrinter(hPrinter); }
  }
}
'@
try { Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue } catch {}
$bytes = [System.IO.File]::ReadAllBytes($FilePath)
if ([RawPrinter]::SendRaw($PrinterName, $bytes)) { exit 0 }
$err = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
Write-Error "WritePrinter/OpenPrinter a echoue (erreur Win32: $err). Verifiez le nom exact de l'imprimante dans Parametres > Imprimantes."
exit 1
