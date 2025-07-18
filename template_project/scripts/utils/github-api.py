#!/usr/bin/env python3
"""
GitHub API utilities for release management
"""

import os
import sys
import json
import subprocess
import requests
from pathlib import Path
from typing import Optional, Dict, List, Any

class GitHubAPI:
    """GitHub API client for release management"""
    
    def __init__(self, token: Optional[str] = None):
        self.token = token or os.getenv('GITHUB_TOKEN')
        self.base_url = "https://api.github.com"
        self.headers = {
            'Authorization': f'token {self.token}',
            'Accept': 'application/vnd.github.v3+json',
            'Content-Type': 'application/json'
        }
        
        if not self.token:
            raise ValueError("GitHub token not provided. Set GITHUB_TOKEN environment variable")
    
    def _make_request(self, method: str, endpoint: str, data: Optional[Dict] = None) -> Dict:
        """Make HTTP request to GitHub API"""
        url = f"{self.base_url}/{endpoint}"
        
        try:
            if method.upper() == 'GET':
                response = requests.get(url, headers=self.headers)
            elif method.upper() == 'POST':
                response = requests.post(url, headers=self.headers, json=data)
            elif method.upper() == 'PATCH':
                response = requests.patch(url, headers=self.headers, json=data)
            elif method.upper() == 'DELETE':
                response = requests.delete(url, headers=self.headers)
            else:
                raise ValueError(f"Unsupported HTTP method: {method}")
            
            response.raise_for_status()
            return response.json() if response.content else {}
            
        except requests.exceptions.RequestException as e:
            print(f"GitHub API request failed: {e}")
            if hasattr(e, 'response') and e.response:
                print(f"Response: {e.response.text}")
            raise
    
    def get_repository_info(self, owner: str, repo: str) -> Dict:
        """Get repository information"""
        return self._make_request('GET', f'repos/{owner}/{repo}')
    
    def get_tags(self, owner: str, repo: str) -> List[Dict]:
        """Get repository tags"""
        return self._make_request('GET', f'repos/{owner}/{repo}/tags')
    
    def get_releases(self, owner: str, repo: str) -> List[Dict]:
        """Get repository releases"""
        return self._make_request('GET', f'repos/{owner}/{repo}/releases')
    
    def get_release_by_tag(self, owner: str, repo: str, tag: str) -> Optional[Dict]:
        """Get release by tag name"""
        try:
            return self._make_request('GET', f'repos/{owner}/{repo}/releases/tags/{tag}')
        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 404:
                return None
            raise
    
    def create_tag(self, owner: str, repo: str, tag: str, sha: str, message: str) -> Dict:
        """Create a new tag"""
        data = {
            'tag': tag,
            'message': message,
            'object': sha,
            'type': 'commit'
        }
        return self._make_request('POST', f'repos/{owner}/{repo}/git/tags', data)
    
    def create_tag_reference(self, owner: str, repo: str, tag: str, sha: str) -> Dict:
        """Create a tag reference"""
        data = {
            'ref': f'refs/tags/{tag}',
            'sha': sha
        }
        return self._make_request('POST', f'repos/{owner}/{repo}/git/refs', data)
    
    def create_release(self, owner: str, repo: str, tag: str, name: str, 
                      body: str, draft: bool = False, prerelease: bool = False) -> Dict:
        """Create a new release"""
        data = {
            'tag_name': tag,
            'name': name,
            'body': body,
            'draft': draft,
            'prerelease': prerelease
        }
        return self._make_request('POST', f'repos/{owner}/{repo}/releases', data)
    
    def update_release(self, owner: str, repo: str, release_id: int, 
                      name: Optional[str] = None, body: Optional[str] = None,
                      draft: Optional[bool] = None, prerelease: Optional[bool] = None) -> Dict:
        """Update an existing release"""
        data = {}
        if name is not None:
            data['name'] = name
        if body is not None:
            data['body'] = body
        if draft is not None:
            data['draft'] = draft
        if prerelease is not None:
            data['prerelease'] = prerelease
        
        return self._make_request('PATCH', f'repos/{owner}/{repo}/releases/{release_id}', data)
    
    def upload_release_asset(self, owner: str, repo: str, release_id: int, 
                           file_path: str, name: Optional[str] = None) -> Dict:
        """Upload a file as release asset"""
        file_path = Path(file_path)
        if not file_path.exists():
            raise FileNotFoundError(f"File not found: {file_path}")
        
        asset_name = name or file_path.name
        
        # Get upload URL
        release = self._make_request('GET', f'repos/{owner}/{repo}/releases/{release_id}')
        upload_url = release['upload_url'].replace('{?name,label}', '')
        
        # Upload file
        with open(file_path, 'rb') as f:
            files = {'file': f}
            headers = {
                'Authorization': f'token {self.token}',
                'Content-Type': 'application/octet-stream'
            }
            
            response = requests.post(
                f"{upload_url}?name={asset_name}",
                headers=headers,
                data=f.read()
            )
            response.raise_for_status()
            return response.json()
    
    def delete_release_asset(self, owner: str, repo: str, asset_id: int) -> None:
        """Delete a release asset"""
        self._make_request('DELETE', f'repos/{owner}/{repo}/releases/assets/{asset_id}')

