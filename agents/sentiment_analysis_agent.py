
"""
Crypto Sentiment Analysis Agent for XplainCrypto
Analyzes market sentiment from social media, news, and on-chain data
"""

import pandas as pd
import numpy as np
from typing import Dict, List, Optional, Tuple
from datetime import datetime, timedelta
import logging
import requests
import re
from textblob import TextBlob
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
import tweepy
import praw
from newsapi import NewsApiClient

logger = logging.getLogger(__name__)

class SentimentAnalysisAgent:
    """
    Advanced sentiment analysis for cryptocurrency markets
    """
    
    def __init__(self, config: Dict):
        self.config = config
        self.vader_analyzer = SentimentIntensityAnalyzer()
        
        # Initialize API clients
        self._init_twitter_client()
        self._init_reddit_client()
        self._init_news_client()
        
        # Sentiment thresholds
        self.sentiment_thresholds = {
            'very_positive': 0.6,
            'positive': 0.2,
            'neutral': -0.2,
            'negative': -0.6,
            'very_negative': -1.0
        }
        
        # Crypto-specific keywords
        self.crypto_keywords = {
            'bullish': ['moon', 'bullish', 'pump', 'hodl', 'diamond hands', 'to the moon', 'buy the dip'],
            'bearish': ['dump', 'crash', 'bearish', 'sell', 'panic', 'rekt', 'paper hands'],
            'neutral': ['stable', 'sideways', 'consolidation', 'range', 'support', 'resistance']
        }
    
    def _init_twitter_client(self):
        """Initialize Twitter API client"""
        try:
            if all(key in self.config for key in ['twitter_api_key', 'twitter_api_secret', 'twitter_access_token', 'twitter_access_token_secret']):
                auth = tweepy.OAuthHandler(
                    self.config['twitter_api_key'],
                    self.config['twitter_api_secret']
                )
                auth.set_access_token(
                    self.config['twitter_access_token'],
                    self.config['twitter_access_token_secret']
                )
                self.twitter_client = tweepy.API(auth, wait_on_rate_limit=True)
                logger.info("Twitter client initialized successfully")
            else:
                self.twitter_client = None
                logger.warning("Twitter API credentials not provided")
        except Exception as e:
            logger.error(f"Error initializing Twitter client: {str(e)}")
            self.twitter_client = None
    
    def _init_reddit_client(self):
        """Initialize Reddit API client"""
        try:
            if all(key in self.config for key in ['reddit_client_id', 'reddit_client_secret']):
                self.reddit_client = praw.Reddit(
                    client_id=self.config['reddit_client_id'],
                    client_secret=self.config['reddit_client_secret'],
                    user_agent='XplainCrypto Sentiment Analyzer 1.0'
                )
                logger.info("Reddit client initialized successfully")
            else:
                self.reddit_client = None
                logger.warning("Reddit API credentials not provided")
        except Exception as e:
            logger.error(f"Error initializing Reddit client: {str(e)}")
            self.reddit_client = None
    
    def _init_news_client(self):
        """Initialize News API client"""
        try:
            if 'news_api_key' in self.config:
                self.news_client = NewsApiClient(api_key=self.config['news_api_key'])
                logger.info("News API client initialized successfully")
            else:
                self.news_client = None
                logger.warning("News API key not provided")
        except Exception as e:
            logger.error(f"Error initializing News client: {str(e)}")
            self.news_client = None
    
    def analyze_twitter_sentiment(self, symbol: str, count: int = 100) -> Dict:
        """Analyze Twitter sentiment for a cryptocurrency"""
        try:
            if not self.twitter_client:
                return {'error': 'Twitter client not available'}
            
            # Search for tweets
            query = f"${symbol} OR {symbol} -filter:retweets"
            tweets = tweepy.Cursor(
                self.twitter_client.search_tweets,
                q=query,
                lang='en',
                result_type='recent'
            ).items(count)
            
            sentiments = []
            tweet_data = []
            
            for tweet in tweets:
                # Clean tweet text
                text = self._clean_text(tweet.text)
                
                # Analyze sentiment
                sentiment_scores = self._analyze_text_sentiment(text)
                sentiments.append(sentiment_scores)
                
                tweet_data.append({
                    'id': tweet.id,
                    'text': text,
                    'created_at': tweet.created_at,
                    'user': tweet.user.screen_name,
                    'followers': tweet.user.followers_count,
                    'retweets': tweet.retweet_count,
                    'likes': tweet.favorite_count,
                    'sentiment': sentiment_scores
                })
            
            # Calculate aggregate sentiment
            if sentiments:
                avg_sentiment = {
                    'compound': np.mean([s['compound'] for s in sentiments]),
                    'positive': np.mean([s['positive'] for s in sentiments]),
                    'negative': np.mean([s['negative'] for s in sentiments]),
                    'neutral': np.mean([s['neutral'] for s in sentiments])
                }
                
                sentiment_distribution = self._categorize_sentiments(sentiments)
                
                return {
                    'platform': 'twitter',
                    'symbol': symbol,
                    'timestamp': datetime.now().isoformat(),
                    'tweet_count': len(tweet_data),
                    'average_sentiment': avg_sentiment,
                    'sentiment_distribution': sentiment_distribution,
                    'tweets': tweet_data[:10],  # Return top 10 tweets
                    'sentiment_trend': self._calculate_sentiment_trend(sentiments),
                    'influencer_sentiment': self._analyze_influencer_sentiment(tweet_data)
                }
            else:
                return {
                    'platform': 'twitter',
                    'symbol': symbol,
                    'error': 'No tweets found'
                }
                
        except Exception as e:
            logger.error(f"Error analyzing Twitter sentiment: {str(e)}")
            return {'error': str(e)}
    
    def analyze_reddit_sentiment(self, symbol: str, subreddits: List[str] = None) -> Dict:
        """Analyze Reddit sentiment for a cryptocurrency"""
        try:
            if not self.reddit_client:
                return {'error': 'Reddit client not available'}
            
            if subreddits is None:
                subreddits = ['cryptocurrency', 'CryptoMarkets', 'Bitcoin', 'ethereum', 'altcoin']
            
            all_posts = []
            sentiments = []
            
            for subreddit_name in subreddits:
                try:
                    subreddit = self.reddit_client.subreddit(subreddit_name)
                    
                    # Search for posts mentioning the symbol
                    for post in subreddit.search(symbol, limit=20):
                        # Analyze post title and content
                        text = f"{post.title} {post.selftext}"
                        text = self._clean_text(text)
                        
                        if len(text) > 10:  # Skip very short posts
                            sentiment_scores = self._analyze_text_sentiment(text)
                            sentiments.append(sentiment_scores)
                            
                            all_posts.append({
                                'id': post.id,
                                'title': post.title,
                                'text': post.selftext[:200],  # First 200 chars
                                'subreddit': subreddit_name,
                                'score': post.score,
                                'upvote_ratio': post.upvote_ratio,
                                'num_comments': post.num_comments,
                                'created_at': datetime.fromtimestamp(post.created_utc),
                                'sentiment': sentiment_scores
                            })
                except Exception as e:
                    logger.warning(f"Error processing subreddit {subreddit_name}: {str(e)}")
                    continue
            
            # Calculate aggregate sentiment
            if sentiments:
                avg_sentiment = {
                    'compound': np.mean([s['compound'] for s in sentiments]),
                    'positive': np.mean([s['positive'] for s in sentiments]),
                    'negative': np.mean([s['negative'] for s in sentiments]),
                    'neutral': np.mean([s['neutral'] for s in sentiments])
                }
                
                sentiment_distribution = self._categorize_sentiments(sentiments)
                
                return {
                    'platform': 'reddit',
                    'symbol': symbol,
                    'timestamp': datetime.now().isoformat(),
                    'post_count': len(all_posts),
                    'subreddits_analyzed': subreddits,
                    'average_sentiment': avg_sentiment,
                    'sentiment_distribution': sentiment_distribution,
                    'top_posts': sorted(all_posts, key=lambda x: x['score'], reverse=True)[:10],
                    'sentiment_by_subreddit': self._analyze_sentiment_by_subreddit(all_posts)
                }
            else:
                return {
                    'platform': 'reddit',
                    'symbol': symbol,
                    'error': 'No relevant posts found'
                }
                
        except Exception as e:
            logger.error(f"Error analyzing Reddit sentiment: {str(e)}")
            return {'error': str(e)}
    
    def analyze_news_sentiment(self, symbol: str, days: int = 7) -> Dict:
        """Analyze news sentiment for a cryptocurrency"""
        try:
            if not self.news_client:
                return {'error': 'News API client not available'}
            
            # Calculate date range
            to_date = datetime.now()
            from_date = to_date - timedelta(days=days)
            
            # Search for news articles
            articles = self.news_client.get_everything(
                q=f"{symbol} cryptocurrency OR {symbol} crypto",
                from_param=from_date.strftime('%Y-%m-%d'),
                to=to_date.strftime('%Y-%m-%d'),
                language='en',
                sort_by='relevancy',
                page_size=100
            )
            
            sentiments = []
            article_data = []
            
            for article in articles['articles']:
                # Analyze article title and description
                text = f"{article['title']} {article['description'] or ''}"
                text = self._clean_text(text)
                
                if len(text) > 10:
                    sentiment_scores = self._analyze_text_sentiment(text)
                    sentiments.append(sentiment_scores)
                    
                    article_data.append({
                        'title': article['title'],
                        'description': article['description'],
                        'source': article['source']['name'],
                        'url': article['url'],
                        'published_at': article['publishedAt'],
                        'sentiment': sentiment_scores
                    })
            
            # Calculate aggregate sentiment
            if sentiments:
                avg_sentiment = {
                    'compound': np.mean([s['compound'] for s in sentiments]),
                    'positive': np.mean([s['positive'] for s in sentiments]),
                    'negative': np.mean([s['negative'] for s in sentiments]),
                    'neutral': np.mean([s['neutral'] for s in sentiments])
                }
                
                sentiment_distribution = self._categorize_sentiments(sentiments)
                
                return {
                    'platform': 'news',
                    'symbol': symbol,
                    'timestamp': datetime.now().isoformat(),
                    'article_count': len(article_data),
                    'date_range': f"{from_date.strftime('%Y-%m-%d')} to {to_date.strftime('%Y-%m-%d')}",
                    'average_sentiment': avg_sentiment,
                    'sentiment_distribution': sentiment_distribution,
                    'top_articles': sorted(article_data, key=lambda x: abs(x['sentiment']['compound']), reverse=True)[:10],
                    'sentiment_by_source': self._analyze_sentiment_by_source(article_data),
                    'daily_sentiment_trend': self._calculate_daily_sentiment_trend(article_data)
                }
            else:
                return {
                    'platform': 'news',
                    'symbol': symbol,
                    'error': 'No relevant articles found'
                }
                
        except Exception as e:
            logger.error(f"Error analyzing news sentiment: {str(e)}")
            return {'error': str(e)}
    
    def get_fear_greed_index(self) -> Dict:
        """Get Fear & Greed Index from Alternative.me"""
        try:
            response = requests.get('https://api.alternative.me/fng/', timeout=10)
            if response.status_code == 200:
                data = response.json()
                current_data = data['data'][0]
                
                return {
                    'value': int(current_data['value']),
                    'value_classification': current_data['value_classification'],
                    'timestamp': current_data['timestamp'],
                    'time_until_update': current_data.get('time_until_update'),
                    'historical_data': data['data'][:30]  # Last 30 days
                }
            else:
                return {'error': f'API request failed with status {response.status_code}'}
                
        except Exception as e:
            logger.error(f"Error fetching Fear & Greed Index: {str(e)}")
            return {'error': str(e)}
    
    def _analyze_text_sentiment(self, text: str) -> Dict:
        """Analyze sentiment of text using multiple methods"""
        # VADER sentiment analysis
        vader_scores = self.vader_analyzer.polarity_scores(text)
        
        # TextBlob sentiment analysis
        blob = TextBlob(text)
        textblob_polarity = blob.sentiment.polarity
        textblob_subjectivity = blob.sentiment.subjectivity
        
        # Crypto-specific keyword analysis
        crypto_sentiment = self._analyze_crypto_keywords(text)
        
        # Combine scores (weighted average)
        combined_compound = (
            vader_scores['compound'] * 0.5 +
            textblob_polarity * 0.3 +
            crypto_sentiment * 0.2
        )
        
        return {
            'compound': combined_compound,
            'positive': vader_scores['pos'],
            'negative': vader_scores['neg'],
            'neutral': vader_scores['neu'],
            'textblob_polarity': textblob_polarity,
            'textblob_subjectivity': textblob_subjectivity,
            'crypto_sentiment': crypto_sentiment
        }
    
    def _analyze_crypto_keywords(self, text: str) -> float:
        """Analyze crypto-specific keywords for sentiment"""
        text_lower = text.lower()
        
        bullish_count = sum(1 for keyword in self.crypto_keywords['bullish'] if keyword in text_lower)
        bearish_count = sum(1 for keyword in self.crypto_keywords['bearish'] if keyword in text_lower)
        neutral_count = sum(1 for keyword in self.crypto_keywords['neutral'] if keyword in text_lower)
        
        total_keywords = bullish_count + bearish_count + neutral_count
        
        if total_keywords == 0:
            return 0.0
        
        # Calculate weighted sentiment
        sentiment_score = (bullish_count - bearish_count) / total_keywords
        return max(-1.0, min(1.0, sentiment_score))
    
    def _clean_text(self, text: str) -> str:
        """Clean and preprocess text"""
        if not text:
            return ""
        
        # Remove URLs
        text = re.sub(r'http\S+|www\S+|https\S+', '', text, flags=re.MULTILINE)
        
        # Remove user mentions and hashtags (but keep the text)
        text = re.sub(r'@\w+|#', '', text)
        
        # Remove extra whitespace
        text = ' '.join(text.split())
        
        return text.strip()
    
    def _categorize_sentiments(self, sentiments: List[Dict]) -> Dict:
        """Categorize sentiments into buckets"""
        categories = {
            'very_positive': 0,
            'positive': 0,
            'neutral': 0,
            'negative': 0,
            'very_negative': 0
        }
        
        for sentiment in sentiments:
            compound = sentiment['compound']
            
            if compound >= self.sentiment_thresholds['very_positive']:
                categories['very_positive'] += 1
            elif compound >= self.sentiment_thresholds['positive']:
                categories['positive'] += 1
            elif compound >= self.sentiment_thresholds['neutral']:
                categories['neutral'] += 1
            elif compound >= self.sentiment_thresholds['negative']:
                categories['negative'] += 1
            else:
                categories['very_negative'] += 1
        
        # Convert to percentages
        total = len(sentiments)
        if total > 0:
            categories = {k: (v / total) * 100 for k, v in categories.items()}
        
        return categories
    
    def _calculate_sentiment_trend(self, sentiments: List[Dict]) -> str:
        """Calculate sentiment trend over time"""
        if len(sentiments) < 10:
            return 'insufficient_data'
        
        # Split into first and second half
        mid_point = len(sentiments) // 2
        first_half = sentiments[:mid_point]
        second_half = sentiments[mid_point:]
        
        first_avg = np.mean([s['compound'] for s in first_half])
        second_avg = np.mean([s['compound'] for s in second_half])
        
        difference = second_avg - first_avg
        
        if difference > 0.1:
            return 'improving'
        elif difference < -0.1:
            return 'declining'
        else:
            return 'stable'
    
    def _analyze_influencer_sentiment(self, tweet_data: List[Dict]) -> Dict:
        """Analyze sentiment from high-influence accounts"""
        # Define influencer threshold (accounts with >10k followers)
        influencer_threshold = 10000
        
        influencer_tweets = [
            tweet for tweet in tweet_data 
            if tweet['followers'] >= influencer_threshold
        ]
        
        if not influencer_tweets:
            return {'count': 0, 'average_sentiment': None}
        
        avg_sentiment = np.mean([tweet['sentiment']['compound'] for tweet in influencer_tweets])
        
        return {
            'count': len(influencer_tweets),
            'average_sentiment': avg_sentiment,
            'top_influencers': sorted(
                influencer_tweets, 
                key=lambda x: x['followers'], 
                reverse=True
            )[:5]
        }
    
    def _analyze_sentiment_by_subreddit(self, posts: List[Dict]) -> Dict:
        """Analyze sentiment breakdown by subreddit"""
        subreddit_sentiments = {}
        
        for post in posts:
            subreddit = post['subreddit']
            if subreddit not in subreddit_sentiments:
                subreddit_sentiments[subreddit] = []
            subreddit_sentiments[subreddit].append(post['sentiment']['compound'])
        
        # Calculate average sentiment per subreddit
        result = {}
        for subreddit, sentiments in subreddit_sentiments.items():
            result[subreddit] = {
                'average_sentiment': np.mean(sentiments),
                'post_count': len(sentiments),
                'sentiment_std': np.std(sentiments)
            }
        
        return result
    
    def _analyze_sentiment_by_source(self, articles: List[Dict]) -> Dict:
        """Analyze sentiment breakdown by news source"""
        source_sentiments = {}
        
        for article in articles:
            source = article['source']
            if source not in source_sentiments:
                source_sentiments[source] = []
            source_sentiments[source].append(article['sentiment']['compound'])
        
        # Calculate average sentiment per source
        result = {}
        for source, sentiments in source_sentiments.items():
            result[source] = {
                'average_sentiment': np.mean(sentiments),
                'article_count': len(sentiments),
                'sentiment_std': np.std(sentiments)
            }
        
        return result
    
    def _calculate_daily_sentiment_trend(self, articles: List[Dict]) -> Dict:
        """Calculate daily sentiment trend from articles"""
        daily_sentiments = {}
        
        for article in articles:
            # Parse date from published_at
            date_str = article['published_at'][:10]  # YYYY-MM-DD
            
            if date_str not in daily_sentiments:
                daily_sentiments[date_str] = []
            daily_sentiments[date_str].append(article['sentiment']['compound'])
        
        # Calculate daily averages
        daily_averages = {}
        for date, sentiments in daily_sentiments.items():
            daily_averages[date] = {
                'average_sentiment': np.mean(sentiments),
                'article_count': len(sentiments)
            }
        
        return daily_averages
    
    def get_comprehensive_sentiment(self, symbol: str) -> Dict:
        """Get comprehensive sentiment analysis from all sources"""
        try:
            results = {
                'symbol': symbol,
                'timestamp': datetime.now().isoformat(),
                'sources': {},
                'overall_sentiment': {},
                'sentiment_score': 0.0,
                'confidence': 0.0
            }
            
            # Analyze Twitter sentiment
            twitter_result = self.analyze_twitter_sentiment(symbol)
            if 'error' not in twitter_result:
                results['sources']['twitter'] = twitter_result
            
            # Analyze Reddit sentiment
            reddit_result = self.analyze_reddit_sentiment(symbol)
            if 'error' not in reddit_result:
                results['sources']['reddit'] = reddit_result
            
            # Analyze news sentiment
            news_result = self.analyze_news_sentiment(symbol)
            if 'error' not in news_result:
                results['sources']['news'] = news_result
            
            # Get Fear & Greed Index
            fg_index = self.get_fear_greed_index()
            if 'error' not in fg_index:
                results['sources']['fear_greed_index'] = fg_index
            
            # Calculate overall sentiment
            if results['sources']:
                results['overall_sentiment'] = self._calculate_overall_sentiment(results['sources'])
                results['sentiment_score'] = results['overall_sentiment'].get('weighted_average', 0.0)
                results['confidence'] = results['overall_sentiment'].get('confidence', 0.0)
            
            return results
            
        except Exception as e:
            logger.error(f"Error getting comprehensive sentiment: {str(e)}")
            return {'error': str(e)}
    
    def _calculate_overall_sentiment(self, sources: Dict) -> Dict:
        """Calculate overall sentiment from multiple sources"""
        sentiments = []
        weights = []
        
        # Weight different sources
        source_weights = {
            'twitter': 0.3,
            'reddit': 0.25,
            'news': 0.35,
            'fear_greed_index': 0.1
        }
        
        for source_name, source_data in sources.items():
            if source_name == 'fear_greed_index':
                # Convert Fear & Greed Index to sentiment scale
                fg_value = source_data.get('value', 50)
                sentiment = (fg_value - 50) / 50  # Convert 0-100 to -1 to 1
                sentiments.append(sentiment)
                weights.append(source_weights[source_name])
            else:
                avg_sentiment = source_data.get('average_sentiment', {}).get('compound', 0)
                sentiments.append(avg_sentiment)
                weights.append(source_weights[source_name])
        
        if not sentiments:
            return {'weighted_average': 0.0, 'confidence': 0.0}
        
        # Calculate weighted average
        weighted_avg = np.average(sentiments, weights=weights)
        
        # Calculate confidence based on agreement between sources
        sentiment_std = np.std(sentiments)
        confidence = max(0.0, 1.0 - sentiment_std)  # Higher std = lower confidence
        
        return {
            'weighted_average': weighted_avg,
            'confidence': confidence,
            'source_sentiments': dict(zip(sources.keys(), sentiments)),
            'source_weights': source_weights
        }
