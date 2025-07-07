
-- XplainCrypto Education Knowledge Base Skill
-- Reusable AI skill for retrieving educational content and learning resources

-- Create the education knowledge base skill
CREATE SKILL education_kb_skill
USING
    type = 'knowledge_base',
    source = 'educational_content_kb',
    description = 'Comprehensive crypto education materials including beginner concepts, advanced strategies, tutorials, and interactive learning content. Provides personalized learning recommendations based on user level and interests.';

-- Create educational content query templates
CREATE TABLE crypto_data_db.education_query_templates (
    template_id VARCHAR(50) PRIMARY KEY,
    template_name VARCHAR(200),
    description TEXT,
    query_pattern TEXT,
    content_filters JSON,
    example_questions TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO crypto_data_db.education_query_templates VALUES
('beginner_concepts',
 'Basic cryptocurrency concepts',
 'Explain fundamental cryptocurrency and blockchain concepts for beginners',
 'Explain {concept} in simple terms for someone new to cryptocurrency.',
 '{"difficulty_filter": "difficulty_level = \"beginner\"", "type_filter": "content_type IN (\"concept_explanation\", \"tutorial\")", "prerequisites": "prerequisites IN (\"none\", \"basic_computer_literacy\")"}',
 'What is Bitcoin? How does blockchain work? What is a cryptocurrency wallet?',
 NOW()),

('intermediate_topics',
 'Intermediate cryptocurrency topics',
 'Provide detailed explanations of intermediate crypto topics and strategies',
 'Explain {topic} and how it works in the cryptocurrency ecosystem.',
 '{"difficulty_filter": "difficulty_level = \"intermediate\"", "type_filter": "content_type IN (\"concept_explanation\", \"strategy_guide\", \"technical_explanation\")", "prerequisites": "prerequisites LIKE \"%blockchain%\" OR prerequisites LIKE \"%cryptocurrency%\""}',
 'What is DeFi? How do smart contracts work? What are trading strategies?',
 NOW()),

('advanced_strategies',
 'Advanced cryptocurrency strategies',
 'Detailed explanations of advanced crypto concepts and strategies',
 'Provide an in-depth explanation of {strategy} including risks and best practices.',
 '{"difficulty_filter": "difficulty_level = \"advanced\"", "type_filter": "content_type IN (\"strategy_guide\", \"technical_explanation\")", "time_filter": "CAST(SUBSTRING_INDEX(estimated_time, \" \", 1) AS UNSIGNED) >= 30"}',
 'How does yield farming work? What are DAOs? How do NFTs function technically?',
 NOW()),

('practical_tutorials',
 'Step-by-step tutorials',
 'Provide practical, actionable tutorials for crypto-related tasks',
 'How do I {task}? Provide step-by-step instructions.',
 '{"type_filter": "content_type = \"tutorial\"", "practical_filter": "content LIKE \"%step%\" OR content LIKE \"%how to%\""}',
 'How do I set up a wallet? How do I trade on Uniswap? How do I stake cryptocurrency?',
 NOW()),

('learning_path',
 'Personalized learning paths',
 'Create learning paths based on user experience and goals',
 'Create a learning path for {user_level} who wants to learn about {topic}.',
 '{"level_filter": "difficulty_level = \"{user_level}\"", "topic_filter": "topic LIKE \"%{topic}%\" OR content LIKE \"%{topic}%\"", "progression": "ORDER BY difficulty_level, estimated_time"}',
 'Create a learning path for beginners interested in DeFi. What should an intermediate user learn about trading?',
 NOW()),

('concept_comparison',
 'Compare and contrast concepts',
 'Compare different cryptocurrency concepts, protocols, or strategies',
 'Compare {concept1} and {concept2}. What are the differences and similarities?',
 '{"comparison_filter": "topic LIKE \"%{concept1}%\" OR topic LIKE \"%{concept2}%\" OR content LIKE \"%{concept1}%\" OR content LIKE \"%{concept2}%\""}',
 'Compare Bitcoin and Ethereum. What is the difference between CEX and DEX?',
 NOW()),

('risk_education',
 'Risk awareness and security',
 'Educate about risks, security, and best practices in cryptocurrency',
 'What are the risks of {activity} and how can I protect myself?',
 '{"risk_filter": "content LIKE \"%risk%\" OR content LIKE \"%security%\" OR content LIKE \"%safe%\" OR topic LIKE \"%security%\""}',
 'What are the risks of DeFi? How do I secure my cryptocurrency? What are common scams?',
 NOW()),

('terminology_explanation',
 'Cryptocurrency terminology',
 'Explain cryptocurrency terms and jargon',
 'What does {term} mean in cryptocurrency?',
 '{"term_filter": "content LIKE \"%{term}%\" OR explanation LIKE \"%{term}%\"", "type_filter": "content_type = \"concept_explanation\""}',
 'What is HODL? What does TVL mean? What is a smart contract?',
 NOW());

-- Create learning progression helper functions
DELIMITER //

CREATE FUNCTION get_learning_prerequisites(topic_param VARCHAR(100))
RETURNS TEXT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE prereq_list TEXT;
    
    SELECT 
        GROUP_CONCAT(DISTINCT prerequisites SEPARATOR ', ')
    INTO prereq_list
    FROM educational_content_kb
    WHERE topic = topic_param
    AND prerequisites != 'none'
    AND prerequisites IS NOT NULL;
    
    RETURN COALESCE(prereq_list, 'No specific prerequisites required');
END //

CREATE FUNCTION recommend_next_topics(current_topic VARCHAR(100), user_level VARCHAR(20))
RETURNS TEXT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE recommendations TEXT;
    
    SELECT 
        GROUP_CONCAT(DISTINCT topic SEPARATOR ', ')
    INTO recommendations
    FROM educational_content_kb
    WHERE difficulty_level = CASE 
        WHEN user_level = 'beginner' THEN 'intermediate'
        WHEN user_level = 'intermediate' THEN 'advanced'
        ELSE 'advanced'
    END
    AND (prerequisites LIKE CONCAT('%', current_topic, '%') OR 
         topic IN (
             SELECT DISTINCT topic 
             FROM educational_content_kb 
             WHERE content LIKE CONCAT('%', current_topic, '%')
             AND difficulty_level != user_level
         ))
    LIMIT 5;
    
    RETURN COALESCE(recommendations, 'Continue exploring advanced topics in your area of interest');
END //

CREATE FUNCTION estimate_learning_time(topic_param VARCHAR(100), user_level VARCHAR(20))
RETURNS VARCHAR(50)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE total_time VARCHAR(50);
    
    SELECT 
        CONCAT(
            SUM(CAST(SUBSTRING_INDEX(estimated_time, ' ', 1) AS UNSIGNED)), 
            ' minutes'
        )
    INTO total_time
    FROM educational_content_kb
    WHERE topic = topic_param
    AND difficulty_level = user_level;
    
    RETURN COALESCE(total_time, 'Time estimate not available');
END //

DELIMITER ;

-- Create educational content views for quick access
CREATE VIEW learning_path_beginner AS
SELECT 
    content_id,
    topic,
    LEFT(content, 200) as content_preview,
    learning_objectives,
    estimated_time,
    prerequisites,
    CASE 
        WHEN topic LIKE '%crypto%' OR topic LIKE '%bitcoin%' THEN 1
        WHEN topic LIKE '%blockchain%' THEN 2
        WHEN topic LIKE '%wallet%' THEN 3
        WHEN topic LIKE '%trading%' THEN 4
        ELSE 5
    END as recommended_order
FROM educational_content_kb
WHERE difficulty_level = 'beginner'
ORDER BY recommended_order, estimated_time;

CREATE VIEW learning_path_intermediate AS
SELECT 
    content_id,
    topic,
    LEFT(content, 200) as content_preview,
    learning_objectives,
    estimated_time,
    prerequisites,
    CASE 
        WHEN topic LIKE '%defi%' THEN 1
        WHEN topic LIKE '%smart%' THEN 2
        WHEN topic LIKE '%trading%' THEN 3
        WHEN topic LIKE '%technical%' THEN 4
        ELSE 5
    END as recommended_order
FROM educational_content_kb
WHERE difficulty_level = 'intermediate'
ORDER BY recommended_order, estimated_time;

CREATE VIEW learning_path_advanced AS
SELECT 
    content_id,
    topic,
    LEFT(content, 200) as content_preview,
    learning_objectives,
    estimated_time,
    prerequisites,
    CASE 
        WHEN topic LIKE '%yield%' OR topic LIKE '%farming%' THEN 1
        WHEN topic LIKE '%dao%' THEN 2
        WHEN topic LIKE '%nft%' THEN 3
        WHEN topic LIKE '%protocol%' THEN 4
        ELSE 5
    END as recommended_order
FROM educational_content_kb
WHERE difficulty_level = 'advanced'
ORDER BY recommended_order, estimated_time;

CREATE VIEW tutorial_catalog AS
SELECT 
    content_id,
    topic,
    LEFT(content, 150) as tutorial_description,
    learning_objectives,
    estimated_time,
    difficulty_level,
    prerequisites,
    CASE 
        WHEN content LIKE '%wallet%' THEN 'Wallet Management'
        WHEN content LIKE '%trading%' OR content LIKE '%exchange%' THEN 'Trading'
        WHEN content LIKE '%defi%' OR content LIKE '%protocol%' THEN 'DeFi'
        WHEN content LIKE '%security%' THEN 'Security'
        ELSE 'General'
    END as tutorial_category
FROM educational_content_kb
WHERE content_type = 'tutorial'
ORDER BY difficulty_level, tutorial_category, estimated_time;

CREATE VIEW concept_glossary AS
SELECT 
    content_id,
    topic,
    LEFT(explanation, 300) as definition,
    difficulty_level,
    examples,
    CASE 
        WHEN topic LIKE '%bitcoin%' OR topic LIKE '%crypto%' THEN 'Fundamentals'
        WHEN topic LIKE '%blockchain%' OR topic LIKE '%smart%' THEN 'Technology'
        WHEN topic LIKE '%defi%' OR topic LIKE '%protocol%' THEN 'DeFi'
        WHEN topic LIKE '%trading%' OR topic LIKE '%market%' THEN 'Trading'
        WHEN topic LIKE '%wallet%' OR topic LIKE '%security%' THEN 'Security'
        ELSE 'Other'
    END as concept_category
FROM educational_content_kb
WHERE content_type = 'concept_explanation'
ORDER BY concept_category, difficulty_level;

-- Create educational content performance tracking
CREATE TABLE crypto_data_db.education_skill_usage (
    usage_id INT AUTO_INCREMENT PRIMARY KEY,
    query_type VARCHAR(100),
    topic_requested VARCHAR(100),
    difficulty_level VARCHAR(20),
    content_returned INT,
    user_satisfaction DECIMAL(3,2),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create sample educational queries for testing
CREATE VIEW sample_education_queries AS
SELECT 
    'Basic Crypto Explanation' as query_example,
    'What is cryptocurrency and how does it work?' as sample_question,
    'beginner_concepts' as template_type,
    'beginner' as target_level
UNION ALL
SELECT 
    'DeFi Introduction',
    'Explain DeFi and how I can get started with it.',
    'intermediate_topics',
    'intermediate'
UNION ALL
SELECT 
    'Wallet Setup Tutorial',
    'How do I set up and secure a cryptocurrency wallet?',
    'practical_tutorials',
    'beginner'
UNION ALL
SELECT 
    'Advanced Yield Farming',
    'Explain yield farming strategies and risks in detail.',
    'advanced_strategies',
    'advanced'
UNION ALL
SELECT 
    'Trading vs Investing',
    'What is the difference between trading and investing in crypto?',
    'concept_comparison',
    'intermediate';

-- Test the education knowledge base skill
SELECT 
    'Education KB Skill Test' as test_type,
    COUNT(*) as total_content,
    COUNT(DISTINCT topic) as unique_topics,
    COUNT(DISTINCT difficulty_level) as difficulty_levels,
    COUNT(DISTINCT content_type) as content_types,
    SUM(CAST(SUBSTRING_INDEX(estimated_time, ' ', 1) AS UNSIGNED)) as total_learning_minutes
FROM educational_content_kb;

-- Test content by difficulty level
SELECT 
    'Content by Difficulty' as test_type,
    difficulty_level,
    COUNT(*) as content_count,
    COUNT(DISTINCT topic) as unique_topics,
    AVG(CAST(SUBSTRING_INDEX(estimated_time, ' ', 1) AS UNSIGNED)) as avg_time_minutes,
    GROUP_CONCAT(DISTINCT content_type) as available_formats
FROM educational_content_kb
GROUP BY difficulty_level
ORDER BY 
    CASE difficulty_level 
        WHEN 'beginner' THEN 1 
        WHEN 'intermediate' THEN 2 
        WHEN 'advanced' THEN 3 
    END;

-- Test tutorial availability
SELECT 
    'Tutorial Availability' as test_type,
    difficulty_level,
    COUNT(*) as tutorial_count,
    GROUP_CONCAT(DISTINCT topic) as tutorial_topics,
    SUM(CAST(SUBSTRING_INDEX(estimated_time, ' ', 1) AS UNSIGNED)) as total_tutorial_time
FROM educational_content_kb
WHERE content_type = 'tutorial'
GROUP BY difficulty_level
ORDER BY 
    CASE difficulty_level 
        WHEN 'beginner' THEN 1 
        WHEN 'intermediate' THEN 2 
        WHEN 'advanced' THEN 3 
    END;

-- Test learning progression paths
SELECT 
    'Learning Progression Test' as test_type,
    'beginner' as starting_level,
    get_learning_prerequisites('blockchain_technology') as blockchain_prereqs,
    recommend_next_topics('cryptocurrency_fundamentals', 'beginner') as next_topics,
    estimate_learning_time('cryptocurrency_fundamentals', 'beginner') as estimated_time;

-- Success validation
SELECT 'Education Knowledge Base Skill created successfully' as status;

SELECT 
    'Educational Content Summary' as summary_type,
    COUNT(*) as total_educational_content,
    COUNT(DISTINCT topic) as unique_topics,
    COUNT(DISTINCT difficulty_level) as difficulty_levels,
    COUNT(DISTINCT content_type) as content_formats,
    MIN(CAST(SUBSTRING_INDEX(estimated_time, ' ', 1) AS UNSIGNED)) as shortest_content_minutes,
    MAX(CAST(SUBSTRING_INDEX(estimated_time, ' ', 1) AS UNSIGNED)) as longest_content_minutes
FROM educational_content_kb;
