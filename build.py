#!/usr/bin/env python3
"""
Build script for VISA Bundle package
"""

import subprocess
import sys
import os
from pathlib import Path


def run_command(command, description):
    """Run a command and handle errors"""
    print(f"\n{'='*50}")
    print(f"🔧 {description}")
    print(f"{'='*50}")

    try:
        result = subprocess.run(command, shell=True,
                                check=True, capture_output=True, text=True)
        print(f"✅ 成功: {description}")
        if result.stdout:
            print(f"輸出: {result.stdout}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ 失敗: {description}")
        print(f"錯誤: {e.stderr}")
        return False


def main():
    """Main build process"""
    print("🚀 開始建置 VISA Bundle 套件")

    # Check if we're in the right directory
    if not os.path.exists("pyproject.toml"):
        print("❌ 錯誤: 找不到 pyproject.toml 檔案，請確認在正確的目錄中執行")
        sys.exit(1)

    # Clean previous builds
    if run_command("python -c \"import shutil; shutil.rmtree('dist', ignore_errors=True); shutil.rmtree('build', ignore_errors=True)\"", "清除舊的建置檔案"):
        print("🧹 已清除舊的建置檔案")

    # Install build dependencies
    if not run_command("pip install --upgrade build twine", "安裝建置工具"):
        print("❌ 無法安裝建置工具")
        sys.exit(1)

    # Run code formatting (optional)
    run_command("black .", "程式碼格式化")
    run_command(
        "flake8 . --max-line-length=88 --extend-ignore=E203,W503", "程式碼檢查")

    # Build the package
    if not run_command("python -m build", "建置套件"):
        print("❌ 套件建置失敗")
        sys.exit(1)

    # Check the package
    if not run_command("python -m twine check dist/*", "檢查套件"):
        print("❌ 套件檢查失敗")
        sys.exit(1)

    print(f"\n🎉 套件建置完成！")
    print(f"📦 建置檔案位於 dist/ 目錄中")

    # List the built files
    dist_path = Path("dist")
    if dist_path.exists():
        print(f"\n📋 建置的檔案:")
        for file in dist_path.iterdir():
            print(f"  - {file.name}")

    print(f"\n🔧 測試安裝指令:")
    print(f"pip install dist/visa_bundle-0.1.0-py3-none-any.whl")

    print(f"\n📤 發布指令:")
    print(f"python -m twine upload dist/*")


if __name__ == "__main__":
    main()
