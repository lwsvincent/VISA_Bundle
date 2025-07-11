@echo off
REM Windows batch script to build and install the package

echo 🚀 開始建置 VISA Bundle 套件...

REM Check if pyproject.toml exists
if not exist pyproject.toml (
    echo ❌ 錯誤: 找不到 pyproject.toml 檔案
    exit /b 1
)

REM Clean previous builds
echo 🧹 清除舊的建置檔案...
rmdir /s /q dist 2>nul
rmdir /s /q build 2>nul
rmdir /s /q *.egg-info 2>nul

REM Install/upgrade build tools
echo 🔧 安裝建置工具...
pip install --upgrade build twine

REM Build the package
echo 📦 建置套件...
python -m build

REM Check the package
echo ✅ 檢查套件...
python -m twine check dist/*

echo.
echo 🎉 套件建置完成！
echo 📦 建置檔案位於 dist/ 目錄中
echo.
echo 🔧 測試安裝指令:
echo pip install dist/visa_bundle-0.1.0-py3-none-any.whl
echo.
echo 📤 發布指令:
echo python -m twine upload dist/*

pause
