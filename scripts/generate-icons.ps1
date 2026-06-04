# Genera iconos de contacto tipo "bolita": circulo claro con el icono de la red
# y, al lado, el nombre/usuario en esa red. Un SVG por contacto (ic-*.svg).
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$repoRoot = (Resolve-Path (Join-Path (Split-Path -Parent $PSCommandPath) "..")).Path
$ff = "'Segoe UI',system-ui,-apple-system,Helvetica,Arial,sans-serif"

function Get-IconPath([string]$iconRef) {
  $u = "https://api.iconify.design/$iconRef.svg"
  $svg = (Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 25).Content
  if ($svg -match 'd="([^"]+)"') { return $Matches[1] }
  throw "Sin path para $iconRef"
}

function Make-Icon([string]$file, [string]$iconRef, [string]$text) {
  $d = Get-IconPath $iconRef
  $H = 40; $cx = 20; $cy = 20; $r = 19
  $isz = 22; $scale = [math]::Round($isz / 24, 4); $ioff = [math]::Round($cx - $isz / 2, 2)
  $tx = 50; $fs = 15
  $tw = [int][math]::Ceiling($text.Length * 8.5)
  $W = $tx + $tw + 6
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.AppendLine("<svg xmlns='http://www.w3.org/2000/svg' width='$W' height='$H' viewBox='0 0 $W $H' role='img'>")
  [void]$sb.AppendLine("<circle cx='$cx' cy='$cy' r='$r' fill='#f2f4f6'/>")
  [void]$sb.AppendLine("<g transform='translate($ioff,$ioff) scale($scale)'><path d='$d' fill='#16202b'/></g>")
  [void]$sb.AppendLine("<text x='$tx' y='25' font-family=`"$ff`" font-size='$fs' font-weight='600' fill='#e9f3f8'>$text</text>")
  [void]$sb.AppendLine("</svg>")
  [System.IO.File]::WriteAllText((Join-Path $repoRoot $file), $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))
  Write-Output "OK $file (W=$W)"
}

$contacts = @(
  @{ file = "ic-github.svg"; icon = "simple-icons/github"; text = "AndersonCoronado357" },
  @{ file = "ic-email.svg"; icon = "simple-icons/gmail"; text = "Correo" },
  @{ file = "ic-linkedin.svg"; icon = "mdi/linkedin"; text = "LinkedIn" },
  @{ file = "ic-instagram.svg"; icon = "simple-icons/instagram"; text = "Instagram" },
  @{ file = "ic-x.svg"; icon = "simple-icons/x"; text = "X" }
)
foreach ($c in $contacts) {
  try { Make-Icon $c.file $c.icon $c.text } catch { Write-Output ("FALLO {0}: {1}" -f $c.file, $_.Exception.Message) }
}
