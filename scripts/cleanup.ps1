Write-Host "Cleaning unused Docker resources..." -ForegroundColor Cyan

docker container prune -f
docker image prune -f

Write-Host "Cleanup completed." -ForegroundColor Green
