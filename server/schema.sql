-- ==============================================================================
-- PandalMap Hopping Squads — Neon PostgreSQL Schema & RLS Policies
-- ==============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ------------------------------------------------------------------------------
-- 1. Profiles (user_id is the authenticated Firebase UID)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS profiles (
    user_id TEXT PRIMARY KEY,
    display_name TEXT NOT NULL,
    avatar_url TEXT,
    is_guest BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 2. Squads
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS squads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL DEFAULT 'Hopping Squad',
    host_user_id TEXT NOT NULL,
    meetup_lat DOUBLE PRECISION,
    meetup_lng DOUBLE PRECISION,
    meetup_label TEXT,
    separation_radius_m INTEGER NOT NULL DEFAULT 500,
    status TEXT NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT valid_radius CHECK (separation_radius_m BETWEEN 50 AND 5000),
    CONSTRAINT valid_status CHECK (status IN ('active', 'closed'))
);

-- ------------------------------------------------------------------------------
-- 3. Squad Members
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS squad_members (
    squad_id UUID NOT NULL REFERENCES squads(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'member',
    share_location BOOLEAN NOT NULL DEFAULT FALSE,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_seen_at TIMESTAMPTZ,
    PRIMARY KEY (squad_id, user_id),
    CONSTRAINT valid_role CHECK (role IN ('host', 'member'))
);

-- ------------------------------------------------------------------------------
-- 4. Locations (Latest known coordinates per squad member)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS squad_locations (
    squad_id UUID NOT NULL REFERENCES squads(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    accuracy_m REAL,
    heading_deg REAL,
    speed_mps REAL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (squad_id, user_id)
);

-- ------------------------------------------------------------------------------
-- 5. Chat Messages
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS squad_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    squad_id UUID NOT NULL REFERENCES squads(id) ON DELETE CASCADE,
    sender_user_id TEXT NOT NULL,
    message_type TEXT NOT NULL DEFAULT 'text',
    message TEXT,
    media_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT valid_message_type CHECK (
        message_type IN ('text', 'image', 'location', 'system')
    )
);

-- ------------------------------------------------------------------------------
-- 6. Squad Events (Audit / event trail)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS squad_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    squad_id UUID NOT NULL REFERENCES squads(id) ON DELETE CASCADE,
    actor_user_id TEXT,
    event_type TEXT NOT NULL,
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 7. Indexes for Query Performance
-- ------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_squad_locations_squad ON squad_locations(squad_id);
CREATE INDEX IF NOT EXISTS idx_squad_members_user ON squad_members(user_id);
CREATE INDEX IF NOT EXISTS idx_squad_members_squad ON squad_members(squad_id);
CREATE INDEX IF NOT EXISTS idx_squad_messages_squad_time ON squad_messages(squad_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_squad_events_squad ON squad_events(squad_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_squads_code ON squads(code);

-- ------------------------------------------------------------------------------
-- 8. Row Level Security (RLS) Policies (PostgreSQL / Neon Authorize)
-- ------------------------------------------------------------------------------
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE squads ENABLE ROW LEVEL SECURITY;
ALTER TABLE squad_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE squad_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE squad_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE squad_events ENABLE ROW LEVEL SECURITY;

-- Profiles: Anyone in the same squad or the user themselves can read profiles
CREATE POLICY profiles_select_policy ON profiles
    FOR SELECT
    USING (TRUE);

-- Profiles: Users can only update their own profile
CREATE POLICY profiles_update_policy ON profiles
    FOR ALL
    USING (user_id = current_setting('request.jwt.claim.sub', true)
        OR user_id = current_setting('request.jwt.claim.user_id', true));

-- Squads: Users can view a squad if they are a member of it
CREATE POLICY squads_member_read_policy ON squads
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM squad_members
            WHERE squad_members.squad_id = squads.id
            AND squad_members.user_id = coalesce(
                current_setting('request.jwt.claim.sub', true),
                current_setting('request.jwt.claim.user_id', true)
            )
        )
    );

-- Squad Members: Users can see members of squads they belong to
CREATE POLICY squad_members_read_policy ON squad_members
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM squad_members AS sm
            WHERE sm.squad_id = squad_members.squad_id
            AND sm.user_id = coalesce(
                current_setting('request.jwt.claim.sub', true),
                current_setting('request.jwt.claim.user_id', true)
            )
        )
    );

-- Locations: Users can only read locations if sharing is enabled and in same squad
CREATE POLICY squad_locations_read_policy ON squad_locations
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM squad_members AS viewer
            JOIN squad_members AS target ON viewer.squad_id = target.squad_id
            WHERE viewer.squad_id = squad_locations.squad_id
            AND target.user_id = squad_locations.user_id
            AND target.share_location = TRUE
            AND viewer.user_id = coalesce(
                current_setting('request.jwt.claim.sub', true),
                current_setting('request.jwt.claim.user_id', true)
            )
        )
    );

-- Locations: Users can only write/update their own location
CREATE POLICY squad_locations_write_policy ON squad_locations
    FOR ALL
    USING (
        user_id = coalesce(
            current_setting('request.jwt.claim.sub', true),
            current_setting('request.jwt.claim.user_id', true)
        )
    );

-- Messages: Users can read messages in their squad
CREATE POLICY squad_messages_read_policy ON squad_messages
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM squad_members
            WHERE squad_members.squad_id = squad_messages.squad_id
            AND squad_members.user_id = coalesce(
                current_setting('request.jwt.claim.sub', true),
                current_setting('request.jwt.claim.user_id', true)
            )
        )
    );