class GitHubReleaseManager:
    """High-level GitHub release management"""
    
    def __init__(self, project_root: str, token: Optional[str] = None):
        self.project_root = Path(project_root)
        self.api = GitHubAPI(token)
        self.owner = None
        self.repo = None
        
        # Auto-detect repository info
        self._detect_repository_info()
    
    def _detect_repository_info(self):
        """Detect repository owner and name from git remote"""
        try:
            # Get remote URL
            result = subprocess.run(
                ['git', 'remote', 'get-url', 'origin'],
                cwd=self.project_root,
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                remote_url = result.stdout.strip()
                
                # Parse GitHub URL
                if 'github.com' in remote_url:
                    if remote_url.startswith('https://'):
                        # https://github.com/owner/repo.git
                        parts = remote_url.replace('https://github.com/', '').replace('.git', '').split('/')
                    elif remote_url.startswith('git@'):
                        # git@github.com:owner/repo.git
                        parts = remote_url.replace('git@github.com:', '').replace('.git', '').split('/')
                    else:
                        raise ValueError(f"Unsupported remote URL format: {remote_url}")
                    
                    if len(parts) >= 2:
                        self.owner = parts[0]
                        self.repo = parts[1]
                        print(f"Detected repository: {self.owner}/{self.repo}")
                        return
            
            raise ValueError("Could not detect repository info from git remote")
            
        except Exception as e:
            print(f"Error detecting repository info: {e}")
            raise
    
    def _get_current_commit_sha(self) -> str:
        """Get current commit SHA"""
        try:
            result = subprocess.run(
                ['git', 'rev-parse', 'HEAD'],
                cwd=self.project_root,
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                return result.stdout.strip()
            else:
                raise ValueError("Could not get current commit SHA")
                
        except Exception as e:
            print(f"Error getting commit SHA: {e}")
            raise
    
    def _read_changelog_section(self, version: str) -> str:
        """Read changelog section for version"""
        changelog_file = self.project_root / "CHANGELOG.md"
        
        if not changelog_file.exists():
            return f"Release {version}"
        
        try:
            with open(changelog_file, 'r', encoding='utf-8') as f:
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
                        continue
                
                if in_section:
                    section_lines.append(line)
            
            # Clean up section content
            while section_lines and not section_lines[0].strip():
                section_lines.pop(0)
            while section_lines and not section_lines[-1].strip():
                section_lines.pop()
            
            return '\n'.join(section_lines) if section_lines else f"Release {version}"
            
        except Exception as e:
            print(f"Error reading changelog: {e}")
            return f"Release {version}"
    
    def tag_exists(self, tag: str) -> bool:
        """Check if tag exists"""
        try:
            tags = self.api.get_tags(self.owner, self.repo)
            return any(t['name'] == tag for t in tags)
        except Exception:
            return False
    
    def release_exists(self, tag: str) -> bool:
        """Check if release exists"""
        try:
            release = self.api.get_release_by_tag(self.owner, self.repo, tag)
            return release is not None
        except Exception:
            return False
    
    def create_tag_and_release(self, version: str, prerelease: bool = False) -> Dict:
        """Create tag and release"""
        tag = f"v{version}" if not version.startswith('v') else version
        
        # Check if tag already exists
        if self.tag_exists(tag):
            print(f"Tag {tag} already exists")
            
            # Check if release exists
            if self.release_exists(tag):
                print(f"Release {tag} already exists")
                return self.api.get_release_by_tag(self.owner, self.repo, tag)
        else:
            # Create tag
            print(f"Creating tag {tag}...")
            commit_sha = self._get_current_commit_sha()
            
            try:
                self.api.create_tag_reference(self.owner, self.repo, tag, commit_sha)
                print(f"Tag {tag} created successfully")
            except Exception as e:
                print(f"Error creating tag: {e}")
                raise
        
        # Create release
        print(f"Creating release {tag}...")
        release_name = f"Release {version}"
        release_body = self._read_changelog_section(version)
        
        try:
            release = self.api.create_release(
                self.owner, self.repo, tag, release_name, 
                release_body, draft=False, prerelease=prerelease
            )
            print(f"Release {tag} created successfully")
            return release
            
        except Exception as e:
            print(f"Error creating release: {e}")
            raise
    
    def upload_assets(self, release_id: int, asset_files: List[str]) -> List[Dict]:
        """Upload assets to release"""
        assets = []
        
        for file_path in asset_files:
            file_path = Path(file_path)
            
            if not file_path.exists():
                print(f"Warning: Asset file not found: {file_path}")
                continue
            
            print(f"Uploading asset: {file_path.name}...")
            
            try:
                asset = self.api.upload_release_asset(
                    self.owner, self.repo, release_id, str(file_path)
                )
                assets.append(asset)
                print(f"Asset uploaded successfully: {file_path.name}")
                
            except Exception as e:
                print(f"Error uploading asset {file_path.name}: {e}")
                continue
        
        return assets

def main():
    """Main function for command-line usage"""
    if len(sys.argv) < 3:
        print("Usage: python github-api.py <project_root> <version>")
        sys.exit(1)
    
    project_root = sys.argv[1]
    version = sys.argv[2]
    
    try:
        manager = GitHubReleaseManager(project_root)
        
        # Create tag and release
        release = manager.create_tag_and_release(version)
        
        # Upload assets
        asset_files = [
            f"{project_root}/dist/*.whl",
            f"{project_root}/CHANGELOG.md",
            f"{project_root}/README.md"
        ]
        
        # Expand glob patterns
        import glob
        expanded_files = []
        for pattern in asset_files:
            expanded_files.extend(glob.glob(pattern))
        
        if expanded_files:
            manager.upload_assets(release['id'], expanded_files)
        
        print(f"Release created successfully: {release['html_url']}")
        
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()