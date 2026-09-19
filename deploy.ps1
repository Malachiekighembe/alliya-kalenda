# Script de déploiement Alliya Kalenda sur Vercel
# Exécuter depuis la racine du projet

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

Write-Host '=== Building Flutter Web ==='
flutter config --enable-web
flutter pub get
if ($LASTEXITCODE -ne 0) { Write-Host 'pub get failed'; exit 1 }

flutter build web --release
if ($LASTEXITCODE -ne 0) { Write-Host 'flutter build failed'; exit 1 }

Write-Host '=== Build complete, checking files ==='
if (-not (Test-Path 'build/web/index.html')) {
    Write-Host 'index.html not found'; exit 1
}
if (-not (Test-Path 'build/web/main.dart.js')) {
    Write-Host 'main.dart.js not found'; exit 1
}

Write-Host '=== Pushing to deploy branch ==='
$branch = 'deploy'
$commitMsg = "Deploy Flutter Web build $(Get-Date -Format 'yyyy-MM-dd HH:mm') [skip ci]"

git checkout $branch 2>$null
if ($LASTEXITCODE -ne 0) {
    git checkout -b $branch
}

git add -f build/web/*
git add vercel.json
git commit -m $commitMsg
git push origin $branch --force

Write-Host '=== Deploy pushed to GitHub ==='
Write-Host 'Vercel will auto-deploy from the deploy branch.'
Write-Host 'Check https://alliyakalenda.vercel.app/'
