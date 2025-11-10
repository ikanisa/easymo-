-- Ensure agent quote upserts can target the session/vendor composite key
-- by adding a unique constraint on the combination.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'agent_quotes_session_vendor_unique'
      AND conrelid = 'public.agent_quotes'::regclass
  ) THEN
    ALTER TABLE public.agent_quotes
      ADD CONSTRAINT agent_quotes_session_vendor_unique
        UNIQUE (session_id, vendor_phone);
  END IF;
END
$$;
