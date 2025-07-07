
-- XplainCrypto Educational Content Knowledge Base
-- This KB manages comprehensive crypto education materials, courses, and learning resources

-- Create embedding model for educational content
CREATE MODEL educational_content_embedding
PREDICT embedding
USING
    engine = 'openai_engine',
    model_name = 'text-embedding-3-large',
    input_columns = ['content'];

-- Create vector database for educational content storage
CREATE DATABASE educational_vectordb
WITH ENGINE = 'chromadb',
PARAMETERS = {
    "persist_directory": "/var/lib/mindsdb/educational_vectors"
};

-- Create the Educational Content Knowledge Base
CREATE KNOWLEDGE BASE educational_content_kb
USING
    model = educational_content_embedding,
    storage = educational_vectordb.education_materials,
    content_columns = ['content', 'explanation', 'examples'],
    metadata_columns = ['topic', 'difficulty_level', 'content_type', 'learning_objectives', 'prerequisites', 'estimated_time'],
    id_column = 'content_id',
    description = 'Comprehensive crypto education materials including courses, tutorials, explanations, and interactive content';

-- Populate with foundational crypto concepts
INSERT INTO educational_content_kb (
    content_id,
    content,
    explanation,
    examples,
    topic,
    difficulty_level,
    content_type,
    learning_objectives,
    prerequisites,
    estimated_time
) VALUES 
-- Beginner Level Content
('crypto_basics_001', 
 'What is Cryptocurrency? Cryptocurrency is a digital or virtual currency that uses cryptography for security. Unlike traditional currencies issued by governments (fiat currencies), cryptocurrencies operate on decentralized networks based on blockchain technology.',
 'Cryptocurrencies are revolutionary because they eliminate the need for central authorities like banks or governments to validate transactions. Instead, they use a distributed network of computers to maintain a secure and transparent ledger of all transactions.',
 'Bitcoin (BTC) was the first cryptocurrency, created in 2009. Ethereum (ETH) introduced smart contracts. Stablecoins like USDC maintain stable value by being pegged to traditional currencies.',
 'cryptocurrency_fundamentals',
 'beginner',
 'concept_explanation',
 'Understand what cryptocurrency is and how it differs from traditional money',
 'none',
 '10 minutes'),

('blockchain_basics_001',
 'Understanding Blockchain Technology: A blockchain is a distributed ledger that maintains a continuously growing list of records (blocks) that are linked and secured using cryptography. Each block contains a cryptographic hash of the previous block, a timestamp, and transaction data.',
 'Think of blockchain as a digital ledger book that is copied across thousands of computers worldwide. When someone wants to add a new page (block) to the book, the majority of computers must agree that the information is valid. Once added, the page cannot be changed or removed.',
 'Bitcoin blockchain records all Bitcoin transactions. Ethereum blockchain can store smart contracts. Supply chain blockchains track products from manufacture to delivery.',
 'blockchain_technology',
 'beginner',
 'concept_explanation',
 'Understand how blockchain technology works and its key properties',
 'basic_computer_literacy',
 '15 minutes'),

('wallet_security_001',
 'Cryptocurrency Wallet Security: A cryptocurrency wallet is a digital tool that allows you to store, send, and receive cryptocurrencies. Wallets come in different types: hot wallets (connected to the internet) and cold wallets (offline storage). Security is paramount as lost private keys mean lost funds forever.',
 'Your wallet contains two key components: a public key (like your bank account number that others can see) and a private key (like your PIN that must be kept secret). The private key is what gives you control over your funds. If someone else gets your private key, they can steal your cryptocurrency.',
 'MetaMask is a popular hot wallet for Ethereum. Ledger Nano S is a cold wallet hardware device. Paper wallets involve printing your keys on paper for offline storage.',
 'wallet_security',
 'beginner',
 'practical_guide',
 'Learn how to securely store and manage cryptocurrency',
 'cryptocurrency_fundamentals',
 '20 minutes'),

-- Intermediate Level Content
('defi_introduction_001',
 'Introduction to Decentralized Finance (DeFi): DeFi refers to a blockchain-based form of finance that does not rely on central financial intermediaries such as brokerages, exchanges, or banks. Instead, it utilizes smart contracts on blockchains, primarily Ethereum, to provide financial services.',
 'DeFi recreates traditional financial systems (lending, borrowing, trading, insurance) using blockchain technology. Smart contracts automatically execute agreements when conditions are met, removing the need for human intermediaries. This can reduce costs and increase accessibility to financial services.',
 'Uniswap allows decentralized token trading. Compound enables lending and borrowing without banks. Aave provides flash loans that must be repaid in the same transaction.',
 'decentralized_finance',
 'intermediate',
 'concept_explanation',
 'Understand DeFi principles and major protocols',
 'blockchain_technology,smart_contracts',
 '25 minutes'),

