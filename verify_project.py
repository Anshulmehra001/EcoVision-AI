#!/usr/bin/env python3
"""
EcoVision AI Project Verification Script
Checks if all required files and configurations are in place
"""

import os
import json
from pathlib import Path
from typing import List, Tuple

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    END = '\033[0m'
    BOLD = '\033[1m'

def check_file_exists(filepath: str) -> bool:
    """Check if a file exists"""
    return Path(filepath).exists()

def check_directory_exists(dirpath: str) -> bool:
    """Check if a directory exists"""
    return Path(dirpath).is_dir()

def print_status(message: str, status: bool, warning: bool = False):
    """Print colored status message"""
    if status:
        print(f"{Colors.GREEN}✓{Colors.END} {message}")
    elif warning:
        print(f"{Colors.YELLOW}⚠{Colors.END} {message}")
    else:
        print(f"{Colors.RED}✗{Colors.END} {message}")

def print_header(text: str):
    """Print section header"""
    print(f"\n{Colors.BOLD}{Colors.BLUE}{'='*60}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.BLUE}{text}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.BLUE}{'='*60}{Colors.END}\n")

def verify_core_files() -> Tuple[int, int]:
    """Verify core Dart files"""
    print_header("Core Files Verification")
    
    files = [
        "lib/main.dart",
        "lib/core/core.dart",
        "lib/core/theme/app_theme.dart",
        "lib/core/models/classification_result.dart",
        "lib/core/models/eco_task.dart",
        "lib/core/models/user_progress.dart",
        "lib/core/services/tflite_service.dart",
        "lib/core/services/opencv_service.dart",
        "lib/core/services/permission_service.dart",
        "lib/core/services/resource_manager.dart",
    ]
    
    passed = 0
    total = len(files)
    
    for file in files:
        exists = check_file_exists(file)
        print_status(f"Core file: {file}", exists)
        if exists:
            passed += 1
    
    return passed, total

def verify_features() -> Tuple[int, int]:
    """Verify feature files"""
    print_header("Feature Files Verification")
    
    files = [
        "lib/features/splash/splash_screen.dart",
        "lib/features/main_scaffold.dart",
        "lib/features/flora_shield/screen.dart",
        "lib/features/flora_shield/provider.dart",
        "lib/features/biodiversity_ear/screen.dart",
        "lib/features/biodiversity_ear/provider.dart",
        "lib/features/aqua_lens/screen.dart",
        "lib/features/aqua_lens/provider.dart",
        "lib/features/eco_action_hub/screen.dart",
        "lib/features/eco_action_hub/task_detail_screen.dart",
        "lib/features/eco_action_hub/providers.dart",
    ]
    
    passed = 0
    total = len(files)
    
    for file in files:
        exists = check_file_exists(file)
        print_status(f"Feature file: {file}", exists)
        if exists:
            passed += 1
    
    return passed, total

def verify_assets() -> Tuple[int, int]:
    """Verify asset files"""
    print_header("Assets Verification")
    
    files = [
        ("assets/models/flora_model.tflite", False),
        ("assets/models/flora_labels.txt", False),
        ("assets/models/bird_model.tflite", False),
        ("assets/models/bird_labels.txt", False),
        ("assets/data/tasks.json", False),
        ("assets/icons/app_icon.png", True),  # Optional
    ]
    
    passed = 0
    total = len(files)
    
    for file, optional in files:
        exists = check_file_exists(file)
        if optional:
            print_status(f"Asset (optional): {file}", exists, warning=not exists)
            if exists:
                passed += 1
        else:
            print_status(f"Asset: {file}", exists)
            if exists:
                passed += 1
    
    return passed, total

def verify_android_config() -> Tuple[int, int]:
    """Verify Android configuration"""
    print_header("Android Configuration Verification")
    
    checks = [
        ("android/app/build.gradle", False),
        ("android/app/src/main/AndroidManifest.xml", False),
        ("android/app/proguard-rules.pro", False),
        ("android/key.properties.template", False),
        ("android/key.properties", True),  # Optional - needs to be created
        ("android/keystore/ecovisionai-release.jks", True),  # Optional - needs to be created
    ]
    
    passed = 0
    total = len(checks)
    
    for file, optional in checks:
        exists = check_file_exists(file)
        if optional:
            print_status(f"Config (needs setup): {file}", exists, warning=not exists)
            if exists:
                passed += 1
        else:
            print_status(f"Config: {file}", exists)
            if exists:
                passed += 1
    
    return passed, total

def verify_tests() -> Tuple[int, int]:
    """Verify test files"""
    print_header("Test Files Verification")
    
    files = [
        "test/unit/models/classification_result_test.dart",
        "test/unit/models/eco_task_test.dart",
        "test/unit/models/user_progress_test.dart",
        "test/unit/services/permission_service_test.dart",
        "test/integration/navigation_test.dart",
        "test/integration/eco_action_hub_test.dart",
        "test/integration/offline_functionality_test.dart",
    ]
    
    passed = 0
    total = len(files)
    
    for file in files:
        exists = check_file_exists(file)
        print_status(f"Test file: {file}", exists)
        if exists:
            passed += 1
    
    return passed, total

