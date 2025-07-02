
"""
Crypto Risk Assessment Agent for XplainCrypto
Provides comprehensive risk analysis for cryptocurrency investments
"""

import pandas as pd
import numpy as np
from typing import Dict, List, Optional, Tuple
from datetime import datetime, timedelta
import logging
from scipy import stats
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA
import warnings
warnings.filterwarnings('ignore')

logger = logging.getLogger(__name__)

class RiskAssessmentAgent:
    """
    Advanced risk assessment for cryptocurrency portfolios and individual assets
    """
    
    def __init__(self, config: Dict):
        self.config = config
        self.risk_free_rate = 0.02  # 2% annual risk-free rate
        
        # Risk categories and thresholds
        self.volatility_thresholds = {
            'very_low': 0.2,
            'low': 0.4,
            'medium': 0.6,
            'high': 0.8,
            'very_high': 1.0
        }
        
        self.correlation_thresholds = {
            'very_low': 0.2,
            'low': 0.4,
            'medium': 0.6,
            'high': 0.8,
            'very_high': 1.0
        }
    
    def assess_portfolio_risk(self, portfolio: Dict, price_data: Dict) -> Dict:
        """
        Comprehensive portfolio risk assessment
        """
        try:
            risk_assessment = {
                'portfolio_id': portfolio.get('id', 'unknown'),
                'timestamp': datetime.now().isoformat(),
                'total_value_usd': 0,
                'risk_metrics': {},
                'asset_risks': {},
                'correlation_analysis': {},
                'var_analysis': {},
                'stress_test_results': {},
                'risk_score': 0.0,
                'risk_level': 'unknown',
                'recommendations': []
            }
            
            # Calculate portfolio value and weights
            portfolio_data = self._prepare_portfolio_data(portfolio, price_data)
            risk_assessment['total_value_usd'] = portfolio_data['total_value']
            
            # Individual asset risk analysis
            for asset in portfolio_data['assets']:
                asset_risk = self._assess_asset_risk(asset, price_data.get(asset['symbol'], {}))
                risk_assessment['asset_risks'][asset['symbol']] = asset_risk
            
            # Portfolio-level risk metrics
            risk_assessment['risk_metrics'] = self._calculate_portfolio_risk_metrics(portfolio_data, price_data)
            
            # Correlation analysis
            risk_assessment['correlation_analysis'] = self._analyze_portfolio_correlations(portfolio_data, price_data)
            
            # Value at Risk (VaR) analysis
            risk_assessment['var_analysis'] = self._calculate_var(portfolio_data, price_data)
            
            # Stress testing
            risk_assessment['stress_test_results'] = self._perform_stress_tests(portfolio_data, price_data)
            
            # Overall risk score and level
            risk_score = self._calculate_overall_risk_score(risk_assessment)
            risk_assessment['risk_score'] = risk_score
            risk_assessment['risk_level'] = self._categorize_risk_level(risk_score)
            
            # Generate recommendations
            risk_assessment['recommendations'] = self._generate_risk_recommendations(risk_assessment)
            
            return risk_assessment
            
        except Exception as e:
            logger.error(f"Error assessing portfolio risk: {str(e)}")
            return {'error': str(e)}
    
    def assess_asset_risk(self, symbol: str, price_data: Dict) -> Dict:
        """
        Detailed risk assessment for individual cryptocurrency
        """
        try:
            asset_risk = {
                'symbol': symbol,
                'timestamp': datetime.now().isoformat(),
                'price_metrics': {},
                'volatility_analysis': {},
                'liquidity_risk': {},
                'technical_risk': {},
                'fundamental_risk': {},
                'market_risk': {},
                'overall_risk_score': 0.0,
                'risk_level': 'unknown'
            }
            
            # Price-based metrics
            asset_risk['price_metrics'] = self._calculate_price_metrics(price_data)
            
            # Volatility analysis
            asset_risk['volatility_analysis'] = self._analyze_volatility(price_data)
            
            # Liquidity risk assessment
            asset_risk['liquidity_risk'] = self._assess_liquidity_risk(price_data)
            
            # Technical risk indicators
            asset_risk['technical_risk'] = self._assess_technical_risk(price_data)
            
            # Market risk factors
            asset_risk['market_risk'] = self._assess_market_risk(symbol, price_data)
            
            # Calculate overall risk score
            risk_score = self._calculate_asset_risk_score(asset_risk)
            asset_risk['overall_risk_score'] = risk_score
            asset_risk['risk_level'] = self._categorize_risk_level(risk_score)
            
            return asset_risk
            
        except Exception as e:
            logger.error(f"Error assessing asset risk for {symbol}: {str(e)}")
            return {'error': str(e)}
    
    def calculate_var(self, portfolio: Dict, price_data: Dict, confidence_levels: List[float] = [0.95, 0.99]) -> Dict:
        """
        Calculate Value at Risk (VaR) for portfolio
        """
        try:
            var_results = {
                'timestamp': datetime.now().isoformat(),
                'confidence_levels': confidence_levels,
                'var_estimates': {},
                'expected_shortfall': {},
                'methodology': 'historical_simulation'
            }
            
            # Prepare portfolio returns
            portfolio_returns = self._calculate_portfolio_returns(portfolio, price_data)
            
            if len(portfolio_returns) < 30:
                return {'error': 'Insufficient data for VaR calculation'}
            
            # Calculate VaR for each confidence level
            for confidence in confidence_levels:
                # Historical VaR
                var_percentile = (1 - confidence) * 100
                var_value = np.percentile(portfolio_returns, var_percentile)
                
                # Expected Shortfall (Conditional VaR)
                tail_returns = portfolio_returns[portfolio_returns <= var_value]
                expected_shortfall = np.mean(tail_returns) if len(tail_returns) > 0 else var_value
                
                var_results['var_estimates'][f'{confidence:.0%}'] = {
                    'var_absolute': var_value,
                    'var_percentage': var_value * 100,
                    'var_dollar': var_value * portfolio.get('total_value', 0)
                }
                
                var_results['expected_shortfall'][f'{confidence:.0%}'] = {
                    'es_absolute': expected_shortfall,
                    'es_percentage': expected_shortfall * 100,
                    'es_dollar': expected_shortfall * portfolio.get('total_value', 0)
                }
            
            # Parametric VaR (assuming normal distribution)
            returns_mean = np.mean(portfolio_returns)
            returns_std = np.std(portfolio_returns)
            
            var_results['parametric_var'] = {}
            for confidence in confidence_levels:
                z_score = stats.norm.ppf(1 - confidence)
                parametric_var = returns_mean + z_score * returns_std
                
                var_results['parametric_var'][f'{confidence:.0%}'] = {
                    'var_absolute': parametric_var,
                    'var_percentage': parametric_var * 100
                }
            
            return var_results
            
        except Exception as e:
            logger.error(f"Error calculating VaR: {str(e)}")
            return {'error': str(e)}
    
    def perform_stress_test(self, portfolio: Dict, price_data: Dict, scenarios: List[Dict] = None) -> Dict:
        """
        Perform stress testing on portfolio
        """
        try:
            if scenarios is None:
                scenarios = self._get_default_stress_scenarios()
            
            stress_results = {
                'timestamp': datetime.now().isoformat(),
                'scenarios': {},
                'worst_case_scenario': {},
                'portfolio_resilience_score': 0.0
            }
            
            portfolio_value = portfolio.get('total_value', 0)
            
            for scenario in scenarios:
                scenario_name = scenario['name']
                scenario_shocks = scenario['shocks']
                
                # Apply shocks to portfolio
                scenario_result = self._apply_stress_scenario(portfolio, scenario_shocks, price_data)
                
                stress_results['scenarios'][scenario_name] = {
                    'description': scenario.get('description', ''),
                    'portfolio_value_before': portfolio_value,
                    'portfolio_value_after': scenario_result['new_value'],
                    'absolute_loss': portfolio_value - scenario_result['new_value'],
                    'percentage_loss': ((portfolio_value - scenario_result['new_value']) / portfolio_value) * 100,
                    'asset_impacts': scenario_result['asset_impacts']
                }
            
            # Find worst case scenario
            worst_scenario = min(
                stress_results['scenarios'].items(),
                key=lambda x: x[1]['portfolio_value_after']
            )
            stress_results['worst_case_scenario'] = {
                'scenario_name': worst_scenario[0],
                'details': worst_scenario[1]
            }
            
            # Calculate portfolio resilience score
            avg_loss = np.mean([s['percentage_loss'] for s in stress_results['scenarios'].values()])
            resilience_score = max(0, 100 - avg_loss)  # Higher score = more resilient
            stress_results['portfolio_resilience_score'] = resilience_score
            
            return stress_results
            
        except Exception as e:
            logger.error(f"Error performing stress test: {str(e)}")
            return {'error': str(e)}
    
    def _prepare_portfolio_data(self, portfolio: Dict, price_data: Dict) -> Dict:
        """Prepare portfolio data for analysis"""
        assets = []
        total_value = 0
        
        for holding in portfolio.get('holdings', []):
            symbol = holding['symbol']
            quantity = holding['quantity']
            current_price = price_data.get(symbol, {}).get('current_price', 0)
            
            asset_value = quantity * current_price
            total_value += asset_value
            
            assets.append({
                'symbol': symbol,
                'quantity': quantity,
                'current_price': current_price,
                'value': asset_value,
                'weight': 0  # Will be calculated after total_value is known
            })
        
        # Calculate weights
        for asset in assets:
            asset['weight'] = asset['value'] / total_value if total_value > 0 else 0
        
        return {
            'assets': assets,
            'total_value': total_value,
            'asset_count': len(assets)
        }
    
    def _assess_asset_risk(self, asset: Dict, price_data: Dict) -> Dict:
        """Assess risk for individual asset"""
        return {
            'symbol': asset['symbol'],
            'weight': asset['weight'],
            'volatility': self._calculate_volatility(price_data),
            'max_drawdown': self._calculate_max_drawdown(price_data),
            'beta': self._calculate_beta(price_data),
            'sharpe_ratio': self._calculate_sharpe_ratio(price_data),
            'risk_contribution': asset['weight'] * self._calculate_volatility(price_data)
        }
    
    def _calculate_portfolio_risk_metrics(self, portfolio_data: Dict, price_data: Dict) -> Dict:
        """Calculate portfolio-level risk metrics"""
        try:
            # Portfolio returns
            portfolio_returns = self._calculate_portfolio_returns(portfolio_data, price_data)
            
            if len(portfolio_returns) == 0:
                return {'error': 'No return data available'}
            
            # Basic statistics
            returns_mean = np.mean(portfolio_returns)
            returns_std = np.std(portfolio_returns)
            returns_skew = stats.skew(portfolio_returns)
            returns_kurtosis = stats.kurtosis(portfolio_returns)
            
            # Risk metrics
            sharpe_ratio = (returns_mean - self.risk_free_rate/365) / returns_std if returns_std > 0 else 0
            sortino_ratio = self._calculate_sortino_ratio(portfolio_returns)
            max_drawdown = self._calculate_portfolio_max_drawdown(portfolio_returns)
            
            # Volatility metrics
            daily_volatility = returns_std
            annual_volatility = returns_std * np.sqrt(365)
            
            return {
                'daily_return_mean': returns_mean,
                'daily_volatility': daily_volatility,
                'annual_volatility': annual_volatility,
                'sharpe_ratio': sharpe_ratio,
                'sortino_ratio': sortino_ratio,
                'max_drawdown': max_drawdown,
                'skewness': returns_skew,
                'kurtosis': returns_kurtosis,
                'var_95': np.percentile(portfolio_returns, 5),
                'var_99': np.percentile(portfolio_returns, 1)
            }
            
        except Exception as e:
            logger.error(f"Error calculating portfolio risk metrics: {str(e)}")
            return {'error': str(e)}
    
    def _analyze_portfolio_correlations(self, portfolio_data: Dict, price_data: Dict) -> Dict:
        """Analyze correlations between portfolio assets"""
        try:
            symbols = [asset['symbol'] for asset in portfolio_data['assets']]
            
            if len(symbols) < 2:
                return {'message': 'Need at least 2 assets for correlation analysis'}
            
            # Prepare return data for all assets
            returns_data = {}
            min_length = float('inf')
            
            for symbol in symbols:
                returns = self._calculate_returns(price_data.get(symbol, {}))
                if len(returns) > 0:
                    returns_data[symbol] = returns
                    min_length = min(min_length, len(returns))
            
            if len(returns_data) < 2 or min_length < 10:
                return {'error': 'Insufficient data for correlation analysis'}
            
            # Align return series
            aligned_returns = {}
            for symbol, returns in returns_data.items():
                aligned_returns[symbol] = returns[-min_length:]
            
            # Calculate correlation matrix
            returns_df = pd.DataFrame(aligned_returns)
            correlation_matrix = returns_df.corr()
            
            # Calculate portfolio diversification metrics
            avg_correlation = correlation_matrix.values[np.triu_indices_from(correlation_matrix.values, k=1)].mean()
            max_correlation = correlation_matrix.values[np.triu_indices_from(correlation_matrix.values, k=1)].max()
            min_correlation = correlation_matrix.values[np.triu_indices_from(correlation_matrix.values, k=1)].min()
            
            # Diversification ratio
            weights = np.array([asset['weight'] for asset in portfolio_data['assets'] if asset['symbol'] in symbols])
            portfolio_volatility = self._calculate_portfolio_volatility(weights, correlation_matrix, returns_df)
            weighted_avg_volatility = sum(weights[i] * returns_df.iloc[:, i].std() for i in range(len(weights)))
            diversification_ratio = weighted_avg_volatility / portfolio_volatility if portfolio_volatility > 0 else 1
            
            return {
                'correlation_matrix': correlation_matrix.to_dict(),
                'average_correlation': avg_correlation,
                'max_correlation': max_correlation,
                'min_correlation': min_correlation,
                'diversification_ratio': diversification_ratio,
                'diversification_level': self._categorize_diversification(avg_correlation),
                'highly_correlated_pairs': self._find_highly_correlated_pairs(correlation_matrix)
            }
            
        except Exception as e:
            logger.error(f"Error analyzing correlations: {str(e)}")
            return {'error': str(e)}
    
    def _calculate_var(self, portfolio_data: Dict, price_data: Dict) -> Dict:
        """Calculate Value at Risk for portfolio"""
        return self.calculate_var(portfolio_data, price_data)
    
    def _perform_stress_tests(self, portfolio_data: Dict, price_data: Dict) -> Dict:
        """Perform stress tests on portfolio"""
        return self.perform_stress_test(portfolio_data, price_data)
    
    def _calculate_overall_risk_score(self, risk_assessment: Dict) -> float:
        """Calculate overall risk score (0-100, higher = riskier)"""
        try:
            scores = []
            weights = []
            
            # Volatility score (30% weight)
            volatility = risk_assessment.get('risk_metrics', {}).get('annual_volatility', 0)
            volatility_score = min(100, volatility * 100)  # Convert to percentage
            scores.append(volatility_score)
            weights.append(0.3)
            
            # VaR score (25% weight)
            var_95 = abs(risk_assessment.get('var_analysis', {}).get('var_estimates', {}).get('95%', {}).get('var_percentage', 0))
            var_score = min(100, var_95)
            scores.append(var_score)
            weights.append(0.25)
            
            # Correlation score (20% weight)
            avg_correlation = risk_assessment.get('correlation_analysis', {}).get('average_correlation', 0)
            correlation_score = abs(avg_correlation) * 100
            scores.append(correlation_score)
            weights.append(0.2)
            
            # Stress test score (25% weight)
            resilience_score = risk_assessment.get('stress_test_results', {}).get('portfolio_resilience_score', 50)
            stress_score = 100 - resilience_score  # Invert so higher = riskier
            scores.append(stress_score)
            weights.append(0.25)
            
            # Calculate weighted average
            if scores and weights:
                overall_score = np.average(scores, weights=weights)
                return min(100, max(0, overall_score))
            
            return 50.0  # Default medium risk
            
        except Exception as e:
            logger.error(f"Error calculating overall risk score: {str(e)}")
            return 50.0
    
    def _categorize_risk_level(self, risk_score: float) -> str:
        """Categorize risk level based on score"""
        if risk_score < 20:
            return 'very_low'
        elif risk_score < 40:
            return 'low'
        elif risk_score < 60:
            return 'medium'
        elif risk_score < 80:
            return 'high'
        else:
            return 'very_high'
    
    def _generate_risk_recommendations(self, risk_assessment: Dict) -> List[str]:
        """Generate risk management recommendations"""
        recommendations = []
        
        risk_level = risk_assessment.get('risk_level', 'medium')
        risk_score = risk_assessment.get('risk_score', 50)
        
        # High-level recommendations based on risk level
        if risk_level in ['high', 'very_high']:
            recommendations.append("Consider reducing position sizes to lower overall portfolio risk")
            recommendations.append("Implement stop-loss orders to limit downside exposure")
        
        # Volatility-based recommendations
        volatility = risk_assessment.get('risk_metrics', {}).get('annual_volatility', 0)
        if volatility > 1.0:  # >100% annual volatility
            recommendations.append("Portfolio exhibits very high volatility - consider diversification")
        
        # Correlation-based recommendations
        avg_correlation = risk_assessment.get('correlation_analysis', {}).get('average_correlation', 0)
        if avg_correlation > 0.7:
            recommendations.append("High correlation between assets - consider adding uncorrelated assets")
        
        # VaR-based recommendations
        var_95 = abs(risk_assessment.get('var_analysis', {}).get('var_estimates', {}).get('95%', {}).get('var_percentage', 0))
        if var_95 > 10:  # >10% daily VaR
            recommendations.append("High Value at Risk detected - consider hedging strategies")
        
        # Stress test recommendations
        resilience_score = risk_assessment.get('stress_test_results', {}).get('portfolio_resilience_score', 50)
        if resilience_score < 30:
            recommendations.append("Portfolio shows low resilience to stress scenarios")
        
        # Asset-specific recommendations
        asset_risks = risk_assessment.get('asset_risks', {})
        high_risk_assets = [symbol for symbol, risk in asset_risks.items() 
                           if risk.get('risk_level') in ['high', 'very_high']]
        
        if high_risk_assets:
            recommendations.append(f"High-risk assets detected: {', '.join(high_risk_assets)}")
        
        return recommendations if recommendations else ["Portfolio risk appears to be within acceptable levels"]
    
    def _calculate_returns(self, price_data: Dict) -> np.ndarray:
        """Calculate returns from price data"""
        prices = price_data.get('prices', [])
        if len(prices) < 2:
            return np.array([])
        
        prices_array = np.array([p['price'] for p in prices])
        returns = np.diff(prices_array) / prices_array[:-1]
        return returns
    
    def _calculate_volatility(self, price_data: Dict, window: int = 30) -> float:
        """Calculate volatility from price data"""
        returns = self._calculate_returns(price_data)
        if len(returns) < window:
            return 0.0
        
        return np.std(returns[-window:]) * np.sqrt(365)  # Annualized
    
    def _calculate_max_drawdown(self, price_data: Dict) -> float:
        """Calculate maximum drawdown"""
        prices = price_data.get('prices', [])
        if len(prices) < 2:
            return 0.0
        
        prices_array = np.array([p['price'] for p in prices])
        cumulative = np.cumprod(1 + np.diff(prices_array) / prices_array[:-1])
        running_max = np.maximum.accumulate(cumulative)
        drawdown = (cumulative - running_max) / running_max
        
        return abs(np.min(drawdown))
    
    def _calculate_beta(self, price_data: Dict, market_data: Dict = None) -> float:
        """Calculate beta relative to market (simplified)"""
        # Simplified beta calculation - would need market data in practice
        returns = self._calculate_returns(price_data)
        if len(returns) < 30:
            return 1.0  # Default beta
        
        # Use volatility as proxy for beta
        volatility = np.std(returns)
        market_volatility = 0.02  # Assumed market daily volatility
        
        return volatility / market_volatility
    
    def _calculate_sharpe_ratio(self, price_data: Dict) -> float:
        """Calculate Sharpe ratio"""
        returns = self._calculate_returns(price_data)
        if len(returns) == 0:
            return 0.0
        
        excess_returns = np.mean(returns) - self.risk_free_rate/365
        return excess_returns / np.std(returns) if np.std(returns) > 0 else 0.0
    
    def _calculate_sortino_ratio(self, returns: np.ndarray) -> float:
        """Calculate Sortino ratio"""
        if len(returns) == 0:
            return 0.0
        
        excess_returns = np.mean(returns) - self.risk_free_rate/365
        downside_returns = returns[returns < 0]
        downside_std = np.std(downside_returns) if len(downside_returns) > 0 else np.std(returns)
        
        return excess_returns / downside_std if downside_std > 0 else 0.0
    
    def _calculate_portfolio_returns(self, portfolio_data: Dict, price_data: Dict) -> np.ndarray:
        """Calculate portfolio returns"""
        # Simplified portfolio return calculation
        # In practice, would need aligned time series data
        
        portfolio_returns = []
        min_length = float('inf')
        
        # Get returns for each asset
        asset_returns = {}
        for asset in portfolio_data['assets']:
            symbol = asset['symbol']
            returns = self._calculate_returns(price_data.get(symbol, {}))
            if len(returns) > 0:
                asset_returns[symbol] = returns
                min_length = min(min_length, len(returns))
        
        if not asset_returns or min_length == 0:
            return np.array([])
        
        # Calculate weighted portfolio returns
        for i in range(min_length):
            portfolio_return = 0
            for asset in portfolio_data['assets']:
                symbol = asset['symbol']
                if symbol in asset_returns:
                    portfolio_return += asset['weight'] * asset_returns[symbol][-(min_length-i)]
            portfolio_returns.append(portfolio_return)
        
        return np.array(portfolio_returns)
    
    def _calculate_portfolio_max_drawdown(self, returns: np.ndarray) -> float:
        """Calculate portfolio maximum drawdown"""
        if len(returns) == 0:
            return 0.0
        
        cumulative = np.cumprod(1 + returns)
        running_max = np.maximum.accumulate(cumulative)
        drawdown = (cumulative - running_max) / running_max
        
        return abs(np.min(drawdown))
    
    def _calculate_portfolio_volatility(self, weights: np.ndarray, correlation_matrix: pd.DataFrame, returns_df: pd.DataFrame) -> float:
        """Calculate portfolio volatility"""
        try:
            # Calculate covariance matrix
            cov_matrix = returns_df.cov()
            
            # Portfolio variance
            portfolio_variance = np.dot(weights, np.dot(cov_matrix, weights))
            
            return np.sqrt(portfolio_variance)
        except:
            return 0.0
    
    def _categorize_diversification(self, avg_correlation: float) -> str:
        """Categorize diversification level"""
        if avg_correlation < 0.2:
            return 'excellent'
        elif avg_correlation < 0.4:
            return 'good'
        elif avg_correlation < 0.6:
            return 'moderate'
        elif avg_correlation < 0.8:
            return 'poor'
        else:
            return 'very_poor'
    
    def _find_highly_correlated_pairs(self, correlation_matrix: pd.DataFrame, threshold: float = 0.8) -> List[Dict]:
        """Find highly correlated asset pairs"""
        pairs = []
        
        for i in range(len(correlation_matrix.columns)):
            for j in range(i+1, len(correlation_matrix.columns)):
                correlation = correlation_matrix.iloc[i, j]
                if abs(correlation) >= threshold:
                    pairs.append({
                        'asset1': correlation_matrix.columns[i],
                        'asset2': correlation_matrix.columns[j],
                        'correlation': correlation
                    })
        
        return sorted(pairs, key=lambda x: abs(x['correlation']), reverse=True)
    
    def _get_default_stress_scenarios(self) -> List[Dict]:
        """Get default stress test scenarios"""
        return [
            {
                'name': 'market_crash',
                'description': 'Severe market crash scenario',
                'shocks': {'all': -0.5}  # 50% drop across all assets
            },
            {
                'name': 'crypto_winter',
                'description': 'Extended bear market',
                'shocks': {'all': -0.8}  # 80% drop across all assets
            },
            {
                'name': 'bitcoin_crash',
                'description': 'Bitcoin-specific crash',
                'shocks': {'BTC': -0.6, 'others': -0.3}  # 60% BTC drop, 30% others
            },
            {
                'name': 'defi_collapse',
                'description': 'DeFi sector collapse',
                'shocks': {'DeFi': -0.7, 'others': -0.2}  # 70% DeFi drop, 20% others
            },
            {
                'name': 'regulatory_crackdown',
                'description': 'Major regulatory restrictions',
                'shocks': {'all': -0.4}  # 40% drop across all assets
            }
        ]
    
    def _apply_stress_scenario(self, portfolio: Dict, shocks: Dict, price_data: Dict) -> Dict:
        """Apply stress scenario to portfolio"""
        new_value = 0
        asset_impacts = {}
        
        for holding in portfolio.get('holdings', []):
            symbol = holding['symbol']
            quantity = holding['quantity']
            current_price = price_data.get(symbol, {}).get('current_price', 0)
            
            # Determine shock to apply
            shock = 0
            if 'all' in shocks:
                shock = shocks['all']
            elif symbol in shocks:
                shock = shocks[symbol]
            elif 'others' in shocks:
                shock = shocks['others']
            
            # Apply shock
            new_price = current_price * (1 + shock)
            new_asset_value = quantity * new_price
            new_value += new_asset_value
            
            asset_impacts[symbol] = {
                'original_price': current_price,
                'new_price': new_price,
                'shock_applied': shock,
                'value_change': new_asset_value - (quantity * current_price)
            }
        
        return {
            'new_value': new_value,
            'asset_impacts': asset_impacts
        }
