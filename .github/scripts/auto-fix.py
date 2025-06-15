#!/usr/bin/env python3
"""
iOS 빌드 자동 수정 스크립트
실패 로그를 분석하고 자동으로 문제를 감지하여 수정사항을 적용합니다.
"""

import re
import os
import json
import subprocess
from typing import Dict, List, Optional

class BuildFailureAnalyzer:
    def __init__(self):
        self.common_issues = {
            "provisioning_profile": {
                "patterns": [
                    r"No profiles for .* were found",
                    r"requires a provisioning profile",
                    r"Profile is missing the required UUID"
                ],
                "solutions": [
                    "regenerate_provisioning_profile",
                    "update_bundle_id_in_profile",
                    "check_app_capabilities"
                ]
            },
            "code_signing": {
                "patterns": [
                    r"No signing certificate .* found",
                    r"No certificate matching .* found",
                    r"Code signing is required"
                ],
                "solutions": [
                    "regenerate_certificates",
                    "update_certificate_name",
                    "switch_to_automatic_signing"
                ]
            },
            "capabilities_mismatch": {
                "patterns": [
                    r"requires a provisioning profile with the .* feature",
                    r"App Groups feature",
                    r"Push Notifications feature"
                ],
                "solutions": [
                    "remove_unused_capabilities",
                    "add_capabilities_to_profile",
                    "update_app_id_configuration"
                ]
            },
            "gem_dependencies": {
                "patterns": [
                    r"Could not find gem",
                    r"bundler: failed to load command",
                    r"Gem::LoadError"
                ],
                "solutions": [
                    "update_gemfile",
                    "clear_gem_cache",
                    "install_missing_gems"
                ]
            }
        }
    
    def analyze_log(self, log_content: str) -> Dict:
        """로그 내용을 분석하여 문제점과 해결책을 반환합니다."""
        detected_issues = []
        
        for issue_type, config in self.common_issues.items():
            for pattern in config["patterns"]:
                if re.search(pattern, log_content, re.IGNORECASE):
                    detected_issues.append({
                        "type": issue_type,
                        "pattern": pattern,
                        "solutions": config["solutions"]
                    })
                    break
        
        return {
            "issues_found": len(detected_issues),
            "detected_issues": detected_issues,
            "recommended_actions": self._get_recommended_actions(detected_issues)
        }
    
    def _get_recommended_actions(self, issues: List[Dict]) -> List[str]:
        """감지된 문제들을 바탕으로 권장 조치사항을 반환합니다."""
        actions = []
        
        for issue in issues:
            if issue["type"] == "provisioning_profile":
                actions.append("🔧 프로비저닝 프로필 재생성 필요")
                actions.append("📋 App ID capabilities 확인 필요")
            elif issue["type"] == "code_signing":
                actions.append("🔐 인증서 재생성 또는 이름 수정 필요")
                actions.append("🔄 자동 서명으로 전환 고려")
            elif issue["type"] == "capabilities_mismatch":
                actions.append("⚠️ 앱 기능과 프로비저닝 프로필 불일치")
                actions.append("🗑️ 불필요한 capabilities 제거 또는 프로필에 추가")
            elif issue["type"] == "gem_dependencies":
                actions.append("💎 Ruby gem 의존성 문제")
                actions.append("🔄 bundle install 재실행 필요")
        
        return list(set(actions))  # 중복 제거
    
    def generate_fix_commands(self, issues: List[Dict]) -> List[str]:
        """자동 수정 명령어들을 생성합니다."""
        commands = []
        
        for issue in issues:
            if issue["type"] == "gem_dependencies":
                commands.extend([
                    "gem update bundler",
                    "bundle clean --force",
                    "bundle install"
                ])
            elif issue["type"] == "code_signing":
                commands.extend([
                    "security delete-keychain fastlane_tmp_keychain || true",
                    "security create-keychain -p '' fastlane_tmp_keychain",
                    "security set-keychain-settings fastlane_tmp_keychain"
                ])
        
        return commands

def main():
    print("🔍 iOS 빌드 실패 로그 분석 시작...")
    
    # GitHub Actions 환경에서 로그 파일 찾기
    log_files = [
        "/Users/runner/Library/Logs/gym/thoughtsreframer-thoughtsreframer.log",
        "./fastlane/report.xml"
    ]
    
    analyzer = BuildFailureAnalyzer()
    
    for log_file in log_files:
        if os.path.exists(log_file):
            print(f"📄 로그 파일 분석 중: {log_file}")
            
            with open(log_file, 'r', encoding='utf-8', errors='ignore') as f:
                log_content = f.read()
            
            analysis = analyzer.analyze_log(log_content)
            
            print(f"🔍 감지된 문제: {analysis['issues_found']}개")
            
            for action in analysis['recommended_actions']:
                print(f"  {action}")
            
            # 자동 수정 명령어 실행
            fix_commands = analyzer.generate_fix_commands(analysis['detected_issues'])
            for cmd in fix_commands:
                print(f"🔧 실행: {cmd}")
                try:
                    subprocess.run(cmd, shell=True, check=True)
                except subprocess.CalledProcessError as e:
                    print(f"⚠️ 명령어 실행 실패: {e}")
            
            break
    else:
        print("📄 로그 파일을 찾을 수 없습니다.")

if __name__ == "__main__":
    main() 