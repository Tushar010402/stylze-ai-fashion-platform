-- Create test database for testing
CREATE DATABASE stylze_test;

-- Grant all privileges
GRANT ALL PRIVILEGES ON DATABASE stylze_db TO stylze_user;
GRANT ALL PRIVILEGES ON DATABASE stylze_test TO stylze_user;

-- Connect to main database
\c stylze_db;

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For text search
CREATE EXTENSION IF NOT EXISTS "btree_gin"; -- For compound indexes

-- Create schemas for logical separation
CREATE SCHEMA IF NOT EXISTS users;
CREATE SCHEMA IF NOT EXISTS wardrobe;
CREATE SCHEMA IF NOT EXISTS avatars;
CREATE SCHEMA IF NOT EXISTS recommendations;
CREATE SCHEMA IF NOT EXISTS notifications;
CREATE SCHEMA IF NOT EXISTS analytics;

-- Grant schema permissions
GRANT ALL ON SCHEMA users TO stylze_user;
GRANT ALL ON SCHEMA wardrobe TO stylze_user;
GRANT ALL ON SCHEMA avatars TO stylze_user;
GRANT ALL ON SCHEMA recommendations TO stylze_user;
GRANT ALL ON SCHEMA notifications TO stylze_user;
GRANT ALL ON SCHEMA analytics TO stylze_user;

-- Set search path
ALTER DATABASE stylze_db SET search_path TO public,users,wardrobe,avatars,recommendations,notifications,analytics;

-- Create ENUM types
CREATE TYPE users.body_type AS ENUM ('ECTOMORPH', 'MESOMORPH', 'ENDOMORPH', 'HOURGLASS', 'PEAR', 'APPLE', 'RECTANGLE', 'INVERTED_TRIANGLE');
CREATE TYPE users.gender AS ENUM ('MALE', 'FEMALE', 'OTHER', 'PREFER_NOT_TO_SAY');
CREATE TYPE wardrobe.clothing_category AS ENUM ('TOP', 'BOTTOM', 'DRESS', 'OUTERWEAR', 'FOOTWEAR', 'ACCESSORY', 'UNDERWEAR', 'SWIMWEAR', 'ACTIVEWEAR');
CREATE TYPE wardrobe.season AS ENUM ('SPRING', 'SUMMER', 'FALL', 'WINTER', 'ALL_SEASON');
CREATE TYPE wardrobe.occasion AS ENUM ('CASUAL', 'FORMAL', 'BUSINESS', 'PARTY', 'SPORT', 'BEACH', 'DATE', 'WEDDING');
CREATE TYPE notifications.notification_type AS ENUM ('EMAIL', 'SMS', 'PUSH', 'IN_APP');
CREATE TYPE notifications.notification_status AS ENUM ('PENDING', 'SENT', 'DELIVERED', 'FAILED', 'READ');

-- Create Users tables
CREATE TABLE IF NOT EXISTS users.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    email_verified BOOLEAN DEFAULT FALSE,
    phone VARCHAR(20),
    phone_verified BOOLEAN DEFAULT FALSE,
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    two_factor_secret VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    is_premium BOOLEAN DEFAULT FALSE,
    premium_expires_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

CREATE TABLE IF NOT EXISTS users.profiles (
    user_id UUID PRIMARY KEY REFERENCES users.users(id) ON DELETE CASCADE,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    display_name VARCHAR(150),
    date_of_birth DATE,
    gender users.gender,
    body_type users.body_type,
    skin_tone VARCHAR(50),
    height_cm INTEGER CHECK (height_cm > 0 AND height_cm < 300),
    weight_kg DECIMAL(5,2) CHECK (weight_kg > 0 AND weight_kg < 500),
    measurements JSONB DEFAULT '{}',
    style_preferences JSONB DEFAULT '{}',
    color_preferences TEXT[] DEFAULT '{}',
    brand_preferences TEXT[] DEFAULT '{}',
    sizes JSONB DEFAULT '{}',
    location VARCHAR(255),
    timezone VARCHAR(50) DEFAULT 'UTC',
    language VARCHAR(10) DEFAULT 'en',
    avatar_url TEXT,
    bio TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS users.sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) UNIQUE NOT NULL,
    refresh_token_hash VARCHAR(255) UNIQUE,
    ip_address INET,
    user_agent TEXT,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create Wardrobe tables
