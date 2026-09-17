# Genera activity.svg: las contribuciones de los ultimos seis meses, dia a dia.
# Sustituye al servicio externo github-readme-activity-graph, que se quedo sin
# cuota y devuelve 402. Mismo diseno que languages.svg: fondo #0d1117, gris y
# el amarillo #e5b80b como acento. Token: GH_TOKEN / GITHUB_TOKEN o GCM.
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
$headers = @{ Authorization = "Bearer $tok"; "User-Agent" = "activity-graph" }

# Duenno del repo en Actions; en local, el usuario del token.
$login = $env:GITHUB_REPOSITORY_OWNER
if (-not $login) {
  $me = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers
  $login = $me.login
}

# GitHub solo entrega un anno por consulta; aqui van seis meses.
$hasta = (Get-Date).ToUniversalTime()
$desde = $hasta.AddMonths(-6).Date

$query = 'query($login:String!,$from:DateTime!,$to:DateTime!){user(login:$login){contributionsCollection(from:$from,to:$to){contributionCalendar{totalContributions weeks{contributionDays{date contributionCount}}}}}}'
$body = @{
  query     = $query
  variables = @{
    login = $login
    from  = $desde.ToString("yyyy-MM-ddTHH:mm:ssZ")
    to    = $hasta.ToString("yyyy-MM-ddTHH:mm:ssZ")
  }
} | ConvertTo-Json -Depth 6 -Compress

$resp = Invoke-RestMethod -Uri "https://api.github.com/graphql" -Method Post -Headers $headers -Body $body -ContentType "application/json"
if ($resp.errors) { throw ("GraphQL: " + ($resp.errors | ConvertTo-Json -Compress)) }

$cal = $resp.data.user.contributionsCollection.contributionCalendar
$dias = @()
foreach ($w in $cal.weeks) {
  foreach ($d in $w.contributionDays) {
    $dias += [pscustomobject]@{ fecha = [datetime]::Parse($d.date); n = [int]$d.contributionCount }
  }
}
$dias = @($dias | Sort-Object fecha)
if ($dias.Count -lt 2) { throw "Sin datos de contribuciones." }

$total = [int]$cal.totalContributions
$maxDia = ($dias | Measure-Object -Property n -Maximum).Maximum
if ($maxDia -lt 1) { $maxDia = 1 }
$tope = [int][math]::Ceiling($maxDia / 5.0) * 5
if ($tope -lt 5) { $tope = 5 }

# ---------- lienzo ----------
$W = 880; $H = 260
$izq = 44; $der = 22; $arriba = 84; $abajo = 34
$gx = $izq; $gy = $arriba; $gw = $W - $izq - $der; $gh = $H - $arriba - $abajo
$ff = "'Segoe UI',system-ui,-apple-system,Helvetica,Arial,sans-serif"
$meses = @("ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic")

$n = $dias.Count
$px = @()
for ($i = 0; $i -lt $n; $i++) {
  $x = $gx + ($gw * $i / ($n - 1))
  $y = $gy + $gh - ($gh * $dias[$i].n / $tope)
  $px += [pscustomobject]@{ x = [math]::Round($x, 2); y = [math]::Round($y, 2); d = $dias[$i] }
}

$linea = ($px | ForEach-Object { "$($_.x),$($_.y)" }) -join " "
$area = "$($px[0].x),$($gy + $gh) " + $linea + " $($px[$n-1].x),$($gy + $gh)"

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("<svg xmlns='http://www.w3.org/2000/svg' width='$W' height='$H' viewBox='0 0 $W $H' role='img'>")
[void]$sb.AppendLine("<style>text{font-family:$ff}</style>")
[void]$sb.AppendLine("<defs><linearGradient id='relleno' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#e5b80b' stop-opacity='0.45'/><stop offset='1' stop-color='#e5b80b' stop-opacity='0.02'/></linearGradient></defs>")
[void]$sb.AppendLine("<rect x='0.5' y='0.5' width='$($W-1)' height='$($H-1)' rx='14' fill='#0d1117' stroke='#30363d'/>")
[void]$sb.AppendLine("<text x='$izq' y='38' fill='#e6edf3' font-size='18' font-weight='600'>Actividad de los ultimos seis meses</text>")
[void]$sb.AppendLine("<rect x='$izq' y='46' width='34' height='3' rx='1.5' fill='#e5b80b'/>")
[void]$sb.AppendLine("<text x='$izq' y='64' fill='#8b949e' font-size='11'>$total contribuciones &#183; maximo de $maxDia en un dia &#183; se actualiza automaticamente</text>")

# Rejilla horizontal con sus valores.
foreach ($f in @(0, 0.5, 1)) {
  $y = [math]::Round($gy + $gh - $gh * $f, 2)
  $v = [int][math]::Round($tope * $f)
  [void]$sb.AppendLine("<line x1='$gx' y1='$y' x2='$($gx+$gw)' y2='$y' stroke='#21262d'/>")
  [void]$sb.AppendLine("<text x='$($gx-10)' y='$($y+4)' fill='#8b949e' font-size='10.5' text-anchor='end'>$v</text>")
}

[void]$sb.AppendLine("<polygon points='$area' fill='url(#relleno)'/>")
[void]$sb.AppendLine("<polyline points='$linea' fill='none' stroke='#e5b80b' stroke-width='2' stroke-linejoin='round' stroke-linecap='round'/>")

# Marca del dia con mas contribuciones.
$pico = $px | Sort-Object { $_.d.n } -Descending | Select-Object -First 1
[void]$sb.AppendLine("<circle cx='$($pico.x)' cy='$($pico.y)' r='3.5' fill='#fff0b0' stroke='#0d1117' stroke-width='1.5'/>")

# Eje de meses: una marca en el primer dia de cada mes.
$mesPrevio = -1
foreach ($p in $px) {
  if ($p.d.fecha.Month -ne $mesPrevio) {
    $mesPrevio = $p.d.fecha.Month
    $etq = $meses[$p.d.fecha.Month - 1]
    [void]$sb.AppendLine("<line x1='$($p.x)' y1='$($gy+$gh)' x2='$($p.x)' y2='$($gy+$gh+5)' stroke='#30363d'/>")
    [void]$sb.AppendLine("<text x='$($p.x)' y='$($gy+$gh+20)' fill='#8b949e' font-size='11' text-anchor='middle'>$etq</text>")
  }
}
[void]$sb.AppendLine("</svg>")

$repoRoot = (Resolve-Path (Join-Path (Split-Path -Parent $PSCommandPath) "..")).Path
[System.IO.File]::WriteAllText((Join-Path $repoRoot "activity.svg"), $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))
Write-Output "WROTE activity.svg | dias=$n total=$total max=$maxDia tope=$tope"