('smart_contracts_001',
 'Smart Contracts Explained: Smart contracts are self-executing contracts with the terms of the agreement directly written into code. They automatically execute when predetermined conditions are met, without requiring human intervention or third-party enforcement.',
 'Smart contracts are like vending machines for the digital world. You put in the required input (like cryptocurrency), and if you meet the conditions (like having enough funds), the contract automatically gives you the output (like tokens or services). The code is law - it cannot be changed once deployed.',
 'A simple smart contract might automatically send payment to a freelancer when they submit work. A complex contract might manage an entire decentralized exchange with thousands of users.',
 'smart_contracts',
 'intermediate',
 'technical_explanation',
 'Understand how smart contracts work and their applications',
 'blockchain_technology,programming_basics',
 '30 minutes'),

('trading_strategies_001',
 'Cryptocurrency Trading Strategies: Trading cryptocurrencies involves buying and selling digital assets to profit from price movements. Key strategies include HODLing (long-term holding), day trading (short-term trades), swing trading (medium-term), and dollar-cost averaging (regular purchases regardless of price).',
 'Successful crypto trading requires understanding market analysis (technical and fundamental), risk management, and emotional control. Technical analysis uses charts and indicators to predict price movements. Fundamental analysis evaluates the underlying value and potential of a cryptocurrency project.',
 'HODLing Bitcoin since 2017 would have been profitable despite volatility. Day trading requires constant monitoring and quick decisions. Dollar-cost averaging into Ethereum over time reduces the impact of price volatility.',
 'trading_strategies',
 'intermediate',
 'strategy_guide',
 'Learn different approaches to cryptocurrency trading',
 'cryptocurrency_fundamentals,market_analysis',
 '35 minutes'),

-- Advanced Level Content
('yield_farming_001',
 'Yield Farming and Liquidity Mining: Yield farming involves lending or staking cryptocurrency to earn rewards, typically in the form of additional cryptocurrency tokens. Liquidity mining is a subset where users provide liquidity to decentralized exchanges and earn tokens as rewards.',
 'Yield farming leverages DeFi protocols to maximize returns on cryptocurrency holdings. Users can earn yields through various mechanisms: providing liquidity to automated market makers, lending on money markets, or staking in governance protocols. Risks include smart contract bugs, impermanent loss, and token price volatility.',
 'Providing ETH/USDC liquidity on Uniswap earns trading fees plus UNI tokens. Lending DAI on Compound earns interest plus COMP tokens. Staking in Curve Finance earns CRV tokens plus trading fees.',
 'yield_farming',
 'advanced',
 'strategy_guide',
 'Master advanced DeFi yield generation strategies',
 'decentralized_finance,smart_contracts,risk_management',
 '45 minutes'),

('nft_technology_001',
 'Non-Fungible Tokens (NFTs) Deep Dive: NFTs are unique digital assets that represent ownership of specific items or content on the blockchain. Unlike cryptocurrencies which are fungible (interchangeable), each NFT has distinct properties that make it non-interchangeable.',
 'NFTs use blockchain technology to prove ownership and authenticity of digital items. They can represent art, music, videos, virtual real estate, or any unique digital asset. Smart contracts govern NFT behavior, including royalties for creators on secondary sales.',
 'CryptoPunks were among the first NFT collections. Bored Ape Yacht Club created a community around NFT ownership. NBA Top Shot digitized basketball highlights as collectible NFTs.',
 'nft_technology',
 'advanced',
 'technical_explanation',
 'Understand NFT technology and market dynamics',
 'blockchain_technology,smart_contracts,digital_ownership',
 '40 minutes'),

('dao_governance_001',
 'Decentralized Autonomous Organizations (DAOs): DAOs are organizations governed by smart contracts and community voting rather than traditional management structures. Members typically hold governance tokens that give them voting rights on proposals affecting the organization.',
 'DAOs represent a new form of organizational structure enabled by blockchain technology. They can manage treasuries, make investment decisions, fund projects, and govern protocols through decentralized voting mechanisms. Governance tokens often have economic value and can be traded.',
 'MakerDAO governs the DAI stablecoin protocol. Uniswap DAO manages the Uniswap protocol development. Investment DAOs like PleasrDAO collectively purchase high-value NFTs.',
 'dao_governance',
 'advanced',
 'organizational_structure',
 'Understand DAO mechanics and governance participation',
 'decentralized_finance,governance_tokens,community_management',
 '50 minutes');

-- Add practical tutorials and guides
INSERT INTO educational_content_kb (
    content_id,
    content,
    explanation,
    examples,
    topic,
    difficulty_level,
    content_type,
    learning_objectives,
    prerequisites,
    estimated_time
) VALUES 
('tutorial_metamask_001',
 'How to Set Up MetaMask Wallet: Step-by-step guide to installing and configuring MetaMask, the most popular Ethereum wallet browser extension. This tutorial covers installation, account creation, seed phrase backup, and basic security practices.',
 'MetaMask serves as your gateway to the Ethereum ecosystem and DeFi applications. Proper setup and security practices are essential for protecting your funds. The seed phrase is your master key - anyone with access to it can control your wallet.',
 'Install from official website only. Write down seed phrase on paper, never store digitally. Test with small amounts first. Enable hardware wallet integration for large amounts.',
 'wallet_setup',
 'beginner',
 'tutorial',
 'Successfully set up and secure a MetaMask wallet',
 'basic_computer_skills',
 '15 minutes'),

