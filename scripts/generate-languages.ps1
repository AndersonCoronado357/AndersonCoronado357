# Genera languages.svg y stats.svg con datos de TODOS los repos (publicos y
# privados). Diseno sobrio: fondo neutro oscuro, escala de grises y el cian
# #31AED8 solo como acento minimo. Token: GH_TOKEN / GITHUB_TOKEN o GCM.
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Get-Token {
  if ($env:GH_TOKEN) { return $env:GH_TOKEN }
  if ($env:GITHUB_TOKEN) { return $env:GITHUB_TOKEN }
  $tmp = [System.IO.Path]::GetTempFileName()
  [System.IO.File]::WriteAllText($tmp, "protocol=https`nhost=github.com`n`n", (New-Object System.Text.UTF8Encoding($false)))
  $out = & cmd /c "git -c credential.interactive=false credential fill < `"$tmp`"" 2>&1 | Out-String
  Remove-Item $tmp -Force
  foreach ($l in ($out -split "`n")) { if ($l -match '^password=(.+?)\s*$') { return $Matches[1] } }
  throw "No hay token. Define GH_TOKEN."
}

$tok = Get-Token
$headers = @{ Authorization = "Bearer $tok"; "User-Agent" = "lang-stats"; Accept = "application/vnd.github+json" }

$repos = @()
$page = 1
while ($true) {
  $batch = Invoke-RestMethod -Uri "https://api.github.com/user/repos?per_page=100&affiliation=owner&visibility=all&page=$page" -Headers $headers
  if (-not $batch -or $batch.Count -eq 0) { break }
  $repos += $batch
  if ($batch.Count -lt 100) { break }
  $page++
}

$lang = @{}
foreach ($r in $repos) {
  try {
    $lr = Invoke-RestMethod -Uri ("https://api.github.com/repos/{0}/languages" -f $r.full_name) -Headers $headers
    foreach ($p in $lr.PSObject.Properties) {
      if ($lang.ContainsKey($p.Name)) { $lang[$p.Name] += [double]$p.Value } else { $lang[$p.Name] = [double]$p.Value }
    }
  } catch { }
}

$total = ($lang.Values | Measure-Object -Sum).Sum
if (-not $total -or $total -le 0) { throw "Sin datos de lenguajes." }

$sorted = $lang.GetEnumerator() | Sort-Object Value -Descending
$top = @($sorted | Select-Object -First 8)
$restSum = (@($sorted | Select-Object -Skip 8) | Measure-Object -Property Value -Sum).Sum

$items = @()
foreach ($e in $top) { $items += [pscustomobject]@{ name = $e.Key; pct = [math]::Round($e.Value / $total * 100, 1) } }
if ($restSum -gt 0) { $items += [pscustomobject]@{ name = "Otros"; pct = [math]::Round($restSum / $total * 100, 1) } }

# Color real de cada lenguaje (paleta oficial de GitHub Linguist); Otros en gris.
$colors = @{
  "JavaScript" = "#f1e05a"; "TypeScript" = "#3178c6"; "C#" = "#178600"; "Blade" = "#f7523f";
  "HTML" = "#e34c26"; "Svelte" = "#ff3e00"; "PHP" = "#4F5D95"; "CSS" = "#563d7c";
  "PLpgSQL" = "#336790"; "ASP.NET" = "#9400ff"; "Python" = "#3572A5"; "Java" = "#b07219";
  "Vue" = "#41b883"; "Shell" = "#89e051"; "Dockerfile" = "#384d54"; "SCSS" = "#c6538c";
  "Dart" = "#00B4AB"; "Kotlin" = "#A97BFF"; "Go" = "#00ADD8"; "Ruby" = "#701516";
  "C++" = "#f34b7d"; "C" = "#555555"; "Otros" = "#8b949e"
}
foreach ($it in $items) {
  $c = if ($colors.ContainsKey($it.name)) { $colors[$it.name] } else { "#8b949e" }
  $it | Add-Member -NotePropertyName color -NotePropertyValue $c
}
$n = $items.Count

$ff = "'Segoe UI',system-ui,-apple-system,Helvetica,Arial,sans-serif"
$repoRoot = (Resolve-Path (Join-Path (Split-Path -Parent $PSCommandPath) "..")).Path

