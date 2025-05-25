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
    New-Item -ItemType Directory -Path $installPath -Force | Out-Null
}

# 2. Download the MinGW ZIP package
Write-Host "🔽 Downloading MinGW package from $mingwUrl ..."
Invoke-WebRequest -Uri $mingwUrl -OutFile $zipPath

# 3. Extract the archive to the target location
Write-Host "📦 Extracting MinGW to $installPath ..."
Expand-Archive -Path $zipPath -DestinationPath $installPath -Force

# 4. Add MinGW bin folder to system PATH if not already present
$currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")

if ($currentPath -notlike "*$binPath*") {
    $newPath = "$currentPath;$binPath"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
    Write-Host "✅ Added $binPath to system PATH."
} else {
    Write-Host "ℹ️ $binPath is already in system PATH."
}

# 5. Remove the downloaded ZIP file
Remove-Item $zipPath -Force

# 6. Create a test folder and write a hello.cpp file
if (!(Test-Path -Path $testFolder)) {
    New-Item -ItemType Directory -Path $testFolder -Force | Out-Null
}

$helloCppCode = @"
#include <iostream>
int main() {
    std::cout << "Hello, C++ environment is ready!" << std::endl;
    return 0;
}
"@

Write-Host "✍️ Creating test file: $testFile"
$helloCppCode | Out-File -Encoding UTF8 $testFile

# 7. Compile hello.cpp using g++
Write-Host "⚙️ Compiling hello.cpp..."
& "$binPath\g++.exe" $testFile -o $exeFile

# 8. Run the compiled test program if compilation succeeded
if (Test-Path $exeFile) {
    Write-Host "✅ Compilation successful. Running test program..."
    $output = & $exeFile
    Write-Host "Program output:"
    Write-Host "--------------------"
    Write-Host $output
    Write-Host "--------------------"
} else {
    Write-Host "❌ Compilation failed."
}

Write-Host "`n🎉 Setup complete. You may need to restart your terminal or PC for PATH changes to take effect."
