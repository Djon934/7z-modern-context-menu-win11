param([Parameter(Mandatory)][string]$Version, [string]$Out = 'release-notes.md')
$text = Get-Content CHANGELOG.md -Raw -Encoding UTF8
$pattern = "(?ms)^## \[$([regex]::Escape($Version))\][^\r\n]*\r?\n(.*?)(?=^## \[|\z)"
$m = [regex]::Match($text, $pattern)
if (-not $m.Success) { throw "В CHANGELOG.md нет раздела для версии $Version" }
$m.Groups[1].Value.Trim() | Set-Content $Out -Encoding UTF8
