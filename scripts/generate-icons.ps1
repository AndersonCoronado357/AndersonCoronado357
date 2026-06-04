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
    $S = 44; $cx = 22; $cy = 22; $r = 21
    $isz = 22; $scale = [math]::Round($isz / 24, 4); $ioff = [math]::Round($cx - $isz / 2, 2)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("<svg xmlns='http://www.w3.org/2000/svg' width='$S' height='$S' viewBox='0 0 $S $S' role='img'>")
    [void]$sb.AppendLine("<circle cx='$cx' cy='$cy' r='$r' fill='#f2f4f6'/>")
    [void]$sb.AppendLine("<g transform='translate($ioff,$ioff) scale($scale)'><path d='$($d)' fill='#31AED8'/></g>")
    [void]$sb.AppendLine("</svg>")
    [System.IO.File]::WriteAllText((Join-Path $repoRoot $c.file), $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))
    Write-Output "OK $($c.file)"
  } catch { Write-Output ("FALLO {0}: {1}" -f $c.file, $_.Exception.Message) }
}
