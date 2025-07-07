
#!/usr/bin/env python3
"""
XplainCrypto Trading Scenarios Test Suite
Real-world trading scenario simulations and validations
"""

import asyncio
import json
import logging
import time
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
import mysql.connector
import pandas as pd
import numpy as np
from dataclasses import dataclass

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@dataclass
class TradingScenario:
    """Trading scenario configuration"""
    name: str
    description: str
    market_condition: str  # 'bull', 'bear', 'sideways', 'volatile'
    assets: List[str]
    timeframe: str  # '1h', '4h', '1d'
    strategy_type: str  # 'momentum', 'mean_reversion', 'sentiment_based'
    risk_level: str  # 'low', 'medium', 'high'
    expected_signals: int
    success_criteria: Dict[str, float]

class TradingScenarioTester:
    """Test trading scenarios and validate AI responses"""
    
    def __init__(self, db_connection):
        self.db_connection = db_connection
        self.test_results = []
        
    def execute_query(self, query: str, fetch: bool = True) -> Optional[Any]:
        """Execute SQL query and return results"""
        try:
            cursor = self.db_connection.cursor(dictionary=True)
            cursor.execute(query)
            
            if fetch:
                results = cursor.fetchall()
                cursor.close()
                return results
            else:
                self.db_connection.commit()
                cursor.close()
                return True
        except Exception as e:
            logger.error(f"Query execution failed: {str(e)}")
            return None
    
    async def run_all_trading_scenarios(self) -> Dict:
        """Run comprehensive trading scenario tests"""
        logger.info("Starting trading scenario tests")
        
        scenarios = [
            TradingScenario(
                name="bull_market_momentum",
                description="Bull market momentum trading with BTC/ETH",
                market_condition="bull",
                assets=["BTC", "ETH"],
                timeframe="4h",
                strategy_type="momentum",
                risk_level="medium",
                expected_signals=3,
                success_criteria={"accuracy": 0.7, "profit_factor": 1.5}
            ),
            TradingScenario(
                name="bear_market_protection",
                description="Bear market risk management and short opportunities",
                market_condition="bear",
                assets=["BTC", "ETH", "ADA"],
                timeframe="1d",
                strategy_type="mean_reversion",
                risk_level="low",
                expected_signals=2,
                success_criteria={"max_drawdown": 0.15, "risk_score": 0.3}
            ),
            TradingScenario(
                name="volatile_market_scalping",
                description="High volatility scalping with multiple altcoins",
                market_condition="volatile",
                assets=["BTC", "ETH", "BNB", "SOL", "DOGE"],
                timeframe="1h",
                strategy_type="sentiment_based",
                risk_level="high",
                expected_signals=8,
                success_criteria={"win_rate": 0.6, "avg_trade_duration": 2.0}
            ),
            TradingScenario(
                name="sideways_market_range",
                description="Range trading in sideways market conditions",
                market_condition="sideways",
                assets=["BTC", "ETH"],
                timeframe="4h",
                strategy_type="mean_reversion",
                risk_level="medium",
                expected_signals=4,
                success_criteria={"consistency": 0.8, "sharpe_ratio": 1.2}
            ),
            TradingScenario(
                name="defi_protocol_analysis",
                description="DeFi protocol trading based on TVL and volume analysis",
                market_condition="bull",
                assets=["UNI", "AAVE", "COMP", "SUSHI"],
                timeframe="1d",
                strategy_type="fundamental",
                risk_level="medium",
                expected_signals=3,
                success_criteria={"protocol_accuracy": 0.75, "tvl_correlation": 0.6}
            )
        ]
        
        scenario_results = []
        for scenario in scenarios:
            result = await self._test_trading_scenario(scenario)
            scenario_results.append(result)
        
        return self._compile_scenario_report(scenario_results)
    
    async def _test_trading_scenario(self, scenario: TradingScenario) -> Dict:
        """Test individual trading scenario"""
        logger.info(f"Testing scenario: {scenario.name}")
        
        start_time = time.time()
        scenario_result = {
            "scenario_name": scenario.name,
            "description": scenario.description,
            "market_condition": scenario.market_condition,
            "status": "running",
            "tests_passed": 0,
            "tests_failed": 0,
            "performance_metrics": {},
            "signals_generated": [],
            "risk_assessment": {},
            "recommendations": []
        }
        
        try:
            # Test 1: Market Data Analysis
            market_analysis = await self._test_market_data_analysis(scenario)
            if market_analysis["success"]:
                scenario_result["tests_passed"] += 1
                scenario_result["performance_metrics"]["market_analysis"] = market_analysis["metrics"]
            else:
                scenario_result["tests_failed"] += 1
            
            # Test 2: Signal Generation
            signal_generation = await self._test_signal_generation(scenario)
            if signal_generation["success"]:
                scenario_result["tests_passed"] += 1
                scenario_result["signals_generated"] = signal_generation["signals"]
                scenario_result["performance_metrics"]["signal_generation"] = signal_generation["metrics"]
            else:
                scenario_result["tests_failed"] += 1
            
            # Test 3: Risk Assessment
            risk_assessment = await self._test_risk_assessment(scenario)
            if risk_assessment["success"]:
                scenario_result["tests_passed"] += 1
                scenario_result["risk_assessment"] = risk_assessment["assessment"]
                scenario_result["performance_metrics"]["risk_assessment"] = risk_assessment["metrics"]
            else:
                scenario_result["tests_failed"] += 1
            
            # Test 4: Sentiment Analysis Integration
            sentiment_analysis = await self._test_sentiment_integration(scenario)
            if sentiment_analysis["success"]:
                scenario_result["tests_passed"] += 1
                scenario_result["performance_metrics"]["sentiment_analysis"] = sentiment_analysis["metrics"]
            else:
                scenario_result["tests_failed"] += 1
            
            # Test 5: Portfolio Optimization
            portfolio_optimization = await self._test_portfolio_optimization(scenario)
            if portfolio_optimization["success"]:
                scenario_result["tests_passed"] += 1
                scenario_result["recommendations"] = portfolio_optimization["recommendations"]
                scenario_result["performance_metrics"]["portfolio_optimization"] = portfolio_optimization["metrics"]
            else:
                scenario_result["tests_failed"] += 1
            
            # Calculate overall success
            total_tests = scenario_result["tests_passed"] + scenario_result["tests_failed"]
            success_rate = scenario_result["tests_passed"] / total_tests if total_tests > 0 else 0
            
            scenario_result["status"] = "completed"
            scenario_result["success_rate"] = success_rate
            scenario_result["duration"] = time.time() - start_time
            scenario_result["meets_criteria"] = self._evaluate_success_criteria(scenario, scenario_result)
            
        except Exception as e:
            scenario_result["status"] = "failed"
            scenario_result["error"] = str(e)
            logger.error(f"Scenario {scenario.name} failed: {str(e)}")
        
        return scenario_result
    
    async def _test_market_data_analysis(self, scenario: TradingScenario) -> Dict:
        """Test market data analysis for the scenario"""
        try:
            # Test real-time price data availability
            price_query = f"""
            SELECT 
                symbol,
                price,
                volume_24h,
                percent_change_24h,
                last_updated
            FROM crypto_data_db.real_time_prices 
            WHERE symbol IN ({','.join([f"'{asset}'" for asset in scenario.assets])})
            AND data_quality_score > 0.7
            ORDER BY last_updated DESC
            """
            
            price_data = self.execute_query(price_query)
            
            if not price_data:
                return {"success": False, "error": "No price data available"}
            
            # Test technical indicators
            technical_query = f"""
            SELECT 
                symbol,
                close_price,
                rsi,
                macd,
                sma_20,
                bollinger_upper,
                bollinger_lower,
                volume_sma_20
            FROM crypto_data_db.daily_technical_indicators 
            WHERE symbol IN ({','.join([f"'{asset}'" for asset in scenario.assets])})
            AND date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
            ORDER BY symbol, date DESC
            """
            
            technical_data = self.execute_query(technical_query)
            
            # Analyze data quality and completeness
            data_quality_score = len(price_data) / len(scenario.assets)
            technical_completeness = len(technical_data) / (len(scenario.assets) * 30)  # 30 days expected
            
            # Test market condition detection
            market_condition_query = f"""
            SELECT 
                AVG(percent_change_24h) as avg_change,
                STDDEV(percent_change_24h) as volatility,
                COUNT(*) as asset_count
            FROM crypto_data_db.real_time_prices 
            WHERE symbol IN ({','.join([f"'{asset}'" for asset in scenario.assets])})
            """
            
            market_condition = self.execute_query(market_condition_query)
            
            if market_condition:
                avg_change = market_condition[0]['avg_change'] or 0
                volatility = market_condition[0]['volatility'] or 0
                
                # Validate market condition matches scenario expectation
                detected_condition = self._detect_market_condition(avg_change, volatility)
                condition_match = detected_condition == scenario.market_condition
            else:
                condition_match = False
            
            success = (
                data_quality_score > 0.8 and 
                technical_completeness > 0.7 and 
                condition_match
            )
            
            return {
                "success": success,
                "metrics": {
                    "data_quality_score": data_quality_score,
                    "technical_completeness": technical_completeness,
                    "market_condition_match": condition_match,
                    "detected_condition": detected_condition if 'detected_condition' in locals() else None,
                    "assets_analyzed": len(price_data),
                    "technical_indicators_available": len(technical_data)
                }
            }
            
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    async def _test_signal_generation(self, scenario: TradingScenario) -> Dict:
        """Test trading signal generation"""
        try:
            signals = []
            
            for asset in scenario.assets:
                # Generate signals based on strategy type
                if scenario.strategy_type == "momentum":
                    signal_query = f"""
                    SELECT 
                        '{asset}' as asset,
                        CASE 
                            WHEN rsi > 70 AND macd > macd_signal THEN 'STRONG_BUY'
                            WHEN rsi > 50 AND macd > macd_signal THEN 'BUY'
                            WHEN rsi < 30 AND macd < macd_signal THEN 'STRONG_SELL'
                            WHEN rsi < 50 AND macd < macd_signal THEN 'SELL'
                            ELSE 'HOLD'
                        END as signal,
                        rsi,
                        macd,
                        macd_signal,
                        close_price
                    FROM crypto_data_db.daily_technical_indicators 
                    WHERE symbol = '{asset}'
                    ORDER BY date DESC 
                    LIMIT 1
                    """
                elif scenario.strategy_type == "mean_reversion":
                    signal_query = f"""
                    SELECT 
                        '{asset}' as asset,
                        CASE 
                            WHEN close_price < bollinger_lower THEN 'BUY'
                            WHEN close_price > bollinger_upper THEN 'SELL'
                            WHEN close_price < sma_20 * 0.95 THEN 'BUY'
                            WHEN close_price > sma_20 * 1.05 THEN 'SELL'
                            ELSE 'HOLD'
                        END as signal,
                        close_price,
                        sma_20,
                        bollinger_upper,
                        bollinger_lower
                    FROM crypto_data_db.daily_technical_indicators 
                    WHERE symbol = '{asset}'
                    ORDER BY date DESC 
                    LIMIT 1
                    """
                elif scenario.strategy_type == "sentiment_based":
                    signal_query = f"""
                    SELECT 
                        '{asset}' as asset,
                        CASE 
                            WHEN sentiment_score > 0.6 AND mention_count > 100 THEN 'BUY'
                            WHEN sentiment_score < -0.6 AND mention_count > 50 THEN 'SELL'
                            WHEN sentiment_score > 0.3 THEN 'WEAK_BUY'
                            WHEN sentiment_score < -0.3 THEN 'WEAK_SELL'
                            ELSE 'HOLD'
                        END as signal,
                        sentiment_score,
                        mention_count,
                        engagement_score
                    FROM crypto_data_db.social_sentiment 
                    WHERE asset_symbol = '{asset}'
                    AND last_updated >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
                    ORDER BY last_updated DESC 
                    LIMIT 1
                    """
                else:  # fundamental analysis for DeFi
                    signal_query = f"""
                    SELECT 
                        '{asset}' as asset,
                        CASE 
                            WHEN tvl_change_24h > 10 AND volume_24h > fees_24h * 100 THEN 'STRONG_BUY'
                            WHEN tvl_change_24h > 5 THEN 'BUY'
                            WHEN tvl_change_24h < -10 THEN 'SELL'
                            WHEN tvl_change_24h < -5 THEN 'WEAK_SELL'
                            ELSE 'HOLD'
                        END as signal,
                        tvl,
                        tvl_change_24h,
                        volume_24h,
                        fees_24h
                    FROM crypto_data_db.defi_real_time 
                    WHERE token_symbol = '{asset}' OR protocol_name LIKE '%{asset}%'
                    ORDER BY last_updated DESC 
                    LIMIT 1
                    """
                
                signal_result = self.execute_query(signal_query)
                if signal_result:
                    signals.extend(signal_result)
            
            # Filter out HOLD signals for active signal count
            active_signals = [s for s in signals if s['signal'] != 'HOLD']
            
            # Calculate signal quality metrics
            signal_strength_distribution = {}
            for signal in signals:
                signal_type = signal['signal']
                signal_strength_distribution[signal_type] = signal_strength_distribution.get(signal_type, 0) + 1
            
            # Validate signal count meets expectations
            signal_count_ok = len(active_signals) >= scenario.expected_signals * 0.7  # Allow 30% tolerance
            
            success = len(signals) > 0 and signal_count_ok
            
            return {
                "success": success,
                "signals": signals,
                "metrics": {
                    "total_signals": len(signals),
                    "active_signals": len(active_signals),
                    "signal_distribution": signal_strength_distribution,
                    "meets_expected_count": signal_count_ok,
                    "expected_signals": scenario.expected_signals
                }
            }
            
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    async def _test_risk_assessment(self, scenario: TradingScenario) -> Dict:
        """Test risk assessment functionality"""
        try:
            risk_assessments = []
            
            for asset in scenario.assets:
                # Get risk profile for asset
                risk_query = f"""
                SELECT 
                    symbol,
                    risk_score,
                    risk_level,
                    volatility_30d,
                    market_cap_rank,
                    technical_risk_score,
                    regulatory_risk_score
                FROM crypto_data_db.asset_risk_profiles 
                WHERE symbol = '{asset}'
                ORDER BY last_updated DESC 
                LIMIT 1
                """
                
                risk_data = self.execute_query(risk_query)
                if risk_data:
                    risk_assessments.extend(risk_data)
            
            if not risk_assessments:
                return {"success": False, "error": "No risk assessment data available"}
            
            # Calculate portfolio-level risk metrics
            avg_risk_score = sum(r['risk_score'] for r in risk_assessments) / len(risk_assessments)
            max_risk_score = max(r['risk_score'] for r in risk_assessments)
            
            # Risk level distribution
            risk_levels = [r['risk_level'] for r in risk_assessments]
            risk_level_counts = {level: risk_levels.count(level) for level in set(risk_levels)}
            
            # Validate risk level matches scenario expectation
            expected_risk_mapping = {
                "low": {"max_avg_risk": 40, "max_individual_risk": 60},
                "medium": {"max_avg_risk": 70, "max_individual_risk": 80},
                "high": {"max_avg_risk": 100, "max_individual_risk": 100}
            }
            
            risk_criteria = expected_risk_mapping[scenario.risk_level]
            risk_level_appropriate = (
                avg_risk_score <= risk_criteria["max_avg_risk"] and
                max_risk_score <= risk_criteria["max_individual_risk"]
            )
            
            # Calculate diversification score
            diversification_score = len(set(r['symbol'] for r in risk_assessments)) / len(scenario.assets)
            
            success = len(risk_assessments) > 0 and diversification_score > 0.8
            
            return {
                "success": success,
                "assessment": {
                    "avg_risk_score": avg_risk_score,
                    "max_risk_score": max_risk_score,
                    "risk_level_distribution": risk_level_counts,
                    "diversification_score": diversification_score,
                    "risk_level_appropriate": risk_level_appropriate
                },
                "metrics": {
                    "assets_assessed": len(risk_assessments),
                    "avg_risk_score": avg_risk_score,
                    "risk_level_match": risk_level_appropriate,
                    "diversification_score": diversification_score
                }
            }
            
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    async def _test_sentiment_integration(self, scenario: TradingScenario) -> Dict:
        """Test sentiment analysis integration"""
        try:
            sentiment_data = []
            
            for asset in scenario.assets:
                sentiment_query = f"""
                SELECT 
                    asset_symbol,
                    AVG(sentiment_score) as avg_sentiment,
                    COUNT(*) as mention_count,
                    AVG(engagement_score) as avg_engagement,
                    MAX(last_updated) as latest_update
                FROM crypto_data_db.social_sentiment 
                WHERE asset_symbol = '{asset}'
                AND last_updated >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
                GROUP BY asset_symbol
                """
                
                sentiment_result = self.execute_query(sentiment_query)
                if sentiment_result:
                    sentiment_data.extend(sentiment_result)
            
            if not sentiment_data:
                return {"success": False, "error": "No sentiment data available"}
            
            # Calculate sentiment metrics
            avg_sentiment = sum(s['avg_sentiment'] for s in sentiment_data) / len(sentiment_data)
            total_mentions = sum(s['mention_count'] for s in sentiment_data)
            avg_engagement = sum(s['avg_engagement'] for s in sentiment_data) / len(sentiment_data)
            
            # Sentiment distribution analysis
            sentiment_categories = []
            for s in sentiment_data:
                if s['avg_sentiment'] > 0.3:
                    sentiment_categories.append('positive')
                elif s['avg_sentiment'] < -0.3:
                    sentiment_categories.append('negative')
                else:
                    sentiment_categories.append('neutral')
            
            sentiment_distribution = {cat: sentiment_categories.count(cat) for cat in set(sentiment_categories)}
            
            # Data freshness check
            latest_updates = [s['latest_update'] for s in sentiment_data if s['latest_update']]
            data_freshness = all(
                (datetime.now() - update).total_seconds() < 3600  # Within 1 hour
                for update in latest_updates
            ) if latest_updates else False
            
            success = (
                len(sentiment_data) > 0 and 
                total_mentions > 50 and  # Minimum mention threshold
                data_freshness
            )
            
            return {
                "success": success,
                "metrics": {
                    "assets_with_sentiment": len(sentiment_data),
                    "avg_sentiment": avg_sentiment,
                    "total_mentions": total_mentions,
                    "avg_engagement": avg_engagement,
                    "sentiment_distribution": sentiment_distribution,
                    "data_freshness": data_freshness
                }
            }
            
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    async def _test_portfolio_optimization(self, scenario: TradingScenario) -> Dict:
        """Test portfolio optimization recommendations"""
        try:
            # Simulate portfolio optimization based on scenario
            optimization_query = f"""
            SELECT 
                symbol,
                price,
                market_cap,
                volume_24h,
                percent_change_24h
            FROM crypto_data_db.real_time_prices 
            WHERE symbol IN ({','.join([f"'{asset}'" for asset in scenario.assets])})
            ORDER BY market_cap DESC
            """
            
            portfolio_data = self.execute_query(optimization_query)
            
            if not portfolio_data:
                return {"success": False, "error": "No portfolio data available"}
            
            # Calculate optimal weights based on market cap and volatility
            total_market_cap = sum(p['market_cap'] for p in portfolio_data if p['market_cap'])
            
            recommendations = []
            for asset_data in portfolio_data:
                if asset_data['market_cap']:
                    # Market cap weighted allocation
                    base_weight = asset_data['market_cap'] / total_market_cap
                    
                    # Adjust for volatility and scenario risk level
                    volatility_factor = abs(asset_data['percent_change_24h']) / 100
                    
                    if scenario.risk_level == "low":
                        adjusted_weight = base_weight * (1 - volatility_factor * 0.5)
                    elif scenario.risk_level == "high":
                        adjusted_weight = base_weight * (1 + volatility_factor * 0.3)
                    else:
                        adjusted_weight = base_weight
                    
                    recommendations.append({
                        "asset": asset_data['symbol'],
                        "recommended_weight": min(max(adjusted_weight, 0.05), 0.4),  # 5% min, 40% max
                        "rationale": f"Market cap weighted with {scenario.risk_level} risk adjustment",
                        "current_price": asset_data['price'],
                        "market_cap": asset_data['market_cap']
                    })
            
            # Normalize weights to sum to 1
            total_weight = sum(r['recommended_weight'] for r in recommendations)
            for rec in recommendations:
                rec['recommended_weight'] = rec['recommended_weight'] / total_weight
            
            # Calculate diversification metrics
            max_weight = max(r['recommended_weight'] for r in recommendations)
            diversification_score = 1 - max_weight  # Higher score = better diversification
            
            success = len(recommendations) > 0 and diversification_score > 0.4
            
            return {
                "success": success,
                "recommendations": recommendations,
                "metrics": {
                    "assets_optimized": len(recommendations),
                    "diversification_score": diversification_score,
                    "max_single_weight": max_weight,
                    "total_market_cap": total_market_cap
                }
            }
            
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def _detect_market_condition(self, avg_change: float, volatility: float) -> str:
        """Detect market condition based on price changes and volatility"""
        if avg_change > 5 and volatility < 10:
            return "bull"
        elif avg_change < -5 and volatility < 10:
            return "bear"
        elif volatility > 15:
            return "volatile"
        else:
            return "sideways"
    
    def _evaluate_success_criteria(self, scenario: TradingScenario, result: Dict) -> bool:
        """Evaluate if scenario meets success criteria"""
        try:
            criteria = scenario.success_criteria
            metrics = result.get("performance_metrics", {})
            
            # Check each criterion
            for criterion, threshold in criteria.items():
                if criterion == "accuracy":
                    actual_accuracy = result.get("success_rate", 0)
                    if actual_accuracy < threshold:
                        return False
                elif criterion == "max_drawdown":
                    # Simulated based on risk assessment
                    max_risk = result.get("risk_assessment", {}).get("max_risk_score", 100)
                    estimated_drawdown = max_risk / 100 * 0.3  # Rough estimation
                    if estimated_drawdown > threshold:
                        return False
                elif criterion == "win_rate":
                    # Based on signal generation success
                    signal_metrics = metrics.get("signal_generation", {})
                    active_signals = signal_metrics.get("active_signals", 0)
                    total_signals = signal_metrics.get("total_signals", 1)
                    win_rate = active_signals / total_signals
                    if win_rate < threshold:
                        return False
            
            return True
            
        except Exception as e:
            logger.error(f"Error evaluating success criteria: {str(e)}")
            return False
    
    def _compile_scenario_report(self, scenario_results: List[Dict]) -> Dict:
        """Compile comprehensive scenario test report"""
        total_scenarios = len(scenario_results)
        successful_scenarios = sum(1 for r in scenario_results if r.get("status") == "completed" and r.get("success_rate", 0) > 0.7)
        
        # Calculate aggregate metrics
        avg_success_rate = sum(r.get("success_rate", 0) for r in scenario_results) / total_scenarios if total_scenarios > 0 else 0
        avg_duration = sum(r.get("duration", 0) for r in scenario_results) / total_scenarios if total_scenarios > 0 else 0
        
        # Identify best and worst performing scenarios
        best_scenario = max(scenario_results, key=lambda x: x.get("success_rate", 0)) if scenario_results else None
        worst_scenario = min(scenario_results, key=lambda x: x.get("success_rate", 0)) if scenario_results else None
        
        # Market condition performance analysis
        market_condition_performance = {}
        for result in scenario_results:
            condition = result.get("market_condition", "unknown")
            if condition not in market_condition_performance:
                market_condition_performance[condition] = {"count": 0, "avg_success": 0}
            market_condition_performance[condition]["count"] += 1
            market_condition_performance[condition]["avg_success"] += result.get("success_rate", 0)
        
        for condition in market_condition_performance:
            count = market_condition_performance[condition]["count"]
            market_condition_performance[condition]["avg_success"] /= count
        
        return {
            "summary": {
                "total_scenarios": total_scenarios,
                "successful_scenarios": successful_scenarios,
                "success_rate": successful_scenarios / total_scenarios if total_scenarios > 0 else 0,
                "avg_scenario_success_rate": avg_success_rate,
                "avg_duration": avg_duration
            },
            "scenario_results": scenario_results,
            "performance_analysis": {
                "best_scenario": best_scenario["scenario_name"] if best_scenario else None,
                "worst_scenario": worst_scenario["scenario_name"] if worst_scenario else None,
                "market_condition_performance": market_condition_performance
            },
            "recommendations": self._generate_trading_recommendations(scenario_results),
            "timestamp": datetime.now().isoformat()
        }
    
    def _generate_trading_recommendations(self, scenario_results: List[Dict]) -> List[str]:
        """Generate recommendations based on scenario test results"""
        recommendations = []
        
        # Analyze failure patterns
        failed_scenarios = [r for r in scenario_results if r.get("success_rate", 0) < 0.7]
        
        if failed_scenarios:
            recommendations.append(f"Review and improve {len(failed_scenarios)} underperforming trading scenarios")
        
        # Market condition specific recommendations
        market_performance = {}
        for result in scenario_results:
            condition = result.get("market_condition", "unknown")
            success_rate = result.get("success_rate", 0)
            if condition not in market_performance:
                market_performance[condition] = []
            market_performance[condition].append(success_rate)
        
        for condition, rates in market_performance.items():
            avg_rate = sum(rates) / len(rates)
            if avg_rate < 0.6:
                recommendations.append(f"Improve {condition} market condition strategies (current success: {avg_rate:.1%})")
        
        # Signal generation recommendations
        signal_issues = []
        for result in scenario_results:
            signal_metrics = result.get("performance_metrics", {}).get("signal_generation", {})
            if signal_metrics.get("active_signals", 0) < result.get("expected_signals", 0) * 0.7:
                signal_issues.append(result["scenario_name"])
        
        if signal_issues:
            recommendations.append(f"Enhance signal generation for scenarios: {', '.join(signal_issues)}")
        
        # Risk management recommendations
        high_risk_scenarios = [
            r for r in scenario_results 
            if r.get("risk_assessment", {}).get("max_risk_score", 0) > 80
        ]
        
        if high_risk_scenarios:
            recommendations.append("Implement additional risk controls for high-risk scenarios")
        
        if not recommendations:
            recommendations.append("All trading scenarios performing well - consider expanding test coverage")
        
        return recommendations

