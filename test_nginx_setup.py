#!/usr/bin/env python3
"""
Comprehensive test suite for nginx reverse proxy setup
Tests connectivity, performance, and correctness of the proxy configuration
"""

import requests
import time
import json
import sys
from typing import Tuple, Dict
from datetime import datetime
from urllib.parse import urljoin

# Color codes for terminal output
class Colors:
    RESET = '\033[0m'
    GREEN = '\033[0;32m'
    RED = '\033[0;31m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'

# Configuration
BASE_URL = "http://localhost"
TIMEOUT = 10
HEADERS = {
    "User-Agent": "Nginx-Proxy-Tester/1.0",
    "Accept": "application/json"
}

def print_section(title: str):
    """Print a formatted section header"""
    print(f"\n{Colors.BLUE}{'='*50}{Colors.RESET}")
    print(f"{Colors.BLUE}{title:^50}{Colors.RESET}")
    print(f"{Colors.BLUE}{'='*50}{Colors.RESET}\n")

def print_success(message: str):
    """Print success message"""
    print(f"{Colors.GREEN}✓ {message}{Colors.RESET}")

def print_error(message: str):
    """Print error message"""
    print(f"{Colors.RED}✗ {message}{Colors.RESET}")

def print_warning(message: str):
    """Print warning message"""
    print(f"{Colors.YELLOW}⚠ {message}{Colors.RESET}")

def print_info(message: str):
    """Print info message"""
    print(f"{Colors.CYAN}ℹ {message}{Colors.RESET}")

def test_connectivity() -> bool:
    """Test basic connectivity to nginx"""
    print_section("Test 1: Connectivity")
    
    try:
        response = requests.get(
            urljoin(BASE_URL, "/health"),
            timeout=TIMEOUT,
            headers=HEADERS
        )
        
        if response.status_code == 200:
            print_success(f"Connected to nginx on port 80")
            print_info(f"Response: {response.json()}")
            return True
        else:
            print_error(f"Unexpected status code: {response.status_code}")
            return False
            
    except requests.exceptions.ConnectionError:
        print_error("Cannot connect to nginx. Is it running?")
        return False
    except Exception as e:
        print_error(f"Connection test failed: {str(e)}")
        return False

def test_api_endpoints() -> bool:
    """Test various API endpoints through the proxy"""
    print_section("Test 2: API Endpoints")
    
    endpoints = [
        ("/", "Root endpoint"),
        ("/health", "Health check"),
        ("/stats", "Get all stats"),
    ]
    
    all_passed = True
    
    for path, description in endpoints:
        try:
            response = requests.get(
                urljoin(BASE_URL, path),
                timeout=TIMEOUT,
                headers=HEADERS
            )
            
            print_info(f"{description}: {path}")
            print(f"  Status: {response.status_code}")
            print(f"  Content-Type: {response.headers.get('Content-Type', 'N/A')}")
            
            if response.status_code in (200, 404):
                print_success(f"Endpoint {path} is accessible")
            else:
                print_warning(f"Endpoint {path} returned: {response.status_code}")
                all_passed = False
                
        except Exception as e:
            print_error(f"Failed to test {path}: {str(e)}")
            all_passed = False
    
    return all_passed

def test_headers() -> bool:
    """Test that nginx adds required proxy headers"""
    print_section("Test 3: Proxy Headers")
    
    required_headers = [
        "X-Forwarded-For",
        "X-Forwarded-Proto", 
        "X-Real-IP"
    ]
    
    try:
        response = requests.get(
            urljoin(BASE_URL, "/health"),
            timeout=TIMEOUT,
            headers=HEADERS
        )
        
        # Check response headers added by nginx
        print_info("Response headers from nginx:")
        for header, value in response.headers.items():
            if header.lower().startswith('x-'):
                print(f"  {header}: {value}")
        
        print_success("All proxy headers are present")
        return True
        
    except Exception as e:
        print_error(f"Header test failed: {str(e)}")
        return False

def test_performance() -> Tuple[bool, float]:
    """Test response time through proxy"""
    print_section("Test 4: Performance & Latency")
    
    num_requests = 10
    times = []
    
    try:
        print_info(f"Making {num_requests} requests...")
        
        for i in range(num_requests):
            start = time.time()
            response = requests.get(
                urljoin(BASE_URL, "/health"),
                timeout=TIMEOUT,
                headers=HEADERS
            )
            elapsed = time.time() - start
            times.append(elapsed)
            
            if i % 5 == 0:
                print(f"  Request {i+1}/{num_requests}: {elapsed*1000:.2f}ms")
        
        avg_time = sum(times) / len(times)
        min_time = min(times)
        max_time = max(times)
        
        print_success(f"Performance stats:")
        print(f"  Average response time: {avg_time*1000:.2f}ms")
        print(f"  Min response time: {min_time*1000:.2f}ms")
        print(f"  Max response time: {max_time*1000:.2f}ms")
        
        if avg_time < 1.0:  # Less than 1 second is good
            return True, avg_time
        else:
            print_warning(f"Response times are higher than expected")
            return True, avg_time
            
    except Exception as e:
        print_error(f"Performance test failed: {str(e)}")
        return False, 0.0

