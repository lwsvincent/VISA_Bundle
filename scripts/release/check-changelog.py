#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Check changelog version consistency for release
"""

import sys
import os
from pathlib import Path

# Add utils to path
sys.path.insert(0, str(Path(__file__).parent.parent / "utils"))

import importlib.util
spec = importlib.util.spec_from_file_location("version_utils", str(Path(__file__).parent.parent / "utils" / "version-utils.py"))
version_utils_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(version_utils_module)
VersionUtils = version_utils_module.VersionUtils
ChangelogParser = version_utils_module.ChangelogParser

def print_status(status, message):
    """Print colored status message with Windows compatibility"""
    colors = {
        'success': '\033[0;32m[OK]\033[0m',
        'error': '\033[0;31m[ERROR]\033[0m',
        'warning': '\033[1;33m[WARNING]\033[0m',
        'info': '\033[0;34m[INFO]\033[0m'
    }
    try:
        print(f"{colors.get(status, '')} {message}")
    except UnicodeEncodeError:
        # Fallback for Windows with cp950 encoding
        fallback_colors = {
            'success': '[OK]',
            'error': '[ERROR]',
            'warning': '[WARNING]',
            'info': '[INFO]'
        }
        print(f"{fallback_colors.get(status, '')} {message}")

def check_changelog_version(project_root):
    """Check changelog version consistency"""
    try:
        print_status('info', 'Checking changelog version consistency...')
        
        # Initialize utilities
        version_utils = VersionUtils(project_root)
        changelog_parser = ChangelogParser(project_root)
        
        # 1. Check if changelog exists
        if not changelog_parser.exists():
            print_status('error', 'CHANGELOG.md not found')
            return False
        
        print_status('success', 'CHANGELOG.md found')
        
        # 2. Get project version
        project_version = version_utils.get_project_version()
        if not project_version:
            print_status('error', 'Could not determine project version from setup.py/pyproject.toml')
            return False
        
        print_status('info', f'Project version: {project_version}')
        
        # 3. Validate semantic version format
        if not version_utils.validate_semver(project_version):
            print_status('error', f'Project version "{project_version}" is not valid semantic version')
            return False
        
        print_status('success', 'Project version format is valid')
        
        # 4. Get changelog version
        changelog_version = changelog_parser.get_latest_version()
        if not changelog_version:
            print_status('error', 'Could not find any version in CHANGELOG.md')
            return False
        
        print_status('info', f'Changelog version: {changelog_version}')
        
        # 5. Validate changelog version format
        if not version_utils.validate_semver(changelog_version):
            print_status('error', f'Changelog version "{changelog_version}" is not valid semantic version')
            return False
        
        print_status('success', 'Changelog version format is valid')
        
        # 6. Compare versions
        if project_version == changelog_version:
            print_status('success', 'Project and changelog versions match')
        else:
            print_status('error', f'Version mismatch: project={project_version}, changelog={changelog_version}')
            print_status('info', 'Please update either the project version or changelog version')
            return False
        
        # 7. Check if version exists in changelog
        if not changelog_parser.is_version_in_changelog(project_version):
            print_status('error', f'Version {project_version} not found in changelog')
            return False
        
        print_status('success', 'Version found in changelog')
        
        # 8. Validate changelog entry
        changelog_section = changelog_parser.get_changelog_section(project_version)
        if not changelog_section:
            print_status('warning', 'Could not extract changelog section for version')
        else:
            # Check if the section has meaningful content
            lines = [line.strip() for line in changelog_section.split('\n') if line.strip()]
            if len(lines) < 3:  # At least header and some content
                print_status('warning', 'Changelog section seems empty or too short')
            else:
                print_status('success', 'Changelog section has content')
        
        # 9. Check for unreleased section
        versions = changelog_parser.parse_changelog()
        has_unreleased = any(v['version'].lower() == 'unreleased' for v in versions)
        if not has_unreleased:
            print_status('warning', 'No "Unreleased" section found in changelog')
        
        print_status('success', 'All changelog version checks passed')
        return True
        
    except Exception as e:
        print_status('error', f'Error checking changelog: {e}')
        return False

def main():
    """Main function"""
    if len(sys.argv) < 2:
        print("Usage: python check-changelog.py <project_root>")
        sys.exit(1)
    
    project_root = sys.argv[1]
    
    if not os.path.exists(project_root):
        print_status('error', f'Project root does not exist: {project_root}')
        sys.exit(1)
    
    # Run the check
    success = check_changelog_version(project_root)
    
    if success:
        print_status('success', 'Changelog version check completed successfully')
        sys.exit(0)
    else:
        print_status('error', 'Changelog version check failed')
        sys.exit(1)

if __name__ == "__main__":
    main()