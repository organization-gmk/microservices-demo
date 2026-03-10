-- Ensure the 'users' table exists
CREATE TABLE IF NOT EXISTS "users" (
    id UUID PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL
);

-- Insert or update the user with the CORRECT $2a$10$ hash
INSERT INTO "users" (id, email, password, role)
VALUES (
    '223e4567-e89b-12d3-a456-426614174006', 
    'testuser@test.com',
    '$2a$10$JUWzy2RMr3A2NqJ/NyIlxObFuDlP6Wrq9Cv9mS/yJemATqjFHV9By', 
    'ADMIN'
)
ON CONFLICT (email) DO UPDATE 
SET password = EXCLUDED.password,
    role = EXCLUDED.role;