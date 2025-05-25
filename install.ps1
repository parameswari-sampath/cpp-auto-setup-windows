# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-NOT $isAdmin) {
    Write-Host "[WARNING] Not running as administrator. PATH modification may fail."
    Write-Host "[INFO] Consider running PowerShell as Administrator for full functionality."
} else {
    Write-Host "[SUCCESS] Running with administrator privileges"
}

Write-Host ""

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
    Write-Host "[STEP 1/6] Creating install directory: $installPath"
    New-Item -ItemType Directory -Path $installPath -Force | Out-Null
} else {
    Write-Host "[STEP 1/6] Install directory already exists: $installPath"
}

# 2. Download the MinGW ZIP package
Write-Host "[STEP 2/6] Downloading MinGW package..."
Write-Host "           Source: $mingwUrl"
try {
    Invoke-WebRequest -Uri $mingwUrl -OutFile $zipPath
    Write-Host "[SUCCESS] Download completed successfully"
} catch {
    Write-Host "[ERROR] Failed to download MinGW package: $($_.Exception.Message)"
    exit 1
}

# 3. Extract the archive to the target location
Write-Host "[STEP 3/6] Extracting MinGW to $installPath..."
try {
    Expand-Archive -Path $zipPath -DestinationPath $installPath -Force
    Write-Host "[SUCCESS] Extraction completed successfully"
} catch {
    Write-Host "[ERROR] Failed to extract archive: $($_.Exception.Message)"
    exit 1
}

# 4. Add MinGW bin folder to system PATH if not already present
Write-Host "[STEP 4/6] Configuring environment variables..."
$currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")

if ($currentPath -notlike "*$binPath*") {
    try {
        if ($isAdmin) {
            # Try to update system PATH (requires admin)
            $newPath = "$currentPath;$binPath"
            [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
            Write-Host "[SUCCESS] Added $binPath to system PATH"
        } else {
            Write-Host "[WARNING] Cannot modify system PATH without admin privileges"
            Write-Host "[INFO] Adding to current session PATH only"
        }
        
        # Always update the current session's PATH
        $env:Path += ";$binPath"
        Write-Host "[SUCCESS] Updated current session PATH"
    } catch {
        Write-Host "[ERROR] Failed to update PATH: $($_.Exception.Message)"
        Write-Host "[INFO] Continuing with current session PATH only..."
        $env:Path += ";$binPath"
    }
} else {
    Write-Host "[INFO] $binPath is already in system PATH"
}

# 5. Remove the downloaded ZIP file
Write-Host "[STEP 5/6] Cleaning up downloaded ZIP file..."
Remove-Item $zipPath -Force

# 6. Create a test folder and write a hello.cpp file
if (!(Test-Path -Path $testFolder)) {
    Write-Host "[STEP 6/6] Creating test directory: $testFolder"
    New-Item -ItemType Directory -Path $testFolder -Force | Out-Null
}

$helloCppCode = @"
#include <iostream>
int main() {
    std::cout << "Hello, C++ environment is ready!" << std::endl;
    return 0;
}
"@

Write-Host "[STEP 6/6] Creating and compiling test file..."
$helloCppCode | Out-File -Encoding UTF8 $testFile

# 7. Compile hello.cpp using g++
Write-Host "           Compiling hello.cpp..."
try {
    $compileProcess = Start-Process -FilePath "$binPath\g++.exe" -ArgumentList "$testFile", "-o", "$exeFile" -Wait -PassThru -NoNewWindow
    
    if ($compileProcess.ExitCode -eq 0) {
        Write-Host "[SUCCESS] Compilation successful!"
    } else {
        Write-Host "[ERROR] Compilation failed with exit code: $($compileProcess.ExitCode)"
    }
} catch {
    Write-Host "[ERROR] Failed to compile: $($_.Exception.Message)"
    Write-Host "[INFO] Make sure g++.exe exists at: $binPath\g++.exe"
}

# 8. Run the compiled test program if compilation succeeded
if (Test-Path $exeFile) {
    Write-Host "           Running test program..."
    try {
        $output = & $exeFile
        Write-Host "[TEST OUTPUT] $output"
    } catch {
        Write-Host "[ERROR] Failed to run test program: $($_.Exception.Message)"
    }
} else {
    Write-Host "[ERROR] Test executable not found. Compilation may have failed."
}

Write-Host ""
Write-Host "========================================"
Write-Host "        SETUP COMPLETED SUCCESSFULLY"
Write-Host "========================================"
Write-Host "MinGW C++ compiler has been installed to:"
Write-Host "  $installPath"
Write-Host ""
if ($isAdmin) {
    Write-Host "System PATH has been updated permanently."
    Write-Host "You may need to restart your terminal for PATH changes"
    Write-Host "to take effect in new sessions."
} else {
    Write-Host "PATH was updated for current session only."
    Write-Host "(Admin rights needed for permanent changes)"
}
Write-Host ""
Write-Host "You can now compile C++ programs using: g++ filename.cpp -o output.exe"
Write-Host "========================================"