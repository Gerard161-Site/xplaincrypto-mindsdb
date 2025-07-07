
#!/usr/bin/env python3
"""
XplainCrypto Historical Data Synchronization Script
Optimizes and synchronizes historical crypto data for MindsDB processing
"""

import asyncio
import aiohttp
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import logging
import json
import time
from typing import Dict, List, Optional
import sqlite3
import mysql.connector
from dataclasses import dataclass
import hashlib

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('historical_sync.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

@dataclass
class SyncConfig:
    """Configuration for data synchronization"""
    batch_size: int = 1000
    max_concurrent_requests: int = 10
    retry_attempts: int = 3
    retry_delay: int = 5
    data_retention_days: int = 365
    compression_enabled: bool = True
    incremental_sync: bool = True

class HistoricalDataSyncer:
    """Main class for historical crypto data synchronization"""
    
    def __init__(self, config: SyncConfig):
        self.config = config
        self.session = None
        self.db_connections = {}
        self.sync_stats = {
            'total_records': 0,
            'successful_syncs': 0,
            'failed_syncs': 0,
            'start_time': None,
            'end_time': None
        }
    
    async def __aenter__(self):
        """Async context manager entry"""
        self.session = aiohttp.ClientSession(
            timeout=aiohttp.ClientTimeout(total=30),
            connector=aiohttp.TCPConnector(limit=self.config.max_concurrent_requests)
        )
        self.sync_stats['start_time'] = datetime.now()
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit"""
        if self.session:
            await self.session.close()
        self.sync_stats['end_time'] = datetime.now()
        self._log_sync_summary()
    
    def _log_sync_summary(self):
        """Log synchronization summary"""
        duration = self.sync_stats['end_time'] - self.sync_stats['start_time']
        logger.info(f"""
        Synchronization Summary:
        - Total Records: {self.sync_stats['total_records']}
        - Successful Syncs: {self.sync_stats['successful_syncs']}
        - Failed Syncs: {self.sync_stats['failed_syncs']}
        - Duration: {duration}
        - Success Rate: {(self.sync_stats['successful_syncs'] / max(1, self.sync_stats['total_records'])) * 100:.2f}%
        """)
    
    async def sync_coinmarketcap_data(self, symbols: List[str], days: int = 365):
        """Sync historical data from CoinMarketCap"""
        logger.info(f"Starting CoinMarketCap sync for {len(symbols)} symbols, {days} days")
        
        tasks = []
        semaphore = asyncio.Semaphore(self.config.max_concurrent_requests)
        
        for symbol in symbols:
            task = self._sync_symbol_data(semaphore, symbol, 'coinmarketcap', days)
            tasks.append(task)
        
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        successful = sum(1 for r in results if not isinstance(r, Exception))
        logger.info(f"CoinMarketCap sync completed: {successful}/{len(symbols)} successful")
        
        return results
    
    async def _sync_symbol_data(self, semaphore: asyncio.Semaphore, symbol: str, source: str, days: int):
        """Sync data for a single symbol"""
        async with semaphore:
            try:
                # Check if incremental sync is possible
                last_sync = await self._get_last_sync_timestamp(symbol, source)
                
                if self.config.incremental_sync and last_sync:
                    start_date = last_sync
                    logger.info(f"Incremental sync for {symbol} from {start_date}")
                else:
                    start_date = datetime.now() - timedelta(days=days)
                    logger.info(f"Full sync for {symbol} from {start_date}")
                
                # Fetch historical data
                data = await self._fetch_historical_data(symbol, source, start_date)
                
                if data:
                    # Process and optimize data
                    processed_data = self._process_historical_data(data, symbol, source)
                    
                    # Store in database
                    await self._store_historical_data(processed_data, symbol, source)
                    
                    # Update sync timestamp
                    await self._update_sync_timestamp(symbol, source)
                    
                    self.sync_stats['successful_syncs'] += 1
                    logger.info(f"Successfully synced {len(processed_data)} records for {symbol}")
                    
                    return processed_data
                else:
                    logger.warning(f"No data received for {symbol}")
                    return None
                    
            except Exception as e:
                logger.error(f"Error syncing {symbol}: {str(e)}")
                self.sync_stats['failed_syncs'] += 1
                return None
    
    async def _fetch_historical_data(self, symbol: str, source: str, start_date: datetime) -> Optional[List[Dict]]:
        """Fetch historical data from external API"""
        for attempt in range(self.config.retry_attempts):
            try:
                if source == 'coinmarketcap':
                    url = f"https://api.coinmarketcap.com/data-api/v3/cryptocurrency/historical"
                    params = {
                        'symbol': symbol,
                        'timeStart': int(start_date.timestamp()),
                        'timeEnd': int(datetime.now().timestamp()),
                        'interval': '1d'
                    }
                elif source == 'defillama':
                    url = f"https://api.llama.fi/protocol/{symbol.lower()}"
                    params = {}
                else:
                    logger.error(f"Unknown data source: {source}")
                    return None
                
                async with self.session.get(url, params=params) as response:
                    if response.status == 200:
                        data = await response.json()
                        return self._extract_data_from_response(data, source)
                    else:
                        logger.warning(f"API request failed for {symbol}: {response.status}")
                        
            except Exception as e:
                logger.warning(f"Attempt {attempt + 1} failed for {symbol}: {str(e)}")
                if attempt < self.config.retry_attempts - 1:
                    await asyncio.sleep(self.config.retry_delay)
        
        return None
    
    def _extract_data_from_response(self, response_data: Dict, source: str) -> List[Dict]:
        """Extract relevant data from API response"""
        if source == 'coinmarketcap':
            if 'data' in response_data and 'quotes' in response_data['data']:
                return response_data['data']['quotes']
        elif source == 'defillama':
            if 'tvl' in response_data:
                return response_data['tvl']
        
        return []
    
    def _process_historical_data(self, raw_data: List[Dict], symbol: str, source: str) -> List[Dict]:
        """Process and optimize historical data"""
        processed_data = []
        
        for record in raw_data:
            try:
                if source == 'coinmarketcap':
                    processed_record = {
                        'symbol': symbol,
                        'timestamp': record.get('timestamp'),
                        'price': float(record.get('quote', {}).get('USD', {}).get('price', 0)),
                        'volume_24h': float(record.get('quote', {}).get('USD', {}).get('volume_24h', 0)),
                        'market_cap': float(record.get('quote', {}).get('USD', {}).get('market_cap', 0)),
                        'percent_change_24h': float(record.get('quote', {}).get('USD', {}).get('percent_change_24h', 0)),
                        'source': source,
                        'data_hash': self._generate_data_hash(record),
                        'processed_at': datetime.now().isoformat()
                    }
                elif source == 'defillama':
                    processed_record = {
                        'protocol': symbol,
                        'timestamp': record.get('date'),
                        'tvl': float(record.get('totalLiquidityUSD', 0)),
                        'source': source,
                        'data_hash': self._generate_data_hash(record),
                        'processed_at': datetime.now().isoformat()
                    }
                
                # Data validation
                if self._validate_record(processed_record):
                    processed_data.append(processed_record)
                    
            except Exception as e:
                logger.warning(f"Error processing record for {symbol}: {str(e)}")
                continue
        
        # Remove duplicates based on data hash
        processed_data = self._remove_duplicates(processed_data)
        
        # Sort by timestamp
        processed_data.sort(key=lambda x: x.get('timestamp', 0))
        
        self.sync_stats['total_records'] += len(processed_data)
        return processed_data
    
    def _generate_data_hash(self, record: Dict) -> str:
        """Generate hash for duplicate detection"""
        record_str = json.dumps(record, sort_keys=True)
        return hashlib.md5(record_str.encode()).hexdigest()
    
    def _validate_record(self, record: Dict) -> bool:
        """Validate processed record"""
        required_fields = ['timestamp', 'source']
        
        for field in required_fields:
            if field not in record or record[field] is None:
                return False
        
        # Check for reasonable timestamp
        if isinstance(record['timestamp'], (int, float)):
            timestamp = datetime.fromtimestamp(record['timestamp'])
            if timestamp < datetime(2009, 1, 1) or timestamp > datetime.now():
                return False
        
        return True
    
    def _remove_duplicates(self, data: List[Dict]) -> List[Dict]:
        """Remove duplicate records based on data hash"""
        seen_hashes = set()
        unique_data = []
        
        for record in data:
            data_hash = record.get('data_hash')
            if data_hash not in seen_hashes:
                seen_hashes.add(data_hash)
                unique_data.append(record)
        
        return unique_data
    
    async def _get_last_sync_timestamp(self, symbol: str, source: str) -> Optional[datetime]:
        """Get timestamp of last successful sync"""
        try:
            # This would query your sync tracking table
            # Implementation depends on your database setup
            query = """
            SELECT MAX(timestamp) as last_sync 
            FROM sync_tracking 
            WHERE symbol = %s AND source = %s
            """
            # Execute query and return result
            return None  # Placeholder
        except Exception as e:
            logger.warning(f"Could not get last sync timestamp: {str(e)}")
            return None
    
    async def _store_historical_data(self, data: List[Dict], symbol: str, source: str):
        """Store processed data in database"""
        try:
            # Batch insert for efficiency
            batch_size = self.config.batch_size
            
            for i in range(0, len(data), batch_size):
                batch = data[i:i + batch_size]
                await self._insert_batch(batch, source)
                
        except Exception as e:
            logger.error(f"Error storing data for {symbol}: {str(e)}")
            raise
    
    async def _insert_batch(self, batch: List[Dict], source: str):
        """Insert batch of records into database"""
        if source == 'coinmarketcap':
            table = 'historical_prices'
            columns = ['symbol', 'timestamp', 'price', 'volume_24h', 'market_cap', 'percent_change_24h', 'source', 'data_hash', 'processed_at']
        elif source == 'defillama':
            table = 'defi_protocols'
            columns = ['protocol', 'timestamp', 'tvl', 'source', 'data_hash', 'processed_at']
        
        # Prepare batch insert query
        placeholders = ', '.join(['%s'] * len(columns))
        query = f"INSERT IGNORE INTO {table} ({', '.join(columns)}) VALUES ({placeholders})"
        
        # Execute batch insert
        values = []
        for record in batch:
            row = [record.get(col) for col in columns]
            values.append(row)
        
        # This would execute the actual database insert
        logger.info(f"Inserted batch of {len(values)} records into {table}")
    
    async def _update_sync_timestamp(self, symbol: str, source: str):
        """Update sync tracking table"""
        try:
            query = """
            INSERT INTO sync_tracking (symbol, source, last_sync, updated_at)
            VALUES (%s, %s, %s, %s)
            ON DUPLICATE KEY UPDATE 
            last_sync = VALUES(last_sync),
            updated_at = VALUES(updated_at)
            """
            values = (symbol, source, datetime.now(), datetime.now())
            # Execute query
            logger.debug(f"Updated sync timestamp for {symbol} ({source})")
        except Exception as e:
            logger.warning(f"Could not update sync timestamp: {str(e)}")

class DataOptimizer:
    """Optimize historical data for MindsDB processing"""
    
    @staticmethod
    def create_technical_indicators(df: pd.DataFrame) -> pd.DataFrame:
        """Add technical indicators to price data"""
        # Simple Moving Averages
        df['sma_7'] = df['price'].rolling(window=7).mean()
        df['sma_30'] = df['price'].rolling(window=30).mean()
        df['sma_90'] = df['price'].rolling(window=90).mean()
        
        # Exponential Moving Averages
        df['ema_12'] = df['price'].ewm(span=12).mean()
        df['ema_26'] = df['price'].ewm(span=26).mean()
        
        # MACD
        df['macd'] = df['ema_12'] - df['ema_26']
        df['macd_signal'] = df['macd'].ewm(span=9).mean()
        
        # RSI
        delta = df['price'].diff()
        gain = (delta.where(delta > 0, 0)).rolling(window=14).mean()
        loss = (-delta.where(delta < 0, 0)).rolling(window=14).mean()
        rs = gain / loss
        df['rsi'] = 100 - (100 / (1 + rs))
        
        # Bollinger Bands
        df['bb_middle'] = df['price'].rolling(window=20).mean()
        bb_std = df['price'].rolling(window=20).std()
        df['bb_upper'] = df['bb_middle'] + (bb_std * 2)
        df['bb_lower'] = df['bb_middle'] - (bb_std * 2)
        
        # Volume indicators
        df['volume_sma'] = df['volume_24h'].rolling(window=7).mean()
        df['volume_ratio'] = df['volume_24h'] / df['volume_sma']
        
        return df
    
    @staticmethod
    def create_market_features(df: pd.DataFrame) -> pd.DataFrame:
        """Create market-specific features"""
        # Price momentum
        df['momentum_1d'] = df['price'].pct_change(1)
        df['momentum_7d'] = df['price'].pct_change(7)
        df['momentum_30d'] = df['price'].pct_change(30)
        
        # Volatility
        df['volatility_7d'] = df['price'].rolling(window=7).std()
        df['volatility_30d'] = df['price'].rolling(window=30).std()
        
        # Market cap rank changes
        df['market_cap_rank'] = df['market_cap'].rank(ascending=False)
        df['rank_change'] = df['market_cap_rank'].diff()
        
        # Support and resistance levels
        df['support_level'] = df['price'].rolling(window=30).min()
        df['resistance_level'] = df['price'].rolling(window=30).max()
        df['price_position'] = (df['price'] - df['support_level']) / (df['resistance_level'] - df['support_level'])
        
        return df

async def main():
    """Main synchronization function"""
    config = SyncConfig(
        batch_size=1000,
        max_concurrent_requests=5,
        retry_attempts=3,
        incremental_sync=True
    )
    
    # Major cryptocurrencies to sync
    symbols = [
        'BTC', 'ETH', 'BNB', 'XRP', 'ADA', 'SOL', 'DOGE', 'DOT', 'AVAX', 'SHIB',
        'MATIC', 'LTC', 'UNI', 'LINK', 'ATOM', 'XLM', 'BCH', 'ALGO', 'VET', 'ICP'
    ]
    
    async with HistoricalDataSyncer(config) as syncer:
        # Sync CoinMarketCap data
        await syncer.sync_coinmarketcap_data(symbols, days=365)
        
        # Additional sync operations can be added here
        logger.info("Historical data synchronization completed")

if __name__ == "__main__":
    asyncio.run(main())
