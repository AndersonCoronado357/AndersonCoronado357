# Genera iconos de contacto tipo "bolita" en la paleta del perfil: circulo con
# degradado cian->navy, icono blanco de la red y, al lado, el nombre/usuario.
# Todos del mismo ancho para que queden alineados en una columna vertical.
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

$contacts = @(
  @{ file = "ic-github.svg"; icon = "simple-icons/github"; text = "AndersonCoronado357" },
  @{ file = "ic-email.svg"; icon = "simple-icons/gmail"; text = "Correo" },
  @{ file = "ic-linkedin.svg"; icon = "mdi/linkedin"; text = "LinkedIn" },
  @{ file = "ic-whatsapp.svg"; icon = "simple-icons/whatsapp"; text = "WhatsApp" },
  @{ file = "ic-spotify.svg"; icon = "simple-icons/spotify"; text = "Spotify" }
)

$tx = 50; $fs = 15
# ancho fijo = el mayor necesario, para alinear todos en columna
$maxW = 0
foreach ($c in $contacts) { $w = $tx + [int][math]::Ceiling($c.text.Length * 8.5) + 10; if ($w -gt $maxW) { $maxW = $w } }

foreach ($c in $contacts) {
  try {
    $d = Get-IconPath $c.icon
    $H = 40; $cx = 20; $cy = 20; $r = 19
    $isz = 22; $scale = [math]::Round($isz / 24, 4); $ioff = [math]::Round($cx - $isz / 2, 2)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("<svg xmlns='http://www.w3.org/2000/svg' width='$maxW' height='$H' viewBox='0 0 $maxW $H' role='img'>")
    [void]$sb.AppendLine("<circle cx='$cx' cy='$cy' r='$r' fill='#f2f4f6'/>")
    [void]$sb.AppendLine("<g transform='translate($ioff,$ioff) scale($scale)'><path d='$($d)' fill='#31AED8'/></g>")
    [void]$sb.AppendLine("<text x='$tx' y='25' font-family=`"$ff`" font-size='$fs' font-weight='600' fill='#e9f3f8'>$($c.text)</text>")
    [void]$sb.AppendLine("</svg>")
    [System.IO.File]::WriteAllText((Join-Path $repoRoot $c.file), $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))
    Write-Output "OK $($c.file)"
  } catch { Write-Output ("FALLO {0}: {1}" -f $c.file, $_.Exception.Message) }
}
Write-Output "ancho_columna=$maxW"
