# Genera iconos de contacto tipo "bolita": circulo blanco con el icono de la red
# en el cian de la paleta. Solo icono (sin texto), cuadrados, para ir en fila.
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$repoRoot = (Resolve-Path (Join-Path (Split-Path -Parent $PSCommandPath) "..")).Path

function Get-IconPath([string]$iconRef) {
  $u = "https://api.iconify.design/$iconRef.svg"
  $svg = (Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 25).Content
  if ($svg -match 'd="([^"]+)"') { return $Matches[1] }
  throw "Sin path para $iconRef"
}

$contacts = @(
  @{ file = "ic-github.svg"; icon = "simple-icons/github" },
  @{ file = "ic-email.svg"; icon = "simple-icons/gmail" },
  @{ file = "ic-linkedin.svg"; icon = "mdi/linkedin" },
  @{ file = "ic-whatsapp.svg"; icon = "simple-icons/whatsapp" },
  @{ file = "ic-spotify.svg"; icon = "simple-icons/spotify" }
)

foreach ($c in $contacts) {
  try {
    $d = Get-IconPath $c.icon
    $S = 48; $cx = 24; $cy = 24; $r = 21
    $isz = 22; $scale = [math]::Round($isz / 24, 4); $ioff = [math]::Round($cx - $isz / 2, 2)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("<svg xmlns='http://www.w3.org/2000/svg' width='$S' height='$S' viewBox='0 0 $S $S' role='img'>")
    [void]$sb.AppendLine("<defs><filter id='s' x='-40%' y='-40%' width='180%' height='180%'><feDropShadow dx='0' dy='1.5' stdDeviation='1.6' flood-color='#0b1a2b' flood-opacity='0.35'/></filter></defs>")
    [void]$sb.AppendLine("<circle cx='$cx' cy='$cy' r='$r' fill='#ffffff' filter='url(#s)'/>")
    [void]$sb.AppendLine("<g transform='translate($ioff,$ioff) scale($scale)'><path d='$($d)' fill='#1b1f24'/></g>")
    [void]$sb.AppendLine("</svg>")
    [System.IO.File]::WriteAllText((Join-Path $repoRoot $c.file), $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))
    Write-Output "OK $($c.file)"
  } catch { Write-Output ("FALLO {0}: {1}" -f $c.file, $_.Exception.Message) }
}