# ---------- languages.svg ----------
$W = 520; $pad = 24
$barX = $pad; $barY = 74; $barW = $W - 2 * $pad; $barH = 16
$rows = [math]::Ceiling($n / 2)
$legendTop = 110; $rowH = 25
$H = $legendTop + $rows * $rowH + 6

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("<svg xmlns='http://www.w3.org/2000/svg' width='$W' height='$H' viewBox='0 0 $W $H' role='img'>")
[void]$sb.AppendLine("<style>text{font-family:$ff}</style>")
[void]$sb.AppendLine("<rect x='0.5' y='0.5' width='$($W-1)' height='$($H-1)' rx='14' fill='#0d1117' stroke='#30363d'/>")
[void]$sb.AppendLine("<text x='$pad' y='38' fill='#e6edf3' font-size='18' font-weight='600'>Lenguajes mas usados</text>")
[void]$sb.AppendLine("<rect x='$pad' y='46' width='34' height='3' rx='1.5' fill='#31AED8'/>")
[void]$sb.AppendLine("<text x='$pad' y='64' fill='#8b949e' font-size='11'>Incluye repositorios privados &#183; se actualiza automaticamente</text>")
[void]$sb.AppendLine("<defs><clipPath id='bar'><rect x='$barX' y='$barY' width='$barW' height='$barH' rx='8'/></clipPath></defs>")
[void]$sb.AppendLine("<g clip-path='url(#bar)'>")
[void]$sb.AppendLine("<rect x='$barX' y='$barY' width='$barW' height='$barH' fill='#21262d'/>")
$cx = [double]$barX
foreach ($it in $items) {
  $segW = [math]::Round($it.pct / 100 * $barW, 2)
  [void]$sb.AppendLine("<rect x='$cx' y='$barY' width='$segW' height='$barH' fill='$($it.color)'/>")
  $cx = $cx + $segW
}
[void]$sb.AppendLine("</g>")
$idx = 0
foreach ($it in $items) {
  $col = $idx % 2
  $row = [math]::Floor($idx / 2)
  $x = if ($col -eq 0) { $pad } else { [int]($W / 2) + 8 }
  $y = $legendTop + $row * $rowH
  $name = $it.name -replace '&', '&amp;'
  [void]$sb.AppendLine("<circle cx='$($x+5)' cy='$($y-4)' r='5' fill='$($it.color)'/>")
  [void]$sb.AppendLine("<text x='$($x+18)' y='$y' fill='#d4dde4' font-size='12.5'>$name <tspan fill='$($it.color)' font-weight='700'>$($it.pct)%</tspan></text>")
  $idx++
}
[void]$sb.AppendLine("</svg>")
[System.IO.File]::WriteAllText((Join-Path $repoRoot "languages.svg"), $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))

# ---------- stats.svg ----------
$distinct = $lang.Count
$principal = $top[0].Key
$totalRepos = $repos.Count
$priv = (@($repos | Where-Object { $_.private }).Count)
$tiles = @(
  @{ v = "$totalRepos"; l = "Repositorios" },
  @{ v = "$priv"; l = "Privados" },
  @{ v = "$distinct"; l = "Lenguajes" },
  @{ v = "$principal"; l = "Principal" }
)
$SW = 520; $sp = 24; $SH = 150
$tw = ($SW - 2 * $sp) / $tiles.Count

$s2 = New-Object System.Text.StringBuilder
[void]$s2.AppendLine("<svg xmlns='http://www.w3.org/2000/svg' width='$SW' height='$SH' viewBox='0 0 $SW $SH' role='img'>")
[void]$s2.AppendLine("<style>text{font-family:$ff}</style>")
[void]$s2.AppendLine("<rect x='0.5' y='0.5' width='$($SW-1)' height='$($SH-1)' rx='14' fill='#0d1117' stroke='#30363d'/>")
[void]$s2.AppendLine("<text x='$sp' y='40' fill='#e6edf3' font-size='18' font-weight='600'>GitHub en numeros</text>")
[void]$s2.AppendLine("<rect x='$sp' y='48' width='34' height='3' rx='1.5' fill='#31AED8'/>")
for ($i = 0; $i -lt $tiles.Count; $i++) {
  $cxc = [int]($sp + $i * $tw + $tw / 2)
  if ($i -gt 0) { $lx = [int]($sp + $i * $tw); [void]$s2.AppendLine("<line x1='$lx' y1='86' x2='$lx' y2='128' stroke='#21262d'/>") }
  $val = $tiles[$i].v -replace '&', '&amp;'
  $fs = if ($val -match '^\d+$') { 28 } else { 15 }
  $vy = if ($val -match '^\d+$') { 108 } else { 104 }
  [void]$s2.AppendLine("<text x='$cxc' y='$vy' fill='#31AED8' font-size='$fs' font-weight='700' text-anchor='middle'>$val</text>")
  [void]$s2.AppendLine("<text x='$cxc' y='130' fill='#8b949e' font-size='11' text-anchor='middle'>$($tiles[$i].l)</text>")
}
[void]$s2.AppendLine("</svg>")
[System.IO.File]::WriteAllText((Join-Path $repoRoot "stats.svg"), $s2.ToString(), (New-Object System.Text.UTF8Encoding($false)))

Write-Output "WROTE languages.svg + stats.svg | langs=$n distinct=$distinct repos=$totalRepos priv=$priv principal=$principal total_bytes=$total"
