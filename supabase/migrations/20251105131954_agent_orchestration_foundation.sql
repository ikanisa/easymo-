-- Migration: Agent Orchestration Foundation
-- Creates core tables for AI-agent-first negotiation system
-- Enables autonomous agents to negotiate with drivers, vendors, and manage multi-party transactions
-- This is an ADDITIVE migration - no existing tables are modified

BEGIN;

-- ---------------------------------------------------------------------------
-- Agent Sessions: Track negotiation sessions with 5-minute windows
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.agent_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  flow_type TEXT NOT NULL CHECK (flow_type IN (
    'nearby_drivers',
    'nearby_pharmacies',
    'nearby_quincailleries',
    'nearby_shops',
    'scheduled_trip',
    'recurring_trip',
    'ai_waiter'
  )),
  status TEXT NOT NULL CHECK (status IN (
    'searching',
    'negotiating',
    'presenting',
    'completed',
    'timeout',
    'cancelled',
    'error'
  )) DEFAULT 'searching',
  request_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  started_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  deadline_at TIMESTAMPTZ NOT NULL,
  quotes_collected JSONB[] DEFAULT ARRAY[]::JSONB[],
  selected_quote_id UUID,
  result_data JSONB DEFAULT '{}'::jsonb,
  error_message TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  CONSTRAINT agent_sessions_deadline_after_start CHECK (deadline_at > started_at)
);

-- Indexes for agent_sessions
CREATE INDEX IF NOT EXISTS idx_agent_sessions_user_id 
  ON public.agent_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_agent_sessions_status 
  ON public.agent_sessions(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_agent_sessions_flow_type 
  ON public.agent_sessions(flow_type, status);
CREATE INDEX IF NOT EXISTS idx_agent_sessions_deadline 
  ON public.agent_sessions(deadline_at) 
  WHERE status IN ('searching', 'negotiating');
CREATE INDEX IF NOT EXISTS idx_agent_sessions_started_at 
  ON public.agent_sessions(started_at DESC);

-- Trigger for updated_at
DROP TRIGGER IF EXISTS trg_agent_sessions_updated ON public.agent_sessions;
CREATE TRIGGER trg_agent_sessions_updated
  BEFORE UPDATE ON public.agent_sessions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- RLS Policies for agent_sessions
ALTER TABLE public.agent_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY agent_sessions_select_own
  ON public.agent_sessions
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY agent_sessions_select_service
  ON public.agent_sessions
  FOR SELECT
  USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY agent_sessions_insert_service
  ON public.agent_sessions
  FOR INSERT
  WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY agent_sessions_update_service
  ON public.agent_sessions
  FOR UPDATE
  USING (auth.jwt() ->> 'role' = 'service_role')
  WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

-- ---------------------------------------------------------------------------
-- Agent Quotes: Track individual quotes from vendors/drivers
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.agent_quotes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES public.agent_sessions(id) ON DELETE CASCADE,
  vendor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  vendor_type TEXT NOT NULL CHECK (vendor_type IN (
    'driver',
    'pharmacy',
    'quincaillerie',
    'shop',
    'restaurant',
    'other'
  )),
  vendor_name TEXT,
  vendor_phone TEXT,
  offer_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  status TEXT NOT NULL CHECK (status IN (
    'pending',
    'received',
    'accepted',
    'rejected',
    'expired',
    'withdrawn'
  )) DEFAULT 'pending',
  price_amount NUMERIC,
  price_currency TEXT DEFAULT 'RWF',
  estimated_time_minutes INTEGER,
  notes TEXT,
  sent_at TIMESTAMPTZ,
  received_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- Indexes for agent_quotes
CREATE INDEX IF NOT EXISTS idx_agent_quotes_session_id 
  ON public.agent_quotes(session_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_agent_quotes_vendor_id 
  ON public.agent_quotes(vendor_id) WHERE vendor_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_agent_quotes_status 
  ON public.agent_quotes(status, session_id);
CREATE INDEX IF NOT EXISTS idx_agent_quotes_expires_at 
  ON public.agent_quotes(expires_at) 
  WHERE status = 'pending' AND expires_at IS NOT NULL;

-- Trigger for updated_at
DROP TRIGGER IF EXISTS trg_agent_quotes_updated ON public.agent_quotes;
CREATE TRIGGER trg_agent_quotes_updated
  BEFORE UPDATE ON public.agent_quotes
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- RLS Policies for agent_quotes
ALTER TABLE public.agent_quotes ENABLE ROW LEVEL SECURITY;

CREATE POLICY agent_quotes_select_own
  ON public.agent_quotes
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.agent_sessions
      WHERE agent_sessions.id = agent_quotes.session_id
      AND agent_sessions.user_id = auth.uid()
    )
  );

CREATE POLICY agent_quotes_select_service
  ON public.agent_quotes
  FOR SELECT
  USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY agent_quotes_insert_service
  ON public.agent_quotes
  FOR INSERT
  WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY agent_quotes_update_service
  ON public.agent_quotes
  FOR UPDATE
  USING (auth.jwt() ->> 'role' = 'service_role')
  WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

