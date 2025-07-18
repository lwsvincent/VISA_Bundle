#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Version utilities for release management
"""

import re
import os
import sys
import ast
import configparser
from pathlib import Path
from typing import Optional, Dict, List, Tuple
from datetime import datetime

class VersionUtils:
    """Utilities for version management and validation"""
    
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.semver_pattern = re.compile(r'^(\d+)\.(\d+)\.(\d+)(?:-([a-zA-Z0-9\-]+))?$')
    
    def extract_version_from_setup_py(self) -> Optional[str]:
        """Extract version from setup.py"""
        setup_py = self.project_root / "setup.py"
        if not setup_py.exists():
            return None
            
        try:
            with open(setup_py, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Look for version= pattern
            version_match = re.search(r'version\s*=\s*["\']([^"\']+)["\']', content)
            if version_match:
                return version_match.group(1)
            
            # Look for version variable
            version_var_match = re.search(r'version\s*=\s*(\w+)', content)
            if version_var_match:
                var_name = version_var_match.group(1)
                var_match = re.search(f'{var_name}\\s*=\\s*["\']([^"\']+)["\']', content)
                if var_match:
                    return var_match.group(1)
            
            return None
            
        except Exception as e:
            print(f"Error reading setup.py: {e}", file=sys.stderr)
            return None
    
    def extract_version_from_pyproject_toml(self) -> Optional[str]:
        """Extract version from pyproject.toml"""
        pyproject_toml = self.project_root / "pyproject.toml"
        if not pyproject_toml.exists():
            return None
            
        try:
            with open(pyproject_toml, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Look for version in [project] section
            version_match = re.search(r'version\s*=\s*["\']([^"\']+)["\']', content)
            if version_match:
                return version_match.group(1)
                
            return None
            
        except Exception as e:
            print(f"Error reading pyproject.toml: {e}", file=sys.stderr)
            return None
    
    def extract_version_from_init_py(self) -> Optional[str]:
        """Extract version from __init__.py files"""
        possible_init_files = [
            self.project_root / "__init__.py",
            self.project_root / "src" / "__init__.py",
        ]
        
        # Look for package directories
        for item in self.project_root.iterdir():
            if item.is_dir() and not item.name.startswith('.'):
                init_file = item / "__init__.py"
                if init_file.exists():
                    possible_init_files.append(init_file)
        
        for init_file in possible_init_files:
            if init_file.exists():
                try:
                    with open(init_file, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    # Look for __version__ variable
                    version_match = re.search(r'__version__\s*=\s*["\']([^"\']+)["\']', content)
                    if version_match:
                        return version_match.group(1)
                        
                except Exception as e:
                    continue
        
        return None
    
    def get_project_version(self) -> Optional[str]:
        """Get version from project configuration files"""
        # Priority order: setup.py, pyproject.toml, __init__.py
        version = self.extract_version_from_setup_py()
        if version:
            return version
            
        version = self.extract_version_from_pyproject_toml()
        if version:
            return version
            
        version = self.extract_version_from_init_py()
        if version:
            return version
            
        return None
    
    def validate_semver(self, version: str) -> bool:
        """Validate semantic version format"""
        return bool(self.semver_pattern.match(version))
    
    def compare_versions(self, version1: str, version2: str) -> int:
        """Compare two semantic versions. Returns -1, 0, or 1"""
        def parse_version(v):
            match = self.semver_pattern.match(v)
            if not match:
                return (0, 0, 0, '')
            return (int(match.group(1)), int(match.group(2)), int(match.group(3)), match.group(4) or '')
        
        v1_parts = parse_version(version1)
        v2_parts = parse_version(version2)
        
        # Compare major, minor, patch
        for i in range(3):
            if v1_parts[i] < v2_parts[i]:
                return -1
            elif v1_parts[i] > v2_parts[i]:
                return 1
        
        # Compare pre-release
        if v1_parts[3] and not v2_parts[3]:
            return -1
        elif not v1_parts[3] and v2_parts[3]:
            return 1
        elif v1_parts[3] < v2_parts[3]:
            return -1
        elif v1_parts[3] > v2_parts[3]:
            return 1
        
        return 0
    
    def increment_version(self, version: str, increment_type: str) -> Optional[str]:
        """Increment version by type: patch, minor, major"""
        match = self.semver_pattern.match(version)
        if not match:
            return None
        
        major = int(match.group(1))
        minor = int(match.group(2))
        patch = int(match.group(3))
        
        if increment_type == "major":
            major += 1
            minor = 0
            patch = 0
        elif increment_type == "minor":
            minor += 1
            patch = 0
        elif increment_type == "patch":
            patch += 1
        else:
            return None
        
        return f"{major}.{minor}.{patch}"
    
    def update_setup_py(self, new_version: str) -> bool:
        """Update version in setup.py"""
        setup_py = self.project_root / "setup.py"
        if not setup_py.exists():
            return True  # Not an error if file doesn't exist
        
        try:
            with open(setup_py, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Replace version= pattern
            content = re.sub(
                r'version\s*=\s*["\'][^"\']+["\']',
                f'version="{new_version}"',
                content
            )
            
            with open(setup_py, 'w', encoding='utf-8') as f:
                f.write(content)
            
            return True
        except Exception as e:
            print(f"Error updating setup.py: {e}", file=sys.stderr)
            return False
    
    def update_pyproject_toml(self, new_version: str) -> bool:
        """Update version in pyproject.toml"""
        pyproject_toml = self.project_root / "pyproject.toml"
        if not pyproject_toml.exists():
            return True  # Not an error if file doesn't exist
        
        try:
            with open(pyproject_toml, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Replace version in [project] section
            content = re.sub(
                r'version\s*=\s*["\'][^"\']+["\']',
                f'version = "{new_version}"',
                content
            )
            
            with open(pyproject_toml, 'w', encoding='utf-8') as f:
                f.write(content)
            
            return True
        except Exception as e:
            print(f"Error updating pyproject.toml: {e}", file=sys.stderr)
            return False
    
    def update_init_py_files(self, new_version: str) -> bool:
        """Update version in __init__.py files"""
        possible_init_files = [
            self.project_root / "__init__.py",
            self.project_root / "src" / "__init__.py",
        ]
        
        # Look for package directories
        for item in self.project_root.iterdir():
            if item.is_dir() and not item.name.startswith('.'):
                init_file = item / "__init__.py"
                if init_file.exists():
                    possible_init_files.append(init_file)
        
        success = True
        for init_file in possible_init_files:
            if init_file.exists():
                try:
                    with open(init_file, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    # Only update if __version__ exists
                    if '__version__' in content:
                        content = re.sub(
                            r'__version__\s*=\s*["\'][^"\']+["\']',
                            f'__version__ = "{new_version}"',
                            content
                        )
                        
                        with open(init_file, 'w', encoding='utf-8') as f:
                            f.write(content)
                        
                except Exception as e:
                    print(f"Error updating {init_file}: {e}", file=sys.stderr)
                    success = False
        
        return success
    
    def set_project_version(self, new_version: str) -> bool:
        """Set version in all project files"""
        if not self.validate_semver(new_version):
            print(f"Invalid version format: {new_version}", file=sys.stderr)
            return False
        
        success = True
        success &= self.update_setup_py(new_version)
        success &= self.update_pyproject_toml(new_version)
        success &= self.update_init_py_files(new_version)
        
        return success

class ChangelogParser:
    """Parser for changelog files"""
    
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.changelog_file = self.project_root / "CHANGELOG.md"
        
        # Supported changelog formats
        self.keepachangelog_pattern = re.compile(r'^##\s*\[([^\]]+)\]\s*-\s*(.+)$')
        self.simple_pattern = re.compile(r'^##\s*v?([0-9]+\.[0-9]+\.[0-9]+(?:-[a-zA-Z0-9\-]+)?)\s*(?:\(([^)]+)\))?')
    
    def exists(self) -> bool:
        """Check if changelog file exists"""
        return self.changelog_file.exists()
    
    def parse_changelog(self) -> List[Dict]:
        """Parse changelog and return list of versions"""
        if not self.changelog_file.exists():
            return []
        
        try:
            with open(self.changelog_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            versions = []
            lines = content.split('\n')
            
            for line in lines:
                line = line.strip()
                
                # Try Keep a Changelog format
                match = self.keepachangelog_pattern.match(line)
                if match:
                    version = match.group(1)
                    date = match.group(2)
                    
                    # Skip "Unreleased" entries
                    if version.lower() != 'unreleased':
                        versions.append({
                            'version': version,
                            'date': date,
                            'format': 'keepachangelog'
                        })
                    continue
                
                # Try simple format
                match = self.simple_pattern.match(line)
                if match:
                    version = match.group(1)
                    date = match.group(2) or ''
                    
                    versions.append({
                        'version': version,
                        'date': date,
                        'format': 'simple'
                    })
            
            return versions
            
        except Exception as e:
            print(f"Error parsing changelog: {e}", file=sys.stderr)
            return []
    
    def get_latest_version(self) -> Optional[str]:
        """Get latest version from changelog"""
        versions = self.parse_changelog()
        if not versions:
            return None
        
        # First version in changelog should be the latest
        return versions[0]['version']
    
    def is_version_in_changelog(self, version: str) -> bool:
        """Check if version exists in changelog"""
        versions = self.parse_changelog()
        for v in versions:
            if v['version'] == version:
                return True
        return False
    
    def get_changelog_section(self, version: str) -> Optional[str]:
        """Get changelog section for specific version"""
        if not self.changelog_file.exists():
            return None
        
        try:
            with open(self.changelog_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            lines = content.split('\n')
            section_lines = []
            in_section = False
            
            for line in lines:
                # Check if this is a version header
                if line.strip().startswith('##'):
                    if in_section:
                        # End of current section
                        break
                    
                    # Check if this is our target version
                    if version in line:
                        in_section = True
                        section_lines.append(line)
                        continue
                
                if in_section:
                    section_lines.append(line)
            
            return '\n'.join(section_lines) if section_lines else None
            
        except Exception as e:
            print(f"Error reading changelog section: {e}", file=sys.stderr)
            return None

def main():
    """Main function for command-line usage"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Version utilities for release management")
    parser.add_argument("project_root", help="Path to the project root")
    parser.add_argument("--set", dest="set_version", help="Set version to specific value")
    parser.add_argument("--increment", dest="increment_type", 
                       choices=["major", "minor", "patch"], 
                       help="Increment version by type")
    
    args = parser.parse_args()
    
    # Initialize utilities
    version_utils = VersionUtils(args.project_root)
    changelog_parser = ChangelogParser(args.project_root)
    
    # Handle version setting
    if args.set_version:
        if version_utils.set_project_version(args.set_version):
            try:
                print(f"[OK] Version set to {args.set_version}")
            except UnicodeEncodeError:
                print(f"[OK] Version set to {args.set_version}")
            sys.exit(0)
        else:
            try:
                print("[ERROR] Failed to set version")
            except UnicodeEncodeError:
                print("[ERROR] Failed to set version")
            sys.exit(1)
    
    # Handle version increment
    if args.increment_type:
        current_version = version_utils.get_project_version()
        if not current_version:
            try:
                print("[ERROR] Could not determine current version")
            except UnicodeEncodeError:
                print("[ERROR] Could not determine current version")
            sys.exit(1)
        
        new_version = version_utils.increment_version(current_version, args.increment_type)
        if new_version:
            print(new_version)  # Just output the new version for scripts
            sys.exit(0)
        else:
            try:
                print("[ERROR] Failed to increment version")
            except UnicodeEncodeError:
                print("[ERROR] Failed to increment version")
            sys.exit(1)
    
    # Default behavior: check versions
    project_version = version_utils.get_project_version()
    print(f"Project version: {project_version}")
    
    # Check if changelog exists
    if not changelog_parser.exists():
        print("Warning: CHANGELOG.md not found", file=sys.stderr)
        sys.exit(1)
    
    # Get changelog version
    changelog_version = changelog_parser.get_latest_version()
    print(f"Changelog version: {changelog_version}")
    
    # Compare versions
    if project_version and changelog_version:
        if project_version == changelog_version:
            try:
                print("[OK] Versions match")
            except UnicodeEncodeError:
                print("[OK] Versions match")
            sys.exit(0)
        else:
            try:
                print(f"[ERROR] Version mismatch: project={project_version}, changelog={changelog_version}")
            except UnicodeEncodeError:
                print(f"[ERROR] Version mismatch: project={project_version}, changelog={changelog_version}")
            sys.exit(1)
    else:
        try:
            print("[ERROR] Could not determine versions")
        except UnicodeEncodeError:
            print("[ERROR] Could not determine versions")
        sys.exit(1)

if __name__ == "__main__":
    main()