
"""
Crypto Price Prediction Agent for XplainCrypto
Implements advanced ML models for cryptocurrency price forecasting
"""

import pandas as pd
import numpy as np
from typing import Dict, List, Optional, Tuple
from datetime import datetime, timedelta
import logging
from sklearn.ensemble import RandomForestRegressor, GradientBoostingRegressor
from sklearn.preprocessing import StandardScaler, MinMaxScaler
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
import xgboost as xgb
import lightgbm as lgb
from prophet import Prophet
import ta

logger = logging.getLogger(__name__)

class CryptoPredictionAgent:
    """
    Advanced cryptocurrency price prediction agent using multiple ML models
    """
    
    def __init__(self, config: Dict):
        self.config = config
        self.models = {}
        self.scalers = {}
        self.feature_columns = []
        self.target_column = 'close'
        
        # Model configurations
        self.model_configs = {
            'xgboost': {
                'n_estimators': 1000,
                'max_depth': 6,
                'learning_rate': 0.01,
                'subsample': 0.8,
                'colsample_bytree': 0.8,
                'random_state': 42
            },
            'lightgbm': {
                'n_estimators': 1000,
                'max_depth': 6,
                'learning_rate': 0.01,
                'subsample': 0.8,
                'colsample_bytree': 0.8,
                'random_state': 42,
                'verbose': -1
            },
            'random_forest': {
                'n_estimators': 500,
                'max_depth': 10,
                'random_state': 42,
                'n_jobs': -1
            },
            'gradient_boosting': {
                'n_estimators': 500,
                'max_depth': 6,
                'learning_rate': 0.01,
                'random_state': 42
            }
        }
    
    def prepare_features(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Prepare technical indicators and features for prediction
        """
        try:
            # Ensure we have OHLCV data
            required_columns = ['open', 'high', 'low', 'close', 'volume']
            if not all(col in df.columns for col in required_columns):
                raise ValueError(f"Missing required columns: {required_columns}")
            
            # Create a copy to avoid modifying original data
            data = df.copy()
            
            # Basic price features
            data['price_change'] = data['close'].pct_change()
            data['price_change_abs'] = data['price_change'].abs()
            data['high_low_ratio'] = data['high'] / data['low']
            data['open_close_ratio'] = data['open'] / data['close']
            
            # Moving averages
            for period in [7, 14, 21, 50, 100, 200]:
                data[f'sma_{period}'] = ta.trend.sma_indicator(data['close'], window=period)
                data[f'ema_{period}'] = ta.trend.ema_indicator(data['close'], window=period)
            
            # Technical indicators
            # RSI
            data['rsi'] = ta.momentum.rsi(data['close'], window=14)
            
            # MACD
            macd = ta.trend.MACD(data['close'])
            data['macd'] = macd.macd()
            data['macd_signal'] = macd.macd_signal()
            data['macd_histogram'] = macd.macd_diff()
            
            # Bollinger Bands
            bb = ta.volatility.BollingerBands(data['close'])
            data['bb_upper'] = bb.bollinger_hband()
            data['bb_lower'] = bb.bollinger_lband()
            data['bb_middle'] = bb.bollinger_mavg()
            data['bb_width'] = (data['bb_upper'] - data['bb_lower']) / data['bb_middle']
            data['bb_position'] = (data['close'] - data['bb_lower']) / (data['bb_upper'] - data['bb_lower'])
            
            # Stochastic Oscillator
            stoch = ta.momentum.StochasticOscillator(data['high'], data['low'], data['close'])
            data['stoch_k'] = stoch.stoch()
            data['stoch_d'] = stoch.stoch_signal()
            
            # Volume indicators
            data['volume_sma'] = ta.volume.volume_sma(data['close'], data['volume'], window=20)
            data['volume_ratio'] = data['volume'] / data['volume_sma']
            
            # Volatility
            data['volatility'] = data['close'].rolling(window=20).std()
            data['volatility_ratio'] = data['volatility'] / data['volatility'].rolling(window=50).mean()
            
            # Price momentum
            for period in [1, 3, 7, 14, 30]:
                data[f'momentum_{period}'] = data['close'] / data['close'].shift(period) - 1
            
            # Support and resistance levels
            data['support'] = data['low'].rolling(window=20).min()
            data['resistance'] = data['high'].rolling(window=20).max()
            data['support_distance'] = (data['close'] - data['support']) / data['close']
            data['resistance_distance'] = (data['resistance'] - data['close']) / data['close']
            
            # Time-based features
            if 'timestamp' in data.columns:
                data['timestamp'] = pd.to_datetime(data['timestamp'])
                data['hour'] = data['timestamp'].dt.hour
                data['day_of_week'] = data['timestamp'].dt.dayofweek
                data['day_of_month'] = data['timestamp'].dt.day
                data['month'] = data['timestamp'].dt.month
                data['quarter'] = data['timestamp'].dt.quarter
            
            # Lag features
            for lag in [1, 2, 3, 5, 7]:
                data[f'close_lag_{lag}'] = data['close'].shift(lag)
                data[f'volume_lag_{lag}'] = data['volume'].shift(lag)
                data[f'rsi_lag_{lag}'] = data['rsi'].shift(lag)
            
            # Rolling statistics
            for window in [7, 14, 30]:
                data[f'close_mean_{window}'] = data['close'].rolling(window=window).mean()
                data[f'close_std_{window}'] = data['close'].rolling(window=window).std()
                data[f'close_min_{window}'] = data['close'].rolling(window=window).min()
                data[f'close_max_{window}'] = data['close'].rolling(window=window).max()
                data[f'volume_mean_{window}'] = data['volume'].rolling(window=window).mean()
            
            # Drop rows with NaN values
            data = data.dropna()
            
            # Store feature columns (excluding target and non-feature columns)
            exclude_columns = ['open', 'high', 'low', 'close', 'volume', 'timestamp']
            self.feature_columns = [col for col in data.columns if col not in exclude_columns]
            
            logger.info(f"Prepared {len(self.feature_columns)} features for prediction")
            return data
            
        except Exception as e:
            logger.error(f"Error preparing features: {str(e)}")
            raise
    
    def train_models(self, data: pd.DataFrame, target_horizon: int = 1) -> Dict:
        """
        Train multiple ML models for price prediction
        """
        try:
            # Prepare target variable (future price)
            data[f'target_{target_horizon}'] = data['close'].shift(-target_horizon)
            data = data.dropna()
            
            # Split features and target
            X = data[self.feature_columns]
            y = data[f'target_{target_horizon}']
            
            # Split into train/validation sets
            split_idx = int(len(data) * 0.8)
            X_train, X_val = X[:split_idx], X[split_idx:]
            y_train, y_val = y[:split_idx], y[split_idx:]
            
            # Scale features
            scaler = StandardScaler()
            X_train_scaled = scaler.fit_transform(X_train)
            X_val_scaled = scaler.transform(X_val)
            
            self.scalers[target_horizon] = scaler
            
            # Train models
            models = {}
            metrics = {}
            
            # XGBoost
            xgb_model = xgb.XGBRegressor(**self.model_configs['xgboost'])
            xgb_model.fit(X_train_scaled, y_train)
            xgb_pred = xgb_model.predict(X_val_scaled)
            
            models['xgboost'] = xgb_model
            metrics['xgboost'] = self._calculate_metrics(y_val, xgb_pred)
            
            # LightGBM
            lgb_model = lgb.LGBMRegressor(**self.model_configs['lightgbm'])
            lgb_model.fit(X_train_scaled, y_train)
            lgb_pred = lgb_model.predict(X_val_scaled)
            
            models['lightgbm'] = lgb_model
            metrics['lightgbm'] = self._calculate_metrics(y_val, lgb_pred)
            
            # Random Forest
            rf_model = RandomForestRegressor(**self.model_configs['random_forest'])
            rf_model.fit(X_train_scaled, y_train)
            rf_pred = rf_model.predict(X_val_scaled)
            
            models['random_forest'] = rf_model
            metrics['random_forest'] = self._calculate_metrics(y_val, rf_pred)
            
            # Gradient Boosting
            gb_model = GradientBoostingRegressor(**self.model_configs['gradient_boosting'])
            gb_model.fit(X_train_scaled, y_train)
            gb_pred = gb_model.predict(X_val_scaled)
            
            models['gradient_boosting'] = gb_model
            metrics['gradient_boosting'] = self._calculate_metrics(y_val, gb_pred)
            
            # Store models
            self.models[target_horizon] = models
            
            # Create ensemble prediction
            ensemble_pred = (xgb_pred + lgb_pred + rf_pred + gb_pred) / 4
            metrics['ensemble'] = self._calculate_metrics(y_val, ensemble_pred)
            
            logger.info(f"Trained models for {target_horizon}-step prediction")
            logger.info(f"Best model: {min(metrics.keys(), key=lambda k: metrics[k]['mae'])}")
            
            return {
                'models': models,
                'metrics': metrics,
                'feature_importance': self._get_feature_importance(models, X_train.columns)
            }
            
        except Exception as e:
            logger.error(f"Error training models: {str(e)}")
            raise
    
    def predict(self, data: pd.DataFrame, target_horizon: int = 1, model_type: str = 'ensemble') -> Dict:
        """
        Make price predictions using trained models
        """
        try:
            if target_horizon not in self.models:
                raise ValueError(f"No trained model for horizon {target_horizon}")
            
            # Prepare features
            features = data[self.feature_columns].iloc[-1:].values
            features_scaled = self.scalers[target_horizon].transform(features)
            
            models = self.models[target_horizon]
            predictions = {}
            
            # Get predictions from all models
            for name, model in models.items():
                pred = model.predict(features_scaled)[0]
                predictions[name] = pred
            
            # Calculate ensemble prediction
            ensemble_pred = np.mean(list(predictions.values()))
            predictions['ensemble'] = ensemble_pred
            
            # Calculate prediction intervals (simple approach)
            pred_std = np.std(list(predictions.values()))
            confidence_interval = {
                'lower_95': ensemble_pred - 1.96 * pred_std,
                'upper_95': ensemble_pred + 1.96 * pred_std,
                'lower_80': ensemble_pred - 1.28 * pred_std,
                'upper_80': ensemble_pred + 1.28 * pred_std
            }
            
            current_price = data['close'].iloc[-1]
            price_change = (ensemble_pred - current_price) / current_price * 100
            
            result = {
                'current_price': current_price,
                'predicted_price': ensemble_pred if model_type == 'ensemble' else predictions[model_type],
                'price_change_percent': price_change,
                'confidence_interval': confidence_interval,
                'all_predictions': predictions,
                'prediction_horizon': target_horizon,
                'timestamp': datetime.now().isoformat()
            }
            
            logger.info(f"Generated prediction for {target_horizon}-step horizon: {ensemble_pred:.4f}")
            return result
            
        except Exception as e:
            logger.error(f"Error making prediction: {str(e)}")
            raise
    
    def _calculate_metrics(self, y_true: np.ndarray, y_pred: np.ndarray) -> Dict:
        """Calculate prediction metrics"""
        return {
            'mae': mean_absolute_error(y_true, y_pred),
            'mse': mean_squared_error(y_true, y_pred),
            'rmse': np.sqrt(mean_squared_error(y_true, y_pred)),
            'r2': r2_score(y_true, y_pred),
            'mape': np.mean(np.abs((y_true - y_pred) / y_true)) * 100
        }
    
    def _get_feature_importance(self, models: Dict, feature_names: List[str]) -> Dict:
        """Get feature importance from models"""
        importance_dict = {}
        
        for name, model in models.items():
            if hasattr(model, 'feature_importances_'):
                importance = model.feature_importances_
                importance_dict[name] = dict(zip(feature_names, importance))
        
        return importance_dict
    
    def train_prophet_model(self, data: pd.DataFrame, symbol: str) -> Dict:
        """
        Train Facebook Prophet model for time series forecasting
        """
        try:
            # Prepare data for Prophet
            prophet_data = data[['timestamp', 'close']].copy()
            prophet_data.columns = ['ds', 'y']
            prophet_data['ds'] = pd.to_datetime(prophet_data['ds'])
            
            # Initialize and fit Prophet model
            model = Prophet(
                daily_seasonality=True,
                weekly_seasonality=True,
                yearly_seasonality=True,
                changepoint_prior_scale=0.05,
                seasonality_prior_scale=10.0
            )
            
            # Add custom regressors if available
            if 'volume' in data.columns:
                prophet_data['volume'] = data['volume'].values
                model.add_regressor('volume')
            
            model.fit(prophet_data)
            
            # Make future predictions
            future = model.make_future_dataframe(periods=30, freq='H')
            if 'volume' in prophet_data.columns:
                # Use last known volume for future predictions
                future['volume'] = prophet_data['volume'].iloc[-1]
            
            forecast = model.predict(future)
            
            # Store model
            self.models[f'prophet_{symbol}'] = model
            
            return {
                'model': model,
                'forecast': forecast,
                'components': model.predict(future)[['ds', 'yhat', 'yhat_lower', 'yhat_upper', 'trend', 'seasonal']]
            }
            
        except Exception as e:
            logger.error(f"Error training Prophet model: {str(e)}")
            raise
    
    def get_prediction_summary(self, symbol: str, timeframes: List[int] = [1, 6, 24, 168]) -> Dict:
        """
        Get comprehensive prediction summary for multiple timeframes
        """
        try:
            summary = {
                'symbol': symbol,
                'timestamp': datetime.now().isoformat(),
                'predictions': {},
                'confidence_scores': {},
                'trend_analysis': {}
            }
            
            for horizon in timeframes:
                if horizon in self.models:
                    # Get prediction for this timeframe
                    pred_result = self.predict(data, horizon)
                    summary['predictions'][f'{horizon}h'] = pred_result
                    
                    # Calculate confidence score based on model agreement
                    predictions = list(pred_result['all_predictions'].values())
                    confidence = 1 - (np.std(predictions) / np.mean(predictions))
                    summary['confidence_scores'][f'{horizon}h'] = confidence
            
            return summary
            
        except Exception as e:
            logger.error(f"Error generating prediction summary: {str(e)}")
            raise