('tutorial_uniswap_001',
 'Trading on Uniswap: Complete guide to using Uniswap, the leading decentralized exchange. Learn how to connect your wallet, swap tokens, provide liquidity, and understand slippage and gas fees.',
 'Uniswap uses automated market makers (AMM) instead of order books. Prices are determined by mathematical formulas based on token ratios in liquidity pools. Understanding slippage and gas fees is crucial for successful trading.',
 'Swapping ETH for USDC with 0.5% slippage tolerance. Providing ETH/DAI liquidity to earn 0.3% trading fees. Checking gas prices before transactions to optimize costs.',
 'decentralized_trading',
 'intermediate',
 'tutorial',
 'Execute trades and provide liquidity on Uniswap',
 'wallet_setup,ethereum_basics',
 '25 minutes'),

('tutorial_compound_001',
 'Lending and Borrowing on Compound: Learn how to earn interest by lending cryptocurrency and how to borrow against your crypto holdings using the Compound protocol.',
 'Compound is a money market protocol where interest rates are determined algorithmically based on supply and demand. Lenders earn interest while borrowers pay interest. Collateralization ratios must be maintained to avoid liquidation.',
 'Lending USDC to earn 3% APY. Borrowing DAI against ETH collateral. Monitoring collateralization ratio to avoid liquidation. Claiming COMP governance tokens.',
 'defi_lending',
 'intermediate',
 'tutorial',
 'Use Compound for lending and borrowing',
 'decentralized_finance,wallet_setup',
 '30 minutes');

-- Create learning path recommendations view
CREATE VIEW learning_path_recommendations AS
SELECT 
    difficulty_level,
    topic,
    COUNT(*) as content_count,
    AVG(CAST(SUBSTRING_INDEX(estimated_time, ' ', 1) AS UNSIGNED)) as avg_time_minutes,
    GROUP_CONCAT(DISTINCT content_type) as available_formats,
    GROUP_CONCAT(DISTINCT prerequisites) as common_prerequisites
FROM educational_content_kb
GROUP BY difficulty_level, topic
ORDER BY 
    CASE difficulty_level 
        WHEN 'beginner' THEN 1 
        WHEN 'intermediate' THEN 2 
        WHEN 'advanced' THEN 3 
    END,
    avg_time_minutes;

-- Create content difficulty progression view
CREATE VIEW content_difficulty_progression AS
SELECT 
    topic,
    difficulty_level,
    content_id,
    LEFT(content, 100) as content_preview,
    learning_objectives,
    estimated_time,
    CASE 
        WHEN prerequisites = 'none' THEN 'Entry Point'
        ELSE CONCAT('Requires: ', prerequisites)
    END as entry_requirements
FROM educational_content_kb
ORDER BY 
    topic,
    CASE difficulty_level 
        WHEN 'beginner' THEN 1 
        WHEN 'intermediate' THEN 2 
        WHEN 'advanced' THEN 3 
    END;

-- Test queries for educational content
-- Query 1: Get beginner-friendly content
SELECT content_id, LEFT(content, 200) as preview, learning_objectives, estimated_time
FROM educational_content_kb
WHERE difficulty_level = 'beginner'
AND prerequisites IN ('none', 'basic_computer_literacy')
ORDER BY estimated_time;

-- Query 2: Find content about DeFi
SELECT content_id, explanation, examples, difficulty_level
FROM educational_content_kb
WHERE topic LIKE '%defi%' OR content LIKE '%DeFi%'
ORDER BY difficulty_level;

-- Query 3: Get practical tutorials
SELECT content_id, content, learning_objectives, estimated_time
FROM educational_content_kb
WHERE content_type = 'tutorial'
ORDER BY difficulty_level, estimated_time;

-- Create indexes for performance optimization
CREATE INDEX idx_educational_topic ON educational_content_kb(topic);
CREATE INDEX idx_educational_difficulty ON educational_content_kb(difficulty_level);
CREATE INDEX idx_educational_type ON educational_content_kb(content_type);
CREATE INDEX idx_educational_prerequisites ON educational_content_kb(prerequisites);

-- Success validation query
SELECT 
    'Educational Content KB' as component,
    COUNT(*) as total_content,
    COUNT(DISTINCT topic) as unique_topics,
    COUNT(DISTINCT difficulty_level) as difficulty_levels,
    COUNT(DISTINCT content_type) as content_types,
    SUM(CAST(SUBSTRING_INDEX(estimated_time, ' ', 1) AS UNSIGNED)) as total_learning_minutes
FROM educational_content_kb;
