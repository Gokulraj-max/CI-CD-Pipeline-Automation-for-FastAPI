param(
    [string]$Url = "http://localhost:8001/health"
)

Write-Host "Checking application health at: $Url" -ForegroundColor Cyan

try {
    $response = Invoke-RestMethod -Uri $Url -Method Get -TimeoutSec 5
    if ($response.status -eq "healthy") {
        Write-Host "Application is healthy! Response: $($response | ConvertTo-Json -Compress)" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "Application returned unexpected payload: $($response | ConvertTo-Json -Compress)" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "Application health check failed: $_" -ForegroundColor Red
    exit 1
}