async def main():
    """Main function to run trading scenario tests"""
    print("🎯 Starting XplainCrypto Trading Scenarios Test Suite")
    print("=" * 60)
    
    # Database connection (would be passed from main test runner)
    try:
        db_connection = mysql.connector.connect(
            host='localhost',
            port=47334,
            user='mindsdb',
            password='',
            database='mindsdb'
        )
        
        tester = TradingScenarioTester(db_connection)
        results = await tester.run_all_trading_scenarios()
        
        print("\n📊 TRADING SCENARIOS RESULTS")
        print("=" * 60)
        
        summary = results['summary']
        print(f"Total Scenarios: {summary['total_scenarios']}")
        print(f"Successful Scenarios: {summary['successful_scenarios']}")
        print(f"Overall Success Rate: {summary['success_rate']:.1%}")
        print(f"Average Scenario Success: {summary['avg_scenario_success_rate']:.1%}")
        print(f"Average Duration: {summary['avg_duration']:.2f}s")
        
        print("\n🎯 SCENARIO BREAKDOWN:")
        for result in results['scenario_results']:
            status_icon = "✅" if result.get('success_rate', 0) > 0.7 else "❌"
            print(f"  {status_icon} {result['scenario_name']}: {result.get('success_rate', 0):.1%} success")
        
        print("\n💡 RECOMMENDATIONS:")
        for rec in results['recommendations']:
            print(f"  • {rec}")
        
        # Save detailed results
        with open('trading_scenarios_results.json', 'w') as f:
            json.dump(results, f, indent=2, default=str)
        
        print(f"\n📄 Detailed results saved to: trading_scenarios_results.json")
        
    except Exception as e:
        logger.error(f"Trading scenarios test failed: {str(e)}")
        return False
    finally:
        if 'db_connection' in locals():
            db_connection.close()
    
    return True

if __name__ == "__main__":
    asyncio.run(main())
