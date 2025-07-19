// Design database schema for storing conversation history
CREATE TABLE Conversations (
    id SERIAL PRIMARY KEY,
    from_agent VARCHAR(50),
    to_agent VARCHAR(50),
    message TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);