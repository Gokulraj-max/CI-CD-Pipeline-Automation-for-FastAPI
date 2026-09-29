param(
    [string]$ImageName = "ci-cd-api",
    [string]$ImageTag = "latest",
    [string]$ContainerName = "ci-cd-api",
    [int]$AppPort = 8001
)

$FullImage = "${ImageName}:${ImageTag}"
$BackupContainer = "${ContainerName}_previous"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Starting Windows Docker Deployment" -ForegroundColor Cyan
Write-Host "Target Image     : $FullImage"
Write-Host "Container Name   : $ContainerName"
Write-Host "Host Port        : $AppPort"
Write-Host "=================================================="

# Check if image exists
$imageCheck = docker images -q $FullImage
if (-not $imageCheck) {
    Write-Host "ERROR: Target image $FullImage does not exist locally." -ForegroundColor Red
    exit 1
}

# Preserve old container
$existing = docker ps -a -q -f "name=^${ContainerName}$"
if ($existing) {
    Write-Host "Backing up existing container..."
    docker rm -f $BackupContainer 2>$null | Out-Null
    docker rename $ContainerName $BackupContainer 2>$null | Out-Null
    docker stop $BackupContainer 2>$null | Out-Null
}

# Run new container
Write-Host "Running new container $ContainerName..."
docker run -d --name $ContainerName --restart unless-stopped -p "${AppPort}:8000" $FullImage

# Poll health check
$Healthy = $false
$HealthUrl = "http://localhost:${AppPort}/health"

for ($i = 1; $i -le 15; $i++) {
    try {
        $res = Invoke-RestMethod -Uri $HealthUrl -Method Get -TimeoutSec 3
        if ($res.status -eq "healthy") {
            $Healthy = $true
            Write-Host "Health check passed on attempt $i/15." -ForegroundColor Green
            break
        }
    } catch {
        Write-Host "Waiting for container to be healthy (attempt $i/15)..."
        Start-Sleep -Seconds 2
    }
}

if ($Healthy) {
    Write-Host "Deployment succeeded! Removing backup container..." -ForegroundColor Green
    docker rm -f $BackupContainer 2>$null | Out-Null
    exit 0
} else {
    Write-Host "ERROR: Health check failed! Rolling back..." -ForegroundColor Red
    docker logs --tail 30 $ContainerName
    docker rm -f $ContainerName 2>$null | Out-Null
    if ($existing) {
        docker start $BackupContainer 2>$null | Out-Null
        docker rename $BackupContainer $ContainerName 2>$null | Out-Null
        Write-Host "Rollback to previous container completed." -ForegroundColor Yellow
    }
    exit 1
}
