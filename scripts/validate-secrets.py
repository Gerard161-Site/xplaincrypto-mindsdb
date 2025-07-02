#!/usr/bin/env python3
"""
XplainCrypto MindsDB Secrets Validation
Tests API key validity and connectivity
"""

import os
import sys
import requests
import time
from pathlib import Path

class SecretsValidator:
    def __init__(self):
        self.secrets_dir = Path("secrets")
        self.results = {}
        
    def read_secret(self, filename):
        """Read secret from file"""
        try:
            with open(self.secrets_dir / filename, 'r') as f:
                return f.read().strip()
        except FileNotFoundError:
            return None
    
    def test_openai_key(self):
        """Test OpenAI API key"""
        api_key = self.read_secret("openai_api_key.txt")
        if not api_key:
            return {"status": "FAIL", "message": "API key not found"}
        
        headers = {"Authorization": f"Bearer {api_key}"}
        try:
            response = requests.get("https://api.openai.com/v1/models", headers=headers, timeout=10)
            if response.status_code == 200:
                return {"status": "PASS", "message": "OpenAI API key valid"}
            else:
                return {"status": "FAIL", "message": f"OpenAI API error: {response.status_code}"}
        except Exception as e:
            return {"status": "FAIL", "message": f"OpenAI connection error: {str(e)}"}
    
    def test_anthropic_key(self):
        """Test Anthropic API key"""
        api_key = self.read_secret("anthropic_api_key.txt")
        if not api_key:
            return {"status": "FAIL", "message": "API key not found"}
        
        headers = {
            "x-api-key": api_key,
            "anthropic-version": "2023-06-01",
            "content-type": "application/json"
        }
        
        data = {
            "model": "claude-3-sonnet-20240229",
            "max_tokens": 10,
            "messages": [{"role": "user", "content": "Hello"}]
        }
        
        try:
            response = requests.post("https://api.anthropic.com/v1/messages", 
                                   headers=headers, json=data, timeout=10)
            if response.status_code == 200:
                return {"status": "PASS", "message": "Anthropic API key valid"}
            else:
                return {"status": "FAIL", "message": f"Anthropic API error: {response.status_code}"}
        except Exception as e:
            return {"status": "FAIL", "message": f"Anthropic connection error: {str(e)}"}
    
    def test_coinmarketcap_key(self):
        """Test CoinMarketCap API key"""
        api_key = self.read_secret("coinmarketcap_api_key.txt")
        if not api_key:
            return {"status": "FAIL", "message": "API key not found"}
        
        headers = {"X-CMC_PRO_API_KEY": api_key}
        try:
            response = requests.get("https://pro-api.coinmarketcap.com/v1/cryptocurrency/listings/latest?limit=1", 
                                  headers=headers, timeout=10)
            if response.status_code == 200:
                return {"status": "PASS", "message": "CoinMarketCap API key valid"}
            else:
                return {"status": "FAIL", "message": f"CoinMarketCap API error: {response.status_code}"}
        except Exception as e:
            return {"status": "FAIL", "message": f"CoinMarketCap connection error: {str(e)}"}
    
    def test_timegpt_key(self):
        """Test TimeGPT API key"""
        api_key = self.read_secret("timegpt_api_key.txt")
        if not api_key:
            return {"status": "FAIL", "message": "API key not found"}
        
        headers = {"authorization": f"Bearer {api_key}"}
        try:
            response = requests.get("https://dashboard.nixtla.io/api/validate_api_key", 
                                  headers=headers, timeout=10)
            if response.status_code == 200:
                return {"status": "PASS", "message": "TimeGPT API key valid"}
            else:
                return {"status": "FAIL", "message": f"TimeGPT API error: {response.status_code}"}
        except Exception as e:
            return {"status": "FAIL", "message": f"TimeGPT connection error: {str(e)}"}
    
    def test_database_credentials(self):
        """Test database credentials"""
        postgres_pass = self.read_secret("postgres_password.txt")
        redis_pass = self.read_secret("redis_password.txt")
        
        results = []
        if postgres_pass:
            results.append({"status": "PASS", "message": "PostgreSQL password found"})
        else:
            results.append({"status": "FAIL", "message": "PostgreSQL password not found"})
            
        if redis_pass:
            results.append({"status": "PASS", "message": "Redis password found"})
        else:
            results.append({"status": "FAIL", "message": "Redis password not found"})
            
        return results
    
    def run_all_tests(self):
        """Run all validation tests"""
        print("🔐 XplainCrypto MindsDB Secrets Validation")
        print("==========================================")
        
        tests = [
            ("OpenAI API", self.test_openai_key),
            ("Anthropic API", self.test_anthropic_key),
            ("CoinMarketCap API", self.test_coinmarketcap_key),
            ("TimeGPT API", self.test_timegpt_key),
        ]
        
        all_passed = True
        
        for test_name, test_func in tests:
            print(f"\n🧪 Testing {test_name}...")
            result = test_func()
            
            if result["status"] == "PASS":
                print(f"✅ {result['message']}")
            else:
                print(f"❌ {result['message']}")
                all_passed = False
            
            time.sleep(1)  # Rate limiting
        
        # Test database credentials
        print(f"\n🧪 Testing Database Credentials...")
        db_results = self.test_database_credentials()
        for result in db_results:
            if result["status"] == "PASS":
                print(f"✅ {result['message']}")
            else:
                print(f"❌ {result['message']}")
                all_passed = False
        
        print(f"\n{'='*50}")
        if all_passed:
            print("✅ All secrets validation passed!")
            return 0
        else:
            print("❌ Some secrets validation failed!")
            return 1

if __name__ == "__main__":
    validator = SecretsValidator()
    exit_code = validator.run_all_tests()
    sys.exit(exit_code) 