def verify_documentation() -> Tuple[int, int]:
    """Verify documentation files"""
    print_header("Documentation Verification")
    
    files = [
        "README.md",
        "BUILD_AND_DEPLOY.md",
        "DEPLOYMENT_CHECKLIST.md",
        "QUICK_START_DEPLOYMENT.md",
        "FINAL_VERIFICATION_AND_BUILD.md",
    ]
    
    passed = 0
    total = len(files)
    
    for file in files:
        exists = check_file_exists(file)
        print_status(f"Documentation: {file}", exists)
        if exists:
            passed += 1
    
    return passed, total

def check_pubspec_dependencies():
    """Check if pubspec.yaml has all required dependencies"""
    print_header("Dependencies Verification")
    
    required_deps = [
        "flutter_riverpod",
        "tflite_flutter",
        "camera",
        "opencv_dart",
        "record",
        "path_provider",
        "shared_preferences",
        "permission_handler",
        "google_fonts",
        "flutter_launcher_icons",
    ]
    
    try:
        with open("pubspec.yaml", "r") as f:
            content = f.read()
            
        passed = 0
        for dep in required_deps:
            if dep in content:
                print_status(f"Dependency: {dep}", True)
                passed += 1
            else:
                print_status(f"Dependency: {dep}", False)
        
        return passed, len(required_deps)
    except Exception as e:
        print_status(f"Error reading pubspec.yaml: {e}", False)
        return 0, len(required_deps)

def check_tasks_json():
    """Verify tasks.json structure"""
    print_header("Tasks JSON Verification")
    
    try:
        with open("assets/data/tasks.json", "r") as f:
            tasks = json.load(f)
        
        if not isinstance(tasks, list):
            print_status("tasks.json is not an array", False)
            return False
        
        print_status(f"tasks.json loaded successfully ({len(tasks)} tasks)", True)
        
        # Check first task structure
        if len(tasks) > 0:
            required_fields = ["id", "title", "description", "instructions", "points", "trigger"]
            task = tasks[0]
            all_fields = all(field in task for field in required_fields)
            print_status(f"Task structure valid (has all required fields)", all_fields)
            return all_fields
        
        return True
    except FileNotFoundError:
        print_status("tasks.json not found", False)
        return False
    except json.JSONDecodeError as e:
        print_status(f"tasks.json invalid JSON: {e}", False)
        return False

def print_summary(results: dict):
    """Print verification summary"""
    print_header("Verification Summary")
    
    total_passed = 0
    total_checks = 0
    
    for category, (passed, total) in results.items():
        total_passed += passed
        total_checks += total
        percentage = (passed / total * 100) if total > 0 else 0
        status = percentage == 100
        print_status(f"{category}: {passed}/{total} ({percentage:.1f}%)", status, warning=(percentage >= 80 and percentage < 100))
    
    print(f"\n{Colors.BOLD}Overall: {total_passed}/{total_checks} checks passed ({total_passed/total_checks*100:.1f}%){Colors.END}\n")
    
    if total_passed == total_checks:
        print(f"{Colors.GREEN}{Colors.BOLD}✓ Project is complete and ready for build!{Colors.END}\n")
    elif total_passed / total_checks >= 0.9:
        print(f"{Colors.YELLOW}{Colors.BOLD}⚠ Project is mostly complete. Review warnings above.{Colors.END}\n")
    else:
        print(f"{Colors.RED}{Colors.BOLD}✗ Project has missing components. Review errors above.{Colors.END}\n")

def print_next_steps():
    """Print next steps"""
    print_header("Next Steps")
    
    steps = [
        "1. Install Flutter SDK if not already installed",
        "2. Run: flutter pub get",
        "3. Run: flutter analyze",
        "4. Create keystore: scripts\\setup_keystore.bat (Windows) or ./scripts/setup_keystore.sh (Linux/Mac)",
        "5. Configure signing: Copy android/key.properties.template to android/key.properties and edit",
        "6. (Optional) Add app icon: Place 1024x1024 PNG at assets/icons/app_icon.png",
        "7. (Optional) Generate icons: flutter pub run flutter_launcher_icons",
        "8. Build debug: flutter build apk --debug",
        "9. Test on device: flutter install --debug",
        "10. Build release: flutter build apk --release",
    ]
    
    for step in steps:
        print(f"  {step}")
    
    print(f"\n{Colors.BLUE}For detailed instructions, see: FINAL_VERIFICATION_AND_BUILD.md{Colors.END}\n")

def main():
    """Main verification function"""
    print(f"\n{Colors.BOLD}{Colors.BLUE}EcoVision AI - Project Verification{Colors.END}")
    print(f"{Colors.BLUE}A VIREN Legacy Project by Aniket Mehra{Colors.END}\n")
    
    results = {}
    
    # Run all verifications
    results["Core Files"] = verify_core_files()
    results["Feature Files"] = verify_features()
    results["Assets"] = verify_assets()
    results["Android Config"] = verify_android_config()
    results["Tests"] = verify_tests()
    results["Documentation"] = verify_documentation()
    results["Dependencies"] = check_pubspec_dependencies()
    
    # Check tasks.json
    check_tasks_json()
    
    # Print summary
    print_summary(results)
    
    # Print next steps
    print_next_steps()

if __name__ == "__main__":
    main()
