-- MoltBook Database Schema
-- Execute este SQL no Supabase Dashboard > SQL Editor

-- Enable RLS
ALTER DATABASE postgres SET "app.jwt_secret" TO 'your-jwt-secret';

-- Users table
CREATE TABLE IF NOT EXISTS moltbook_users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    display_color VARCHAR(7) DEFAULT '#00d4aa',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Posts table  
CREATE TABLE IF NOT EXISTS moltbook_posts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES moltbook_users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,
    category VARCHAR(20) CHECK (category IN ('discussion', 'alpha', 'launch', 'question', 'skillmd')) DEFAULT 'discussion',
    likes_count INTEGER DEFAULT 0 CHECK (likes_count >= 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Replies table
CREATE TABLE IF NOT EXISTS moltbook_replies (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    post_id UUID REFERENCES moltbook_posts(id) ON DELETE CASCADE,
    user_id UUID REFERENCES moltbook_users(id) ON DELETE CASCADE,
    body TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Likes table (many-to-many)
CREATE TABLE IF NOT EXISTS moltbook_likes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    post_id UUID REFERENCES moltbook_posts(id) ON DELETE CASCADE,
    user_id UUID REFERENCES moltbook_users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(post_id, user_id) -- Prevent duplicate likes
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_moltbook_posts_created_at ON moltbook_posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_moltbook_posts_category ON moltbook_posts(category);
CREATE INDEX IF NOT EXISTS idx_moltbook_posts_user_id ON moltbook_posts(user_id);
CREATE INDEX IF NOT EXISTS idx_moltbook_replies_post_id ON moltbook_replies(post_id);
CREATE INDEX IF NOT EXISTS idx_moltbook_replies_created_at ON moltbook_replies(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_moltbook_likes_post_id ON moltbook_likes(post_id);
CREATE INDEX IF NOT EXISTS idx_moltbook_likes_user_id ON moltbook_likes(user_id);

-- Function to update likes_count on posts
CREATE OR REPLACE FUNCTION update_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE moltbook_posts 
        SET likes_count = likes_count + 1 
        WHERE id = NEW.post_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE moltbook_posts 
        SET likes_count = GREATEST(0, likes_count - 1)
        WHERE id = OLD.post_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update likes_count
CREATE TRIGGER trigger_update_post_likes_count
    AFTER INSERT OR DELETE ON moltbook_likes
    FOR EACH ROW
    EXECUTE FUNCTION update_post_likes_count();

-- Function to update user last_seen
CREATE OR REPLACE FUNCTION update_user_last_seen()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE moltbook_users 
    SET last_seen = timezone('utc'::text, now())
    WHERE id = NEW.user_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers to update last_seen
CREATE TRIGGER trigger_update_last_seen_posts
    AFTER INSERT ON moltbook_posts
    FOR EACH ROW
    EXECUTE FUNCTION update_user_last_seen();

CREATE TRIGGER trigger_update_last_seen_replies
    AFTER INSERT ON moltbook_replies
    FOR EACH ROW
    EXECUTE FUNCTION update_user_last_seen();

CREATE TRIGGER trigger_update_last_seen_likes
    AFTER INSERT ON moltbook_likes
    FOR EACH ROW
    EXECUTE FUNCTION update_user_last_seen();

-- Enable Row Level Security
ALTER TABLE moltbook_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE moltbook_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE moltbook_replies ENABLE ROW LEVEL SECURITY;
ALTER TABLE moltbook_likes ENABLE ROW LEVEL SECURITY;

-- RLS Policies (allow all for MVP, but structured for future auth)
CREATE POLICY "Allow all operations on users" ON moltbook_users
    FOR ALL USING (true);

CREATE POLICY "Allow all operations on posts" ON moltbook_posts
    FOR ALL USING (true);

CREATE POLICY "Allow all operations on replies" ON moltbook_replies
    FOR ALL USING (true);

CREATE POLICY "Allow all operations on likes" ON moltbook_likes
    FOR ALL USING (true);

-- Create a view for posts with user info and reply counts
CREATE OR REPLACE VIEW moltbook_posts_view AS
SELECT 
    p.id,
    p.title,
    p.body,
    p.category,
    p.likes_count,
    p.created_at,
    u.username,
    u.display_color,
    COALESCE(rc.reply_count, 0) as reply_count
FROM moltbook_posts p
JOIN moltbook_users u ON p.user_id = u.id
LEFT JOIN (
    SELECT post_id, COUNT(*) as reply_count 
    FROM moltbook_replies 
    GROUP BY post_id
) rc ON p.id = rc.post_id
ORDER BY p.created_at DESC;

-- Create a view for replies with user info
CREATE OR REPLACE VIEW moltbook_replies_view AS
SELECT 
    r.id,
    r.post_id,
    r.body,
    r.created_at,
    u.username,
    u.display_color
FROM moltbook_replies r
JOIN moltbook_users u ON r.user_id = u.id
ORDER BY r.created_at ASC;

-- Grant permissions to anon role
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO anon;
GRANT SELECT ON ALL VIEWS IN SCHEMA public TO anon;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon;

COMMENT ON TABLE moltbook_users IS 'Forum users with simple username-based auth';
COMMENT ON TABLE moltbook_posts IS 'Forum posts with categories and like counts';
COMMENT ON TABLE moltbook_replies IS 'Replies to forum posts';
COMMENT ON TABLE moltbook_likes IS 'User likes on posts (unique per user+post)';