#!/usr/bin/env python3
"""
Installation and setup script for VISA Bundle
"""

import subprocess
import sys
import os
from pathlib import Path


def run_command(command, description, check=True):
    """Run a command and handle errors"""
    print(f"🔧 {description}...")

    try:
        result = subprocess.run(command, shell=True,
                                check=check, capture_output=True, text=True)
        if result.returncode == 0:
            print(f"✅ {description} 完成")
            return True
        else:
            print(f"⚠️ {description} 警告: {result.stderr}")
            return False
    except subprocess.CalledProcessError as e:
        print(f"❌ {description} 失敗: {e.stderr}")
        return False


def check_python_version():
    """Check if Python version is compatible"""
    python_version = sys.version_info
    if python_version.major < 3 or (python_version.major == 3 and python_version.minor < 8):
        print(f"❌ Python 版本 {python_version.major}.{python_version.minor} 不支援")
        print(f"🔧 請升級到 Python 3.8 或更新版本")
        return False

    print(
        f"✅ Python 版本 {python_version.major}.{python_version.minor}.{python_version.micro} 符合要求")
    return True


def install_from_source():
    """Install package from source"""
    print("📦 從原始碼安裝 VISA Bundle...")

    # Check if we're in the right directory
    if not os.path.exists("pyproject.toml"):
        print("❌ 找不到 pyproject.toml，請確認在正確的目錄中執行")
        return False

    # Install in development mode
    if run_command("pip install -e .", "安裝套件 (開發模式)"):
        print("🎉 VISA Bundle 安裝完成！")
        return True

    return False


def install_from_pypi():
    """Install package from PyPI"""
    print("📦 從 PyPI 安裝 VISA Bundle...")

    if run_command("pip install visa-bundle", "從 PyPI 安裝套件"):
        print("🎉 VISA Bundle 安裝完成！")
        return True

    return False


def install_dependencies():
    """Install required dependencies"""
    print("📋 安裝相依套件...")

    # Upgrade pip first
    run_command("pip install --upgrade pip", "升級 pip")

    # Install base dependencies
    if os.path.exists("requirements.txt"):
        return run_command("pip install -r requirements.txt", "安裝基本相依套件")
    else:
        return run_command("pip install pyvisa>=1.11.0", "安裝 pyvisa")


def install_dev_dependencies():
    """Install development dependencies"""
    print("🛠️ 安裝開發相依套件...")

    if os.path.exists("requirements-dev.txt"):
        return run_command("pip install -r requirements-dev.txt", "安裝開發相依套件")
    else:
        dev_packages = [
            "pytest>=6.0",
            "pytest-cov",
            "black",
            "flake8",
            "mypy",
            "build",
            "twine"
        ]
        return run_command(f"pip install {' '.join(dev_packages)}", "安裝開發工具")


def test_installation():
    """Test if the installation was successful"""
    print("🧪 測試安裝...")

    test_code = """
import sys
try:
    import visa_bundle
    from visa_bundle import VISA, Opened_List, Setting
    print("✅ VISA Bundle 匯入成功")
    print(f"📦 版本: {getattr(visa_bundle, '__version__', 'unknown')}")
    sys.exit(0)
except ImportError as e:
    print(f"❌ 匯入失敗: {e}")
    sys.exit(1)
"""

    return run_command(f'python -c "{test_code}"', "測試套件匯入")


def main():
    """Main installation process"""
    print("🚀 VISA Bundle 安裝程式")
    print("=" * 50)

    # Check Python version
    if not check_python_version():
        sys.exit(1)

    # Ask user for installation type
    print("\n請選擇安裝方式:")
    print("1. 從原始碼安裝 (開發模式)")
    print("2. 從 PyPI 安裝 (使用者模式)")
    print("3. 只安裝相依套件")
    print("4. 安裝開發環境")

    choice = input("\n請輸入選項 (1-4): ").strip()

    success = False

    if choice == "1":
        # Source installation
        if install_dependencies():
            success = install_from_source()

    elif choice == "2":
        # PyPI installation
        success = install_from_pypi()

    elif choice == "3":
        # Dependencies only
        success = install_dependencies()

    elif choice == "4":
        # Development environment
        if install_dependencies():
            if install_dev_dependencies():
                success = install_from_source()

    else:
        print("❌ 無效的選項")
        sys.exit(1)

    if success:
        # Test the installation
        if test_installation():
            print(f"\n🎉 安裝完成！")
            print(f"📖 使用範例:")
            print(f"   from visa_bundle import VISA, Setting")
            print(f"   visa = VISA()")
            print(f"   Setting.VISA_Print_Enable = True")
        else:
            print(f"\n⚠️ 安裝完成但測試失敗，請檢查配置")
    else:
        print(f"\n❌ 安裝失敗")
        sys.exit(1)


if __name__ == "__main__":
    main()