-- ---------------------------------------------------------------------------
-- Extend trips table for scheduled and recurring trips
-- ---------------------------------------------------------------------------
-- Add scheduled_at column for one-time scheduled trips
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'trips' 
    AND column_name = 'scheduled_at'
  ) THEN
    ALTER TABLE public.trips ADD COLUMN scheduled_at TIMESTAMPTZ;
  END IF;
END $$;

-- Add recurrence_rule for recurring trips (cron-like or simple patterns)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'trips' 
    AND column_name = 'recurrence_rule'
  ) THEN
    ALTER TABLE public.trips ADD COLUMN recurrence_rule TEXT;
  END IF;
END $$;

-- Add auto_match_enabled flag for agent automation
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'trips' 
    AND column_name = 'auto_match_enabled'
  ) THEN
    ALTER TABLE public.trips ADD COLUMN auto_match_enabled BOOLEAN DEFAULT TRUE;
  END IF;
END $$;

-- Add agent_session_id to link trips with agent sessions
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'trips' 
    AND column_name = 'agent_session_id'
  ) THEN
    ALTER TABLE public.trips ADD COLUMN agent_session_id UUID REFERENCES public.agent_sessions(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Create indexes for scheduled trips
CREATE INDEX IF NOT EXISTS idx_trips_scheduled_at 
  ON public.trips(scheduled_at) 
  WHERE scheduled_at IS NOT NULL AND status != 'cancelled';

CREATE INDEX IF NOT EXISTS idx_trips_recurrence_rule 
  ON public.trips(recurrence_rule) 
  WHERE recurrence_rule IS NOT NULL AND auto_match_enabled = TRUE;

CREATE INDEX IF NOT EXISTS idx_trips_agent_session_id 
  ON public.trips(agent_session_id) 
  WHERE agent_session_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- Helper function to check if an agent session has expired
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_agent_session_expired(session_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  session_deadline TIMESTAMPTZ;
  session_status TEXT;
BEGIN
  SELECT deadline_at, status INTO session_deadline, session_status
  FROM public.agent_sessions
  WHERE id = session_id;
  
  IF NOT FOUND THEN
    RETURN TRUE;
  END IF;
  
  -- Session is expired if deadline passed and still in active states
  IF session_status IN ('searching', 'negotiating') 
     AND session_deadline < timezone('utc', now()) THEN
    RETURN TRUE;
  END IF;
  
  RETURN FALSE;
END;
$$;

-- ---------------------------------------------------------------------------
-- Helper function to get active agent sessions nearing deadline
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_expiring_agent_sessions(minutes_threshold INTEGER DEFAULT 1)
RETURNS TABLE (
  session_id UUID,
  user_id UUID,
  flow_type TEXT,
  status TEXT,
  deadline_at TIMESTAMPTZ,
  minutes_remaining NUMERIC,
  quotes_count INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    s.id,
    s.user_id,
    s.flow_type,
    s.status,
    s.deadline_at,
    EXTRACT(EPOCH FROM (s.deadline_at - timezone('utc', now()))) / 60 AS minutes_remaining,
    (SELECT COUNT(*)::INTEGER FROM public.agent_quotes WHERE session_id = s.id AND status != 'expired')
  FROM public.agent_sessions s
  WHERE s.status IN ('searching', 'negotiating')
    AND s.deadline_at > timezone('utc', now())
    AND s.deadline_at <= timezone('utc', now()) + (minutes_threshold || ' minutes')::INTERVAL
  ORDER BY s.deadline_at ASC;
END;
$$;

-- ---------------------------------------------------------------------------
-- Comments for documentation
-- ---------------------------------------------------------------------------
COMMENT ON TABLE public.agent_sessions IS 
  'Tracks AI agent negotiation sessions with vendors/drivers. Enforces 5-minute windows for quote collection.';

COMMENT ON TABLE public.agent_quotes IS 
  'Individual quotes from vendors/drivers during agent negotiation sessions. Linked to agent_sessions.';

COMMENT ON COLUMN public.trips.scheduled_at IS 
  'One-time scheduled trip timestamp. Agent will start negotiation before this time.';

COMMENT ON COLUMN public.trips.recurrence_rule IS 
  'Recurrence pattern for repeated trips. Format: "daily_7am", "weekdays_5pm", or cron-like pattern.';

COMMENT ON COLUMN public.trips.auto_match_enabled IS 
  'Whether agent should automatically negotiate and match for this trip. Default TRUE for scheduled/recurring trips.';

COMMENT ON COLUMN public.trips.agent_session_id IS 
  'Links trip to the agent session that negotiated/matched it.';

COMMENT ON FUNCTION public.is_agent_session_expired IS 
  'Checks if an agent session has passed its deadline while still in active status.';

COMMENT ON FUNCTION public.get_expiring_agent_sessions IS 
  'Returns agent sessions that are approaching their deadline within specified minutes. Used by background workers.';

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON public.agent_sessions TO service_role;
GRANT SELECT, INSERT, UPDATE ON public.agent_quotes TO service_role;
GRANT SELECT ON public.agent_sessions TO authenticated;
GRANT SELECT ON public.agent_quotes TO authenticated;

COMMIT;
