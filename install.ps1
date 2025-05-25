# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-NOT $isAdmin) {
    Write-Host "⚠️ Not running as administrator. PATH modification may fail." -ForegroundColor Yellow
    Write-Host "ℹ️ Consider running PowerShell as Administrator for full functionality." -ForegroundColor Yellow
} else {
    Write-Host "✅ Running with administrator privileges" -ForegroundColor Green
}

# Define URLs and paths
$mingwUrl = "https://github.com/parameswari-sampath/cpp-auto-setup-windows/releases/download/v1.0.0/cpp.zip"
$zipPath = "$env:TEMP\mingw.zip"
$installPath = "C:\iamdev\MinGW"
$binPath = "$installPath\bin"
$testFolder = "C:\iamdev\cpp-test"
$testFile = "$testFolder\hello.cpp"
$exeFile = "$testFolder\hello.exe"

# 1. Create install directory if it doesn't exist
if (!(Test-Path -Path $installPath)) {
    Write-Host "📁 Creating install directory: $installPath" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $installPath -Force | Out-Null
}

# 2. Download the MinGW ZIP package
Write-Host "🔽 Downloading MinGW package from $mingwUrl ..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $mingwUrl -OutFile $zipPath
    Write-Host "✅ Download completed successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to download MinGW package: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# 3. Extract the archive to the target location
Write-Host "📦 Extracting MinGW to $installPath ..." -ForegroundColor Cyan
try {
    Expand-Archive -Path $zipPath -DestinationPath $installPath -Force
    Write-Host "✅ Extraction completed successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to extract archive: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# 4. Add MinGW bin folder to system PATH if not already present
Write-Host "🔧 Checking system PATH..." -ForegroundColor Cyan
$currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")

if ($currentPath -notlike "*$binPath*") {
    try {
        if ($isAdmin) {
            # Try to update system PATH (requires admin)
            $newPath = "$currentPath;$binPath"
            [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
            Write-Host "✅ Added $binPath to system PATH." -ForegroundColor Green
        } else {
            Write-Host "⚠️ Cannot modify system PATH without admin privileges." -ForegroundColor Yellow
            Write-Host "ℹ️ Adding to current session PATH only." -ForegroundColor Yellow
        }
        
        # Always update the current session's PATH
        $env:Path += ";$binPath"
        Write-Host "✅ Updated current session PATH." -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to update PATH: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "ℹ️ Continuing with current session PATH only..." -ForegroundColor Yellow
        $env:Path += ";$binPath"
    }
} else {
    Write-Host "ℹ️ $binPath is already in system PATH." -ForegroundColor Yellow
}

# 5. Remove the downloaded ZIP file
Write-Host "🗑️ Cleaning up downloaded ZIP file..." -ForegroundColor Cyan
Remove-Item $zipPath -Force

# 6. Create a test folder and write a hello.cpp file
if (!(Test-Path -Path $testFolder)) {
    Write-Host "📁 Creating test directory: $testFolder" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $testFolder -Force | Out-Null
}

$helloCppCode = @"
#include <iostream>
int main() {
    std::cout << "Hello, C++ environment is ready!" << std::endl;
    return 0;
}
"@

Write-Host "✍️ Creating test file: $testFile" -ForegroundColor Cyan
$helloCppCode | Out-File -Encoding UTF8 $testFile

# 7. Compile hello.cpp using g++
Write-Host "⚙️ Compiling hello.cpp..." -ForegroundColor Cyan
try {
    $compileProcess = Start-Process -FilePath "$binPath\g++.exe" -ArgumentList "$testFile", "-o", "$exeFile" -Wait -PassThru -NoNewWindow
    
    if ($compileProcess.ExitCode -eq 0) {
        Write-Host "✅ Compilation successful!" -ForegroundColor Green
    } else {
        Write-Host "❌ Compilation failed with exit code: $($compileProcess.ExitCode)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Failed to compile: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "ℹ️ Make sure g++.exe exists at: $binPath\g++.exe" -ForegroundColor Yellow
}

# 8. Run the compiled test program if compilation succeeded
if (Test-Path $exeFile) {
    Write-Host "🚀 Running test program..." -ForegroundColor Cyan
    try {
        $output = & $exeFile
        Write-Host "Program output:" -ForegroundColor Green
        Write-Host "--------------------" -ForegroundColor Gray
        Write-Host $output -ForegroundColor White
        Write-Host "--------------------" -ForegroundColor Gray
    } catch {
        Write-Host "❌ Failed to run test program: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Test executable not found. Compilation may have failed." -ForegroundColor Red
}

Write-Host "`n🎉 Setup complete!" -ForegroundColor Green
if ($isAdmin) {
    Write-Host "ℹ️ System PATH has been updated permanently." -ForegroundColor Yellow
    Write-Host "ℹ️ You may need to restart your terminal for PATH changes to take effect in new sessions." -ForegroundColor Yellow
} else {
    Write-Host "ℹ️ PATH was updated for current session only (admin rights needed for permanent changes)." -ForegroundColor Yellow
}
Write-Host "ℹ️ Current session PATH has been updated and should work immediately." -ForegroundColor Yellow

# Only pause if running interactively (not in automated flow)
if ([Environment]::UserInteractive -and -not [Environment]::GetCommandLineArgs().Contains('-NonInteractive')) {
    Write-Host "`nPress Enter to exit..." -ForegroundColor Cyan
    Read-Host
}