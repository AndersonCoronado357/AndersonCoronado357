# Genera botones tipo "pill" redondeados y a medida (btn-*.svg) para los
# enlaces de contacto, con el icono oficial de cada marca y la paleta del perfil.
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$repoRoot = (Resolve-Path (Join-Path (Split-Path -Parent $PSCommandPath) "..")).Path
$ff = "'Segoe UI',system-ui,-apple-system,Helvetica,Arial,sans-serif"

function Get-IconPath([string]$slug) {
  $u = "https://raw.githubusercontent.com/simple-icons/simple-icons/develop/icons/$slug.svg"
  $svg = (Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 25).Content
  if ($svg -match 'd="([^"]+)"') { return $Matches[1] }
  throw "Sin path para $slug"
}

function Make-Button([string]$file, [string]$slug, [string]$label) {
  $d = Get-IconPath $slug
  $H = 40; $iconSize = 18; $lx = 16; $gap = 10; $fontSize = 14
  $tx = $lx + $iconSize + $gap
  $tw = [int][math]::Ceiling($label.Length * 8.2)
  $W = $tx + $tw + 16
  $scale = [math]::Round($iconSize / 24, 4)
  $iy = [math]::Round(($H - $iconSize) / 2, 2)
  $rx = [int]($H / 2)
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.AppendLine("<svg xmlns='http://www.w3.org/2000/svg' width='$W' height='$H' viewBox='0 0 $W $H' role='img'>")
  [void]$sb.AppendLine("<defs><linearGradient id='g' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#22405c'/><stop offset='1' stop-color='#13273a'/></linearGradient></defs>")
  [void]$sb.AppendLine("<rect x='0.7' y='0.7' width='$($W-1.4)' height='$($H-1.4)' rx='$rx' fill='url(#g)' stroke='#31AED8' stroke-opacity='0.85' stroke-width='1.3'/>")
  [void]$sb.AppendLine("<g transform='translate($lx,$iy) scale($scale)'><path d='$d' fill='#31AED8'/></g>")
  [void]$sb.AppendLine("<text x='$tx' y='25' font-family=`"$ff`" font-size='$fontSize' font-weight='600' fill='#eaf3f8'>$label</text>")
  [void]$sb.AppendLine("</svg>")
  [System.IO.File]::WriteAllText((Join-Path $repoRoot $file), $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))
  Write-Output "WROTE $file (W=$W, icon_len=$($d.Length))"
}

Make-Button "btn-github.svg" "github" "AndersonCoronado357"
Make-Button "btn-email.svg" "gmail" "Correo"
