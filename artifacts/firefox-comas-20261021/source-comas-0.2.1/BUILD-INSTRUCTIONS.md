# Source and build instructions — SGO DXN Capture COMAS 0.2.1

This source package reproduces the self-distributed COMAS Firefox add-on submitted to Mozilla for signing.

## Files

- `sgo_dnx_extension_dev/manifest.json`, `background.js`, and `content-sgo.js`: shared Firefox bridge sources. The build script adapts the local development origin to COMAS.
- `sgo_dnx_extension/content-dxn.js`: the OBS capture buttons and parser used by the COMAS package.
- `sgo_dnx_extension_dev/scripts/build-firefox.ps1`: generates the COMAS manifest, copies the runtime sources, and packages the XPI/ZIP.

## Build on Windows PowerShell

From this folder, run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\sgo_dnx_extension_dev\scripts\build-firefox.ps1 -Target comas -OutputDirectory .\output
```

The generated files appear in `output`. The script uses only Windows PowerShell/.NET built-in ZIP and JSON support; it does not download dependencies. Mozilla signing is performed separately through the AMO Developer Hub.