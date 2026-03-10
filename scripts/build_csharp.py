#!/usr/bin/env python3
"""
C# DLL 建置腳本
自動化建置 VisaBundleCore.dll
"""

import subprocess
import sys
import os
from pathlib import Path
import shutil


def print_header(text):
    """列印標題"""
    print("\n" + "=" * 60)
    print(f"  {text}")
    print("=" * 60 + "\n")


def check_dotnet():
    """檢查 .NET SDK 是否已安裝"""
    print_header("檢查 .NET SDK")

    try:
        result = subprocess.run(
            ["dotnet", "--version"],
            capture_output=True,
            text=True,
            check=True
        )
        version = result.stdout.strip()
        print(f"✅ .NET SDK 已安裝: {version}")
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("❌ .NET SDK 未安裝")
        print("\n請安裝 .NET SDK:")
        print("  Windows: https://dotnet.microsoft.com/download")
        print("  Linux: sudo apt install dotnet-sdk-6.0")
        print("  macOS: brew install dotnet")
        return False


def build_dll(configuration="Release"):
    """建置 DLL"""
    print_header(f"建置 C# DLL ({configuration})")

    # 專案路徑
    project_root = Path(__file__).parent.parent
    csproj_path = project_root / "src" / "VisaBundleCore" / "VisaBundleCore.csproj"

    if not csproj_path.exists():
        print(f"❌ 找不到專案檔: {csproj_path}")
        return False

    print(f"專案檔: {csproj_path}")
    print(f"組態: {configuration}")

    try:
        # 還原依賴
        print("\n[1/3] 還原 NuGet 套件...")
        subprocess.run(
            ["dotnet", "restore", str(csproj_path)],
            check=True,
            cwd=str(csproj_path.parent)
        )
        print("✅ 還原完成")

        # 建置
        print("\n[2/3] 建置專案...")
        subprocess.run(
            [
                "dotnet", "build",
                str(csproj_path),
                "-c", configuration,
                "--no-restore"
            ],
            check=True,
            cwd=str(csproj_path.parent)
        )
        print("✅ 建置完成")

        # 驗證輸出
        print("\n[3/3] 驗證輸出...")
        output_dir = project_root / "bin" / configuration
        dll_path = output_dir / "net48" / "VisaBundleCore.dll"

        if dll_path.exists():
            size = dll_path.stat().st_size
            print(f"✅ DLL 已產生: {dll_path}")
            print(f"   大小: {size:,} bytes ({size / 1024:.1f} KB)")
            return True
        else:
            print(f"❌ 找不到 DLL: {dll_path}")
            print("\n可能的輸出位置:")
            for path in output_dir.rglob("*.dll"):
                print(f"  - {path}")
            return False

    except subprocess.CalledProcessError as e:
        print(f"\n❌ 建置失敗: {e}")
        return False


def copy_to_python_bin():
    """複製 DLL 到 Python 專案的 bin 目錄"""
    print_header("複製 DLL 到 Python bin/")

    project_root = Path(__file__).parent.parent
    src_dll = project_root / "bin" / "Release" / "net48" / "VisaBundleCore.dll"
    dest_dir = project_root / "bin"
    dest_dll = dest_dir / "VisaBundleCore.dll"

    if not src_dll.exists():
        print(f"❌ 找不到來源 DLL: {src_dll}")
        return False

    # 建立目標目錄
    dest_dir.mkdir(parents=True, exist_ok=True)

    # 複製
    shutil.copy2(src_dll, dest_dll)
    print(f"✅ 已複製: {src_dll}")
    print(f"   → {dest_dll}")

    # 也複製 XML 文檔（如果存在）
    src_xml = src_dll.with_suffix('.xml')
    if src_xml.exists():
        dest_xml = dest_dll.with_suffix('.xml')
        shutil.copy2(src_xml, dest_xml)
        print(f"✅ 已複製文檔: {dest_xml}")

    return True


def test_dll():
    """測試 DLL 是否可以被 Python 載入"""
    print_header("測試 DLL 載入")

    try:
        import clr
    except ImportError:
        print("⚠️  pythonnet 未安裝，跳過測試")
        print("   安裝: pip install pythonnet")
        return True  # 不算失敗

    project_root = Path(__file__).parent.parent
    dll_path = project_root / "bin" / "VisaBundleCore.dll"

    if not dll_path.exists():
        print(f"❌ DLL 不存在: {dll_path}")
        return False

    try:
        print(f"載入 DLL: {dll_path}")
        clr.AddReference(str(dll_path.absolute()))

        print("匯入命名空間...")
        from VisaBundle.Core import VisaCore, VisaSettingsCore, VISAManagerCore

        print("\n✅ DLL 載入成功！")
        print(f"   - VisaCore: {VisaCore}")
        print(f"   - VisaSettingsCore: {VisaSettingsCore}")
        print(f"   - VISAManagerCore: {VISAManagerCore}")

        # 測試靜態方法
        print("\n測試靜態方法...")
        resources = VisaCore.ListResources()
        print(f"   - ListResources(): {resources}")

        return True

    except Exception as e:
        print(f"\n❌ 載入失敗: {e}")
        import traceback
        traceback.print_exc()
        return False


def main():
    """主函式"""
    print_header("VisaBundleCore C# DLL 建置工具")

    # 解析參數
    configuration = "Release"
    if len(sys.argv) > 1:
        if sys.argv[1].lower() in ["debug", "d"]:
            configuration = "Debug"
        elif sys.argv[1].lower() in ["release", "r"]:
            configuration = "Release"

    # 執行建置流程
    steps = [
        ("檢查環境", check_dotnet),
        ("建置 DLL", lambda: build_dll(configuration)),
        ("複製檔案", copy_to_python_bin),
        ("測試載入", test_dll),
    ]

    for step_name, step_func in steps:
        if not step_func():
            print(f"\n❌ 失敗於: {step_name}")
            print("\n建置終止")
            sys.exit(1)

    # 完成
    print_header("建置完成！")
    print("✅ 所有步驟成功")
    print("\nDLL 位置:")
    print("  - bin/VisaBundleCore.dll")
    print("\n下一步:")
    print("  1. 修改 Python wrapper 來調用 C# DLL")
    print("  2. 執行測試: pytest tests/")
    print("  3. 更新文檔")


if __name__ == "__main__":
    main()
