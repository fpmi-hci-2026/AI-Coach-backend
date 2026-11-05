# Smoke-tests wrapper for Windows PowerShell.
# Requires Python 3.8+ and a running Prism mock (or real backend).
# Usage:
#   powershell -ExecutionPolicy Bypass -File api-tests/smoke-test.ps1
#   powershell -ExecutionPolicy Bypass -File api-tests/smoke-test.ps1 -BaseUrl http://localhost:8000

param(
    [string]$BaseUrl = "http://localhost:4010"
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
python "$ScriptDir\smoke-test.py" --base-url $BaseUrl
exit $LASTEXITCODE
