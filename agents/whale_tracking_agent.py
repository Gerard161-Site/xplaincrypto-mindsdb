
"""
Crypto Whale Tracking Agent for XplainCrypto
Monitors large transactions and whale wallet activities
"""

import pandas as pd
import numpy as np
from typing import Dict, List, Optional, Tuple
from datetime import datetime, timedelta
import logging
import requests
from web3 import Web3
import time

logger = logging.getLogger(__name__)

class WhaleTrackingAgent:
    """
    Advanced whale tracking and large transaction monitoring
    """
    
    def __init__(self, config: Dict):
        self.config = config
        self.whale_thresholds = {
            'BTC': 100,      # 100+ BTC
            'ETH': 1000,     # 1000+ ETH
            'USDT': 1000000, # 1M+ USDT
            'USDC': 1000000, # 1M+ USDC
            'BNB': 10000,    # 10K+ BNB
            'ADA': 1000000,  # 1M+ ADA
            'SOL': 10000,    # 10K+ SOL
            'DOT': 100000,   # 100K+ DOT
        }
        
        # Initialize Web3 connections
        self.web3_connections = {}
        self._init_blockchain_connections()
        
        # Known whale addresses (examples - replace with real data)
        self.known_whales = {
            'ethereum': [
                '0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6',  # Example whale address
                '0x8894E0a0c962CB723c1976a4421c95949bE2D4E3',  # Example whale address
            ],
            'bitcoin': [
                '1P5ZEDWTKTFGxQjZphgWPQUpe554WKDfHQ',  # Example whale address
                '3Kzh9qAqVWQhEsfQz7zEQL1EuSx5tyNLNS',  # Example whale address
            ]
        }
    
    def _init_blockchain_connections(self):
        """Initialize blockchain connections"""
        try:
            # Ethereum mainnet
            if 'ethereum_rpc_url' in self.config:
                self.web3_connections['ethereum'] = Web3(Web3.HTTPProvider(self.config['ethereum_rpc_url']))
                logger.info("Ethereum Web3 connection initialized")
            
            # BSC
            if 'bsc_rpc_url' in self.config:
                self.web3_connections['bsc'] = Web3(Web3.HTTPProvider(self.config['bsc_rpc_url']))
                logger.info("BSC Web3 connection initialized")
            
            # Polygon
            if 'polygon_rpc_url' in self.config:
                self.web3_connections['polygon'] = Web3(Web3.HTTPProvider(self.config['polygon_rpc_url']))
                logger.info("Polygon Web3 connection initialized")
                
        except Exception as e:
            logger.error(f"Error initializing blockchain connections: {str(e)}")
    
    def track_large_transactions(self, symbol: str, blockchain: str = 'ethereum', hours: int = 24) -> Dict:
        """Track large transactions for a specific cryptocurrency"""
        try:
            large_transactions = {
                'symbol': symbol,
                'blockchain': blockchain,
                'timestamp': datetime.now().isoformat(),
                'time_range_hours': hours,
                'transactions': [],
                'summary': {}
            }
            
            # Get transactions based on blockchain
            if blockchain == 'ethereum':
                transactions = self._get_ethereum_large_transactions(symbol, hours)
            elif blockchain == 'bitcoin':
                transactions = self._get_bitcoin_large_transactions(symbol, hours)
            elif blockchain == 'bsc':
                transactions = self._get_bsc_large_transactions(symbol, hours)
            else:
                return {'error': f'Blockchain {blockchain} not supported'}
            
            large_transactions['transactions'] = transactions
            large_transactions['summary'] = self._analyze_transaction_patterns(transactions)
            
            return large_transactions
            
        except Exception as e:
            logger.error(f"Error tracking large transactions: {str(e)}")
            return {'error': str(e)}
    
    def monitor_whale_wallets(self, blockchain: str = 'ethereum') -> Dict:
        """Monitor known whale wallet activities"""
        try:
            whale_activities = {
                'blockchain': blockchain,
                'timestamp': datetime.now().isoformat(),
                'whale_count': 0,
                'activities': [],
                'summary': {}
            }
            
            if blockchain not in self.known_whales:
                return {'error': f'No known whales for blockchain {blockchain}'}
            
            whale_addresses = self.known_whales[blockchain]
            whale_activities['whale_count'] = len(whale_addresses)
            
            for address in whale_addresses:
                try:
                    activity = self._analyze_whale_address(address, blockchain)
                    if activity:
                        whale_activities['activities'].append(activity)
                except Exception as e:
                    logger.warning(f"Error analyzing whale address {address}: {str(e)}")
                    continue
            
            whale_activities['summary'] = self._summarize_whale_activities(whale_activities['activities'])
            
            return whale_activities
            
        except Exception as e:
            logger.error(f"Error monitoring whale wallets: {str(e)}")
            return {'error': str(e)}
    
    def detect_whale_movements(self, symbol: str, threshold_usd: float = 1000000) -> Dict:
        """Detect significant whale movements across multiple blockchains"""
        try:
            movements = {
                'symbol': symbol,
                'threshold_usd': threshold_usd,
                'timestamp': datetime.now().isoformat(),
                'movements': [],
                'alerts': []
            }
            
            # Check multiple blockchains
            blockchains = ['ethereum', 'bitcoin', 'bsc']
            
            for blockchain in blockchains:
                try:
                    blockchain_movements = self._detect_blockchain_movements(symbol, blockchain, threshold_usd)
                    movements['movements'].extend(blockchain_movements)
                except Exception as e:
                    logger.warning(f"Error detecting movements on {blockchain}: {str(e)}")
                    continue
            
            # Generate alerts for significant movements
            movements['alerts'] = self._generate_movement_alerts(movements['movements'])
            
            return movements
            
        except Exception as e:
            logger.error(f"Error detecting whale movements: {str(e)}")
            return {'error': str(e)}
    
    def _get_ethereum_large_transactions(self, symbol: str, hours: int) -> List[Dict]:
        """Get large Ethereum transactions"""
        transactions = []
        
        try:
            if 'ethereum' not in self.web3_connections:
                return transactions
            
            web3 = self.web3_connections['ethereum']
            
            # Get recent blocks
            latest_block = web3.eth.block_number
            blocks_to_check = min(hours * 240, 1000)  # Approximate blocks per hour
            
            threshold = self.whale_thresholds.get(symbol, 1000000)  # Default threshold
            
            for block_num in range(latest_block - blocks_to_check, latest_block):
                try:
                    block = web3.eth.get_block(block_num, full_transactions=True)
                    
                    for tx in block.transactions:
                        # Analyze transaction value
                        value_eth = web3.from_wei(tx.value, 'ether')
                        
                        if value_eth > threshold:
                            tx_data = {
                                'hash': tx.hash.hex(),
                                'from': tx['from'],
                                'to': tx.to,
                                'value_eth': float(value_eth),
                                'value_usd': float(value_eth) * self._get_eth_price(),
                                'gas_price': tx.gasPrice,
                                'block_number': block_num,
                                'timestamp': datetime.fromtimestamp(block.timestamp).isoformat(),
                                'type': self._classify_transaction_type(tx)
                            }
                            transactions.append(tx_data)
                            
                except Exception as e:
                    logger.warning(f"Error processing block {block_num}: {str(e)}")
                    continue
                    
                # Rate limiting
                time.sleep(0.1)
                
        except Exception as e:
            logger.error(f"Error getting Ethereum transactions: {str(e)}")
        
        return sorted(transactions, key=lambda x: x['value_usd'], reverse=True)[:100]
    
    def _get_bitcoin_large_transactions(self, symbol: str, hours: int) -> List[Dict]:
        """Get large Bitcoin transactions using external API"""
        transactions = []
        
        try:
            # Use blockchain.info API or similar
            api_url = "https://blockchain.info/blocks?format=json"
            response = requests.get(api_url, timeout=10)
            
            if response.status_code == 200:
                blocks = response.json()['blocks']
                threshold = self.whale_thresholds.get('BTC', 100)
                
                for block in blocks[:10]:  # Check recent blocks
                    block_hash = block['hash']
                    
                    # Get block details
                    block_url = f"https://blockchain.info/rawblock/{block_hash}"
                    block_response = requests.get(block_url, timeout=10)
                    
                    if block_response.status_code == 200:
                        block_data = block_response.json()
                        
                        for tx in block_data['tx']:
                            total_output = sum(out['value'] for out in tx['out']) / 100000000  # Convert to BTC
                            
                            if total_output > threshold:
                                tx_data = {
                                    'hash': tx['hash'],
                                    'value_btc': total_output,
                                    'value_usd': total_output * self._get_btc_price(),
                                    'inputs': len(tx['inputs']),
                                    'outputs': len(tx['out']),
                                    'timestamp': datetime.fromtimestamp(tx['time']).isoformat(),
                                    'type': 'bitcoin_transfer'
                                }
                                transactions.append(tx_data)
                    
                    time.sleep(0.5)  # Rate limiting
                    
        except Exception as e:
            logger.error(f"Error getting Bitcoin transactions: {str(e)}")
        
        return sorted(transactions, key=lambda x: x['value_usd'], reverse=True)[:50]
    
    def _get_bsc_large_transactions(self, symbol: str, hours: int) -> List[Dict]:
        """Get large BSC transactions"""
        # Similar to Ethereum but for BSC
        transactions = []
        
        try:
            if 'bsc' not in self.web3_connections:
                return transactions
            
            web3 = self.web3_connections['bsc']
            
            # Implementation similar to Ethereum
            # ... (BSC-specific logic)
            
        except Exception as e:
            logger.error(f"Error getting BSC transactions: {str(e)}")
        
        return transactions
    
    def _analyze_whale_address(self, address: str, blockchain: str) -> Dict:
        """Analyze a specific whale address"""
        try:
            if blockchain == 'ethereum' and 'ethereum' in self.web3_connections:
                web3 = self.web3_connections['ethereum']
                
                # Get balance
                balance_wei = web3.eth.get_balance(address)
                balance_eth = web3.from_wei(balance_wei, 'ether')
                
                # Get recent transactions
                recent_txs = self._get_address_transactions(address, blockchain)
                
                return {
                    'address': address,
                    'blockchain': blockchain,
                    'balance_eth': float(balance_eth),
                    'balance_usd': float(balance_eth) * self._get_eth_price(),
                    'recent_transactions': recent_txs[:10],
                    'activity_score': self._calculate_activity_score(recent_txs),
                    'last_activity': recent_txs[0]['timestamp'] if recent_txs else None
                }
            
            elif blockchain == 'bitcoin':
                # Use external API for Bitcoin address analysis
                return self._analyze_bitcoin_address(address)
            
        except Exception as e:
            logger.error(f"Error analyzing whale address {address}: {str(e)}")
            return None
    
    def _analyze_bitcoin_address(self, address: str) -> Dict:
        """Analyze Bitcoin address using external API"""
        try:
            api_url = f"https://blockchain.info/rawaddr/{address}"
            response = requests.get(api_url, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                
                balance_btc = data['final_balance'] / 100000000
                recent_txs = []
                
                for tx in data['txs'][:10]:
                    tx_data = {
                        'hash': tx['hash'],
                        'timestamp': datetime.fromtimestamp(tx['time']).isoformat(),
                        'value': sum(out['value'] for out in tx['out'] if out.get('addr') == address) / 100000000
                    }
                    recent_txs.append(tx_data)
                
                return {
                    'address': address,
                    'blockchain': 'bitcoin',
                    'balance_btc': balance_btc,
                    'balance_usd': balance_btc * self._get_btc_price(),
                    'transaction_count': data['n_tx'],
                    'recent_transactions': recent_txs,
                    'first_seen': datetime.fromtimestamp(data['txs'][-1]['time']).isoformat() if data['txs'] else None
                }
                
        except Exception as e:
            logger.error(f"Error analyzing Bitcoin address {address}: {str(e)}")
            return None
    
    def _get_address_transactions(self, address: str, blockchain: str, limit: int = 20) -> List[Dict]:
        """Get recent transactions for an address"""
        transactions = []
        
        try:
            if blockchain == 'ethereum' and 'ethereum' in self.web3_connections:
                # Use Etherscan API or similar for transaction history
                # This is a simplified implementation
                pass
            
        except Exception as e:
            logger.error(f"Error getting address transactions: {str(e)}")
        
        return transactions
    
    def _detect_blockchain_movements(self, symbol: str, blockchain: str, threshold_usd: float) -> List[Dict]:
        """Detect significant movements on a specific blockchain"""
        movements = []
        
        try:
            # Get recent large transactions
            large_txs = self._get_ethereum_large_transactions(symbol, 1) if blockchain == 'ethereum' else []
            
            for tx in large_txs:
                if tx.get('value_usd', 0) >= threshold_usd:
                    movement = {
                        'blockchain': blockchain,
                        'transaction_hash': tx['hash'],
                        'from_address': tx['from'],
                        'to_address': tx['to'],
                        'amount_usd': tx['value_usd'],
                        'timestamp': tx['timestamp'],
                        'movement_type': self._classify_movement_type(tx),
                        'risk_level': self._assess_movement_risk(tx)
                    }
                    movements.append(movement)
            
        except Exception as e:
            logger.error(f"Error detecting movements on {blockchain}: {str(e)}")
        
        return movements
    
    def _classify_transaction_type(self, tx) -> str:
        """Classify transaction type"""
        if tx.to is None:
            return 'contract_creation'
        elif tx.value == 0:
            return 'contract_interaction'
        else:
            return 'transfer'
    
    def _classify_movement_type(self, tx: Dict) -> str:
        """Classify whale movement type"""
        from_addr = tx.get('from_address', '').lower()
        to_addr = tx.get('to_address', '').lower()
        
        # Known exchange addresses (simplified)
        exchange_addresses = [
            '0x742d35cc6634c0532925a3b8d4c9db96c4b4d8b6',  # Example exchange
            '0x8894e0a0c962cb723c1976a4421c95949be2d4e3',  # Example exchange
        ]
        
        from_exchange = any(addr in from_addr for addr in exchange_addresses)
        to_exchange = any(addr in to_addr for addr in exchange_addresses)
        
        if from_exchange and not to_exchange:
            return 'exchange_outflow'
        elif not from_exchange and to_exchange:
            return 'exchange_inflow'
        elif from_exchange and to_exchange:
            return 'exchange_to_exchange'
        else:
            return 'wallet_to_wallet'
    
    def _assess_movement_risk(self, tx: Dict) -> str:
        """Assess risk level of whale movement"""
        amount_usd = tx.get('amount_usd', 0)
        movement_type = tx.get('movement_type', '')
        
        if amount_usd > 10000000:  # $10M+
            return 'very_high'
        elif amount_usd > 5000000:  # $5M+
            return 'high'
        elif amount_type == 'exchange_outflow' and amount_usd > 1000000:
            return 'high'  # Large outflows are concerning
        elif amount_usd > 1000000:  # $1M+
            return 'medium'
        else:
            return 'low'
    
    def _analyze_transaction_patterns(self, transactions: List[Dict]) -> Dict:
        """Analyze patterns in large transactions"""
        if not transactions:
            return {}
        
        total_volume = sum(tx.get('value_usd', 0) for tx in transactions)
        avg_transaction_size = total_volume / len(transactions)
        
        # Analyze transaction types
        type_counts = {}
        for tx in transactions:
            tx_type = tx.get('type', 'unknown')
            type_counts[tx_type] = type_counts.get(tx_type, 0) + 1
        
        # Analyze time distribution
        timestamps = [tx.get('timestamp') for tx in transactions if tx.get('timestamp')]
        time_analysis = self._analyze_time_distribution(timestamps)
        
        return {
            'total_transactions': len(transactions),
            'total_volume_usd': total_volume,
            'average_transaction_size_usd': avg_transaction_size,
            'largest_transaction_usd': max(tx.get('value_usd', 0) for tx in transactions),
            'transaction_types': type_counts,
            'time_analysis': time_analysis
        }
    
    def _summarize_whale_activities(self, activities: List[Dict]) -> Dict:
        """Summarize whale wallet activities"""
        if not activities:
            return {}
        
        total_balance_usd = sum(activity.get('balance_usd', 0) for activity in activities)
        active_whales = sum(1 for activity in activities if activity.get('activity_score', 0) > 0.5)
        
        return {
            'total_whales_monitored': len(activities),
            'active_whales': active_whales,
            'total_balance_usd': total_balance_usd,
            'average_balance_usd': total_balance_usd / len(activities),
            'most_active_whale': max(activities, key=lambda x: x.get('activity_score', 0), default={}),
            'largest_whale': max(activities, key=lambda x: x.get('balance_usd', 0), default={})
        }
    
    def _generate_movement_alerts(self, movements: List[Dict]) -> List[Dict]:
        """Generate alerts for significant whale movements"""
        alerts = []
        
        for movement in movements:
            risk_level = movement.get('risk_level', 'low')
            amount_usd = movement.get('amount_usd', 0)
            movement_type = movement.get('movement_type', '')
            
            if risk_level in ['high', 'very_high']:
                alert = {
                    'type': 'whale_movement_alert',
                    'severity': risk_level,
                    'message': f"Large {movement_type} detected: ${amount_usd:,.0f}",
                    'transaction_hash': movement.get('transaction_hash'),
                    'timestamp': movement.get('timestamp'),
                    'recommended_action': self._get_recommended_action(movement)
                }
                alerts.append(alert)
        
        return alerts
    
    def _get_recommended_action(self, movement: Dict) -> str:
        """Get recommended action based on whale movement"""
        movement_type = movement.get('movement_type', '')
        risk_level = movement.get('risk_level', 'low')
        
        if movement_type == 'exchange_inflow' and risk_level == 'very_high':
            return 'Monitor for potential selling pressure'
        elif movement_type == 'exchange_outflow' and risk_level == 'high':
            return 'Potential accumulation signal - monitor for bullish sentiment'
        elif risk_level == 'very_high':
            return 'High impact movement - monitor market reaction closely'
        else:
            return 'Continue monitoring'
    
    def _calculate_activity_score(self, transactions: List[Dict]) -> float:
        """Calculate activity score for a whale address"""
        if not transactions:
            return 0.0
        
        # Score based on transaction frequency and recency
        recent_txs = len([tx for tx in transactions if self._is_recent(tx.get('timestamp'))])
        total_txs = len(transactions)
        
        frequency_score = min(1.0, recent_txs / 10)  # Normalize to 0-1
        recency_score = 1.0 if recent_txs > 0 else 0.0
        
        return (frequency_score + recency_score) / 2
    
    def _is_recent(self, timestamp_str: str, hours: int = 24) -> bool:
        """Check if timestamp is within recent hours"""
        try:
            timestamp = datetime.fromisoformat(timestamp_str.replace('Z', '+00:00'))
            cutoff = datetime.now() - timedelta(hours=hours)
            return timestamp > cutoff
        except:
            return False
    
    def _analyze_time_distribution(self, timestamps: List[str]) -> Dict:
        """Analyze time distribution of transactions"""
        if not timestamps:
            return {}
        
        try:
            # Convert timestamps to datetime objects
            datetimes = []
            for ts in timestamps:
                try:
                    dt = datetime.fromisoformat(ts.replace('Z', '+00:00'))
                    datetimes.append(dt)
                except:
                    continue
            
            if not datetimes:
                return {}
            
            # Analyze by hour
            hour_counts = {}
            for dt in datetimes:
                hour = dt.hour
                hour_counts[hour] = hour_counts.get(hour, 0) + 1
            
            # Find peak activity hours
            peak_hour = max(hour_counts.keys(), key=lambda h: hour_counts[h])
            
            return {
                'peak_activity_hour': peak_hour,
                'hourly_distribution': hour_counts,
                'total_timespan_hours': (max(datetimes) - min(datetimes)).total_seconds() / 3600
            }
            
        except Exception as e:
            logger.error(f"Error analyzing time distribution: {str(e)}")
            return {}
    
    def _get_eth_price(self) -> float:
        """Get current ETH price in USD"""
        try:
            response = requests.get('https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd', timeout=5)
            if response.status_code == 200:
                return response.json()['ethereum']['usd']
        except:
            pass
        return 2000.0  # Fallback price
    
    def _get_btc_price(self) -> float:
        """Get current BTC price in USD"""
        try:
            response = requests.get('https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd', timeout=5)
            if response.status_code == 200:
                return response.json()['bitcoin']['usd']
        except:
            pass
        return 50000.0  # Fallback price
