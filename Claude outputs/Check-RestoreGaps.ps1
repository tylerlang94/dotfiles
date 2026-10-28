<#
.SYNOPSIS
  Reads the raw FTP-log extract (deleted_files.txt from Select-String), pulls out the files
  ajackson deleted on Oct 26 between 5:50 and 6:20 PM MDT (23:50-00:20 UTC), and lists any that
  are still missing under -Root.

.EXAMPLE
  .\Check-RestoreGaps.ps1 -LogExtract C:\Users\tyleradmin\deleted_files.txt -Root E:\SFTP-Root\Engineering
#>
param(
    [Parameter(Mandatory)] [string]$LogExtract,
    [string]$Root    = 'E:\SFTP-Root\Engineering',
    [string]$User    = 'ajackson',
    [datetime]$FromUtc = '2026-10-26 23:50:00',
    [datetime]$ToUtc   = '2026-10-27 00:20:00',
    [string]$OutPath = 'C:\Temp\still_missing.csv'
)

# Get-Content detects the UTF-16 BOM. Select-String output was hard-wrapped, so rejoin lines.
$text = (Get-Content -LiteralPath $LogExtract -Raw) -replace "`r?`n", ''

# W3C fields: date time c-ip c-port cs-username s-sitename s-computername - s-ip s-port cs-method cs-uri-stem sc-status
$pattern = '(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d) \S+ \d+ \S+\\' + [regex]::Escape($User) +
           ' (?:\S+ ){5}DELE (\S+) 250 '
$hits = [regex]::Matches($text, $pattern)
Write-Host ("Parsed {0} DELE records for {1} in the whole extract" -f $hits.Count, $User)

$seen = @{}
$missing = foreach ($m in $hits) {
    $ts = [datetime]$m.Groups[1].Value
    if ($ts -lt $FromUtc -or $ts -gt $ToUtc) { continue }
    $ftp = $m.Groups[2].Value
    if ($ftp -match '(^|/)\._|\.DS_Store') { continue }      # macOS junk
    $rel = $ftp.Trim('/')
    if ($seen.ContainsKey($rel)) { continue }
    $seen[$rel] = $true

    $full = Join-Path $Root ($rel -replace '/', '\')
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
        [pscustomobject]@{
            deleted_utc      = $m.Groups[1].Value
            ftp_path         = $ftp
            windows_path     = $full
            path_is_relative = -not $ftp.StartsWith('/')
        }
    }
}

New-Item -ItemType Directory -Force -Path (Split-Path $OutPath) | Out-Null
@($missing) | Export-Csv $OutPath -NoTypeInformation

Write-Host ("Checked {0} unique files in the window under {1}" -f $seen.Count, $Root)
Write-Host ("Still missing: {0}  ->  {1}" -f @($missing).Count, $OutPath)
if (@($missing).Count) {
    $missing | Group-Object { ($_.ftp_path.Trim('/') -split '/')[0..2] -join '/' } |
        Sort-Object Count -Descending | Select-Object Count, Name -First 20 | Format-Table -AutoSize
}
