
"""
Crypto Market Anomaly Detection Agent for XplainCrypto
Detects unusual patterns, price movements, and market irregularities
"""

import pandas as pd
import numpy as np
from typing import Dict, List, Optional, Tuple
from datetime import datetime, timedelta
import logging
from sklearn.ensemble import IsolationForest
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import DBSCAN
from sklearn.decomposition import PCA
import scipy.stats as stats
from scipy import signal
import warnings
warnings.filterwarnings('ignore')

logger = logging.getLogger(__name__)

class AnomalyDetectionAgent:
    """
    Advanced anomaly detection for cryptocurrency markets
    """
    
    def __init__(self, config: Dict):
        self.config = config
        self.models = {}
        self.scalers = {}
        self.thresholds = {}
        
        # Anomaly detection parameters
        self.isolation_forest_params = {
            'contamination': 0.1,
            'random_state': 42,
            'n_estimators': 100
        }
        
        self.dbscan_params = {
            'eps': 0.5,
            'min_samples': 5
        }
    
    def detect_price_anomalies(self, data: pd.DataFrame, symbol: str) -> Dict:
        """
        Detect price-based anomalies using multiple methods
        """
        try:
            anomalies = {
                'symbol': symbol,
                'timestamp': datetime.now().isoformat(),
                'anomalies': [],
                'severity_scores': {},
                'anomaly_types': {}
            }
            
            # 1. Statistical outliers using Z-score
            price_changes = data['close'].pct_change().dropna()
            z_scores = np.abs(stats.zscore(price_changes))
            z_anomalies = np.where(z_scores > 3)[0]
            
            for idx in z_anomalies:
                anomalies['anomalies'].append({
                    'type': 'statistical_outlier',
                    'timestamp': data.index[idx],
                    'price': data['close'].iloc[idx],
                    'change_percent': price_changes.iloc[idx] * 100,
                    'z_score': z_scores[idx],
                    'severity': 'high' if z_scores[idx] > 4 else 'medium'
                })
            
            # 2. Isolation Forest for multivariate anomalies
            features = self._prepare_anomaly_features(data)
            if len(features) > 10:  # Need sufficient data
                scaler = StandardScaler()
                features_scaled = scaler.fit_transform(features)
                
                iso_forest = IsolationForest(**self.isolation_forest_params)
                anomaly_labels = iso_forest.fit_predict(features_scaled)
                anomaly_scores = iso_forest.score_samples(features_scaled)
                
                # Find anomalies (labeled as -1)
                iso_anomalies = np.where(anomaly_labels == -1)[0]
                
                for idx in iso_anomalies:
                    anomalies['anomalies'].append({
                        'type': 'multivariate_anomaly',
                        'timestamp': data.index[idx],
                        'price': data['close'].iloc[idx],
                        'anomaly_score': anomaly_scores[idx],
                        'severity': 'high' if anomaly_scores[idx] < -0.5 else 'medium'
                    })
            
            # 3. Volume-Price divergence anomalies
            volume_price_anomalies = self._detect_volume_price_divergence(data)
            anomalies['anomalies'].extend(volume_price_anomalies)
            
            # 4. Sudden spike detection
            spike_anomalies = self._detect_price_spikes(data)
            anomalies['anomalies'].extend(spike_anomalies)
            
            # 5. Pattern-based anomalies
            pattern_anomalies = self._detect_pattern_anomalies(data)
            anomalies['anomalies'].extend(pattern_anomalies)
            
            # Calculate severity scores
            anomalies['severity_scores'] = self._calculate_severity_scores(anomalies['anomalies'])
            
            # Categorize anomaly types
            anomalies['anomaly_types'] = self._categorize_anomalies(anomalies['anomalies'])
            
            logger.info(f"Detected {len(anomalies['anomalies'])} anomalies for {symbol}")
            return anomalies
            
        except Exception as e:
            logger.error(f"Error detecting price anomalies: {str(e)}")
            raise
    
    def detect_market_manipulation(self, data: pd.DataFrame, symbol: str) -> Dict:
        """
        Detect potential market manipulation patterns
        """
        try:
            manipulation_signals = {
                'symbol': symbol,
                'timestamp': datetime.now().isoformat(),
                'signals': [],
                'risk_level': 'low'
            }
            
            # 1. Pump and dump detection
            pump_dump_signals = self._detect_pump_dump(data)
            manipulation_signals['signals'].extend(pump_dump_signals)
            
            # 2. Wash trading detection
            wash_trading_signals = self._detect_wash_trading(data)
            manipulation_signals['signals'].extend(wash_trading_signals)
            
            # 3. Spoofing detection
            spoofing_signals = self._detect_spoofing(data)
            manipulation_signals['signals'].extend(spoofing_signals)
            
            # 4. Coordinated trading detection
            coordinated_signals = self._detect_coordinated_trading(data)
            manipulation_signals['signals'].extend(coordinated_signals)
            
            # Calculate overall risk level
            if len(manipulation_signals['signals']) > 5:
                manipulation_signals['risk_level'] = 'high'
            elif len(manipulation_signals['signals']) > 2:
                manipulation_signals['risk_level'] = 'medium'
            
            return manipulation_signals
            
        except Exception as e:
            logger.error(f"Error detecting market manipulation: {str(e)}")
            raise
    
    def detect_flash_crashes(self, data: pd.DataFrame, symbol: str) -> Dict:
        """
        Detect flash crash events and rapid price movements
        """
        try:
            flash_events = {
                'symbol': symbol,
                'timestamp': datetime.now().isoformat(),
                'events': [],
                'recovery_analysis': {}
            }
            
            # Calculate price changes
            price_changes = data['close'].pct_change()
            
            # Define flash crash criteria
            crash_threshold = -0.05  # 5% drop
            recovery_threshold = 0.03  # 3% recovery
            time_window = 10  # minutes
            
            # Find potential flash crashes
            for i in range(len(data) - time_window):
                window_data = data.iloc[i:i+time_window]
                window_changes = price_changes.iloc[i:i+time_window]
                
                # Check for rapid decline
                min_change = window_changes.min()
                if min_change < crash_threshold:
                    crash_idx = window_changes.idxmin()
                    
                    # Check for recovery
                    post_crash_data = data.iloc[i+time_window:i+time_window*2]
                    if len(post_crash_data) > 0:
                        recovery = (post_crash_data['close'].max() - data['close'].iloc[crash_idx]) / data['close'].iloc[crash_idx]
                        
                        flash_events['events'].append({
                            'type': 'flash_crash',
                            'timestamp': crash_idx,
                            'price_before': data['close'].iloc[i],
                            'price_crash': data['close'].iloc[crash_idx],
                            'crash_magnitude': min_change * 100,
                            'recovery_percent': recovery * 100,
                            'volume_spike': window_data['volume'].max() / window_data['volume'].mean(),
                            'duration_minutes': time_window
                        })
            
            return flash_events
            
        except Exception as e:
            logger.error(f"Error detecting flash crashes: {str(e)}")
            raise
    
    def _prepare_anomaly_features(self, data: pd.DataFrame) -> np.ndarray:
        """Prepare features for multivariate anomaly detection"""
        features = []
        
        # Price-based features
        features.append(data['close'].pct_change().fillna(0))
        features.append(data['high'] / data['low'] - 1)
        features.append(data['close'] / data['open'] - 1)
        
        # Volume features
        features.append(data['volume'].pct_change().fillna(0))
        features.append(data['volume'] / data['volume'].rolling(20).mean() - 1)
        
        # Volatility features
        features.append(data['close'].rolling(20).std())
        features.append(data['high'].rolling(20).std())
        
        # Moving average deviations
        for period in [5, 10, 20]:
            ma = data['close'].rolling(period).mean()
            features.append((data['close'] - ma) / ma)
        
        return np.column_stack(features)
    
    def _detect_volume_price_divergence(self, data: pd.DataFrame) -> List[Dict]:
        """Detect volume-price divergence anomalies"""
        anomalies = []
        
        # Calculate price and volume changes
        price_changes = data['close'].pct_change()
        volume_changes = data['volume'].pct_change()
        
        # Find divergences
        for i in range(1, len(data)):
            price_change = price_changes.iloc[i]
            volume_change = volume_changes.iloc[i]
            
            # Significant price increase with volume decrease
            if price_change > 0.02 and volume_change < -0.3:
                anomalies.append({
                    'type': 'volume_price_divergence',
                    'subtype': 'price_up_volume_down',
                    'timestamp': data.index[i],
                    'price': data['close'].iloc[i],
                    'price_change': price_change * 100,
                    'volume_change': volume_change * 100,
                    'severity': 'medium'
                })
            
            # Significant price decrease with volume increase
            elif price_change < -0.02 and volume_change > 0.5:
                anomalies.append({
                    'type': 'volume_price_divergence',
                    'subtype': 'price_down_volume_up',
                    'timestamp': data.index[i],
                    'price': data['close'].iloc[i],
                    'price_change': price_change * 100,
                    'volume_change': volume_change * 100,
                    'severity': 'high'
                })
        
        return anomalies
    
    def _detect_price_spikes(self, data: pd.DataFrame) -> List[Dict]:
        """Detect sudden price spikes"""
        anomalies = []
        
        # Calculate rolling statistics
        rolling_mean = data['close'].rolling(20).mean()
        rolling_std = data['close'].rolling(20).std()
        
        # Find spikes
        for i in range(20, len(data)):
            current_price = data['close'].iloc[i]
            mean_price = rolling_mean.iloc[i]
            std_price = rolling_std.iloc[i]
            
            # Check for upward spike
            if current_price > mean_price + 3 * std_price:
                anomalies.append({
                    'type': 'price_spike',
                    'subtype': 'upward_spike',
                    'timestamp': data.index[i],
                    'price': current_price,
                    'deviation_factor': (current_price - mean_price) / std_price,
                    'severity': 'high'
                })
            
            # Check for downward spike
            elif current_price < mean_price - 3 * std_price:
                anomalies.append({
                    'type': 'price_spike',
                    'subtype': 'downward_spike',
                    'timestamp': data.index[i],
                    'price': current_price,
                    'deviation_factor': (mean_price - current_price) / std_price,
                    'severity': 'high'
                })
        
        return anomalies
    
    def _detect_pattern_anomalies(self, data: pd.DataFrame) -> List[Dict]:
        """Detect pattern-based anomalies"""
        anomalies = []
        
        # Detect gaps
        gaps = self._detect_gaps(data)
        anomalies.extend(gaps)
        
        # Detect unusual candlestick patterns
        candlestick_anomalies = self._detect_candlestick_anomalies(data)
        anomalies.extend(candlestick_anomalies)
        
        return anomalies
    
    def _detect_gaps(self, data: pd.DataFrame) -> List[Dict]:
        """Detect price gaps"""
        anomalies = []
        
        for i in range(1, len(data)):
            prev_close = data['close'].iloc[i-1]
            current_open = data['open'].iloc[i]
            
            gap_percent = (current_open - prev_close) / prev_close * 100
            
            if abs(gap_percent) > 2:  # 2% gap threshold
                anomalies.append({
                    'type': 'price_gap',
                    'subtype': 'gap_up' if gap_percent > 0 else 'gap_down',
                    'timestamp': data.index[i],
                    'gap_percent': gap_percent,
                    'prev_close': prev_close,
                    'current_open': current_open,
                    'severity': 'high' if abs(gap_percent) > 5 else 'medium'
                })
        
        return anomalies
    
    def _detect_candlestick_anomalies(self, data: pd.DataFrame) -> List[Dict]:
        """Detect unusual candlestick patterns"""
        anomalies = []
        
        for i in range(len(data)):
            open_price = data['open'].iloc[i]
            high_price = data['high'].iloc[i]
            low_price = data['low'].iloc[i]
            close_price = data['close'].iloc[i]
            
            # Calculate body and wick sizes
            body_size = abs(close_price - open_price)
            upper_wick = high_price - max(open_price, close_price)
            lower_wick = min(open_price, close_price) - low_price
            total_range = high_price - low_price
            
            # Detect doji (very small body)
            if body_size / total_range < 0.1 and total_range > 0:
                anomalies.append({
                    'type': 'candlestick_pattern',
                    'subtype': 'doji',
                    'timestamp': data.index[i],
                    'body_ratio': body_size / total_range,
                    'severity': 'low'
                })
            
            # Detect hammer/hanging man (long lower wick)
            elif lower_wick > 2 * body_size and upper_wick < body_size:
                anomalies.append({
                    'type': 'candlestick_pattern',
                    'subtype': 'hammer_hanging_man',
                    'timestamp': data.index[i],
                    'lower_wick_ratio': lower_wick / body_size,
                    'severity': 'medium'
                })
        
        return anomalies
    
    def _detect_pump_dump(self, data: pd.DataFrame) -> List[Dict]:
        """Detect pump and dump patterns"""
        signals = []
        
        # Look for rapid price increases followed by rapid decreases
        price_changes = data['close'].pct_change()
        volume_changes = data['volume'].pct_change()
        
        for i in range(10, len(data) - 10):
            # Check for pump phase
            pump_window = price_changes.iloc[i-5:i+1]
            pump_volume = volume_changes.iloc[i-5:i+1]
            
            if pump_window.sum() > 0.15 and pump_volume.mean() > 0.5:  # 15% price increase with high volume
                # Check for dump phase
                dump_window = price_changes.iloc[i+1:i+11]
                
                if dump_window.sum() < -0.1:  # 10% price decrease
                    signals.append({
                        'type': 'pump_dump',
                        'pump_start': data.index[i-5],
                        'pump_end': data.index[i],
                        'dump_end': data.index[i+10],
                        'pump_magnitude': pump_window.sum() * 100,
                        'dump_magnitude': dump_window.sum() * 100,
                        'volume_spike': pump_volume.mean() * 100,
                        'severity': 'high'
                    })
        
        return signals
    
    def _detect_wash_trading(self, data: pd.DataFrame) -> List[Dict]:
        """Detect potential wash trading patterns"""
        signals = []
        
        # Look for high volume with minimal price movement
        for i in range(20, len(data)):
            window_data = data.iloc[i-20:i]
            
            volume_mean = window_data['volume'].mean()
            volume_current = data['volume'].iloc[i]
            price_volatility = window_data['close'].std() / window_data['close'].mean()
            
            # High volume with low volatility
            if volume_current > 3 * volume_mean and price_volatility < 0.01:
                signals.append({
                    'type': 'wash_trading',
                    'timestamp': data.index[i],
                    'volume_ratio': volume_current / volume_mean,
                    'price_volatility': price_volatility,
                    'severity': 'medium'
                })
        
        return signals
    
    def _detect_spoofing(self, data: pd.DataFrame) -> List[Dict]:
        """Detect potential spoofing patterns (simplified)"""
        signals = []
        
        # Look for rapid volume spikes followed by immediate reversals
        volume_changes = data['volume'].pct_change()
        
        for i in range(2, len(data) - 2):
            if (volume_changes.iloc[i] > 2 and  # Large volume spike
                volume_changes.iloc[i+1] < -0.5 and  # Immediate volume drop
                abs(data['close'].pct_change().iloc[i]) < 0.01):  # Minimal price impact
                
                signals.append({
                    'type': 'spoofing',
                    'timestamp': data.index[i],
                    'volume_spike': volume_changes.iloc[i] * 100,
                    'volume_drop': volume_changes.iloc[i+1] * 100,
                    'price_impact': data['close'].pct_change().iloc[i] * 100,
                    'severity': 'medium'
                })
        
        return signals
    
    def _detect_coordinated_trading(self, data: pd.DataFrame) -> List[Dict]:
        """Detect coordinated trading patterns"""
        signals = []
        
        # Look for synchronized volume and price movements
        price_changes = data['close'].pct_change()
        volume_changes = data['volume'].pct_change()
        
        # Calculate correlation in rolling windows
        for i in range(20, len(data)):
            window_price = price_changes.iloc[i-20:i]
            window_volume = volume_changes.iloc[i-20:i]
            
            correlation = window_price.corr(window_volume)
            
            # High correlation might indicate coordination
            if abs(correlation) > 0.8:
                signals.append({
                    'type': 'coordinated_trading',
                    'timestamp': data.index[i],
                    'price_volume_correlation': correlation,
                    'severity': 'low' if abs(correlation) < 0.9 else 'medium'
                })
        
        return signals
    
    def _calculate_severity_scores(self, anomalies: List[Dict]) -> Dict:
        """Calculate severity scores for anomalies"""
        severity_counts = {'low': 0, 'medium': 0, 'high': 0}
        
        for anomaly in anomalies:
            severity = anomaly.get('severity', 'low')
            severity_counts[severity] += 1
        
        total_anomalies = len(anomalies)
        if total_anomalies == 0:
            return {'overall_score': 0, 'distribution': severity_counts}
        
        # Calculate weighted score
        weights = {'low': 1, 'medium': 3, 'high': 5}
        weighted_score = sum(severity_counts[sev] * weights[sev] for sev in severity_counts)
        overall_score = weighted_score / total_anomalies
        
        return {
            'overall_score': overall_score,
            'distribution': severity_counts,
            'total_anomalies': total_anomalies
        }
    
    def _categorize_anomalies(self, anomalies: List[Dict]) -> Dict:
        """Categorize anomalies by type"""
        categories = {}
        
        for anomaly in anomalies:
            anomaly_type = anomaly.get('type', 'unknown')
            if anomaly_type not in categories:
                categories[anomaly_type] = 0
            categories[anomaly_type] += 1
        
        return categories