CREATE TABLE IF NOT EXISTS wardrobe.items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,
    name VARCHAR(255),
    category wardrobe.clothing_category NOT NULL,
    subcategory VARCHAR(100),
    brand VARCHAR(100),
    size VARCHAR(20),
    color_primary VARCHAR(50),
    color_secondary VARCHAR(50),
    pattern VARCHAR(50),
    material VARCHAR(100),
    price DECIMAL(10,2),
    purchase_date DATE,
    season wardrobe.season[],
    occasions wardrobe.occasion[],
    tags TEXT[] DEFAULT '{}',
    image_url TEXT NOT NULL,
    thumbnail_url TEXT,
    ai_description TEXT,
    ai_metadata JSONB DEFAULT '{}',
    color_histogram JSONB,
    usage_count INTEGER DEFAULT 0,
    last_worn DATE,
    is_favorite BOOLEAN DEFAULT FALSE,
    is_archived BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS wardrobe.outfits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    occasion wardrobe.occasion,
    season wardrobe.season,
    weather_type VARCHAR(50),
    style_tags TEXT[] DEFAULT '{}',
    is_ai_generated BOOLEAN DEFAULT FALSE,
    ai_confidence FLOAT CHECK (ai_confidence >= 0 AND ai_confidence <= 1),
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    wear_count INTEGER DEFAULT 0,
    last_worn DATE,
    is_favorite BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS wardrobe.outfit_items (
    outfit_id UUID NOT NULL REFERENCES wardrobe.outfits(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES wardrobe.items(id) ON DELETE CASCADE,
    item_order INTEGER DEFAULT 0,
    PRIMARY KEY (outfit_id, item_id)
);

-- Create Avatar tables
CREATE TABLE IF NOT EXISTS avatars.user_avatars (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,
    version INTEGER DEFAULT 1,
    mesh_data JSONB NOT NULL,
    texture_urls JSONB,
    measurements JSONB NOT NULL,
    body_landmarks JSONB,
    skin_tone VARCHAR(50),
    hair_color VARCHAR(50),
    eye_color VARCHAR(50),
    face_shape VARCHAR(50),
    provider VARCHAR(50) DEFAULT 'custom', -- 'custom', 'ready_player_me', 'metahuman'
    provider_avatar_id VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS avatars.virtual_tryons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,
    avatar_id UUID NOT NULL REFERENCES avatars.user_avatars(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES wardrobe.items(id) ON DELETE CASCADE,
    render_url TEXT,
    video_url TEXT,
    fit_score FLOAT CHECK (fit_score >= 0 AND fit_score <= 1),
    fit_analysis JSONB,
    adjustments JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create Recommendations tables
CREATE TABLE IF NOT EXISTS recommendations.user_preferences (
    user_id UUID PRIMARY KEY REFERENCES users.users(id) ON DELETE CASCADE,
    style_vector FLOAT[] CHECK (array_length(style_vector, 1) = 128), -- 128-dimensional embedding
    color_affinity JSONB DEFAULT '{}',
    brand_affinity JSONB DEFAULT '{}',
    price_range JSONB DEFAULT '{"min": 0, "max": 1000}',
    sustainability_preference INTEGER DEFAULT 5 CHECK (sustainability_preference >= 0 AND sustainability_preference <= 10),
    comfort_preference INTEGER DEFAULT 5 CHECK (comfort_preference >= 0 AND comfort_preference <= 10),
    trendiness_preference INTEGER DEFAULT 5 CHECK (trendiness_preference >= 0 AND trendiness_preference <= 10),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS recommendations.outfit_recommendations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,
    outfit_id UUID REFERENCES wardrobe.outfits(id) ON DELETE SET NULL,
    recommendation_type VARCHAR(50), -- 'daily', 'event', 'weather', 'trend'
    context JSONB DEFAULT '{}',
    score FLOAT CHECK (score >= 0 AND score <= 1),
    reason TEXT,
    feedback VARCHAR(20), -- 'liked', 'disliked', 'worn', 'skipped'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE
);

-- Create Notifications tables
CREATE TABLE IF NOT EXISTS notifications.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,
    type notifications.notification_type NOT NULL,
    status notifications.notification_status DEFAULT 'PENDING',
    subject VARCHAR(255),
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    scheduled_for TIMESTAMP WITH TIME ZONE,
    sent_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    read_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create Analytics tables
CREATE TABLE IF NOT EXISTS analytics.user_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users.users(id) ON DELETE SET NULL,
    session_id UUID REFERENCES users.sessions(id) ON DELETE SET NULL,
    event_type VARCHAR(100) NOT NULL,
    event_data JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX idx_users_email ON users.users(email);
CREATE INDEX idx_users_phone ON users.users(phone) WHERE phone IS NOT NULL;
CREATE INDEX idx_sessions_user_id ON users.sessions(user_id);
CREATE INDEX idx_sessions_token ON users.sessions(token_hash);
CREATE INDEX idx_sessions_expires ON users.sessions(expires_at);

CREATE INDEX idx_wardrobe_items_user ON wardrobe.items(user_id);
CREATE INDEX idx_wardrobe_items_category ON wardrobe.items(category);
CREATE INDEX idx_wardrobe_items_brand ON wardrobe.items(brand) WHERE brand IS NOT NULL;
CREATE INDEX idx_wardrobe_items_colors ON wardrobe.items(color_primary, color_secondary);
CREATE INDEX idx_wardrobe_items_tags ON wardrobe.items USING gin(tags);
CREATE INDEX idx_wardrobe_items_seasons ON wardrobe.items USING gin(season);
CREATE INDEX idx_wardrobe_items_occasions ON wardrobe.items USING gin(occasions);

CREATE INDEX idx_outfits_user ON wardrobe.outfits(user_id);
CREATE INDEX idx_outfits_occasion ON wardrobe.outfits(occasion) WHERE occasion IS NOT NULL;
CREATE INDEX idx_outfit_items_outfit ON wardrobe.outfit_items(outfit_id);
CREATE INDEX idx_outfit_items_item ON wardrobe.outfit_items(item_id);

CREATE INDEX idx_avatars_user ON avatars.user_avatars(user_id);
CREATE INDEX idx_avatars_active ON avatars.user_avatars(user_id, is_active) WHERE is_active = TRUE;
CREATE INDEX idx_tryons_user ON avatars.virtual_tryons(user_id);

CREATE INDEX idx_recommendations_user ON recommendations.outfit_recommendations(user_id);
CREATE INDEX idx_recommendations_created ON recommendations.outfit_recommendations(created_at DESC);
CREATE INDEX idx_recommendations_expires ON recommendations.outfit_recommendations(expires_at) WHERE expires_at IS NOT NULL;

CREATE INDEX idx_notifications_user ON notifications.notifications(user_id);
CREATE INDEX idx_notifications_status ON notifications.notifications(status);
CREATE INDEX idx_notifications_scheduled ON notifications.notifications(scheduled_for) WHERE scheduled_for IS NOT NULL;

CREATE INDEX idx_events_user ON analytics.user_events(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX idx_events_type ON analytics.user_events(event_type);
CREATE INDEX idx_events_created ON analytics.user_events(created_at DESC);

-- Create update timestamp trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users.users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON users.profiles 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_wardrobe_items_updated_at BEFORE UPDATE ON wardrobe.items 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_outfits_updated_at BEFORE UPDATE ON wardrobe.outfits 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_avatars_updated_at BEFORE UPDATE ON avatars.user_avatars 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert initial test data (optional)
INSERT INTO users.users (email, password_hash, email_verified) 
VALUES ('test@stylze.ai', '$2b$10$YourHashedPasswordHere', true)
ON CONFLICT (email) DO NOTHING;

-- Grant all permissions on all tables to the user
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA users TO stylze_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA wardrobe TO stylze_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA avatars TO stylze_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA recommendations TO stylze_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA notifications TO stylze_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA analytics TO stylze_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA users TO stylze_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA wardrobe TO stylze_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA avatars TO stylze_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA recommendations TO stylze_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA notifications TO stylze_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA analytics TO stylze_user;