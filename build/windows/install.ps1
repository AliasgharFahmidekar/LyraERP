param([Parameter(Mandatory=$true)][string]$Config)
$ErrorActionPreference = 'Stop'
$appRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$programData = Join-Path $env:ProgramData 'LyraERP'
$dataDir = Join-Path $programData 'data'
$logDir = Join-Path $programData 'logs'
New-Item -ItemType Directory -Force $programData,$dataDir,$logDir | Out-Null
function Get-IniValue([string]$key, [string]$default='') {
  $line = Select-String -Path $Config -Pattern ('^' + [regex]::Escape($key) + '=') | Select-Object -First 1
  if ($line) { return $line.Line.Substring($key.Length + 1) }
  return $default
}
$adminName = Get-IniValue 'AdminName' 'Administrator'
$adminEmail = Get-IniValue 'AdminEmail' 'admin@lyraerp.local'
$adminPassword = Get-IniValue 'AdminPassword'
if ([string]::IsNullOrWhiteSpace($adminPassword)) { throw 'Admin password is required.' }
$envText = @(
'APP_NAME=LyraERP',
'APP_ENV=production',
'APP_KEY=',
'APP_DEBUG=false',
'APP_TIMEZONE=UTC',
'APP_URL=http://127.0.0.1:8090',
'APP_LOCALE=en',
'APP_FALLBACK_LOCALE=en',
'APP_CURRENCY=USD',
'APP_MAINTENANCE_DRIVER=file',
'BCRYPT_ROUNDS=12',
'LOG_CHANNEL=stack',
'LOG_STACK=single',
'LOG_DEPRECATIONS_CHANNEL=null',
'LOG_LEVEL=warning',
'DB_CONNECTION=sqlite',
('DB_DATABASE=' + ($dataDir.Replace('\','/')) + '/lyraerp.sqlite'),
'SESSION_DRIVER=database',
'SESSION_LIFETIME=120',
'SESSION_ENCRYPT=false',
'SESSION_PATH=/',
'SESSION_DOMAIN=null',
'BROADCAST_CONNECTION=log',
'FILESYSTEM_DISK=public',
'QUEUE_CONNECTION=database',
'CACHE_STORE=database',
'CACHE_PREFIX=lyraerp_',
'MAIL_MAILER=log',
'MAIL_FROM_ADDRESS=hello@lyraerp.local',
'MAIL_FROM_NAME=LyraERP'
)
$envText | Set-Content -Path (Join-Path $appRoot '.env') -Encoding UTF8
$php = Join-Path $appRoot 'php\php.exe'
if (-not (Test-Path $php)) { throw ('PHP runtime not found: ' + $php) }
$dbFile = Join-Path $dataDir 'lyraerp.sqlite'
if (-not (Test-Path $dbFile)) { New-Item -ItemType File -Path $dbFile | Out-Null }
& $php artisan key:generate --force
if ($LASTEXITCODE -ne 0) { throw 'Failed to generate application key.' }
& $php artisan erp:install "--admin-name=$adminName" "--admin-email=$adminEmail" "--admin-password=$adminPassword"
if ($LASTEXITCODE -ne 0) { throw 'LyraERP initial installation failed.' }
& $php artisan optimize
if ($LASTEXITCODE -ne 0) { throw 'Laravel optimization failed.' }
& $php artisan storage:link
$nssm = Join-Path $appRoot 'tools\nssm.exe'
if (-not (Test-Path $nssm)) { throw ('NSSM not found: ' + $nssm) }
$service = 'LyraERP'
& $nssm stop $service confirm 2>$null
& $nssm remove $service confirm 2>$null
& $nssm install $service $php
& $nssm set $service AppDirectory $appRoot
& $nssm set $service AppParameters 'artisan serve --host=127.0.0.1 --port=8090'
& $nssm set $service DisplayName 'LyraERP'
& $nssm set $service Description 'LyraERP local ERP web service'
& $nssm set $service Start SERVICE_AUTO_START
& $nssm set $service AppExit Default Restart
& $nssm set $service AppRestartDelay 3000
& $nssm set $service AppStdout (Join-Path $logDir 'server.log')
& $nssm set $service AppStderr (Join-Path $logDir 'server-error.log')
& $nssm start $service
if ($LASTEXITCODE -ne 0) { throw 'Failed to start LyraERP Windows service.' }
Set-Content (Join-Path $programData 'INSTALLATION_COMPLETE.txt') @(
'LyraERP installation completed.',
'URL: http://127.0.0.1:8090',
('Admin: ' + $adminEmail)
)
Remove-Item $Config -Force -ErrorAction SilentlyContinue