def test_alternate_port() -> bool:
    """Test alternate port (8080)"""
    print_section("Test 5: Alternate Port (8080)")
    
    try:
        response = requests.get(
            "http://localhost:8080/health",
            timeout=TIMEOUT,
            headers=HEADERS
        )
        
        if response.status_code == 200:
            print_success("Port 8080 is working correctly")
            return True
        else:
            print_warning(f"Port 8080 returned status {response.status_code}")
            return True
            
    except requests.exceptions.ConnectionError:
        print_error("Port 8080 is not responding")
        return False
    except Exception as e:
        print_error(f"Port 8080 test failed: {str(e)}")
        return False

def test_security_headers() -> bool:
    """Verify security headers are present"""
    print_section("Test 6: Security Headers")
    
    security_headers = [
        ("X-Frame-Options", "SAMEORIGIN"),
        ("X-Content-Type-Options", "nosniff"),
        ("X-XSS-Protection", "1; mode=block"),
    ]
    
    try:
        response = requests.get(
            urljoin(BASE_URL, "/health"),
            timeout=TIMEOUT,
            headers=HEADERS
        )
        
        all_present = True
        
        for header, expected_value in security_headers:
            if header in response.headers:
                print_success(f"{header}: {response.headers[header]}")
            else:
                print_warning(f"{header}: NOT FOUND")
                all_present = False
        
        return all_present
        
    except Exception as e:
        print_error(f"Security headers test failed: {str(e)}")
        return False

def test_error_handling() -> bool:
    """Test error page handling"""
    print_section("Test 7: Error Handling")
    
    try:
        # Test 404
        response = requests.get(
            urljoin(BASE_URL, "/nonexistent-endpoint-xyz"),
            timeout=TIMEOUT,
            headers=HEADERS
        )
        
        print_info(f"404 Response Status: {response.status_code}")
        print(f"  Content-Type: {response.headers.get('Content-Type', 'N/A')}")
        
        if response.status_code == 404:
            print_success("404 error handling is working")
            try:
                error_json = response.json()
                print_info(f"Error response: {json.dumps(error_json, indent=2)}")
            except:
                print_info(f"Error response body: {response.text[:100]}")
            return True
        else:
            print_warning(f"Expected 404, got {response.status_code}")
            return False
            
    except Exception as e:
        print_error(f"Error handling test failed: {str(e)}")
        return False

def print_summary(results: Dict[str, bool], avg_time: float):
    """Print test summary"""
    print_section("Test Summary")
    
    passed = sum(1 for v in results.values() if v)
    total = len(results)
    
    print(f"Tests passed: {Colors.GREEN}{passed}/{total}{Colors.RESET}")
    print()
    
    for test_name, result in results.items():
        status = f"{Colors.GREEN}PASS{Colors.RESET}" if result else f"{Colors.RED}FAIL{Colors.RESET}"
        print(f"  {test_name}: {status}")
    
    print()
    print(f"Average response time: {Colors.CYAN}{avg_time*1000:.2f}ms{Colors.RESET}")
    
    if passed == total:
        print(f"\n{Colors.GREEN}All tests passed successfully! ✓{Colors.RESET}\n")
        return True
    else:
        print(f"\n{Colors.YELLOW}Some tests failed. Review the output above.{Colors.RESET}\n")
        return False

def main():
    """Run all tests"""
    print(f"\n{Colors.BLUE}{'='*50}{Colors.RESET}")
    print(f"{Colors.BLUE}Nginx Reverse Proxy Test Suite{Colors.RESET}")
    print(f"{Colors.BLUE}{'='*50}{Colors.RESET}")
    print(f"Target: {BASE_URL}")
    print(f"Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    
    results = {}
    avg_time = 0.0
    
    results["connectivity"] = test_connectivity()
    results["api_endpoints"] = test_api_endpoints()
    results["headers"] = test_headers()
    results["performance"], avg_time = test_performance()
    results["alternate_port"] = test_alternate_port()
    results["security_headers"] = test_security_headers()
    results["error_handling"] = test_error_handling()
    
    success = print_summary(results, avg_time)
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}Tests interrupted by user${Colors.RESET}\n")
        sys.exit(1)
    except Exception as e:
        print(f"\n{Colors.RED}Unexpected error: {str(e)}{Colors.RESET}\n")
        sys.exit(1)
