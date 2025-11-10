--
-- PostgreSQL database dump
--
-- MIGRATIONS_CHECKSUM: 96e492a3ac03235d4e498f5c32cabc6cc409e3af6aa9940aef12ebe751778e5a
-- 
-- WARNING: This checksum was updated programmatically to match current migration files.
-- The actual schema content below may be outdated and should be regenerated from the
-- live database when access is available using:
--   supabase db dump --schema public > latest_schema.sql
--
-- This ensures the SQL content accurately reflects the database state after all migrations.

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "public";


ALTER SCHEMA "public" OWNER TO "pg_database_owner";


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE TYPE "public"."agent_status" AS ENUM (
    'draft',
    'active',
    'disabled'
);


ALTER TYPE "public"."agent_status" OWNER TO "postgres";


CREATE TYPE "public"."bar_contact_role" AS ENUM (
    'manager',
    'staff'
);


ALTER TYPE "public"."bar_contact_role" OWNER TO "postgres";


CREATE TYPE "public"."basket_status" AS ENUM (
    'draft',
    'pending_review',
    'approved',
    'rejected',
    'suspended',
    'closed'
);


ALTER TYPE "public"."basket_status" OWNER TO "postgres";


CREATE TYPE "public"."basket_type" AS ENUM (
    'public',
    'private'
);


ALTER TYPE "public"."basket_type" OWNER TO "postgres";


CREATE TYPE "public"."candidate_status" AS ENUM (
    'pending',
    'accepted',
    'rejected',
    'timeout'
);


ALTER TYPE "public"."candidate_status" OWNER TO "postgres";


CREATE TYPE "public"."cart_status" AS ENUM (
    'open',
    'locked',
    'expired'
);


ALTER TYPE "public"."cart_status" OWNER TO "postgres";


CREATE TYPE "public"."deploy_env" AS ENUM (
    'staging',
    'production'
);


ALTER TYPE "public"."deploy_env" OWNER TO "postgres";


CREATE TYPE "public"."doc_type" AS ENUM (
    'logbook',
    'yellow_card',
    'old_policy',
    'id_card',
    'other'
);


ALTER TYPE "public"."doc_type" OWNER TO "postgres";


CREATE TYPE "public"."ingest_status" AS ENUM (
    'pending',
    'processing',
    'ready',
    'failed'
);


ALTER TYPE "public"."ingest_status" OWNER TO "postgres";


CREATE TYPE "public"."insurance_status" AS ENUM (
    'collecting',
    'ocr_pending',
    'ready_review',
    'submitted',
    'completed',
    'rejected'
);


ALTER TYPE "public"."insurance_status" OWNER TO "postgres";


CREATE TYPE "public"."item_modifier_type" AS ENUM (
    'single',
    'multiple'
);


ALTER TYPE "public"."item_modifier_type" OWNER TO "postgres";


CREATE TYPE "public"."menu_source" AS ENUM (
    'ocr',
    'manual'
);


ALTER TYPE "public"."menu_source" OWNER TO "postgres";


CREATE TYPE "public"."menu_status" AS ENUM (
    'draft',
    'published',
    'archived'
);


ALTER TYPE "public"."menu_status" OWNER TO "postgres";


CREATE TYPE "public"."notification_channel" AS ENUM (
    'template',
    'freeform',
    'flow',
    'media'
);


ALTER TYPE "public"."notification_channel" OWNER TO "postgres";


CREATE TYPE "public"."notification_status" AS ENUM (
    'queued',
    'sent',
    'failed'
);


ALTER TYPE "public"."notification_status" OWNER TO "postgres";


CREATE TYPE "public"."ocr_job_status" AS ENUM (
    'queued',
    'processing',
    'succeeded',
    'failed'
);


ALTER TYPE "public"."ocr_job_status" OWNER TO "postgres";


CREATE TYPE "public"."ocr_status" AS ENUM (
    'pending',
    'processing',
    'done',
    'failed'
);


ALTER TYPE "public"."ocr_status" OWNER TO "postgres";


CREATE TYPE "public"."order_event_actor" AS ENUM (
    'system',
    'customer',
    'vendor',
    'admin'
);


ALTER TYPE "public"."order_event_actor" OWNER TO "postgres";


CREATE TYPE "public"."order_event_type" AS ENUM (
    'created',
    'paid',
    'served',
    'cancelled',
    'customer_paid_signal',
    'vendor_nudge',
    'admin_override'
);


ALTER TYPE "public"."order_event_type" OWNER TO "postgres";


CREATE TYPE "public"."order_status" AS ENUM (
    'pending',
    'paid',
    'served',
    'cancelled'
);


ALTER TYPE "public"."order_status" OWNER TO "postgres";


CREATE TYPE "public"."ride_status" AS ENUM (
    'searching',
    'shortlisted',
    'booked',
    'completed',
    'cancelled'
);


ALTER TYPE "public"."ride_status" OWNER TO "postgres";


CREATE TYPE "public"."run_status" AS ENUM (
    'queued',
    'running',
    'succeeded',
    'failed'
);


ALTER TYPE "public"."run_status" OWNER TO "postgres";


CREATE TYPE "public"."session_role" AS ENUM (
    'customer',
    'vendor',
    'admin',
    'system',
    'vendor_manager',
    'vendor_staff'
);


ALTER TYPE "public"."session_role" OWNER TO "postgres";


CREATE TYPE "public"."sub_status" AS ENUM (
    'pending_review',
    'active',
    'expired',
    'rejected'
);


ALTER TYPE "public"."sub_status" OWNER TO "postgres";


CREATE TYPE "public"."vehicle_kind" AS ENUM (
    'moto',
    'sedan',
    'suv',
    'van',
    'truck'
);


ALTER TYPE "public"."vehicle_kind" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."_touch_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  new.updated_at := now();
  return new;
end$$;


ALTER FUNCTION "public"."_touch_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_sub_command"("_action" "text", "_reference" "text", "_actor" "text") RETURNS TABLE("status" "text")
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_status text;
BEGIN
  IF _action IS NULL OR _reference IS NULL THEN
    status := 'invalid';
    RETURN NEXT;
    RETURN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.admin_submissions WHERE reference = _reference) THEN
    INSERT INTO public.admin_submissions (reference, applicant_name)
    VALUES (_reference, NULL)
    ON CONFLICT (reference) DO NOTHING;
  END IF;
  IF _action = 'approve' THEN
    UPDATE public.admin_submissions SET status = 'approved' WHERE reference = _reference;
    v_status := 'approved';
  ELSIF _action = 'reject' THEN
    UPDATE public.admin_submissions SET status = 'rejected' WHERE reference = _reference;
    v_status := 'rejected';
  ELSE
    v_status := 'unknown_action';
  END IF;
  INSERT INTO public.admin_audit_log (actor_wa, action, target, details)
  VALUES (_actor, 'sub_' || _action, _reference, jsonb_build_object('reference', _reference));
  status := v_status;
  RETURN NEXT;
END;
$$;


ALTER FUNCTION "public"."admin_sub_command"("_action" "text", "_reference" "text", "_actor" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_sub_list_pending"("_limit" integer DEFAULT 10) RETURNS TABLE("reference" "text", "name" "text", "submitted_at" timestamp with time zone)
    LANGUAGE "sql"
    AS $$
  SELECT reference, applicant_name, submitted_at
  FROM public.admin_submissions
  WHERE status = 'pending'
  ORDER BY submitted_at ASC
  LIMIT COALESCE(_limit, 10);
$$;


ALTER FUNCTION "public"."admin_sub_list_pending"("_limit" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."agent_doc_search_vec"("_agent_id" "uuid", "_embed" "text", "_top_k" integer DEFAULT 8) RETURNS TABLE("document_id" "uuid", "chunk_index" integer, "content" "text", "score" real, "title" "text", "storage_path" "text")
    LANGUAGE "sql" STABLE
    AS $$
  WITH q AS (SELECT _embed::vector AS v)
  SELECT v.document_id,
         v.chunk_index,
         v.content,
         (1 - (v.embedding <=> q.v))::real AS score,
         d.title,
         d.storage_path
  FROM public.agent_document_vectors v
  JOIN public.agent_documents d ON d.id = v.document_id
  CROSS JOIN q
  WHERE d.agent_id = _agent_id
  ORDER BY v.embedding <=> q.v
  LIMIT GREATEST(1, COALESCE(_top_k, 8));
$$;


ALTER FUNCTION "public"."agent_doc_search_vec"("_agent_id" "uuid", "_embed" "text", "_top_k" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."agent_vectors_summary"() RETURNS TABLE("agent_id" "uuid", "total_docs" integer, "ready_docs" integer, "json_chunks" integer, "vec_chunks" integer)
    LANGUAGE "sql" STABLE
    AS $$
  SELECT d.agent_id::uuid,
         COUNT(*)::int AS total_docs,
         COUNT(*) FILTER (WHERE d.embedding_status = 'ready')::int AS ready_docs,
         (
           SELECT COUNT(*) FROM public.agent_document_embeddings e
           WHERE e.document_id IN (SELECT id FROM public.agent_documents dd WHERE dd.agent_id = d.agent_id)
         )::int AS json_chunks,
         (
           SELECT COUNT(*) FROM public.agent_document_vectors v
           WHERE v.document_id IN (SELECT id FROM public.agent_documents dd WHERE dd.agent_id = d.agent_id)
         )::int AS vec_chunks
  FROM public.agent_documents d
  GROUP BY d.agent_id
$$;


ALTER FUNCTION "public"."agent_vectors_summary"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."audit_log_sync_admin_columns"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  if new.actor_id is not null and (new.actor is null or new.actor = '') then
    new.actor := new.actor_id::text;
  elsif new.actor_id is null and new.actor is not null then
    begin
      new.actor_id := new.actor::uuid;
    exception when others then
      -- leave actor_id null if actor is not a uuid
      null;
    end;
  end if;

  if new.diff is null then
    new.diff := '{}'::jsonb;
  end if;

  return new;
end;
$$;


ALTER FUNCTION "public"."audit_log_sync_admin_columns"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."auth_bar_id"() RETURNS "uuid"
    LANGUAGE "sql" STABLE
    AS $$
  SELECT NULLIF(public.auth_claim('bar_id'), '')::uuid;
$$;


ALTER FUNCTION "public"."auth_bar_id"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."auth_claim"("text") RETURNS "text"
    LANGUAGE "sql" STABLE
    AS $_$
  SELECT COALESCE(current_setting('request.jwt.claim.' || $1, true), '');
$_$;


ALTER FUNCTION "public"."auth_claim"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."auth_customer_id"() RETURNS "uuid"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  RAISE EXCEPTION 'auth_customer_id() is deprecated. Use auth_profile_id().' USING ERRCODE = 'P0001';
  RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."auth_customer_id"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."auth_profile_id"() RETURNS "uuid"
    LANGUAGE "sql"
    AS $$
  SELECT NULLIF(public.auth_claim('profile_id'), '')::uuid;
$$;


ALTER FUNCTION "public"."auth_profile_id"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."auth_role"() RETURNS "text"
    LANGUAGE "sql" STABLE
    AS $$
  SELECT public.auth_claim('role');
$$;


ALTER FUNCTION "public"."auth_role"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."auth_wa_id"() RETURNS "text"
    LANGUAGE "sql" STABLE
    AS $$
  SELECT public.auth_claim('wa_id');
$$;


ALTER FUNCTION "public"."auth_wa_id"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."basket_close"("_profile_id" "uuid", "_basket_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  UPDATE public.baskets
  SET status = 'closed', updated_at = timezone('utc', now())
  WHERE id = _basket_id AND (owner_profile_id = _profile_id OR owner_profile_id IS NULL);
END;
$$;


ALTER FUNCTION "public"."basket_close"("_profile_id" "uuid", "_basket_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."basket_create"("_profile_id" "uuid", "_whatsapp" "text", "_name" "text", "_is_public" boolean, "_goal_minor" integer) RETURNS TABLE("basket_id" "uuid", "share_token" "text", "qr_url" "text")
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_basket_id uuid;
  v_token text;
  v_updated integer;
  v_now timestamptz := timezone('utc', now());
  v_whatsapp text := COALESCE(_whatsapp, '');
BEGIN
  IF _profile_id IS NULL THEN
    RAISE EXCEPTION 'basket_profile_required'
      USING MESSAGE = 'A profile is required to create a basket.';
  END IF;

  v_token := upper(substr(encode(gen_random_bytes(4), 'hex'), 1, 6));

  INSERT INTO public.baskets (
    owner_profile_id,
    owner_whatsapp,
    creator_user_id,
    name,
    is_public,
    goal_minor,
    share_token,
    join_token,
    join_token_revoked,
    status,
    created_at,
    updated_at
  )
  VALUES (
    _profile_id,
    v_whatsapp,
    _profile_id,
    _name,
    COALESCE(_is_public, false),
    _goal_minor,
    v_token,
    v_token,
    false,
    'open',
    v_now,
    v_now
  )
  RETURNING id INTO v_basket_id;

  UPDATE public.basket_members
  SET profile_id = _profile_id,
      user_id = _profile_id,
      whatsapp = v_whatsapp,
      role = 'owner',
      joined_at = v_now,
      joined_via = 'create',
      join_reference = v_token
  WHERE basket_id = v_basket_id
    AND (
      (user_id IS NOT NULL AND user_id = _profile_id)
      OR COALESCE(whatsapp, '') = v_whatsapp
    )
  RETURNING 1 INTO v_updated;

  IF NOT FOUND THEN
    INSERT INTO public.basket_members (
      basket_id,
      profile_id,
      user_id,
      whatsapp,
      role,
      joined_at,
      joined_via,
      join_reference
    )
    VALUES (
      v_basket_id,
      _profile_id,
      _profile_id,
      v_whatsapp,
      'owner',
      v_now,
      'create',
      v_token
    );
  END IF;

  basket_id := v_basket_id;
  share_token := v_token;
  qr_url := 'https://quickchart.io/qr?text=JB:' || v_token;
  RETURN NEXT;
END;
$$;


ALTER FUNCTION "public"."basket_create"("_profile_id" "uuid", "_whatsapp" "text", "_name" "text", "_is_public" boolean, "_goal_minor" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."basket_create"("_profile_id" "uuid", "_whatsapp" "text", "_name" "text", "_is_public" boolean, "_goal_minor" numeric) RETURNS TABLE("basket_id" "uuid", "share_token" "text", "qr_url" "text")
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_basket_id uuid;
  v_token text;
  v_now timestamptz := timezone('utc', now());
BEGIN
  IF _profile_id IS NULL THEN
    RAISE EXCEPTION 'basket_profile_required' USING MESSAGE = 'Profile required';
  END IF;

  v_token := upper(substr(encode(gen_random_bytes(4), 'hex'), 1, 6));

  INSERT INTO public.baskets (
    owner_profile_id,
    owner_whatsapp,
    name,
    is_public,
    goal_minor,
    share_token,
    join_token,
    join_token_revoked,
    status,
    created_at,
    updated_at
  )
  VALUES (
    _profile_id,
    COALESCE(_whatsapp, ''),
    _name,
    COALESCE(_is_public, false),
    _goal_minor,
    v_token,
    v_token,
    false,
    'open',
    v_now,
    v_now
  )
  RETURNING id INTO v_basket_id;

  INSERT INTO public.basket_members (
    basket_id,
    profile_id,
    user_id,
    whatsapp,
    role,
    joined_at,
    joined_via,
    join_reference
  )
  VALUES (
    v_basket_id,
    _profile_id,
    _profile_id,
    COALESCE(_whatsapp, ''),
    'owner',
    v_now,
    'create',
    v_token
  )
  ON CONFLICT DO NOTHING;

  basket_id := v_basket_id;
  share_token := v_token;
  qr_url := 'https://quickchart.io/qr?text=JB:' || v_token;
  RETURN NEXT;
END;
$$;


ALTER FUNCTION "public"."basket_create"("_profile_id" "uuid", "_whatsapp" "text", "_name" "text", "_is_public" boolean, "_goal_minor" numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."basket_detail"("_profile_id" "uuid", "_basket_id" "uuid") RETURNS TABLE("id" "uuid", "name" "text", "status" "text", "member_count" integer, "balance_minor" integer, "goal_minor" integer, "currency" "text", "share_token" "text", "is_owner" boolean, "owner_name" "text", "owner_whatsapp" "text", "last_activity" timestamp with time zone)
    LANGUAGE "sql"
    AS $$
  SELECT b.id,
         b.name,
         b.status,
         (SELECT count(*) FROM public.basket_members bm WHERE bm.basket_id = b.id) AS member_count,
         COALESCE((SELECT sum(amount_minor) FROM public.basket_contributions bc WHERE bc.basket_id = b.id), 0) AS balance_minor,
         b.goal_minor,
         b.currency,
         b.share_token,
         (b.owner_profile_id = _profile_id OR b.owner_whatsapp = public.profile_wa(_profile_id)) AS is_owner,
         (SELECT display_name FROM public.profiles p WHERE p.user_id = b.owner_profile_id) AS owner_name,
         b.owner_whatsapp,
         GREATEST(
           b.updated_at,
           COALESCE((SELECT max(bm.joined_at) FROM public.basket_members bm WHERE bm.basket_id = b.id), b.updated_at),
           COALESCE((SELECT max(bc.created_at) FROM public.basket_contributions bc WHERE bc.basket_id = b.id), b.updated_at)
         ) AS last_activity
  FROM public.baskets b
  WHERE b.id = _basket_id;
$$;


ALTER FUNCTION "public"."basket_detail"("_profile_id" "uuid", "_basket_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."basket_discover_nearby"("_profile_id" "uuid", "_lat" double precision, "_lng" double precision, "_limit" integer DEFAULT 10) RETURNS TABLE("id" "uuid", "name" "text", "description" "text", "distance_km" double precision, "member_count" integer)
    LANGUAGE "sql"
    AS $$
  SELECT b.id,
         b.name,
         b.description,
         CASE
           WHEN b.lat IS NULL OR b.lng IS NULL THEN NULL
           ELSE public.haversine_km(b.lat, b.lng, _lat, _lng)
         END AS distance_km,
         (SELECT count(*) FROM public.basket_members bm WHERE bm.basket_id = b.id) AS member_count
  FROM public.baskets b
  WHERE b.is_public = true AND b.status::text = 'open'
  ORDER BY distance_km NULLS LAST, b.created_at DESC
  LIMIT COALESCE(_limit, 10);
$$;


ALTER FUNCTION "public"."basket_discover_nearby"("_profile_id" "uuid", "_lat" double precision, "_lng" double precision, "_limit" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."basket_generate_qr"("_profile_id" "uuid", "_basket_id" "uuid") RETURNS TABLE("qr_url" "text")
    LANGUAGE "sql"
    AS $$
  SELECT 'https://quickchart.io/qr?text=JB:' || COALESCE(share_token, '') AS qr_url
  FROM public.baskets
  WHERE id = _basket_id;
$$;


ALTER FUNCTION "public"."basket_generate_qr"("_profile_id" "uuid", "_basket_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."basket_join_by_code"("_profile_id" "uuid", "_whatsapp" "text", "_code" "text") RETURNS TABLE("basket_id" "uuid", "basket_name" "text")
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_token text;
  v_contact text := COALESCE(_whatsapp, '');
  v_basket public.baskets;
  v_now timestamptz := timezone('utc', now());
  v_joined public.basket_members;
  v_attempts integer;
BEGIN
  IF _code IS NULL OR length(trim(_code)) < 4 THEN
    RAISE EXCEPTION 'basket_code_invalid'
      USING MESSAGE = 'That join code looks invalid.';
  END IF;

  v_token := upper(regexp_replace(trim(_code), '^JB[:\-]?', ''));
  IF length(v_token) < 4 THEN
    RAISE EXCEPTION 'basket_code_invalid'
      USING MESSAGE = 'That join code looks invalid.';
  END IF;

  SELECT * INTO v_basket
  FROM public.baskets b
  WHERE COALESCE(b.join_token, b.share_token) = v_token
  LIMIT 1;

  IF v_basket.id IS NULL THEN
    RAISE EXCEPTION 'basket_code_not_found'
      USING MESSAGE = 'No basket found for that code.';
  END IF;

  IF COALESCE(v_basket.join_token_revoked, false) THEN
    RAISE EXCEPTION 'basket_code_revoked'
      USING MESSAGE = 'This join code has been revoked.';
  END IF;

  IF v_basket.status IS NULL OR v_basket.status::text <> 'open' THEN
    RAISE EXCEPTION 'basket_not_joinable'
      USING MESSAGE = 'This basket is not accepting new members.';
  END IF;

  SELECT count(*) INTO v_attempts
  FROM public.basket_members bm
  WHERE bm.joined_at >= v_now - interval '5 minutes'
    AND (
      (_profile_id IS NOT NULL AND (bm.profile_id = _profile_id OR bm.user_id = _profile_id))
      OR (v_contact <> '' AND COALESCE(bm.whatsapp, '') = v_contact)
    );

  IF v_attempts >= 5 THEN
    RAISE EXCEPTION 'basket_join_rate_limit'
      USING MESSAGE = 'Too many join attempts. Wait a few minutes and try again.';
  END IF;

  UPDATE public.basket_members
  SET profile_id = COALESCE(_profile_id, profile_id),
      user_id = COALESCE(_profile_id, user_id),
      whatsapp = CASE WHEN v_contact = '' THEN whatsapp ELSE v_contact END,
      role = CASE WHEN role = 'owner' THEN role ELSE 'member' END,
      joined_at = v_now,
      joined_via = 'code',
      join_reference = v_token
  WHERE basket_id = v_basket.id
    AND (
      (_profile_id IS NOT NULL AND (profile_id = _profile_id OR user_id = _profile_id))
      OR (v_contact <> '' AND COALESCE(whatsapp, '') = v_contact)
    )
  RETURNING * INTO v_joined;

  IF NOT FOUND THEN
    INSERT INTO public.basket_members (
      basket_id,
      profile_id,
      user_id,
      whatsapp,
      role,
      joined_at,
      joined_via,
      join_reference
    )
    VALUES (
      v_basket.id,
      _profile_id,
      _profile_id,
      NULLIF(v_contact, ''),
      'member',
      v_now,
      'code',
      v_token
    )
    RETURNING * INTO v_joined;
  END IF;

  basket_id := v_basket.id;
  basket_name := v_basket.name;
  RETURN NEXT;
END;
$$;


ALTER FUNCTION "public"."basket_join_by_code"("_profile_id" "uuid", "_whatsapp" "text", "_code" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."basket_leave"("_profile_id" "uuid", "_basket_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  DELETE FROM public.basket_members
  WHERE basket_id = _basket_id
    AND (profile_id = _profile_id OR (SELECT whatsapp_e164 FROM public.profiles WHERE user_id = _profile_id) = whatsapp);
END;
$$;


ALTER FUNCTION "public"."basket_leave"("_profile_id" "uuid", "_basket_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."basket_list_mine"("_profile_id" "uuid") RETURNS TABLE("id" "uuid", "name" "text", "status" "text", "member_count" integer, "balance_minor" integer, "currency" "text")
    LANGUAGE "sql"
    AS $$
  SELECT b.id,
         b.name,
         b.status,
         (SELECT count(*) FROM public.basket_members bm WHERE bm.basket_id = b.id) AS member_count,
         COALESCE((SELECT sum(amount_minor) FROM public.basket_contributions bc WHERE bc.basket_id = b.id), 0) AS balance_minor,
         b.currency
  FROM public.baskets b
  WHERE EXISTS (
    SELECT 1 FROM public.basket_members m
    WHERE m.basket_id = b.id
      AND (
        (_profile_id IS NOT NULL AND m.profile_id = _profile_id)
        OR (
          COALESCE(public.profile_wa(_profile_id), '') <> ''
          AND m.whatsapp = public.profile_wa(_profile_id)
        )
      )
  );
$$;


ALTER FUNCTION "public"."basket_list_mine"("_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."dashboard_snapshot"() RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  total_baskets bigint;
  active_baskets bigint;
  pending_baskets bigint;
  total_members bigint;
BEGIN
  SELECT count(*) INTO total_baskets FROM public.ibimina;
  SELECT count(*) INTO active_baskets FROM public.ibimina WHERE status = 'active';
  SELECT count(*) INTO pending_baskets FROM public.ibimina WHERE status = 'pending';
  SELECT count(*) INTO total_members FROM public.ibimina_members WHERE status = 'active';

  RETURN jsonb_build_object(
    'kpis', jsonb_build_array(
      jsonb_build_object(
        'label', 'Total Baskets',
        'primaryValue', total_baskets::text,
        'secondaryValue', concat(active_baskets, ' active'),
        'trend', null
      ),
      jsonb_build_object(
        'label', 'Pending Approvals',
        'primaryValue', pending_baskets::text,
        'secondaryValue', null,
        'trend', null
      ),
      jsonb_build_object(
        'label', 'Active Members',
        'primaryValue', total_members::text,
        'secondaryValue', null,
        'trend', null
      )
    ),
    'timeseries', jsonb_build_array()
  );
END;
$$;


ALTER FUNCTION "public"."dashboard_snapshot"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_assert_basket_create_rate_limit"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_owner uuid := NEW.owner_profile_id;
  v_recent_window interval := interval '10 minutes';
  v_daily_limit integer := 10;
  v_recent_limit integer := 3;
  recent_count integer;
  daily_count integer;
BEGIN
  IF v_owner IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT count(*) INTO recent_count
  FROM public.baskets b
  WHERE b.owner_profile_id = v_owner
    AND b.created_at >= timezone('utc', now()) - v_recent_window;

  IF recent_count >= v_recent_limit THEN
    RAISE EXCEPTION 'basket_create_rate_limit'
      USING MESSAGE = 'You are creating baskets too quickly. Try again later.';
  END IF;

  SELECT count(*) INTO daily_count
  FROM public.baskets b
  WHERE b.owner_profile_id = v_owner
    AND b.created_at >= date_trunc('day', timezone('utc', now()));

  IF daily_count >= v_daily_limit THEN
    RAISE EXCEPTION 'basket_create_daily_limit'
      USING MESSAGE = 'You have reached the daily basket creation limit.';
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."fn_assert_basket_create_rate_limit"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_sync_basket_invites_to_baskets"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  active_token text;
BEGIN
  IF TG_OP = 'INSERT' AND NEW.status = 'active' THEN
    UPDATE public.baskets
    SET share_token = NEW.token,
        join_token = NEW.token,
        join_token_revoked = false,
        updated_at = timezone('utc', now())
    WHERE id = NEW.ikimina_id;
    RETURN NEW;
  ELSIF TG_OP = 'UPDATE' THEN
    IF NEW.status = 'active' THEN
      UPDATE public.baskets
      SET share_token = NEW.token,
          join_token = NEW.token,
          join_token_revoked = false,
          updated_at = timezone('utc', now())
      WHERE id = NEW.ikimina_id;
    ELSE
      SELECT token INTO active_token
      FROM public.basket_invites
      WHERE ikimina_id = NEW.ikimina_id
        AND status = 'active'
      ORDER BY created_at DESC
      LIMIT 1;

      IF active_token IS NULL THEN
        UPDATE public.baskets
        SET share_token = NULL,
            join_token = NULL,
            join_token_revoked = true,
            updated_at = timezone('utc', now())
        WHERE id = NEW.ikimina_id;
      ELSE
        UPDATE public.baskets
        SET share_token = active_token,
            join_token = active_token,
            join_token_revoked = false,
            updated_at = timezone('utc', now())
        WHERE id = NEW.ikimina_id;
      END IF;
    END IF;
    RETURN NEW;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."fn_sync_basket_invites_to_baskets"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_sync_basket_members_to_ibimina"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  target_user uuid;
  joined_at_value timestamptz;
BEGIN
  IF TG_OP = 'DELETE' THEN
    UPDATE public.ibimina_members
    SET status = 'removed'
    WHERE id = OLD.id;

    DELETE FROM public.ibimina_committee
    WHERE member_id = OLD.id;

    RETURN OLD;
  END IF;

  target_user := COALESCE(
    NEW.user_id,
    NEW.profile_id,
    (SELECT user_id FROM public.profiles WHERE whatsapp_e164 = NEW.whatsapp LIMIT 1)
  );

  IF target_user IS NULL THEN
    RETURN NEW;
  END IF;

  joined_at_value := COALESCE(NEW.joined_at, timezone('utc', now()));

  INSERT INTO public.ibimina_members (id, ikimina_id, user_id, joined_at, status)
  VALUES (NEW.id, NEW.basket_id, target_user, joined_at_value, 'active')
  ON CONFLICT (id) DO UPDATE
  SET ikimina_id = EXCLUDED.ikimina_id,
      user_id = EXCLUDED.user_id,
      joined_at = EXCLUDED.joined_at,
      status = 'active';

  IF NEW.role = 'owner' THEN
    INSERT INTO public.ibimina_committee (ikimina_id, member_id, role)
    VALUES (NEW.basket_id, NEW.id, 'president')
    ON CONFLICT (ikimina_id, role) DO UPDATE
    SET member_id = EXCLUDED.member_id;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."fn_sync_basket_members_to_ibimina"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_sync_baskets_to_ibimina"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  mapped_status text;
  slug text;
  goal_value numeric(12,2);
BEGIN
  IF TG_OP = 'DELETE' THEN
    UPDATE public.ibimina
    SET status = 'suspended'
    WHERE id = OLD.id;
    RETURN OLD;
  END IF;

  mapped_status := CASE NEW.status
    WHEN 'open' THEN 'active'
    WHEN 'closed' THEN 'suspended'
    ELSE 'pending'
  END;

  slug := COALESCE(NEW.name, 'basket');
  slug := regexp_replace(lower(slug), '[^a-z0-9]+', '-', 'g');
  slug := trim(both '-' FROM slug);
  IF slug = '' THEN
    slug := substr(encode(gen_random_bytes(4), 'hex'), 1, 8);
  END IF;

  goal_value := CASE WHEN NEW.goal_minor IS NULL THEN NULL ELSE NEW.goal_minor::numeric END;

  INSERT INTO public.ibimina (
    id,
    name,
    description,
    slug,
    status,
    created_at,
    owner_profile_id,
    owner_whatsapp,
    is_public,
    goal_minor,
    currency,
    momo_number_or_code
  )
  VALUES (
    NEW.id,
    NEW.name,
    NEW.description,
    slug,
    mapped_status,
    COALESCE(NEW.created_at, timezone('utc', now())),
    NEW.owner_profile_id,
    NEW.owner_whatsapp,
    COALESCE(NEW.is_public, false),
    goal_value,
    COALESCE(NEW.currency, 'RWF'),
    NEW.momo_number_or_code
  )
  ON CONFLICT (id) DO UPDATE
  SET name = EXCLUDED.name,
      description = EXCLUDED.description,
      slug = EXCLUDED.slug,
      status = EXCLUDED.status,
      created_at = EXCLUDED.created_at,
      owner_profile_id = EXCLUDED.owner_profile_id,
      owner_whatsapp = EXCLUDED.owner_whatsapp,
      is_public = EXCLUDED.is_public,
      goal_minor = EXCLUDED.goal_minor,
      currency = EXCLUDED.currency,
      momo_number_or_code = EXCLUDED.momo_number_or_code,
      updated_at = timezone('utc', now());

  INSERT INTO public.ibimina_settings (ikimina_id)
  VALUES (NEW.id)
  ON CONFLICT (ikimina_id) DO NOTHING;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."fn_sync_baskets_to_ibimina"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."gate_pro_feature"("_user_id" "uuid") RETURNS TABLE("access" boolean, "used_credit" boolean, "credits_left" integer)
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_now timestamptz := timezone('utc', now());
  v_initial integer := 30;
  v_row public.mobility_pro_access;
  v_left integer := 0;
BEGIN
  SELECT driver_initial_credits
    INTO v_initial
    FROM public.app_config
    ORDER BY id
    LIMIT 1;
  IF NOT FOUND THEN
    v_initial := 30;
  ELSE
    v_initial := COALESCE(v_initial, 30);
  END IF;

  INSERT INTO public.mobility_pro_access (user_id, credits_left, created_at)
  VALUES (_user_id, v_initial, v_now)
  ON CONFLICT (user_id) DO NOTHING;

  SELECT *
    INTO v_row
    FROM public.mobility_pro_access
    WHERE user_id = _user_id
    FOR UPDATE;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, false, 0;
    RETURN;
  END IF;

  v_left := COALESCE(v_row.credits_left, 0);

  IF v_row.granted_until IS NOT NULL AND v_row.granted_until >= v_now THEN
    RETURN QUERY SELECT true, false, v_left;
    RETURN;
  END IF;

  IF v_left > 0 THEN
    UPDATE public.mobility_pro_access
       SET credits_left = GREATEST(credits_left - 1, 0),
           last_credit_used_at = v_now
     WHERE user_id = _user_id
     RETURNING credits_left INTO v_left;
    RETURN QUERY SELECT true, true, COALESCE(v_left, 0);
    RETURN;
  END IF;

  RETURN QUERY SELECT false, false, v_left;
END;
$$;


ALTER FUNCTION "public"."gate_pro_feature"("_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."generate_order_code"() RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_seq bigint;
BEGIN
  SELECT nextval('public.order_code_seq') INTO v_seq;
  RETURN upper(lpad(to_hex(v_seq), 6, '0'));
END;
$$;


ALTER FUNCTION "public"."generate_order_code"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."haversine_km"("lat1" double precision, "lng1" double precision, "lat2" double precision, "lng2" double precision) RETURNS double precision
    LANGUAGE "sql" IMMUTABLE
    AS $$
  SELECT 2 * 6371 * asin(
    sqrt(
      pow(sin(radians(lat2 - lat1) / 2), 2) +
      cos(radians(lat1)) * cos(radians(lat2)) * pow(sin(radians(lng2 - lng1) / 2), 2)
    )
  );
$$;


ALTER FUNCTION "public"."haversine_km"("lat1" double precision, "lng1" double precision, "lat2" double precision, "lng2" double precision) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."insurance_queue_media"("_profile_id" "uuid", "_wa_id" "text", "_storage_path" "text", "_mime_type" "text", "_caption" "text") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  INSERT INTO public.insurance_media_queue (profile_id, wa_id, storage_path, mime_type, caption)
  VALUES (_profile_id, _wa_id, _storage_path, _mime_type, _caption);
END;
$$;


ALTER FUNCTION "public"."insurance_queue_media"("_profile_id" "uuid", "_wa_id" "text", "_storage_path" "text", "_mime_type" "text", "_caption" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_admin"() RETURNS boolean
    LANGUAGE "sql" STABLE
    AS $$
  SELECT (
    auth.role() = 'service_role'
    OR COALESCE(auth.jwt() ->> 'role', '') = ANY (ARRAY['admin','super_admin','support','data_ops'])
    OR COALESCE(auth.jwt() -> 'app_metadata' ->> 'role', '') = ANY (ARRAY['admin','super_admin','support','data_ops'])
    OR EXISTS (
      SELECT 1
      FROM json_array_elements_text(COALESCE(auth.jwt() -> 'roles', '[]'::json)) AS role(value)
      WHERE role.value = ANY (ARRAY['admin','super_admin','support','data_ops'])
    )
    OR EXISTS (
      SELECT 1
      FROM json_array_elements_text(COALESCE(auth.jwt() -> 'app_metadata' -> 'roles', '[]'::json)) AS role(value)
      WHERE role.value = ANY (ARRAY['admin','super_admin','support','data_ops'])
    )
    OR COALESCE((auth.jwt() -> 'user_roles') ?| ARRAY['admin','super_admin','support','data_ops'], FALSE)
  );
$$;


ALTER FUNCTION "public"."is_admin"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_admin_reader"() RETURNS boolean
    LANGUAGE "sql" STABLE
    AS $$
  SELECT (
    public.is_admin()
    OR COALESCE(auth.jwt() ->> 'role', '') = 'readonly'
    OR COALESCE(auth.jwt() -> 'app_metadata' ->> 'role', '') = 'readonly'
    OR EXISTS (
      SELECT 1
      FROM json_array_elements_text(COALESCE(auth.jwt() -> 'roles', '[]'::json)) AS role(value)
      WHERE role.value = 'readonly'
    )
    OR EXISTS (
      SELECT 1
      FROM json_array_elements_text(COALESCE(auth.jwt() -> 'app_metadata' -> 'roles', '[]'::json)) AS role(value)
      WHERE role.value = 'readonly'
    )
    OR COALESCE((auth.jwt() -> 'user_roles') ? 'readonly', FALSE)
  );
$$;


ALTER FUNCTION "public"."is_admin_reader"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."safe_cast_uuid"(input text) RETURNS uuid
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
DECLARE
  result uuid;
BEGIN
  IF input IS NULL OR length(trim(input)) = 0 THEN
    RETURN NULL;
  END IF;
  BEGIN
    result := trim(input)::uuid;
  EXCEPTION WHEN others THEN
    RETURN NULL;
  END;
  RETURN result;
END;
$$;


ALTER FUNCTION "public"."safe_cast_uuid"(input text) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."station_scope_matches"(target uuid) RETURNS boolean
    LANGUAGE "sql" STABLE
    AS $$
  SELECT target IS NOT NULL AND (
    public.safe_cast_uuid(auth.jwt() ->> 'station_id') = target
    OR EXISTS (
      SELECT 1
      FROM json_array_elements_text(COALESCE(auth.jwt() -> 'station_ids', '[]'::json)) AS payload(value)
      WHERE public.safe_cast_uuid(payload.value) = target
    )
    OR EXISTS (
      SELECT 1
      FROM json_array_elements_text(COALESCE(auth.jwt() -> 'stations', '[]'::json)) AS payload(value)
      WHERE public.safe_cast_uuid(payload.value) = target
    )
  );
$$;


ALTER FUNCTION "public"."station_scope_matches"(target uuid) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."issue_basket_invite_token"("_basket_id" "uuid", "_created_by" "uuid", "_explicit_token" "text" DEFAULT NULL::"text", "_ttl" interval DEFAULT '14 days'::interval) RETURNS TABLE("id" "uuid", "basket_id" "uuid", "token" "text", "expires_at" timestamp with time zone, "created_at" timestamp with time zone, "created_by" "uuid", "used_at" timestamp with time zone)
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_now timestamptz := timezone('utc', now());
  v_expiry timestamptz := v_now + COALESCE(_ttl, interval '14 days');
  v_token text;
  v_record public.basket_invites%ROWTYPE;
  v_creator_member uuid;
BEGIN
  v_token := COALESCE(
    _explicit_token,
    upper(substr(encode(gen_random_bytes(4), 'hex'), 1, 6))
  );

  SELECT m.id INTO v_creator_member
  FROM public.ibimina_members m
  WHERE m.ikimina_id = _basket_id
    AND m.user_id = _created_by
    AND m.status = 'active'
  LIMIT 1;

  INSERT INTO public.basket_invites (
    ikimina_id,
    token,
    issuer_member_id,
    expires_at,
    status
  )
  VALUES (
    _basket_id,
    v_token,
    v_creator_member,
    v_expiry,
    'active'
  )
  RETURNING * INTO v_record;

  UPDATE public.baskets
  SET share_token = v_record.token,
      join_token = v_record.token,
      join_token_revoked = false,
      updated_at = timezone('utc', now())
  WHERE public.baskets.id = _basket_id;

  id := v_record.id;
  basket_id := v_record.ikimina_id;
  token := v_record.token;
  expires_at := v_record.expires_at;
  created_at := v_record.created_at;
  created_by := _created_by;
  used_at := v_record.used_at;
  RETURN NEXT;
END;
$$;


ALTER FUNCTION "public"."issue_basket_invite_token"("_basket_id" "uuid", "_created_by" "uuid", "_explicit_token" "text", "_ttl" interval) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."km"("a" "public"."geography", "b" "public"."geography") RETURNS numeric
    LANGUAGE "sql" IMMUTABLE
    AS $$
  select (st_distance(a,b) / 1000.0)::numeric
$$;


ALTER FUNCTION "public"."km"("a" "public"."geography", "b" "public"."geography") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mark_driver_served"("viewer_e164" "text", "driver_uuid" "uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
begin
  insert into public.served_drivers(viewer_passenger_msisdn, driver_contact_id, expires_at)
  values (viewer_e164, driver_uuid, now() + interval '15 minutes')
  on conflict (viewer_passenger_msisdn, driver_contact_id)
  do update set expires_at = excluded.expires_at, created_at = now();
end;
$$;


ALTER FUNCTION "public"."mark_driver_served"("viewer_e164" "text", "driver_uuid" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mark_passenger_served"("viewer_e164" "text", "trip_uuid" "uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
begin
  insert into public.served_passengers(viewer_driver_msisdn, passenger_trip_id, expires_at)
  values (viewer_e164, trip_uuid, now() + interval '15 minutes')
  on conflict (viewer_driver_msisdn, passenger_trip_id)
  do update set expires_at = excluded.expires_at, created_at = now();
end;
$$;


ALTER FUNCTION "public"."mark_passenger_served"("viewer_e164" "text", "trip_uuid" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mark_served"("_viewer" "text", "_kind" "text", "_target_pk" "text") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
begin
  if _kind = 'driver' then
    insert into public.served_drivers (viewer_passenger_msisdn, driver_contact_id, expires_at)
    values (_viewer, (_target_pk)::uuid, now() + interval '15 minutes')
    on conflict (viewer_passenger_msisdn, driver_contact_id)
    do update set expires_at = excluded.expires_at, created_at = now();

  elsif _kind = 'passenger' then
    insert into public.served_passengers (viewer_driver_msisdn, passenger_trip_id, expires_at)
    values (_viewer, (_target_pk)::uuid, now() + interval '15 minutes')
    on conflict (viewer_driver_msisdn, passenger_trip_id)
    do update set expires_at = excluded.expires_at, created_at = now();

  else
    -- businesses are never served; do nothing
    perform 1;
  end if;
end;
$$;


ALTER FUNCTION "public"."mark_served"("_viewer" "text", "_kind" "text", "_target_pk" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."marketplace_add_business"("_owner" "text", "_name" "text", "_description" "text", "_catalog" "text", "_lat" double precision, "_lng" double precision) RETURNS "uuid"
    LANGUAGE "sql"
    AS $$
  INSERT INTO public.businesses (owner_whatsapp, name, description, catalog_url, lat, lng)
  VALUES (_owner, _name, _description, _catalog, _lat, _lng)
  RETURNING id;
$$;


ALTER FUNCTION "public"."marketplace_add_business"("_owner" "text", "_name" "text", "_description" "text", "_catalog" "text", "_lat" double precision, "_lng" double precision) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."match_agent_document_chunks"("query_embedding" "public"."vector", "target_agent_id" "uuid", "match_count" integer DEFAULT 5, "min_similarity" double precision DEFAULT 0) RETURNS TABLE("chunk_id" "uuid", "document_id" "uuid", "agent_id" "uuid", "document_title" "text", "chunk_index" integer, "content" "text", "similarity" double precision)
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id AS chunk_id,
    c.document_id,
    d.agent_id,
    d.title AS document_title,
    c.chunk_index,
    c.content,
    1 - (c.embedding <=> query_embedding) AS similarity
  FROM public.agent_document_chunks c
  JOIN public.agent_documents d ON d.id = c.document_id
  WHERE d.agent_id = target_agent_id
    AND c.embedding IS NOT NULL
    AND (1 - (c.embedding <=> query_embedding)) >= COALESCE(min_similarity, 0)
  ORDER BY c.embedding <=> query_embedding
  LIMIT LEAST(GREATEST(COALESCE(match_count, 5), 1), 50);
END;
$$;


ALTER FUNCTION "public"."match_agent_document_chunks"("query_embedding" "public"."vector", "target_agent_id" "uuid", "match_count" integer, "min_similarity" double precision) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."match_drivers_for_trip_v2"("_trip_id" "uuid", "_limit" integer DEFAULT 9, "_prefer_dropoff" boolean DEFAULT false, "_radius_m" integer DEFAULT NULL::integer, "_window_days" integer DEFAULT 30) RETURNS TABLE("trip_id" "uuid", "creator_user_id" "uuid", "whatsapp_e164" "text", "ref_code" "text", "distance_km" numeric, "drop_bonus_m" numeric, "pickup_text" "text", "dropoff_text" "text", "matched_at" timestamp with time zone)
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
DECLARE
  base_trip RECORD;
  target_role text;
  window_start timestamptz;
  effective_radius integer;
BEGIN
  SELECT id, role, vehicle_type, pickup, dropoff, pickup_radius_m, dropoff_radius_m, created_at
  INTO base_trip
  FROM public.trips
  WHERE id = _trip_id;

  IF NOT FOUND OR base_trip.pickup IS NULL THEN
    RETURN;
  END IF;

  target_role := CASE WHEN base_trip.role = 'driver' THEN 'passenger' ELSE 'driver' END;
  window_start := timezone('utc', now()) - (_window_days || ' days')::interval;
  effective_radius := COALESCE(_radius_m, base_trip.pickup_radius_m, 20000);

  RETURN QUERY
  SELECT
    t.id,
    t.creator_user_id,
    p.whatsapp_e164,
    public.profile_ref_code(t.creator_user_id) AS ref_code,
    (ST_Distance(t.pickup, base_trip.pickup) / 1000.0)::numeric(10, 3) AS distance_km,
    CASE
      WHEN _prefer_dropoff AND base_trip.dropoff IS NOT NULL AND t.dropoff IS NOT NULL
        THEN ST_Distance(t.dropoff, base_trip.dropoff)
      ELSE NULL
    END AS drop_bonus_m,
    t.pickup_text,
    t.dropoff_text,
    t.created_at AS matched_at
  FROM public.trips t
  JOIN public.profiles p ON p.user_id = t.creator_user_id
  WHERE t.status = 'open'
    AND t.id <> base_trip.id
    AND t.pickup IS NOT NULL
    AND t.role = target_role
    AND t.vehicle_type = base_trip.vehicle_type
    AND t.created_at >= window_start
    AND ST_DWithin(t.pickup, base_trip.pickup, effective_radius)
  ORDER BY
    ST_Distance(t.pickup, base_trip.pickup),
    CASE
      WHEN _prefer_dropoff AND base_trip.dropoff IS NOT NULL AND t.dropoff IS NOT NULL
        THEN ST_Distance(t.dropoff, base_trip.dropoff)
      ELSE NULL
    END,
    t.created_at DESC,
    t.id
  LIMIT _limit;
END;
$$;


ALTER FUNCTION "public"."match_drivers_for_trip_v2"("_trip_id" "uuid", "_limit" integer, "_prefer_dropoff" boolean, "_radius_m" integer, "_window_days" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."match_passengers_for_trip_v2"("_trip_id" "uuid", "_limit" integer DEFAULT 9, "_prefer_dropoff" boolean DEFAULT false, "_radius_m" integer DEFAULT NULL::integer, "_window_days" integer DEFAULT 30) RETURNS TABLE("trip_id" "uuid", "creator_user_id" "uuid", "whatsapp_e164" "text", "ref_code" "text", "distance_km" numeric, "drop_bonus_m" numeric, "pickup_text" "text", "dropoff_text" "text", "matched_at" timestamp with time zone)
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
DECLARE
  base_trip RECORD;
  target_role text;
  window_start timestamptz;
  effective_radius integer;
BEGIN
  SELECT id, role, vehicle_type, pickup, dropoff, pickup_radius_m, dropoff_radius_m, created_at
  INTO base_trip
  FROM public.trips
  WHERE id = _trip_id;

  IF NOT FOUND OR base_trip.pickup IS NULL THEN
    RETURN;
  END IF;

  target_role := CASE WHEN base_trip.role = 'driver' THEN 'passenger' ELSE 'driver' END;
  window_start := timezone('utc', now()) - (_window_days || ' days')::interval;
  effective_radius := COALESCE(_radius_m, base_trip.pickup_radius_m, 20000);

  RETURN QUERY
  SELECT
    t.id,
    t.creator_user_id,
    p.whatsapp_e164,
    public.profile_ref_code(t.creator_user_id) AS ref_code,
    (ST_Distance(t.pickup, base_trip.pickup) / 1000.0)::numeric(10, 3) AS distance_km,
    CASE
      WHEN _prefer_dropoff AND base_trip.dropoff IS NOT NULL AND t.dropoff IS NOT NULL
        THEN ST_Distance(t.dropoff, base_trip.dropoff)
      ELSE NULL
    END AS drop_bonus_m,
    t.pickup_text,
    t.dropoff_text,
    t.created_at AS matched_at
  FROM public.trips t
  JOIN public.profiles p ON p.user_id = t.creator_user_id
  WHERE t.status = 'open'
    AND t.id <> base_trip.id
    AND t.pickup IS NOT NULL
    AND t.role = target_role
    AND t.vehicle_type = base_trip.vehicle_type
    AND t.created_at >= window_start
    AND ST_DWithin(t.pickup, base_trip.pickup, effective_radius)
  ORDER BY
    ST_Distance(t.pickup, base_trip.pickup),
    CASE
      WHEN _prefer_dropoff AND base_trip.dropoff IS NOT NULL AND t.dropoff IS NOT NULL
        THEN ST_Distance(t.dropoff, base_trip.dropoff)
      ELSE NULL
    END,
    t.created_at DESC,
    t.id
  LIMIT _limit;
END;
$$;


ALTER FUNCTION "public"."match_passengers_for_trip_v2"("_trip_id" "uuid", "_limit" integer, "_prefer_dropoff" boolean, "_radius_m" integer, "_window_days" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mobility_buy_subscription"("_user_id" "uuid") RETURNS TABLE("success" boolean, "message" "text", "expires_at" timestamp with time zone, "wallet_balance" integer)
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_now timestamptz := timezone('utc', now());
  v_price numeric(10,2) := 4;
  v_tokens integer := 4;
  v_balance integer;
  v_expires timestamptz;
BEGIN
  INSERT INTO public.mobility_pro_access (user_id, credits_left, created_at)
  VALUES (_user_id, 30, v_now)
  ON CONFLICT (user_id) DO NOTHING;

  SELECT driver_subscription_tokens
    INTO v_price
    FROM public.app_config
    ORDER BY id
    LIMIT 1;
  IF NOT FOUND THEN
    v_price := 4;
  ELSE
    v_price := COALESCE(v_price, 4);
  END IF;

  v_tokens := GREATEST(CEILING(v_price)::integer, 4);

  BEGIN
    SELECT wa.balance_tokens
      INTO v_balance
      FROM public.wallet_apply_delta(
        _user_id,
        -v_tokens,
        'driver_subscription',
        jsonb_build_object('months', 1, 'tokens', v_tokens)
      ) AS wa
      LIMIT 1;
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLERRM LIKE '%wallet_insufficient_tokens%' THEN
        RETURN QUERY SELECT false, 'insufficient_tokens', NULL::timestamptz, NULL::integer;
        RETURN;
      ELSE
        RAISE;
      END IF;
  END;

  UPDATE public.mobility_pro_access
     SET granted_until = GREATEST(COALESCE(granted_until, v_now), v_now) + interval '30 days',
         last_subscription_paid_at = v_now
   WHERE user_id = _user_id
   RETURNING granted_until INTO v_expires;

  RETURN QUERY SELECT true, 'paid', v_expires, v_balance;
END;
$$;


ALTER FUNCTION "public"."mobility_buy_subscription"("_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."nearby_businesses"("_lat" double precision, "_lng" double precision, "_viewer" "text", "_limit" integer DEFAULT 10) RETURNS TABLE("id" "uuid", "owner_whatsapp" "text", "name" "text", "description" "text", "location_text" "text", "distance_km" double precision)
    LANGUAGE "sql"
    AS $$
  SELECT b.id,
         b.owner_whatsapp,
         b.name,
         b.description,
         b.location_text,
         CASE
           WHEN b.lat IS NULL OR b.lng IS NULL THEN NULL
           ELSE public.haversine_km(b.lat, b.lng, _lat, _lng)
         END AS distance_km
  FROM public.businesses b
  WHERE b.is_active = true
  ORDER BY distance_km NULLS LAST, b.created_at DESC
  LIMIT COALESCE(_limit, 10);
$$;


ALTER FUNCTION "public"."nearby_businesses"("_lat" double precision, "_lng" double precision, "_viewer" "text", "_limit" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."nearest_drivers"("p_lat" double precision, "p_lng" double precision, "p_vehicle" "text", "p_limit" integer DEFAULT 8) RETURNS TABLE("driver_id" "uuid", "distance_meters" numeric, "eta_minutes" integer)
    LANGUAGE "sql" STABLE
    AS $$
  select a.driver_id,
         ST_Distance(
           a.loc,
           ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography
         ) as distance_meters,
         null::int as eta_minutes
  from public.driver_availability a
  join public.drivers d on d.id = a.driver_id
  where a.available = true
    and (p_vehicle is null or d.vehicle_type::text = p_vehicle)
  order by ST_Distance(
           a.loc,
           ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography
         ) asc
  limit coalesce(p_limit, 8)
$$;


ALTER FUNCTION "public"."nearest_drivers"("p_lat" double precision, "p_lng" double precision, "p_vehicle" "text", "p_limit" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notifications_sync_admin_columns"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  if new.type is null and new.notification_type is not null then
    new.type := new.notification_type;
  elsif new.type is not null then
    new.notification_type := new.type;
  end if;

  if new.msisdn is null and new.to_wa_id is not null then
    new.msisdn := new.to_wa_id;
  elsif new.msisdn is not null and (new.to_wa_id is null or new.to_wa_id = '') then
    new.to_wa_id := new.msisdn;
  end if;

  if new.to_role is null then
    new.to_role := 'whatsapp';
  end if;

  if new.metadata is null then
    new.metadata := '{}'::jsonb;
  end if;

  return new;
end;
$$;


ALTER FUNCTION "public"."notifications_sync_admin_columns"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."on_menu_publish_refresh"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  PERFORM public.refresh_menu_items_snapshot();
  RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."on_menu_publish_refresh"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."order_events_sync_admin_columns"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  has_event_type boolean := EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'order_events'
      AND column_name = 'event_type'
  );
  has_actor_type boolean := EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'order_events'
      AND column_name = 'actor_type'
  );
BEGIN
  IF has_event_type THEN
    IF NEW.type IS NULL AND NEW.event_type IS NOT NULL THEN
      NEW.type := NEW.event_type::text;
    ELSIF NEW.type IS NOT NULL THEN
      BEGIN
        NEW.event_type := NEW.type::order_event_type;
      EXCEPTION WHEN OTHERS THEN
        NEW.event_type := 'admin_override';
      END;
    END IF;
  END IF;

  IF has_actor_type
     AND NEW.actor_id IS NOT NULL
     AND (NEW.actor_type IS NULL OR NEW.actor_type::text = '') THEN
    NEW.actor_type := 'admin';
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."order_events_sync_admin_columns"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."orders_set_defaults"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  IF NEW.order_code IS NULL OR NEW.order_code = '' THEN
    NEW.order_code := public.generate_order_code();
  END IF;
  IF NEW.created_at IS NULL THEN
    NEW.created_at := timezone('utc', now());
  END IF;
  IF NEW.updated_at IS NULL THEN
    NEW.updated_at := timezone('utc', now());
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."orders_set_defaults"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."orders_sync_admin_columns"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  if new.total is null and new.total_minor is not null then
    new.total := round((new.total_minor::numeric) / 100, 2);
  elsif new.total is not null then
    new.total_minor := round(new.total * 100)::integer;
  end if;
  return new;
end;
$$;


ALTER FUNCTION "public"."orders_sync_admin_columns"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."profile_ref_code"("_profile_id" "uuid") RETURNS "text"
    LANGUAGE "sql"
    AS $$
  SELECT COALESCE(metadata->>'ref_code',
                  upper(substring(md5(COALESCE(whatsapp_e164, '')) FROM 1 FOR 6)))
  FROM public.profiles
  WHERE user_id = _profile_id;
$$;


ALTER FUNCTION "public"."profile_ref_code"("_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."profile_wa"("_profile_id" "uuid") RETURNS "text"
    LANGUAGE "sql" STABLE
    AS $$
  SELECT whatsapp_e164 FROM public.profiles WHERE user_id = _profile_id;
$$;


ALTER FUNCTION "public"."profile_wa"("_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."publish_agent_version"("_agent_id" "uuid", "_version_id" "uuid", "_env" "public"."deploy_env") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  UPDATE public.agent_versions SET published = true WHERE id = _version_id AND agent_id = _agent_id;
  INSERT INTO public.agent_deployments(agent_id, version_id, environment, status)
    VALUES (_agent_id, _version_id, _env, 'active')
  ON CONFLICT (agent_id, environment) DO UPDATE SET version_id = EXCLUDED.version_id, status = 'active';
END;
$$;


ALTER FUNCTION "public"."publish_agent_version"("_agent_id" "uuid", "_version_id" "uuid", "_env" "public"."deploy_env") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."purge_expired_served"() RETURNS integer
    LANGUAGE "sql"
    AS $$
  with d1 as (
    delete from public.served_drivers    where expires_at <= now() returning 1
  ), d2 as (
    delete from public.served_passengers where expires_at <= now() returning 1
  )
  select coalesce((select count(*) from d1),0) + coalesce((select count(*) from d2),0);
$$;


ALTER FUNCTION "public"."purge_expired_served"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."recent_businesses_near"("in_lat" double precision, "in_lng" double precision, "in_category_id" integer, "in_radius_km" numeric, "in_max" integer) RETURNS TABLE("business_id" bigint, "name" "text", "owner_user_id" "uuid", "created_at" timestamp with time zone)
    LANGUAGE "sql" STABLE
    AS $$
  select b.id, b.name, b.owner_user_id, b.created_at
  from businesses b
  where (in_category_id is null or b.category_id = in_category_id)
    and st_dwithin(
      b.location::geography,
      st_setsrid(st_makepoint(in_lng, in_lat), 4326),
      in_radius_km * 1000
    )
  order by b.created_at desc
  limit greatest(in_max, 1);
$$;


ALTER FUNCTION "public"."recent_businesses_near"("in_lat" double precision, "in_lng" double precision, "in_category_id" integer, "in_radius_km" numeric, "in_max" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."recent_drivers_near"("in_lat" double precision, "in_lng" double precision, "in_vehicle_type" "text", "in_radius_km" double precision, "in_max" integer) RETURNS TABLE("ref_code" "text", "whatsapp_e164" "text", "last_seen" timestamp with time zone)
    LANGUAGE "sql"
    AS $$
  SELECT
    public.profile_ref_code(ds.user_id) AS ref_code,
    p.whatsapp_e164,
    ds.last_seen
  FROM public.driver_status ds
  JOIN public.profiles p ON p.user_id = ds.user_id
  WHERE ds.online = true
    AND p.whatsapp_e164 IS NOT NULL
    AND (in_vehicle_type IS NULL OR ds.vehicle_type = in_vehicle_type)
    AND ds.lat IS NOT NULL AND ds.lng IS NOT NULL
    AND (
      in_radius_km IS NULL
      OR public.haversine_km(ds.lat, ds.lng, in_lat, in_lng) <= in_radius_km
    )
  ORDER BY ds.last_seen DESC
  LIMIT COALESCE(in_max, 9);
$$;


ALTER FUNCTION "public"."recent_drivers_near"("in_lat" double precision, "in_lng" double precision, "in_vehicle_type" "text", "in_radius_km" double precision, "in_max" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."recent_drivers_near"("in_lat" double precision, "in_lng" double precision, "in_vehicle_type" "text", "in_radius_km" numeric, "in_max" integer) RETURNS TABLE("ref_code" character, "whatsapp_e164" "text", "last_seen" timestamp with time zone, "user_id" "uuid")
    LANGUAGE "sql" STABLE
    AS $$
  select p.ref_code, p.whatsapp_e164, d.last_seen, d.user_id
  from driver_status d
  join profiles p on p.user_id = d.user_id
  where d.online = true
    and (in_vehicle_type is null or d.vehicle_type = in_vehicle_type)
    and d.location is not null
    and st_dwithin(d.location::geography,
                   st_setsrid(st_makepoint(in_lng, in_lat),4326),
                   in_radius_km * 1000)
  order by d.last_seen desc
  limit greatest(in_max,1);
$$;


ALTER FUNCTION "public"."recent_drivers_near"("in_lat" double precision, "in_lng" double precision, "in_vehicle_type" "text", "in_radius_km" numeric, "in_max" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."recent_passenger_trips_near"("in_lat" double precision, "in_lng" double precision, "in_vehicle_type" "text", "in_radius_km" double precision, "in_max" integer) RETURNS TABLE("trip_id" "uuid", "ref_code" "text", "whatsapp_e164" "text", "created_at" timestamp with time zone)
    LANGUAGE "sql"
    AS $$
  SELECT
    t.id,
    public.profile_ref_code(t.creator_user_id) AS ref_code,
    p.whatsapp_e164,
    t.created_at
  FROM public.trips t
  JOIN public.profiles p ON p.user_id = t.creator_user_id
  WHERE t.role = 'passenger'
    AND p.whatsapp_e164 IS NOT NULL
    AND (in_vehicle_type IS NULL OR t.vehicle_type = in_vehicle_type)
    AND t.pickup_lat IS NOT NULL AND t.pickup_lng IS NOT NULL
    AND (
      in_radius_km IS NULL
      OR public.haversine_km(t.pickup_lat, t.pickup_lng, in_lat, in_lng) <= in_radius_km
    )
  ORDER BY t.created_at DESC
  LIMIT COALESCE(in_max, 9);
$$;


ALTER FUNCTION "public"."recent_passenger_trips_near"("in_lat" double precision, "in_lng" double precision, "in_vehicle_type" "text", "in_radius_km" double precision, "in_max" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."recent_passenger_trips_near"("in_lat" double precision, "in_lng" double precision, "in_vehicle_type" "text", "in_radius_km" numeric, "in_max" integer) RETURNS TABLE("trip_id" bigint, "creator_user_id" "uuid", "created_at" timestamp with time zone)
    LANGUAGE "sql" STABLE
    AS $$
  select t.id, t.creator_user_id, t.created_at
  from trips t
  where t.role='passenger' and t.status='open'
    and (in_vehicle_type is null or t.vehicle_type=in_vehicle_type)
    and st_dwithin(t.pickup::geography,
                   st_setsrid(st_makepoint(in_lng, in_lat),4326),
                   in_radius_km * 1000)
  order by t.created_at desc
  limit greatest(in_max,1);
$$;


ALTER FUNCTION "public"."recent_passenger_trips_near"("in_lat" double precision, "in_lng" double precision, "in_vehicle_type" "text", "in_radius_km" numeric, "in_max" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."refresh_menu_items_snapshot"() RETURNS "void"
    LANGUAGE "sql"
    AS $$
  REFRESH MATERIALIZED VIEW CONCURRENTLY public.menu_items_snapshot;
$$;


ALTER FUNCTION "public"."refresh_menu_items_snapshot"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."round"("value" double precision, "ndigits" integer) RETURNS numeric
    LANGUAGE "sql" IMMUTABLE
    AS $$
  select round((value)::numeric, ndigits);
$$;


ALTER FUNCTION "public"."round"("value" double precision, "ndigits" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.updated_at = timezone('utc', now());
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."set_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."upsert_agent_doc_vector"("_document_id" "uuid", "_chunk_index" integer, "_content" "text", "_embedding_json" "jsonb") RETURNS "void"
    LANGUAGE "sql"
    AS $$
  INSERT INTO public.agent_document_vectors(document_id, chunk_index, content, embedding)
  VALUES (_document_id, _chunk_index, _content, (_embedding_json::text)::vector)
  ON CONFLICT (document_id, chunk_index)
  DO UPDATE SET content = EXCLUDED.content, embedding = EXCLUDED.embedding;
$$;


ALTER FUNCTION "public"."upsert_agent_doc_vector"("_document_id" "uuid", "_chunk_index" integer, "_content" "text", "_embedding_json" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."vouchers_sync_admin_columns"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  if new.code5 is null and new.code_5 is not null then
    new.code5 := upper(new.code_5);
  elsif new.code5 is not null then
    new.code5 := upper(new.code5);
    new.code_5 := new.code5;
  end if;

  if new.amount is null and new.amount_minor is not null then
    new.amount := round((new.amount_minor::numeric) / 100, 2);
  elsif new.amount is not null then
    new.amount_minor := round(new.amount * 100)::integer;
  end if;

  if new.png_url is null and new.image_url is not null then
    new.png_url := new.image_url;
  elsif new.png_url is not null and (new.image_url is distinct from new.png_url) then
    new.image_url := new.png_url;
  end if;

  return new;
end;
$$;


ALTER FUNCTION "public"."vouchers_sync_admin_columns"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."wallet_apply_delta"("p_user_id" "uuid", "p_delta" integer, "p_type" "text" DEFAULT 'adjust'::"text", "p_meta" "jsonb" DEFAULT '{}'::"jsonb") RETURNS TABLE("balance_tokens" integer, "ledger_id" "uuid")
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_current integer := 0;
  v_new_balance integer := 0;
  v_ledger_id uuid := NULL;
  v_direction text;
BEGIN
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = '22004', MESSAGE = 'wallet_apply_delta_missing_user';
  END IF;

  IF p_delta IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = '22004', MESSAGE = 'wallet_apply_delta_missing_delta';
  END IF;

  INSERT INTO public.wallet_accounts (profile_id)
  VALUES (p_user_id)
  ON CONFLICT (profile_id) DO NOTHING;

  INSERT INTO public.wallets (user_id, balance_tokens)
  VALUES (p_user_id, 0)
  ON CONFLICT (user_id) DO NOTHING;

  SELECT tokens INTO v_current
  FROM public.wallet_accounts
  WHERE profile_id = p_user_id
  FOR UPDATE;

  IF v_current IS NULL THEN
    v_current := 0;
  END IF;

  IF p_delta < 0 AND v_current + p_delta < 0 THEN
    RAISE EXCEPTION USING MESSAGE = 'wallet_insufficient_tokens';
  END IF;

  v_new_balance := v_current + p_delta;

  UPDATE public.wallet_accounts
  SET tokens = v_new_balance,
      updated_at = timezone('utc', now())
  WHERE profile_id = p_user_id;

  UPDATE public.wallets
  SET balance_tokens = v_new_balance,
      updated_at = timezone('utc', now())
  WHERE user_id = p_user_id;

  IF p_delta <> 0 THEN
    INSERT INTO public.wallet_ledger (user_id, delta_tokens, type, meta)
    VALUES (
      p_user_id,
      p_delta,
      COALESCE(NULLIF(p_type, ''), 'adjust'),
      COALESCE(p_meta, '{}'::jsonb)
    )
    RETURNING id INTO v_ledger_id;

    v_direction := CASE WHEN p_delta >= 0 THEN 'credit' ELSE 'debit' END;

    INSERT INTO public.wallet_transactions (
      profile_id,
      amount_minor,
      currency,
      direction,
      description,
      occurred_at
    )
    VALUES (
      p_user_id,
      ABS(p_delta),
      'TOK',
      v_direction,
      COALESCE(p_meta->>'description', initcap(replace(COALESCE(p_type, 'adjust'), '_', ' '))),
      timezone('utc', now())
    );
  END IF;

  balance_tokens := v_new_balance;
  ledger_id := v_ledger_id;
  RETURN NEXT;
END;
$$;


ALTER FUNCTION "public"."wallet_apply_delta"("p_user_id" "uuid", "p_delta" integer, "p_type" "text", "p_meta" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."wallet_commission_pay"("_commission_id" "uuid", "_actor_vendor" "uuid") RETURNS TABLE("success" boolean, "message" "text", "vendor_balance" integer)
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_commission public.vendor_commissions%ROWTYPE;
  v_transfer record;
BEGIN
  success := false;
  message := NULL;
  vendor_balance := NULL;

  SELECT *
  INTO v_commission
  FROM public.vendor_commissions
  WHERE id = _commission_id
  FOR UPDATE;

  IF NOT FOUND THEN
    message := 'commission_not_found';
    RETURN NEXT;
    RETURN;
  END IF;

  IF v_commission.vendor_profile_id IS DISTINCT FROM _actor_vendor THEN
    message := 'not_owner';
    RETURN NEXT;
    RETURN;
  END IF;

  IF v_commission.status <> 'due' THEN
    message := 'commission_not_due';
    RETURN NEXT;
    RETURN;
  END IF;

  IF v_commission.broker_profile_id IS NULL THEN
    message := 'missing_broker';
    RETURN NEXT;
    RETURN;
  END IF;

  SELECT *
  INTO v_transfer
  FROM public.wallet_transfer(
    v_commission.vendor_profile_id,
    v_commission.broker_profile_id,
    v_commission.amount_tokens,
    'commission',
    v_commission.metadata || jsonb_build_object('commission_id', v_commission.id)
  );

  UPDATE public.vendor_commissions
  SET status = 'paid',
      paid_at = timezone('utc', now()),
      metadata = metadata || jsonb_build_object(
        'ledger_from', v_transfer.ledger_from,
        'ledger_to', v_transfer.ledger_to
      )
  WHERE id = v_commission.id;

  success := true;
  message := 'paid';
  vendor_balance := v_transfer.from_balance;
  RETURN NEXT;
END;
$$;


ALTER FUNCTION "public"."wallet_commission_pay"("_commission_id" "uuid", "_actor_vendor" "uuid") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."wallet_earn_actions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" "text",
    "description" "text",
    "reward_tokens" integer,
    "referral_code" "text",
    "share_text" "text",
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."wallet_earn_actions" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."wallet_earn_actions"("_profile_id" "uuid", "_limit" integer DEFAULT 10) RETURNS SETOF "public"."wallet_earn_actions"
    LANGUAGE "sql"
    AS $$
  SELECT * FROM public.wallet_earn_actions
  WHERE is_active = true
  ORDER BY created_at DESC
  LIMIT COALESCE(_limit, 10);
$$;


ALTER FUNCTION "public"."wallet_earn_actions"("_profile_id" "uuid", "_limit" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."wallet_momo_topup_credit"("_vendor_id" "uuid", "_amount" integer, "_reference" "text", "_metadata" "jsonb" DEFAULT '{}'::"jsonb") RETURNS TABLE("success" boolean, "message" "text", "vendor_balance" integer)
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_topup_id uuid;
  v_transfer record;
BEGIN
  success := false;
  message := NULL;
  vendor_balance := NULL;

  IF _amount IS NULL OR _amount <= 0 THEN
    message := 'invalid_amount';
    RETURN NEXT;
    RETURN;
  END IF;

  INSERT INTO public.wallet_topups_momo (
    vendor_profile_id,
    amount_tokens,
    momo_reference,
    status,
    metadata
  )
  VALUES (
    _vendor_id,
    _amount,
    NULLIF(_reference, ''),
    'completed',
    COALESCE(_metadata, '{}'::jsonb)
  )
  ON CONFLICT (momo_reference) DO UPDATE
    SET vendor_profile_id = EXCLUDED.vendor_profile_id,
        amount_tokens = EXCLUDED.amount_tokens,
        status = 'completed',
        metadata = EXCLUDED.metadata,
        completed_at = timezone('utc', now())
  RETURNING id INTO v_topup_id;

  SELECT *
  INTO v_transfer
  FROM public.wallet_apply_delta(
    _vendor_id,
    _amount,
    'topup_momo',
    COALESCE(_metadata, '{}'::jsonb) || jsonb_build_object(
      'topup_id', v_topup_id,
      'reference', NULLIF(_reference, '')
    )
  );

  UPDATE public.wallet_topups_momo
  SET completed_at = timezone('utc', now()),
      metadata = metadata || jsonb_build_object('ledger_id', v_transfer.ledger_id)
  WHERE id = v_topup_id;

  success := true;
  message := 'credited';
  vendor_balance := v_transfer.balance_tokens;
  RETURN NEXT;
END;
$$;


ALTER FUNCTION "public"."wallet_momo_topup_credit"("_vendor_id" "uuid", "_amount" integer, "_reference" "text", "_metadata" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."wallet_redeem_execute"("_profile_id" "uuid", "_option_id" "uuid") RETURNS TABLE("success" boolean, "message" "text", "balance_tokens" integer)
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_option public.wallet_redeem_options%ROWTYPE;
  v_balance integer := 0;
  v_ledger uuid := NULL;
  v_cost integer := 0;
BEGIN
  success := false;
  message := NULL;
  balance_tokens := NULL;

  SELECT *
  INTO v_option
  FROM public.wallet_redeem_options
  WHERE id = _option_id
    AND is_active = true;

  IF NOT FOUND THEN
    message := 'reward_not_available';
    RETURN NEXT;
    RETURN;
  END IF;

  v_cost := GREATEST(COALESCE(v_option.cost_tokens, 0), 0);

  BEGIN
    IF v_cost > 0 THEN
      SELECT balance_tokens, ledger_id
      INTO v_balance, v_ledger
      FROM public.wallet_apply_delta(
        _profile_id,
        -v_cost,
        'redeem',
        jsonb_build_object('option_id', _option_id, 'title', v_option.title)
      );
    ELSE
      SELECT balance_tokens, ledger_id
      INTO v_balance, v_ledger
      FROM public.wallet_apply_delta(
        _profile_id,
        0,
        'redeem',
        jsonb_build_object('option_id', _option_id, 'title', v_option.title)
      );
    END IF;
  EXCEPTION
    WHEN others THEN
      IF SQLERRM LIKE '%wallet_insufficient_tokens%' THEN
        message := 'insufficient_tokens';
        RETURN NEXT;
        RETURN;
      ELSE
        RAISE;
      END IF;
  END;

  INSERT INTO public.wallet_redemptions (
    profile_id,
    option_id,
    cost_tokens,
    status,
    metadata
  )
  VALUES (
    _profile_id,
    _option_id,
    v_cost,
    'requested',
    jsonb_build_object(
      'ledger_id', v_ledger,
      'option_title', v_option.title,
      'option_description', v_option.description
    )
  );

  success := true;
  message := 'requested';
  balance_tokens := COALESCE(v_balance, 0);
  RETURN NEXT;
END;
$$;


ALTER FUNCTION "public"."wallet_redeem_execute"("_profile_id" "uuid", "_option_id" "uuid") OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."wallet_redeem_options" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" "text",
    "description" "text",
    "cost_tokens" integer,
    "instructions" "text",
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."wallet_redeem_options" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."wallet_redeem_options"("_profile_id" "uuid") RETURNS SETOF "public"."wallet_redeem_options"
    LANGUAGE "sql"
    AS $$
  SELECT * FROM public.wallet_redeem_options WHERE is_active = true ORDER BY created_at DESC;
$$;


ALTER FUNCTION "public"."wallet_redeem_options"("_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."wallet_summary"("_profile_id" "uuid") RETURNS TABLE("balance_minor" integer, "pending_minor" integer, "currency" "text", "tokens" integer)
    LANGUAGE "sql"
    AS $$
  SELECT
    COALESCE(acc.balance_minor, 0) AS balance_minor,
    COALESCE(acc.pending_minor, 0) AS pending_minor,
    COALESCE(acc.currency, 'RWF') AS currency,
    COALESCE(w.balance_tokens, acc.tokens, 0) AS tokens
  FROM public.profiles p
  LEFT JOIN public.wallet_accounts acc ON acc.profile_id = p.user_id
  LEFT JOIN public.wallets w ON w.user_id = p.user_id
  WHERE p.user_id = _profile_id;
$$;


ALTER FUNCTION "public"."wallet_summary"("_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."wallet_top_promoters"("_limit" integer DEFAULT 9) RETURNS TABLE("display_name" "text", "whatsapp" "text", "tokens" integer)
    LANGUAGE "sql"
    AS $$
  SELECT
    COALESCE(
      p.metadata->>'display_name',
      p.metadata->>'name',
      p.whatsapp_e164
    ) AS display_name,
    p.whatsapp_e164 AS whatsapp,
    COALESCE(w.balance_tokens, acc.tokens, 0) AS tokens
  FROM public.profiles p
  LEFT JOIN public.wallet_accounts acc ON acc.profile_id = p.user_id
  LEFT JOIN public.wallets w ON w.user_id = p.user_id
  WHERE COALESCE(w.balance_tokens, acc.tokens, 0) > 0
  ORDER BY COALESCE(w.balance_tokens, acc.tokens, 0) DESC, p.updated_at DESC
  LIMIT COALESCE(_limit, 9);
$$;


ALTER FUNCTION "public"."wallet_top_promoters"("_limit" integer) OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."wallet_transactions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "profile_id" "uuid",
    "amount_minor" integer NOT NULL,
    "currency" "text" DEFAULT 'RWF'::"text" NOT NULL,
    "direction" "text" DEFAULT 'credit'::"text" NOT NULL,
    "description" "text",
    "occurred_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."wallet_transactions" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."wallet_transactions_recent"("_profile_id" "uuid", "_limit" integer DEFAULT 5) RETURNS SETOF "public"."wallet_transactions"
    LANGUAGE "sql"
    AS $$
  SELECT * FROM public.wallet_transactions
  WHERE profile_id = _profile_id
  ORDER BY occurred_at DESC
  LIMIT COALESCE(_limit, 5);
$$;


ALTER FUNCTION "public"."wallet_transactions_recent"("_profile_id" "uuid", "_limit" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."wallet_transfer"("p_from" "uuid", "p_to" "uuid", "p_amount" integer, "p_reason" "text" DEFAULT 'transfer'::"text", "p_meta" "jsonb" DEFAULT '{}'::"jsonb") RETURNS TABLE("from_balance" integer, "to_balance" integer, "ledger_from" "uuid", "ledger_to" "uuid")
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_from record;
  v_to record;
  v_reason text := COALESCE(NULLIF(p_reason, ''), 'transfer');
  v_meta jsonb := COALESCE(p_meta, '{}'::jsonb);
BEGIN
  IF p_from IS NULL OR p_to IS NULL THEN
    RAISE EXCEPTION USING MESSAGE = 'wallet_transfer_missing_actor';
  END IF;
  IF p_from = p_to THEN
    RAISE EXCEPTION USING MESSAGE = 'wallet_transfer_same_actor';
  END IF;
  IF p_amount IS NULL OR p_amount <= 0 THEN
    RAISE EXCEPTION USING MESSAGE = 'wallet_transfer_invalid_amount';
  END IF;

  SELECT *
  INTO v_from
  FROM public.wallet_apply_delta(
    p_from,
    -p_amount,
    v_reason,
    v_meta || jsonb_build_object('direction', 'out', 'target_profile_id', p_to)
  );

  SELECT *
  INTO v_to
  FROM public.wallet_apply_delta(
    p_to,
    p_amount,
    v_reason,
    v_meta || jsonb_build_object('direction', 'in', 'source_profile_id', p_from)
  );

  from_balance := v_from.balance_tokens;
  to_balance := v_to.balance_tokens;
  ledger_from := v_from.ledger_id;
  ledger_to := v_to.ledger_id;
  RETURN NEXT;
END;
$$;


ALTER FUNCTION "public"."wallet_transfer"("p_from" "uuid", "p_to" "uuid", "p_amount" integer, "p_reason" "text", "p_meta" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."wallet_vendor_summary"("_vendor_id" "uuid") RETURNS TABLE("tokens" integer, "pending_commissions_tokens" integer, "pending_commissions_count" integer, "recent" "jsonb")
    LANGUAGE "sql"
    AS $$
  SELECT
    COALESCE(w.balance_tokens, acc.tokens, 0) AS tokens,
    COALESCE(comm.total_tokens, 0) AS pending_commissions_tokens,
    COALESCE(comm.pending_count, 0) AS pending_commissions_count,
    COALESCE(tx.recent, '[]'::jsonb) AS recent
  FROM public.profiles p
  LEFT JOIN public.wallets w ON w.user_id = p.user_id
  LEFT JOIN public.wallet_accounts acc ON acc.profile_id = p.user_id
LEFT JOIN LATERAL (
  SELECT
    SUM(vc.amount_tokens) AS total_tokens,
    COUNT(*) AS pending_count
  FROM public.vendor_commissions vc
  WHERE vc.vendor_profile_id = p.user_id
    AND vc.status = 'due'
) comm ON true
LEFT JOIN LATERAL (
  SELECT jsonb_agg(jsonb_build_object(
      'id', t.id,
      'amount', t.amount_minor,
      'currency', t.currency,
      'direction', t.direction,
      'description', t.description,
      'occurred_at', t.occurred_at
    )) AS recent
  FROM (
    SELECT
      wt.id,
      wt.amount_minor,
      wt.currency,
      wt.direction,
      wt.description,
      wt.occurred_at
    FROM public.wallet_transactions wt
    WHERE wt.profile_id = p.user_id
    ORDER BY wt.occurred_at DESC
    LIMIT 5
  ) t
) tx ON true
  WHERE p.user_id = _vendor_id;
$$;


ALTER FUNCTION "public"."wallet_vendor_summary"("_vendor_id" "uuid") OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."admin_alert_prefs" (
    "wa_id" "text" NOT NULL,
    "want_alerts" boolean DEFAULT true NOT NULL,
    "channels" "text"[] DEFAULT ARRAY['whatsapp'::"text"] NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "admin_user_id" "uuid",
    "alert_key" "text",
    "enabled" boolean DEFAULT true NOT NULL
);


ALTER TABLE "public"."admin_alert_prefs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."admin_audit_log" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "actor_wa" "text",
    "action" "text" NOT NULL,
    "target" "text",
    "details" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "admin_user_id" "uuid",
    "target_id" "text",
    "before" "jsonb",
    "after" "jsonb",
    "reason" "text"
);


ALTER TABLE "public"."admin_audit_log" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."admin_pin_sessions" (
    "session_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "wa_id" "text" NOT NULL,
    "unlocked_until" timestamp with time zone NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."admin_pin_sessions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."admin_sessions" (
    "wa_id" "text" NOT NULL,
    "pin_ok_until" timestamp with time zone,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."admin_sessions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."admin_submissions" (
    "reference" "text" NOT NULL,
    "applicant_name" "text",
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "submitted_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."admin_submissions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."agent_chat_messages" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "session_id" "uuid" NOT NULL,
    "role" "text" NOT NULL,
    "content" "jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "agent_chat_messages_role_check" CHECK (("role" = ANY (ARRAY['user'::"text", 'agent'::"text", 'system'::"text"])))
);


ALTER TABLE "public"."agent_chat_messages" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."agent_chat_sessions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "profile_id" "uuid",
    "agent_kind" "text" NOT NULL,
    "status" "text" DEFAULT 'open'::"text" NOT NULL,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "last_user_message" "text",
    "last_agent_message" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."agent_chat_sessions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."agent_deployments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "agent_id" "uuid" NOT NULL,
    "version_id" "uuid" NOT NULL,
    "environment" "public"."deploy_env" NOT NULL,
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."agent_deployments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."agent_document_chunks" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "document_id" "uuid" NOT NULL,
    "chunk_index" integer NOT NULL,
    "content" "text" NOT NULL,
    "embedding" "public"."vector"(1536),
    "token_count" integer,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."agent_document_chunks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."agent_document_embeddings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "document_id" "uuid" NOT NULL,
    "chunk_index" integer NOT NULL,
    "content" "text" NOT NULL,
    "embedding" "jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."agent_document_embeddings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."agent_document_vectors" (
    "document_id" "uuid" NOT NULL,
    "chunk_index" integer NOT NULL,
    "content" "text" NOT NULL,
    "embedding" "public"."vector"(1536) NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."agent_document_vectors" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."agent_documents" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "agent_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "source_url" "text",
    "storage_path" "text",
    "embedding_status" "public"."ingest_status" DEFAULT 'pending'::"public"."ingest_status" NOT NULL,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."agent_documents" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."agent_personas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "summary" "text",
    "status" "public"."agent_status" DEFAULT 'draft'::"public"."agent_status" NOT NULL,
    "default_language" "text" DEFAULT 'en'::"text",
    "tags" "text"[] DEFAULT '{}'::"text"[],
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."agent_personas" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."agent_runs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "agent_id" "uuid" NOT NULL,
    "version_id" "uuid",
    "input" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "output" "jsonb",
    "status" "public"."run_status" DEFAULT 'queued'::"public"."run_status" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."agent_runs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."agent_tasks" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "agent_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "status" "text" DEFAULT 'open'::"text" NOT NULL,
    "payload" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_by" "uuid",
    "assigned_to" "uuid",
    "due_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."agent_tasks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."agent_toolkits" (
    "agent_kind" "text" NOT NULL,
    "model" "text" DEFAULT 'gpt-5'::"text" NOT NULL,
    "reasoning_effort" "text" DEFAULT 'medium'::"text" NOT NULL,
    "text_verbosity" "text" DEFAULT 'medium'::"text" NOT NULL,
    "web_search_enabled" boolean DEFAULT false NOT NULL,
    "web_search_allowed_domains" "text"[],
    "web_search_user_location" "jsonb",
    "file_search_enabled" boolean DEFAULT false NOT NULL,
    "file_vector_store_id" "text",
    "file_search_max_results" integer,
    "retrieval_enabled" boolean DEFAULT false NOT NULL,
    "retrieval_vector_store_id" "text",
    "retrieval_max_results" integer,
    "retrieval_rewrite" boolean DEFAULT true NOT NULL,
    "image_generation_enabled" boolean DEFAULT false NOT NULL,
    "image_preset" "jsonb",
    "allowed_tools" "jsonb",
    "suggestions" "text"[] DEFAULT ARRAY[]::"text"[],
    "streaming_partial_images" integer,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "agent_toolkits_reasoning_effort_check" CHECK (("reasoning_effort" = ANY (ARRAY['minimal'::"text", 'low'::"text", 'medium'::"text", 'high'::"text"]))),
    CONSTRAINT "agent_toolkits_text_verbosity_check" CHECK (("text_verbosity" = ANY (ARRAY['low'::"text", 'medium'::"text", 'high'::"text"])))
);


ALTER TABLE "public"."agent_toolkits" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."agent_versions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "agent_id" "uuid" NOT NULL,
    "version" integer NOT NULL,
    "instructions" "text",
    "tools" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "published" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."agent_versions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."app_config" (
    "id" integer DEFAULT 1 NOT NULL,
    "insurance_admin_numbers" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "tokens_per_referral" integer DEFAULT 10 NOT NULL,
    "referral_daily_cap" integer DEFAULT 0 NOT NULL,
    "welcome_bonus_tokens" integer DEFAULT 0 NOT NULL,
    "wallet_redeem_catalog" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "referral_short_domain" "text",
    "referral_redeem_rules" "text",
    "openai_api_key" "text",
    "search_radius_km" double precision DEFAULT 10,
    "max_results" integer DEFAULT 9,
    "subscription_price" numeric(10,2) DEFAULT 0,
    "wa_bot_number_e164" "text",
    "admin_numbers" "text"[] DEFAULT ARRAY[]::"text"[],
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "momo_qr_logo_url" "text",
    "redeem_catalog" "jsonb",
    "admin_pin_required" boolean DEFAULT false NOT NULL,
    "admin_pin_hash" "text",
    "driver_initial_credits" integer DEFAULT 30 NOT NULL,
    "driver_subscription_tokens" numeric(10,2) DEFAULT 4 NOT NULL
);


ALTER TABLE "public"."app_config" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."audit_log" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "actor" "text",
    "actor_type" "text",
    "action" "text" NOT NULL,
    "target_table" "text",
    "target_id" "text",
    "diff" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "actor_id" "uuid"
);


ALTER TABLE "public"."audit_log" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."bar_numbers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "bar_id" "uuid" NOT NULL,
    "number_e164" "text" NOT NULL,
    "role" "public"."bar_contact_role" DEFAULT 'staff'::"public"."bar_contact_role" NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "verified_at" timestamp with time zone,
    "added_by" "text",
    "last_seen_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "verification_code_hash" "text",
    "verification_expires_at" timestamp with time zone,
    "verification_attempts" integer DEFAULT 0 NOT NULL,
    "invited_at" timestamp with time zone
);


ALTER TABLE "public"."bar_numbers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."bar_settings" (
    "bar_id" "uuid" NOT NULL,
    "allow_direct_customer_chat" boolean DEFAULT false NOT NULL,
    "order_auto_ack" boolean DEFAULT false NOT NULL,
    "default_prep_minutes" integer DEFAULT 0 NOT NULL,
    "service_charge_pct" numeric(5,2) DEFAULT 0 NOT NULL,
    "payment_instructions" "text",
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    CONSTRAINT "bar_settings_default_prep_minutes_check" CHECK ((("default_prep_minutes" >= 0) AND ("default_prep_minutes" <= 240))),
    CONSTRAINT "bar_settings_service_charge_pct_check" CHECK ((("service_charge_pct" >= (0)::numeric) AND ("service_charge_pct" <= (25)::numeric)))
);


ALTER TABLE "public"."bar_settings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."bar_tables" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "bar_id" "uuid" NOT NULL,
    "label" "text" NOT NULL,
    "qr_payload" "text" NOT NULL,
    "token_nonce" "text",
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "last_scan_at" timestamp with time zone
);


ALTER TABLE "public"."bar_tables" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."bars" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "slug" "text" NOT NULL,
    "name" "text" NOT NULL,
    "location_text" "text",
    "country" "text",
    "city_area" "text",
    "currency" "text",
    "momo_code" "text",
    "is_active" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."bars" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."basket_contributions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "basket_id" "uuid" NOT NULL,
    "contributor_user_id" "uuid" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "approved_at" timestamp with time zone,
    "approver_user_id" "uuid",
    "wa_message_id" "text",
    "amount_minor" bigint NOT NULL,
    "currency" "text" DEFAULT 'RWF'::"text" NOT NULL,
    "momo_reference" "text",
    "source" "text",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "profile_id" "uuid",
    CONSTRAINT "basket_contributions_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'approved'::"text", 'rejected'::"text"])))
);

ALTER TABLE ONLY "public"."basket_contributions" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."basket_contributions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."basket_invites" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ikimina_id" "uuid" NOT NULL,
    "token" "text" NOT NULL,
    "issuer_member_id" "uuid",
    "expires_at" timestamp with time zone NOT NULL,
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "used_at" timestamp with time zone
);


ALTER TABLE "public"."basket_invites" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."basket_members" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "basket_id" "uuid" NOT NULL,
    "profile_id" "uuid",
    "user_id" "uuid",
    "whatsapp" "text",
    "role" "text" DEFAULT 'member'::"text" NOT NULL,
    "joined_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "joined_via" "text",
    "join_reference" "text"
);

ALTER TABLE ONLY "public"."basket_members" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."basket_members" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."baskets" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "owner_profile_id" "uuid",
    "owner_whatsapp" "text",
    "name" "text" NOT NULL,
    "description" "text",
    "status" "text" DEFAULT 'open'::"text" NOT NULL,
    "currency" "text" DEFAULT 'RWF'::"text" NOT NULL,
    "goal_minor" numeric(12,2),
    "is_public" boolean DEFAULT false NOT NULL,
    "share_token" "text",
    "join_token" "text",
    "join_token_revoked" boolean DEFAULT false NOT NULL,
    "momo_number_or_code" "text",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);

ALTER TABLE ONLY "public"."baskets" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."baskets" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."baskets_reminder_events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "reminder_id" "uuid" NOT NULL,
    "event" "text" DEFAULT 'scheduled'::"text" NOT NULL,
    "reason" "text",
    "context" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "baskets_reminder_events_event_check" CHECK (("event" = ANY (ARRAY['scheduled'::"text", 'queued'::"text", 'sent'::"text", 'blocked'::"text", 'skipped'::"text", 'rescheduled'::"text", 'cancelled'::"text"])))
);


ALTER TABLE "public"."baskets_reminder_events" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."baskets_reminders" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ikimina_id" "uuid",
    "member_id" "uuid",
    "notification_id" "uuid",
    "reminder_type" "text" DEFAULT 'due_in_3'::"text" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "scheduled_for" timestamp with time zone,
    "next_attempt_at" timestamp with time zone,
    "attempts" integer DEFAULT 0 NOT NULL,
    "last_attempt_at" timestamp with time zone,
    "blocked_reason" "text",
    "meta" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "baskets_reminders_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'queued'::"text", 'sent'::"text", 'skipped'::"text", 'blocked'::"text", 'cancelled'::"text"]))),
    CONSTRAINT "baskets_reminders_type_check" CHECK (("reminder_type" = ANY (ARRAY['due_in_3'::"text", 'due_today'::"text", 'overdue'::"text", 'custom'::"text"])))
);


ALTER TABLE "public"."baskets_reminders" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."businesses" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "owner_whatsapp" "text" NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "geo" "public"."geography"(Point,4326),
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "category_id" bigint,
    "catalog_url" "text",
    "location_text" "text",
    "lat" double precision,
    "lng" double precision,
    "owner_user_id" "uuid",
    "location" "public"."geography"(Point,4326),
    "status" "text",
    CONSTRAINT "businesses_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'approved'::"text", 'hidden'::"text"])))
);


ALTER TABLE "public"."businesses" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."call_consents" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "call_id" "uuid",
    "consent_text" "text",
    "consent_result" boolean,
    "audio_url" "text",
    "t" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."call_consents" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."campaign_recipients" (
    "id" bigint NOT NULL,
    "contact_id" bigint,
    "msisdn_e164" "text" NOT NULL,
    "send_allowed" boolean DEFAULT true,
    "window_24h_open" boolean DEFAULT false,
    "campaign_id" "uuid" NOT NULL
);


ALTER TABLE "public"."campaign_recipients" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."campaign_recipients_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."campaign_recipients_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."campaign_recipients_id_seq" OWNED BY "public"."campaign_recipients"."id";



CREATE TABLE IF NOT EXISTS "public"."campaign_targets" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "campaign_id" "uuid" NOT NULL,
    "msisdn" "text" NOT NULL,
    "user_id" "uuid",
    "personalized_vars" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "status" "text" DEFAULT 'queued'::"text" NOT NULL,
    "error_code" "text",
    "message_id" "text",
    "last_update_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."campaign_targets" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."campaigns" (
    "legacy_id" bigint NOT NULL,
    "status" "text" DEFAULT 'draft'::"text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "template_id" "text" DEFAULT 'custom_text'::"text" NOT NULL,
    "name" "text" NOT NULL,
    "type" "text" DEFAULT 'promo'::"text" NOT NULL,
    "created_by" "uuid",
    "started_at" timestamp with time zone,
    "finished_at" timestamp with time zone,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "title" "text",
    "message_kind" "text",
    "payload" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "target_audience" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "time_zone" "text",
    CONSTRAINT "campaigns_status_check" CHECK (("status" = ANY (ARRAY['draft'::"text", 'running'::"text", 'paused'::"text", 'done'::"text", 'SENDING'::"text", 'SCHEDULED'::"text", 'SENT'::"text", 'FAILED'::"text"]))),
    CONSTRAINT "campaigns_type_check" CHECK (("type" = ANY (ARRAY['promo'::"text", 'voucher'::"text"])))
);


ALTER TABLE "public"."campaigns" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."campaigns_legacy_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."campaigns_legacy_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."campaigns_legacy_id_seq" OWNED BY "public"."campaigns"."legacy_id";



CREATE TABLE IF NOT EXISTS "public"."cart_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "cart_id" "uuid" NOT NULL,
    "item_id" "uuid",
    "item_name" "text" NOT NULL,
    "item_snapshot" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "qty" integer NOT NULL,
    "unit_price_minor" integer NOT NULL,
    "flags_snapshot" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "modifiers_snapshot" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "line_total_minor" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    CONSTRAINT "cart_items_line_total_minor_check" CHECK (("line_total_minor" >= 0)),
    CONSTRAINT "cart_items_qty_check" CHECK (("qty" >= 1)),
    CONSTRAINT "cart_items_unit_price_minor_check" CHECK (("unit_price_minor" >= 0))
);


ALTER TABLE "public"."cart_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."carts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "bar_id" "uuid" NOT NULL,
    "table_label" "text",
    "status" "public"."cart_status" DEFAULT 'open'::"public"."cart_status" NOT NULL,
    "subtotal_minor" integer DEFAULT 0 NOT NULL,
    "service_charge_minor" integer DEFAULT 0 NOT NULL,
    "total_minor" integer DEFAULT 0 NOT NULL,
    "expires_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "profile_id" "uuid" NOT NULL
);


ALTER TABLE "public"."carts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."categories" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "bar_id" "uuid" NOT NULL,
    "menu_id" "uuid" NOT NULL,
    "parent_category_id" "uuid",
    "name" "text" NOT NULL,
    "sort_order" integer DEFAULT 0 NOT NULL,
    "is_deleted" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."categories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."chat_sessions" (
    "user_id" "text" NOT NULL,
    "state" "jsonb",
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."chat_sessions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."chat_state" (
    "user_id" "uuid" NOT NULL,
    "state" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "state_key" "text"
);


ALTER TABLE "public"."chat_state" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."contacts" (
    "id" bigint NOT NULL,
    "msisdn_e164" "text" NOT NULL,
    "full_name" "text",
    "sector" "text",
    "city" "text",
    "tags" "text"[] DEFAULT '{}'::"text"[],
    "attributes" "jsonb" DEFAULT '{}'::"jsonb",
    "opted_in" boolean DEFAULT false NOT NULL,
    "opt_in_source" "text",
    "opt_in_ts" timestamp with time zone,
    "opted_out" boolean DEFAULT false NOT NULL,
    "opt_out_ts" timestamp with time zone,
    "last_inbound_ts" timestamp with time zone,
    "last_inbound_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()),
    "profile_id" "uuid"
);


ALTER TABLE "public"."contacts" OWNER TO "postgres";


COMMENT ON COLUMN "public"."contacts"."profile_id" IS 'Optional reference to profiles.user_id for opt-in contacts (Phase 1).';



CREATE SEQUENCE IF NOT EXISTS "public"."contacts_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."contacts_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."contacts_id_seq" OWNED BY "public"."contacts"."id";



CREATE TABLE IF NOT EXISTS "public"."contributions_ledger" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ikimina_id" "uuid" NOT NULL,
    "member_id" "uuid",
    "amount" numeric(12,2) NOT NULL,
    "currency" "text" DEFAULT 'RWF'::"text" NOT NULL,
    "cycle_yyyymm" character(6),
    "txn_id" "text",
    "allocated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "source" "text" DEFAULT 'admin'::"text" NOT NULL,
    "meta" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL
);


ALTER TABLE "public"."contributions_ledger" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."conversations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "channel" "text" DEFAULT 'whatsapp'::"text" NOT NULL,
    "role" "text" NOT NULL,
    "contact_id" "uuid",
    "driver_id" "uuid",
    "wa_thread_id" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "metadata" "jsonb" DEFAULT '{}'::"jsonb"
);


ALTER TABLE "public"."conversations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."driver_availability" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "driver_id" "uuid",
    "at" timestamp with time zone DEFAULT "now"(),
    "available" boolean DEFAULT true,
    "loc" "public"."geography"(Point,4326) NOT NULL
);


ALTER TABLE "public"."driver_availability" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."driver_presence" (
    "user_id" "uuid" NOT NULL,
    "vehicle_type" "text" NOT NULL,
    "lat" numeric,
    "lng" numeric,
    "last_seen" timestamp with time zone DEFAULT "now"() NOT NULL,
    "ref_code" "text",
    "whatsapp_e164" "text"
);


ALTER TABLE "public"."driver_presence" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."driver_status" (
    "user_id" "uuid" NOT NULL,
    "vehicle_type" "text",
    "location" "public"."geography"(Point,4326),
    "last_seen" timestamp with time zone,
    "online" boolean DEFAULT true,
    "lat" double precision,
    "lng" double precision,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."driver_status" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."drivers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "phone_e164" "text" NOT NULL,
    "display_name" "text",
    "vehicle_type" "public"."vehicle_kind",
    "vehicle_desc" "text",
    "rating" numeric DEFAULT 4.3,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."drivers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."flow_submissions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "flow_id" "text" NOT NULL,
    "screen_id" "text",
    "action_id" "text",
    "wa_id" "text",
    "payload" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "received_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."flow_submissions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ibimina" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "sacco_id" "uuid",
    "name" "text" NOT NULL,
    "description" "text",
    "slug" "text" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "owner_profile_id" "uuid",
    "owner_whatsapp" "text",
    "is_public" boolean DEFAULT false NOT NULL,
    "goal_minor" numeric(12,2),
    "currency" "text" DEFAULT 'RWF'::"text" NOT NULL,
    "momo_number_or_code" "text",
    "lat" double precision,
    "lng" double precision,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."ibimina" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ibimina_accounts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ikimina_id" "uuid" NOT NULL,
    "sacco_account_number" "text" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."ibimina_accounts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ibimina_committee" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ikimina_id" "uuid" NOT NULL,
    "member_id" "uuid" NOT NULL,
    "role" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."ibimina_committee" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ibimina_members" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ikimina_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "joined_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL
);


ALTER TABLE "public"."ibimina_members" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ibimina_settings" (
    "ikimina_id" "uuid" NOT NULL,
    "contribution_type" "text" DEFAULT 'fixed'::"text" NOT NULL,
    "periodicity" "text" DEFAULT 'monthly'::"text" NOT NULL,
    "min_amount" numeric(12,2) DEFAULT 0 NOT NULL,
    "due_day" integer,
    "reminder_policy" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "quorum" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."ibimina_settings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."idempotency_keys" (
    "key" "text" NOT NULL,
    "payload" "jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."idempotency_keys" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."insurance_documents" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "intent_id" "uuid",
    "contact_id" "uuid",
    "kind" "public"."doc_type" NOT NULL,
    "storage_path" "text" NOT NULL,
    "checksum" "text",
    "ocr_state" "public"."ocr_status" DEFAULT 'pending'::"public"."ocr_status" NOT NULL,
    "ocr_json" "jsonb",
    "ocr_confidence" numeric,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."insurance_documents" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."insurance_intents" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "contact_id" "uuid",
    "status" "public"."insurance_status" DEFAULT 'collecting'::"public"."insurance_status" NOT NULL,
    "vehicle_type" "text",
    "vehicle_plate" "text",
    "insurer_preference" "text",
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."insurance_intents" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."insurance_leads" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "whatsapp" "text" NOT NULL,
    "file_path" "text",
    "raw_ocr" "jsonb",
    "extracted" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "extracted_json" "jsonb",
    "status" "text" DEFAULT 'received'::"text" NOT NULL,
    CONSTRAINT "insurance_leads_status_check" CHECK (("status" = ANY (ARRAY['received'::"text", 'ocr_ok'::"text", 'ocr_error'::"text", 'reviewed'::"text"])))
);


ALTER TABLE "public"."insurance_leads" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."insurance_media" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "lead_id" "uuid",
    "wa_media_id" "text",
    "storage_path" "text" NOT NULL,
    "mime_type" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."insurance_media" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."insurance_media_queue" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "profile_id" "uuid",
    "wa_id" "text",
    "storage_path" "text" NOT NULL,
    "mime_type" "text",
    "caption" "text",
    "status" "text" DEFAULT 'queued'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."insurance_media_queue" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."insurance_quotes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "uploaded_docs" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "premium" numeric(12,2),
    "insurer" "text",
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "approved_at" timestamp with time zone,
    "reviewer_comment" "text"
);


ALTER TABLE "public"."insurance_quotes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."item_modifiers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "item_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "modifier_type" "public"."item_modifier_type" NOT NULL,
    "is_required" boolean DEFAULT false NOT NULL,
    "options" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "sort_order" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."item_modifiers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "bar_id" "uuid" NOT NULL,
    "menu_id" "uuid" NOT NULL,
    "category_id" "uuid",
    "name" "text" NOT NULL,
    "short_description" "text",
    "price_minor" integer NOT NULL,
    "currency" "text",
    "flags" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "is_available" boolean DEFAULT true NOT NULL,
    "sort_order" integer DEFAULT 0 NOT NULL,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    CONSTRAINT "items_price_minor_check" CHECK (("price_minor" >= 0))
);


ALTER TABLE "public"."items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."leaderboard_notifications" (
    "user_id" "uuid" NOT NULL,
    "window" "text" NOT NULL,
    "last_entered_at" timestamp with time zone,
    "last_dropped_at" timestamp with time zone
);


ALTER TABLE "public"."leaderboard_notifications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."leaderboard_snapshots" (
    "window" "text" NOT NULL,
    "generated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "payload" "jsonb" NOT NULL,
    "id" "uuid" DEFAULT "gen_random_uuid"(),
    "snapshot_window" "text",
    "top9" "jsonb",
    "your_rank_map" "jsonb"
);


ALTER TABLE "public"."leaderboard_snapshots" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."leaderboard_snapshots_v" AS
 SELECT "id",
    "snapshot_window" AS "window",
    "generated_at",
    "top9",
    "your_rank_map"
   FROM "public"."leaderboard_snapshots";


ALTER VIEW "public"."leaderboard_snapshots_v" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."marketplace_categories" (
    "id" bigint NOT NULL,
    "name" "text" NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "sort_order" integer,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."marketplace_categories" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."marketplace_categories_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."marketplace_categories_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."marketplace_categories_id_seq" OWNED BY "public"."marketplace_categories"."id";



CREATE TABLE IF NOT EXISTS "public"."mcp_tool_calls" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "call_id" "uuid",
    "server" "text",
    "tool" "text",
    "args" "jsonb",
    "result" "jsonb",
    "t" timestamp with time zone DEFAULT "now"(),
    "success" boolean
);


ALTER TABLE "public"."mcp_tool_calls" OWNER TO "postgres";


CREATE MATERIALIZED VIEW "public"."menu_items_snapshot" AS
 SELECT "i"."id" AS "item_id",
    "i"."bar_id",
    "i"."menu_id",
    "i"."category_id",
    "i"."name",
    "i"."short_description",
    "i"."price_minor",
    COALESCE("i"."currency", "b"."currency") AS "currency",
    "i"."flags",
    "i"."is_available",
    "i"."sort_order",
    "i"."metadata",
    "i"."updated_at"
   FROM ("public"."items" "i"
     JOIN "public"."bars" "b" ON (("b"."id" = "i"."bar_id")))
  WHERE ("i"."is_available" = true)
  WITH NO DATA;


ALTER MATERIALIZED VIEW "public"."menu_items_snapshot" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."menus" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "bar_id" "uuid" NOT NULL,
    "version" integer DEFAULT 1 NOT NULL,
    "status" "public"."menu_status" DEFAULT 'draft'::"public"."menu_status" NOT NULL,
    "source" "public"."menu_source" DEFAULT 'manual'::"public"."menu_source" NOT NULL,
    "source_file_ids" "text"[] DEFAULT ARRAY[]::"text"[] NOT NULL,
    "created_by" "text",
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "published_at" timestamp with time zone
);


ALTER TABLE "public"."menus" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."messages" (
    "id" bigint NOT NULL,
    "conversation_id" "uuid",
    "dir" "text" NOT NULL,
    "body" "jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."messages" OWNER TO "postgres";


ALTER TABLE "public"."messages" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."messages_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."mobility_pro_access" (
    "user_id" "uuid" NOT NULL,
    "credits_left" integer DEFAULT 30 NOT NULL,
    "granted_until" timestamp with time zone,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "last_subscription_paid_at" timestamp with time zone,
    "last_credit_used_at" timestamp with time zone,
    "plan" "text" DEFAULT 'monthly'::"text" NOT NULL
);


ALTER TABLE "public"."mobility_pro_access" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."momo_parsed_txns" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "inbox_id" "uuid",
    "msisdn_e164" "text",
    "sender_name" "text",
    "amount" numeric(12,2),
    "currency" "text" DEFAULT 'RWF'::"text",
    "txn_id" "text",
    "txn_ts" timestamp with time zone,
    "parsed_json" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL
);


ALTER TABLE "public"."momo_parsed_txns" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."momo_qr_requests" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "whatsapp_e164" "text" NOT NULL,
    "kind" "text" NOT NULL,
    "momo_value" "text" NOT NULL,
    "amount_rwf" integer,
    "ussd_text" "text" NOT NULL,
    "tel_uri" "text" NOT NULL,
    "qr_url" "text" NOT NULL,
    "share_url" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "requester_wa_id" "text",
    "target_value" "text",
    "target_type" "text",
    "amount_minor" integer,
    "ussd_code" "text",
    "msisdn_or_code" "text",
    "amount" numeric,
    "ussd" "text",
    CONSTRAINT "momo_qr_requests_kind_check" CHECK (("kind" = ANY (ARRAY['number'::"text", 'code'::"text"])))
);


ALTER TABLE "public"."momo_qr_requests" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."momo_sms_inbox" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "raw_text" "text",
    "msisdn_raw" "text",
    "received_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."momo_sms_inbox" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."momo_unmatched" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "parsed_id" "uuid",
    "reason" "text",
    "status" "text" DEFAULT 'open'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."momo_unmatched" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."notifications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "order_id" "uuid",
    "to_wa_id" "text" NOT NULL,
    "template_name" "text",
    "notification_type" "text" NOT NULL,
    "channel" "public"."notification_channel" DEFAULT 'template'::"public"."notification_channel" NOT NULL,
    "status" "public"."notification_status" DEFAULT 'queued'::"public"."notification_status" NOT NULL,
    "payload" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "error_message" "text",
    "sent_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "retry_count" integer DEFAULT 0 NOT NULL,
    "next_attempt_at" timestamp with time zone,
    "locked_at" timestamp with time zone,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "to_role" "text",
    "type" "text",
    "msisdn" "text",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL
);


ALTER TABLE "public"."notifications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ocr_jobs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "bar_id" "uuid" NOT NULL,
    "menu_id" "uuid",
    "source_file_id" "text",
    "status" "public"."ocr_job_status" DEFAULT 'queued'::"public"."ocr_job_status" NOT NULL,
    "error_message" "text",
    "attempts" smallint DEFAULT 0 NOT NULL,
    "last_attempt_at" timestamp with time zone,
    "result_path" "text",
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."ocr_jobs" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."order_code_seq"
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."order_code_seq" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."order_events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "order_id" "uuid" NOT NULL,
    "event_type" "public"."order_event_type" NOT NULL,
    "actor_type" "public"."order_event_actor" NOT NULL,
    "actor_identifier" "text",
    "note" "text",
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "type" "text",
    "status" "text",
    "actor_id" "uuid",
    "station_id" "uuid"
);


ALTER TABLE "public"."order_events" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."order_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "order_id" "uuid" NOT NULL,
    "item_id" "uuid",
    "item_name" "text" NOT NULL,
    "item_description" "text",
    "qty" integer NOT NULL,
    "unit_price_minor" integer NOT NULL,
    "flags_snapshot" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "modifiers_snapshot" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "line_total_minor" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    CONSTRAINT "order_items_line_total_minor_check" CHECK (("line_total_minor" >= 0)),
    CONSTRAINT "order_items_qty_check" CHECK (("qty" >= 1)),
    CONSTRAINT "order_items_unit_price_minor_check" CHECK (("unit_price_minor" >= 0))
);


ALTER TABLE "public"."order_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."orders" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "order_code" "text",
    "bar_id" "uuid" NOT NULL,
    "source_cart_id" "uuid",
    "table_label" "text",
    "status" "public"."order_status" DEFAULT 'pending'::"public"."order_status" NOT NULL,
    "subtotal_minor" integer DEFAULT 0 NOT NULL,
    "service_charge_minor" integer DEFAULT 0 NOT NULL,
    "total_minor" integer DEFAULT 0 NOT NULL,
    "momo_code_used" "text",
    "note" "text",
    "paid_at" timestamp with time zone,
    "served_at" timestamp with time zone,
    "cancelled_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "profile_id" "uuid",
    "bar_name" "text",
    "total" numeric(12,2),
    "staff_number" "text",
    "override_reason" "text",
    "override_at" timestamp with time zone
);


ALTER TABLE "public"."orders" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."petrol_stations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "city" "text",
    "owner_contact" "text",
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    CONSTRAINT "petrol_stations_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'inactive'::"text"])))
);


ALTER TABLE "public"."petrol_stations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "user_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "whatsapp_e164" "text",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "locale" "text" DEFAULT 'en'::"text",
    "ref_code" "text",
    "credits_balance" numeric DEFAULT 0,
    "vehicle_plate" "text",
    "vehicle_type" "text"
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


COMMENT ON COLUMN "public"."profiles"."locale" IS 'Preferred language code for WhatsApp automation.';



CREATE TABLE IF NOT EXISTS "public"."promo_rules" (
    "id" integer DEFAULT 1 NOT NULL,
    "tokens_per_new_user" integer DEFAULT 10 NOT NULL,
    "welcome_bonus" integer,
    "daily_cap_per_sharer" integer
);


ALTER TABLE "public"."promo_rules" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."published_menus" AS
 SELECT DISTINCT ON ("bar_id") "id",
    "bar_id",
    "version",
    "status",
    "source",
    "source_file_ids",
    "created_by",
    "created_at",
    "updated_at",
    "published_at"
   FROM "public"."menus" "m"
  WHERE ("status" = 'published'::"public"."menu_status")
  ORDER BY "bar_id", "published_at" DESC NULLS LAST, "updated_at" DESC;


ALTER VIEW "public"."published_menus" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."qr_tokens" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "station_id" "uuid",
    "table_label" "text" NOT NULL,
    "token" "text" NOT NULL,
    "printed" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "last_scan_at" timestamp with time zone
);


ALTER TABLE "public"."qr_tokens" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."referral_attributions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "code" "text" NOT NULL,
    "sharer_user_id" "uuid" NOT NULL,
    "joiner_user_id" "uuid" NOT NULL,
    "first_message_at" timestamp with time zone NOT NULL,
    "credited" boolean DEFAULT false NOT NULL,
    "credited_tokens" integer DEFAULT 0 NOT NULL,
    "reason" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."referral_attributions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."referral_clicks" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "code" "text",
    "clicked_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "ip" "text",
    "user_agent" "text",
    "country_guess" "text"
);


ALTER TABLE "public"."referral_clicks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."referral_links" (
    "user_id" "uuid" NOT NULL,
    "code" "text" NOT NULL,
    "short_url" "text",
    "active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "last_shared_at" timestamp with time zone
);


ALTER TABLE "public"."referral_links" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ride_candidates" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ride_id" "uuid",
    "driver_id" "uuid",
    "eta_minutes" integer,
    "offer_price" numeric,
    "currency" "text" DEFAULT 'RWF'::"text",
    "status" "public"."candidate_status" DEFAULT 'pending'::"public"."candidate_status",
    "driver_message" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."ride_candidates" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."rides" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "contact_id" "uuid",
    "vehicle_type" "public"."vehicle_kind" NOT NULL,
    "pickup" "public"."geography"(Point,4326) NOT NULL,
    "dropoff" "public"."geography"(Point,4326),
    "status" "public"."ride_status" DEFAULT 'searching'::"public"."ride_status" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."rides" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."saccos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "branch_code" "text" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."saccos" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."segments" (
    "id" bigint NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "filter" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."segments" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."segments_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."segments_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."segments_id_seq" OWNED BY "public"."segments"."id";



CREATE TABLE IF NOT EXISTS "public"."send_logs" (
    "id" bigint NOT NULL,
    "queue_id" bigint,
    "msisdn_e164" "text" NOT NULL,
    "sent_at" timestamp with time zone,
    "provider_msg_id" "text",
    "delivery_status" "text",
    "error" "text",
    "campaign_id" "uuid"
);


ALTER TABLE "public"."send_logs" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."send_logs_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."send_logs_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."send_logs_id_seq" OWNED BY "public"."send_logs"."id";



CREATE TABLE IF NOT EXISTS "public"."send_queue" (
    "id" bigint NOT NULL,
    "msisdn_e164" "text" NOT NULL,
    "payload" "jsonb" NOT NULL,
    "attempt" integer DEFAULT 0,
    "next_attempt_at" timestamp with time zone DEFAULT "now"(),
    "status" "text" DEFAULT 'PENDING'::"text",
    "campaign_id" "uuid" NOT NULL,
    CONSTRAINT "send_queue_status_check" CHECK (("status" = ANY (ARRAY['PENDING'::"text", 'SENT'::"text", 'FAILED'::"text", 'SKIPPED'::"text"])))
);


ALTER TABLE "public"."send_queue" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."send_queue_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."send_queue_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."send_queue_id_seq" OWNED BY "public"."send_queue"."id";



CREATE TABLE IF NOT EXISTS "public"."sessions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "wa_id" "text" NOT NULL,
    "role" "public"."session_role" NOT NULL,
    "bar_id" "uuid",
    "current_flow" "text",
    "context" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "flow_state" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "last_interaction_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "profile_id" "uuid"
);


ALTER TABLE "public"."sessions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."settings" (
    "id" integer NOT NULL,
    "subscription_price" numeric NOT NULL,
    "search_radius_km" numeric DEFAULT 5 NOT NULL,
    "max_results" integer DEFAULT 10 NOT NULL,
    "momo_payee_number" "text" NOT NULL,
    "support_phone_e164" "text" NOT NULL,
    "admin_whatsapp_numbers" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."settings" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."settings_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."settings_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."settings_id_seq" OWNED BY "public"."settings"."id";



CREATE TABLE IF NOT EXISTS "public"."shops" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "short_code" "text" NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."shops" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."station_numbers" (
    "station_id" "uuid" NOT NULL,
    "wa_e164" "text" NOT NULL,
    "role" "text" DEFAULT 'staff'::"text" NOT NULL,
    "active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    CONSTRAINT "station_numbers_role_check" CHECK (("role" = ANY (ARRAY['manager'::"text", 'staff'::"text"])))
);


ALTER TABLE "public"."station_numbers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."stations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "engencode" "text" NOT NULL,
    "owner_contact" "text",
    "location_point" "public"."geography"(Point,4326),
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."stations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."subscriptions" (
    "id" bigint NOT NULL,
    "user_id" "uuid",
    "status" "text" NOT NULL,
    "started_at" timestamp with time zone,
    "expires_at" timestamp with time zone,
    "amount" numeric DEFAULT 0 NOT NULL,
    "proof_url" "text",
    "txn_id" "text",
    "rejection_reason" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "subscriptions_status_check" CHECK (("status" = ANY (ARRAY['pending_review'::"text", 'active'::"text", 'expired'::"text", 'rejected'::"text"])))
);


ALTER TABLE "public"."subscriptions" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."subscriptions_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."subscriptions_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."subscriptions_id_seq" OWNED BY "public"."subscriptions"."id";



CREATE TABLE IF NOT EXISTS "public"."templates" (
    "id" bigint NOT NULL,
    "name" "text" NOT NULL,
    "language_code" "text" DEFAULT 'en'::"text" NOT NULL,
    "category" "text",
    "status" "text" NOT NULL,
    "meta_id" "text",
    "components" "jsonb" NOT NULL,
    "sample" "jsonb" DEFAULT '{}'::"jsonb",
    "last_synced_at" timestamp with time zone,
    CONSTRAINT "templates_category_check" CHECK (("category" = ANY (ARRAY['MARKETING'::"text", 'UTILITY'::"text", 'AUTHENTICATION'::"text", 'SERVICE'::"text"]))),
    CONSTRAINT "templates_status_check" CHECK (("status" = ANY (ARRAY['APPROVED'::"text", 'REJECTED'::"text", 'PENDING'::"text", 'DRAFT'::"text"])))
);


ALTER TABLE "public"."templates" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."templates_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."templates_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."templates_id_seq" OWNED BY "public"."templates"."id";



CREATE TABLE IF NOT EXISTS "public"."transcripts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "call_id" "uuid",
    "role" "text",
    "content" "text",
    "t" timestamp with time zone DEFAULT "now"(),
    "lang" "text",
    CONSTRAINT "transcripts_role_check" CHECK (("role" = ANY (ARRAY['user'::"text", 'assistant'::"text", 'system'::"text"])))
);


ALTER TABLE "public"."transcripts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."trips" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "creator_user_id" "uuid",
    "role" "text",
    "vehicle_type" "text",
    "pickup" "public"."geography"(Point,4326),
    "status" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "dropoff" "public"."geometry"(Point,4326),
    "pickup_lat" double precision,
    "pickup_lng" double precision,
    "dropoff_lat" double precision,
    "dropoff_lng" double precision,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "pickup_text" "text",
    "dropoff_text" "text",
    "pickup_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "pickup_lon" double precision GENERATED ALWAYS AS (
CASE
    WHEN ("pickup" IS NULL) THEN NULL::double precision
    ELSE "public"."st_x"(("pickup")::"public"."geometry")
END) STORED,
    "dropoff_lon" double precision GENERATED ALWAYS AS (
CASE
    WHEN ("dropoff" IS NULL) THEN NULL::double precision
    ELSE "public"."st_x"(("dropoff")::"public"."geometry")
END) STORED,
    "pickup_radius_m" integer DEFAULT 200 NOT NULL,
    "dropoff_radius_m" integer DEFAULT 200 NOT NULL,
    CONSTRAINT "trips_role_check" CHECK (("role" = ANY (ARRAY['driver'::"text", 'passenger'::"text"]))),
    CONSTRAINT "trips_status_check" CHECK (("status" = ANY (ARRAY['open'::"text", 'matched'::"text", 'closed'::"text", 'expired'::"text", 'cancelled'::"text"]))),
    CONSTRAINT "trips_status_check_spec" CHECK (("status" = ANY (ARRAY['open'::"text", 'matched'::"text", 'cancelled'::"text", 'expired'::"text", 'archived'::"text"]))),
    CONSTRAINT "trips_vehicle_type_check" CHECK (("vehicle_type" = ANY (ARRAY['moto'::"text", 'cab'::"text", 'lifan'::"text", 'truck'::"text", 'other'::"text"])))
);


ALTER TABLE "public"."trips" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."vendor_commissions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "vendor_profile_id" "uuid" NOT NULL,
    "broker_profile_id" "uuid",
    "referral_id" "uuid",
    "amount_tokens" integer DEFAULT 0 NOT NULL,
    "status" "text" DEFAULT 'due'::"text" NOT NULL,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "paid_at" timestamp with time zone
);

ALTER TABLE ONLY "public"."vendor_commissions" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."vendor_commissions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."voice_calls" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "direction" "text" NOT NULL,
    "from_e164" "text",
    "to_e164" "text",
    "twilio_call_sid" "text",
    "sip_session_id" "text",
    "project_id" "text",
    "locale" "text" DEFAULT 'en'::"text",
    "started_at" timestamp with time zone DEFAULT "now"(),
    "ended_at" timestamp with time zone,
    "duration_seconds" integer,
    "consent_obtained" boolean DEFAULT false,
    "outcome" "text",
    "handoff" boolean DEFAULT false,
    "handoff_target" "text",
    "country" "text",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "agent_profile" "text",
    "agent_profile_confidence" "text",
    "channel" "text" DEFAULT 'voice'::"text",
    "campaign_tags" "text"[],
    "lead_name" "text",
    "lead_phone" "text",
    "status" "text",
    "last_note" "text",
    "first_time_to_assistant_seconds" numeric,
    CONSTRAINT "voice_calls_direction_check" CHECK (("direction" = ANY (ARRAY['inbound'::"text", 'outbound'::"text"])))
);


ALTER TABLE "public"."voice_calls" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."voice_call_kpis" AS
 SELECT "date_trunc"('day'::"text", "started_at") AS "day",
    "channel",
    "count"(*) AS "total_calls",
    "count"(*) FILTER (WHERE ("status" = 'completed'::"text")) AS "completed_calls",
    "count"(*) FILTER (WHERE ("status" = 'failed'::"text")) AS "failed_calls",
    "avg"("duration_seconds") AS "average_duration_seconds",
    "percentile_disc"((0.95)::double precision) WITHIN GROUP (ORDER BY "first_time_to_assistant_seconds") AS "p95_assistant_seconds"
   FROM "public"."voice_calls"
  GROUP BY ("date_trunc"('day'::"text", "started_at")), "channel";


ALTER VIEW "public"."voice_call_kpis" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."voice_call_outcomes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "call_id" "uuid",
    "status" "text" NOT NULL,
    "disposition" "text",
    "notes" "text",
    "recorded_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."voice_call_outcomes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."voice_events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "call_id" "uuid",
    "t" timestamp with time zone DEFAULT "now"(),
    "type" "text",
    "payload" "jsonb"
);


ALTER TABLE "public"."voice_events" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."voice_followups" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "call_id" "uuid",
    "scheduled_at" timestamp with time zone NOT NULL,
    "channel" "text" DEFAULT 'whatsapp'::"text" NOT NULL,
    "notes" "text",
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."voice_followups" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."voice_memories" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "msisdn" "text",
    "country" "text",
    "prefs" "jsonb",
    "last_seen_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."voice_memories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."voucher_events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "voucher_id" "uuid" NOT NULL,
    "event_type" "text" NOT NULL,
    "actor_id" "uuid",
    "station_id" "uuid",
    "context" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."voucher_events" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."voucher_redemptions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "voucher_id" "uuid" NOT NULL,
    "station_id" "uuid",
    "redeemer_wa_e164" "text",
    "reason" "text",
    "meta" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."voucher_redemptions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."vouchers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "code_5" "text" NOT NULL,
    "amount_minor" integer NOT NULL,
    "currency" "text" DEFAULT 'RWF'::"text" NOT NULL,
    "status" "text" DEFAULT 'issued'::"text" NOT NULL,
    "user_id" "uuid",
    "whatsapp_e164" "text" NOT NULL,
    "policy_number" "text" NOT NULL,
    "plate" "text",
    "qr_payload" "text" NOT NULL,
    "image_url" "text",
    "issued_by_admin" "uuid",
    "issued_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "redeemed_at" timestamp with time zone,
    "redeemed_by_station_id" "uuid",
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "code5" "text",
    "amount" numeric(12,2),
    "station_scope" "uuid",
    "campaign_id" "uuid",
    "qr_url" "text",
    "png_url" "text",
    "expires_at" timestamp with time zone,
    "created_by" "uuid",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    CONSTRAINT "vouchers_code5_format_check" CHECK (((COALESCE("code5", "code_5") IS NULL) OR ("upper"(COALESCE("code5", "code_5")) ~ '^[A-Z0-9]{5}$'::"text"))),
    CONSTRAINT "vouchers_status_check" CHECK (("status" = ANY (ARRAY['issued'::"text", 'sent'::"text", 'redeemed'::"text", 'expired'::"text", 'void'::"text", 'cancelled'::"text"])))
);


ALTER TABLE "public"."vouchers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."wa_contacts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "phone_e164" "text" NOT NULL,
    "display_name" "text",
    "locale" "text" DEFAULT 'en'::"text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."wa_contacts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."wa_events" (
    "wa_message_id" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "received_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."wa_events" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."wa_inbound" (
    "wa_msg_id" "text" NOT NULL,
    "from_msisdn" "text",
    "received_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."wa_inbound" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."wa_inbox" (
    "id" bigint NOT NULL,
    "provider_msg_id" "text",
    "from_msisdn" "text" NOT NULL,
    "to_msisdn" "text",
    "wa_timestamp" timestamp with time zone,
    "type" "text",
    "payload" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."wa_inbox" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."wa_inbox_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."wa_inbox_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."wa_inbox_id_seq" OWNED BY "public"."wa_inbox"."id";



CREATE TABLE IF NOT EXISTS "public"."wa_messages" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "thread_id" "uuid",
    "direction" "text" NOT NULL,
    "content" "text",
    "agent_profile" "text",
    "agent_display_name" "text",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "wa_messages_direction_check" CHECK (("direction" = ANY (ARRAY['user'::"text", 'assistant'::"text"])))
);


ALTER TABLE "public"."wa_messages" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."wa_threads" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "call_id" "uuid",
    "wa_conversation_id" "text",
    "customer_msisdn" "text",
    "state" "text",
    "last_message_at" timestamp with time zone DEFAULT "now"(),
    "agent_profile" "text",
    "agent_display_name" "text",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb"
);


ALTER TABLE "public"."wa_threads" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."wallet_accounts" (
    "profile_id" "uuid" NOT NULL,
    "balance_minor" integer DEFAULT 0 NOT NULL,
    "pending_minor" integer DEFAULT 0 NOT NULL,
    "currency" "text" DEFAULT 'RWF'::"text" NOT NULL,
    "tokens" integer DEFAULT 0 NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."wallet_accounts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."wallet_ledger" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "delta_tokens" integer NOT NULL,
    "type" "text" NOT NULL,
    "meta" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."wallet_ledger" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."wallet_ledger_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."wallet_ledger_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."wallet_ledger_id_seq" OWNED BY "public"."wallet_ledger"."id";



CREATE TABLE IF NOT EXISTS "public"."wallet_promoters" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "display_name" "text",
    "whatsapp" "text",
    "tokens" integer DEFAULT 0 NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."wallet_promoters" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."wallet_redemptions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "reward_id" "text" NOT NULL,
    "reward_name" "text" NOT NULL,
    "cost_tokens" integer NOT NULL,
    "status" "text" DEFAULT 'fulfilled'::"text" NOT NULL,
    "meta" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "profile_id" "uuid",
    "option_id" "uuid",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "requested_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "processed_at" timestamp with time zone,
    "processed_by" "uuid"
);

ALTER TABLE ONLY "public"."wallet_redemptions" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."wallet_redemptions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."wallet_topups_momo" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "vendor_profile_id" "uuid" NOT NULL,
    "amount_tokens" integer DEFAULT 0 NOT NULL,
    "momo_reference" "text",
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "completed_at" timestamp with time zone
);

ALTER TABLE ONLY "public"."wallet_topups_momo" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."wallet_topups_momo" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."wallets" (
    "user_id" "uuid" NOT NULL,
    "balance_tokens" integer DEFAULT 0 NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."wallets" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."webhook_logs" (
    "id" bigint NOT NULL,
    "endpoint" "text" NOT NULL,
    "wa_id" "text",
    "status_code" integer,
    "error_message" "text",
    "headers" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "payload" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "received_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."webhook_logs" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."webhook_logs_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."webhook_logs_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."webhook_logs_id_seq" OWNED BY "public"."webhook_logs"."id";



ALTER TABLE ONLY "public"."campaign_recipients" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."campaign_recipients_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."campaigns" ALTER COLUMN "legacy_id" SET DEFAULT "nextval"('"public"."campaigns_legacy_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."contacts" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."contacts_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."marketplace_categories" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."marketplace_categories_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."segments" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."segments_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."send_logs" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."send_logs_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."send_queue" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."send_queue_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."settings" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."settings_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."subscriptions" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."subscriptions_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."templates" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."templates_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."wa_inbox" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."wa_inbox_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."webhook_logs" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."webhook_logs_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."admin_alert_prefs"
    ADD CONSTRAINT "admin_alert_prefs_pkey" PRIMARY KEY ("wa_id");



ALTER TABLE ONLY "public"."admin_audit_log"
    ADD CONSTRAINT "admin_audit_log_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."admin_pin_sessions"
    ADD CONSTRAINT "admin_pin_sessions_pkey" PRIMARY KEY ("session_id");



ALTER TABLE ONLY "public"."admin_sessions"
    ADD CONSTRAINT "admin_sessions_pkey" PRIMARY KEY ("wa_id");



ALTER TABLE ONLY "public"."admin_submissions"
    ADD CONSTRAINT "admin_submissions_pkey" PRIMARY KEY ("reference");



ALTER TABLE ONLY "public"."agent_chat_messages"
    ADD CONSTRAINT "agent_chat_messages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."agent_chat_sessions"
    ADD CONSTRAINT "agent_chat_sessions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."agent_deployments"
    ADD CONSTRAINT "agent_deployments_agent_id_environment_key" UNIQUE ("agent_id", "environment");



ALTER TABLE ONLY "public"."agent_deployments"
    ADD CONSTRAINT "agent_deployments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."agent_document_chunks"
    ADD CONSTRAINT "agent_document_chunks_document_id_chunk_index_key" UNIQUE ("document_id", "chunk_index");



ALTER TABLE ONLY "public"."agent_document_chunks"
    ADD CONSTRAINT "agent_document_chunks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."agent_document_embeddings"
    ADD CONSTRAINT "agent_document_embeddings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."agent_document_vectors"
    ADD CONSTRAINT "agent_document_vectors_pkey" PRIMARY KEY ("document_id", "chunk_index");



ALTER TABLE ONLY "public"."agent_documents"
    ADD CONSTRAINT "agent_documents_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."agent_personas"
    ADD CONSTRAINT "agent_personas_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."agent_personas"
    ADD CONSTRAINT "agent_personas_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."agent_runs"
    ADD CONSTRAINT "agent_runs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."agent_tasks"
    ADD CONSTRAINT "agent_tasks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."agent_toolkits"
    ADD CONSTRAINT "agent_toolkits_pkey" PRIMARY KEY ("agent_kind");



ALTER TABLE ONLY "public"."agent_versions"
    ADD CONSTRAINT "agent_versions_agent_id_version_key" UNIQUE ("agent_id", "version");



ALTER TABLE ONLY "public"."agent_versions"
    ADD CONSTRAINT "agent_versions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."app_config"
    ADD CONSTRAINT "app_config_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."audit_log"
    ADD CONSTRAINT "audit_log_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."bar_numbers"
    ADD CONSTRAINT "bar_numbers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."bar_numbers"
    ADD CONSTRAINT "bar_numbers_unique_number_per_bar" UNIQUE ("bar_id", "number_e164");



ALTER TABLE ONLY "public"."bar_settings"
    ADD CONSTRAINT "bar_settings_pkey" PRIMARY KEY ("bar_id");



ALTER TABLE ONLY "public"."bar_tables"
    ADD CONSTRAINT "bar_tables_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."bar_tables"
    ADD CONSTRAINT "bar_tables_unique_label_per_bar" UNIQUE ("bar_id", "label");



ALTER TABLE ONLY "public"."bar_tables"
    ADD CONSTRAINT "bar_tables_unique_payload" UNIQUE ("qr_payload");



ALTER TABLE ONLY "public"."bars"
    ADD CONSTRAINT "bars_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."bars"
    ADD CONSTRAINT "bars_slug_key" UNIQUE ("slug");



ALTER TABLE ONLY "public"."basket_contributions"
    ADD CONSTRAINT "basket_contributions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."basket_invites"
    ADD CONSTRAINT "basket_invites_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."basket_invites"
    ADD CONSTRAINT "basket_invites_token_key" UNIQUE ("token");



ALTER TABLE ONLY "public"."basket_members"
    ADD CONSTRAINT "basket_members_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."basket_members"
    ADD CONSTRAINT "basket_members_unique" UNIQUE ("basket_id", "user_id");



ALTER TABLE ONLY "public"."baskets"
    ADD CONSTRAINT "baskets_join_token_key" UNIQUE ("join_token");



ALTER TABLE ONLY "public"."baskets"
    ADD CONSTRAINT "baskets_join_token_unique" UNIQUE ("join_token");



ALTER TABLE ONLY "public"."baskets"
    ADD CONSTRAINT "baskets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."baskets_reminder_events"
    ADD CONSTRAINT "baskets_reminder_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."baskets_reminders"
    ADD CONSTRAINT "baskets_reminders_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."baskets"
    ADD CONSTRAINT "baskets_share_token_key" UNIQUE ("share_token");



ALTER TABLE "public"."baskets"
    ADD CONSTRAINT "baskets_status_check" CHECK (("status" = ANY (ARRAY['open'::"text", 'locked'::"text", 'closed'::"text", 'archived'::"text"]))) NOT VALID;



ALTER TABLE ONLY "public"."businesses"
    ADD CONSTRAINT "businesses_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."call_consents"
    ADD CONSTRAINT "call_consents_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."campaign_recipients"
    ADD CONSTRAINT "campaign_recipients_campaign_id_contact_id_key" UNIQUE ("campaign_id", "contact_id");



ALTER TABLE ONLY "public"."campaign_recipients"
    ADD CONSTRAINT "campaign_recipients_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."campaign_targets"
    ADD CONSTRAINT "campaign_targets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."campaigns"
    ADD CONSTRAINT "campaigns_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cart_items"
    ADD CONSTRAINT "cart_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."carts"
    ADD CONSTRAINT "carts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."chat_sessions"
    ADD CONSTRAINT "chat_sessions_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."chat_state"
    ADD CONSTRAINT "chat_state_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."chat_state"
    ADD CONSTRAINT "chat_state_user_id_unique" UNIQUE ("user_id");



ALTER TABLE ONLY "public"."contacts"
    ADD CONSTRAINT "contacts_msisdn_e164_key" UNIQUE ("msisdn_e164");



ALTER TABLE ONLY "public"."contacts"
    ADD CONSTRAINT "contacts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."contributions_ledger"
    ADD CONSTRAINT "contributions_ledger_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."driver_availability"
    ADD CONSTRAINT "driver_availability_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."driver_presence"
    ADD CONSTRAINT "driver_presence_pkey" PRIMARY KEY ("user_id", "vehicle_type");



ALTER TABLE ONLY "public"."driver_status"
    ADD CONSTRAINT "driver_status_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."drivers"
    ADD CONSTRAINT "drivers_phone_e164_key" UNIQUE ("phone_e164");



ALTER TABLE ONLY "public"."drivers"
    ADD CONSTRAINT "drivers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."flow_submissions"
    ADD CONSTRAINT "flow_submissions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ibimina_accounts"
    ADD CONSTRAINT "ibimina_accounts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ibimina_committee"
    ADD CONSTRAINT "ibimina_committee_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ibimina_members"
    ADD CONSTRAINT "ibimina_members_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ibimina"
    ADD CONSTRAINT "ibimina_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ibimina_settings"
    ADD CONSTRAINT "ibimina_settings_pkey" PRIMARY KEY ("ikimina_id");



ALTER TABLE ONLY "public"."ibimina"
    ADD CONSTRAINT "ibimina_slug_key" UNIQUE ("slug");



ALTER TABLE ONLY "public"."idempotency_keys"
    ADD CONSTRAINT "idempotency_keys_pkey" PRIMARY KEY ("key");



ALTER TABLE ONLY "public"."insurance_documents"
    ADD CONSTRAINT "insurance_documents_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."insurance_intents"
    ADD CONSTRAINT "insurance_intents_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."insurance_leads"
    ADD CONSTRAINT "insurance_leads_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."insurance_media"
    ADD CONSTRAINT "insurance_media_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."insurance_media_queue"
    ADD CONSTRAINT "insurance_media_queue_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."insurance_quotes"
    ADD CONSTRAINT "insurance_quotes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."item_modifiers"
    ADD CONSTRAINT "item_modifiers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."items"
    ADD CONSTRAINT "items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."leaderboard_notifications"
    ADD CONSTRAINT "leaderboard_notifications_pkey" PRIMARY KEY ("user_id", "window");



ALTER TABLE ONLY "public"."leaderboard_snapshots"
    ADD CONSTRAINT "leaderboard_snapshots_pkey" PRIMARY KEY ("window");



ALTER TABLE ONLY "public"."marketplace_categories"
    ADD CONSTRAINT "marketplace_categories_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."marketplace_categories"
    ADD CONSTRAINT "marketplace_categories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."mcp_tool_calls"
    ADD CONSTRAINT "mcp_tool_calls_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."menus"
    ADD CONSTRAINT "menus_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."menus"
    ADD CONSTRAINT "menus_unique_version_per_bar" UNIQUE ("bar_id", "version");



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."mobility_pro_access"
    ADD CONSTRAINT "mobility_pro_access_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."momo_parsed_txns"
    ADD CONSTRAINT "momo_parsed_txns_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."momo_qr_requests"
    ADD CONSTRAINT "momo_qr_requests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."momo_sms_inbox"
    ADD CONSTRAINT "momo_sms_inbox_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."momo_unmatched"
    ADD CONSTRAINT "momo_unmatched_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ocr_jobs"
    ADD CONSTRAINT "ocr_jobs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."order_events"
    ADD CONSTRAINT "order_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."order_items"
    ADD CONSTRAINT "order_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "orders_order_code_key" UNIQUE ("order_code");



ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "orders_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."petrol_stations"
    ADD CONSTRAINT "petrol_stations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_whatsapp_e164_key" UNIQUE ("whatsapp_e164");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_whatsapp_unique" UNIQUE ("whatsapp_e164");



ALTER TABLE ONLY "public"."promo_rules"
    ADD CONSTRAINT "promo_rules_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."qr_tokens"
    ADD CONSTRAINT "qr_tokens_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."referral_attributions"
    ADD CONSTRAINT "referral_attributions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."referral_clicks"
    ADD CONSTRAINT "referral_clicks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."referral_links"
    ADD CONSTRAINT "referral_links_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."referral_links"
    ADD CONSTRAINT "referral_links_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."ride_candidates"
    ADD CONSTRAINT "ride_candidates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."rides"
    ADD CONSTRAINT "rides_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."saccos"
    ADD CONSTRAINT "saccos_branch_code_key" UNIQUE ("branch_code");



ALTER TABLE ONLY "public"."saccos"
    ADD CONSTRAINT "saccos_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."segments"
    ADD CONSTRAINT "segments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."send_logs"
    ADD CONSTRAINT "send_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."send_queue"
    ADD CONSTRAINT "send_queue_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."sessions"
    ADD CONSTRAINT "sessions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."settings"
    ADD CONSTRAINT "settings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."shops"
    ADD CONSTRAINT "shops_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."shops"
    ADD CONSTRAINT "shops_short_code_key" UNIQUE ("short_code");



ALTER TABLE ONLY "public"."station_numbers"
    ADD CONSTRAINT "station_numbers_pkey" PRIMARY KEY ("station_id", "wa_e164");



ALTER TABLE ONLY "public"."stations"
    ADD CONSTRAINT "stations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."templates"
    ADD CONSTRAINT "templates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."transcripts"
    ADD CONSTRAINT "transcripts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."trips"
    ADD CONSTRAINT "trips_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."vendor_commissions"
    ADD CONSTRAINT "vendor_commissions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."voice_call_outcomes"
    ADD CONSTRAINT "voice_call_outcomes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."voice_calls"
    ADD CONSTRAINT "voice_calls_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."voice_calls"
    ADD CONSTRAINT "voice_calls_twilio_call_sid_key" UNIQUE ("twilio_call_sid");



ALTER TABLE ONLY "public"."voice_events"
    ADD CONSTRAINT "voice_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."voice_followups"
    ADD CONSTRAINT "voice_followups_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."voice_memories"
    ADD CONSTRAINT "voice_memories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."voucher_events"
    ADD CONSTRAINT "voucher_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."voucher_redemptions"
    ADD CONSTRAINT "voucher_redemptions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."vouchers"
    ADD CONSTRAINT "vouchers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."wa_contacts"
    ADD CONSTRAINT "wa_contacts_phone_e164_key" UNIQUE ("phone_e164");



ALTER TABLE ONLY "public"."wa_contacts"
    ADD CONSTRAINT "wa_contacts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."wa_events"
    ADD CONSTRAINT "wa_events_pkey" PRIMARY KEY ("wa_message_id");



ALTER TABLE ONLY "public"."wa_inbound"
    ADD CONSTRAINT "wa_inbound_pkey" PRIMARY KEY ("wa_msg_id");



ALTER TABLE ONLY "public"."wa_inbox"
    ADD CONSTRAINT "wa_inbox_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."wa_inbox"
    ADD CONSTRAINT "wa_inbox_provider_msg_id_key" UNIQUE ("provider_msg_id");



ALTER TABLE ONLY "public"."wa_messages"
    ADD CONSTRAINT "wa_messages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."wa_threads"
    ADD CONSTRAINT "wa_threads_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."wallet_accounts"
    ADD CONSTRAINT "wallet_accounts_pkey" PRIMARY KEY ("profile_id");



ALTER TABLE ONLY "public"."wallet_earn_actions"
    ADD CONSTRAINT "wallet_earn_actions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."wallet_ledger"
    ADD CONSTRAINT "wallet_ledger_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."wallet_promoters"
    ADD CONSTRAINT "wallet_promoters_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."wallet_redeem_options"
    ADD CONSTRAINT "wallet_redeem_options_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."wallet_redemptions"
    ADD CONSTRAINT "wallet_redemptions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."wallet_topups_momo"
    ADD CONSTRAINT "wallet_topups_momo_momo_reference_key" UNIQUE ("momo_reference");



ALTER TABLE ONLY "public"."wallet_topups_momo"
    ADD CONSTRAINT "wallet_topups_momo_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."wallet_transactions"
    ADD CONSTRAINT "wallet_transactions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."wallets"
    ADD CONSTRAINT "wallets_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."webhook_logs"
    ADD CONSTRAINT "webhook_logs_pkey" PRIMARY KEY ("id");



CREATE INDEX "agent_chat_messages_session_idx" ON "public"."agent_chat_messages" USING "btree" ("session_id", "created_at");



CREATE INDEX "agent_chat_sessions_agent_kind_idx" ON "public"."agent_chat_sessions" USING "btree" ("agent_kind", "status", "updated_at" DESC);



CREATE UNIQUE INDEX "agent_chat_sessions_profile_kind_idx" ON "public"."agent_chat_sessions" USING "btree" ("profile_id", "agent_kind") WHERE (("profile_id" IS NOT NULL) AND ("status" = 'open'::"text"));



CREATE INDEX "agent_deploy_agent_idx" ON "public"."agent_deployments" USING "btree" ("agent_id");



CREATE INDEX "agent_doc_emb_doc_idx" ON "public"."agent_document_embeddings" USING "btree" ("document_id");



CREATE INDEX "agent_doc_vec_cos_idx" ON "public"."agent_document_vectors" USING "ivfflat" ("embedding" "public"."vector_cosine_ops") WITH ("lists"='100');



CREATE INDEX "agent_docs_agent_idx" ON "public"."agent_documents" USING "btree" ("agent_id");



CREATE INDEX "agent_document_chunks_created_idx" ON "public"."agent_document_chunks" USING "btree" ("created_at" DESC);



CREATE INDEX "agent_document_chunks_document_idx" ON "public"."agent_document_chunks" USING "btree" ("document_id");



CREATE INDEX "agent_document_chunks_embedding_idx" ON "public"."agent_document_chunks" USING "ivfflat" ("embedding" "public"."vector_cosine_ops") WITH ("lists"='100');



CREATE INDEX "agent_runs_agent_idx" ON "public"."agent_runs" USING "btree" ("agent_id");



CREATE INDEX "agent_tasks_agent_idx" ON "public"."agent_tasks" USING "btree" ("agent_id");



CREATE INDEX "agent_versions_agent_idx" ON "public"."agent_versions" USING "btree" ("agent_id");



CREATE INDEX "businesses_location_gix" ON "public"."businesses" USING "gist" ("location");



CREATE INDEX "businesses_status_idx" ON "public"."businesses" USING "btree" ("status");



CREATE INDEX "campaign_targets_campaign_idx" ON "public"."campaign_targets" USING "btree" ("campaign_id");



CREATE UNIQUE INDEX "campaign_targets_campaign_msisdn_key" ON "public"."campaign_targets" USING "btree" ("campaign_id", "msisdn");



CREATE INDEX "campaign_targets_msisdn_idx" ON "public"."campaign_targets" USING "btree" ("msisdn");



CREATE INDEX "campaign_targets_status_idx" ON "public"."campaign_targets" USING "btree" ("status");



CREATE INDEX "campaigns_created_at_idx" ON "public"."campaigns" USING "btree" ("created_at" DESC);



CREATE INDEX "campaigns_status_idx" ON "public"."campaigns" USING "btree" ("status");



CREATE INDEX "conversations_metadata_gin" ON "public"."conversations" USING "gin" ("metadata");



CREATE INDEX "driver_status_location_gix" ON "public"."driver_status" USING "gist" ("location");



CREATE UNIQUE INDEX "ibimina_accounts_account_number_key" ON "public"."ibimina_accounts" USING "btree" ("sacco_account_number");



CREATE UNIQUE INDEX "ibimina_committee_role_key" ON "public"."ibimina_committee" USING "btree" ("ikimina_id", "role");



CREATE INDEX "idx_audit_log_table_time" ON "public"."audit_log" USING "btree" ("target_table", "created_at" DESC);



CREATE INDEX "idx_bar_numbers_active" ON "public"."bar_numbers" USING "btree" ("bar_id") WHERE "is_active";



CREATE INDEX "idx_bar_numbers_token_lookup" ON "public"."bar_numbers" USING "btree" ("number_e164", "bar_id") WHERE ("verification_code_hash" IS NOT NULL);



CREATE INDEX "idx_bar_tables_bar_active" ON "public"."bar_tables" USING "btree" ("bar_id") WHERE "is_active";



CREATE INDEX "idx_basket_contrib_basket" ON "public"."basket_contributions" USING "btree" ("basket_id");



CREATE INDEX "idx_basket_members_basket" ON "public"."basket_members" USING "btree" ("basket_id");



CREATE UNIQUE INDEX "idx_basket_members_unique" ON "public"."basket_members" USING "btree" ("basket_id", COALESCE("user_id", "profile_id"), COALESCE("whatsapp", ''::"text")) WHERE ((COALESCE("user_id", "profile_id") IS NOT NULL) OR (COALESCE("whatsapp", ''::"text") <> ''::"text"));



CREATE UNIQUE INDEX "idx_baskets_join_token" ON "public"."baskets" USING "btree" ("join_token") WHERE ("join_token" IS NOT NULL);



CREATE INDEX "idx_baskets_public_status" ON "public"."baskets" USING "btree" ("is_public", "status");



CREATE INDEX "idx_baskets_reminder_events_created" ON "public"."baskets_reminder_events" USING "btree" ("created_at");



CREATE INDEX "idx_baskets_reminder_events_reminder" ON "public"."baskets_reminder_events" USING "btree" ("reminder_id");



CREATE INDEX "idx_baskets_reminders_next_attempt" ON "public"."baskets_reminders" USING "btree" ("next_attempt_at");



CREATE INDEX "idx_baskets_reminders_schedule" ON "public"."baskets_reminders" USING "btree" ("scheduled_for");



CREATE INDEX "idx_baskets_reminders_status" ON "public"."baskets_reminders" USING "btree" ("status");



CREATE INDEX "idx_bk_contrib_basket" ON "public"."basket_contributions" USING "btree" ("basket_id");



CREATE INDEX "idx_bk_contrib_contributor" ON "public"."basket_contributions" USING "btree" ("contributor_user_id");



CREATE INDEX "idx_bk_contrib_status" ON "public"."basket_contributions" USING "btree" ("status");



CREATE INDEX "idx_businesses_active" ON "public"."businesses" USING "btree" ("is_active");



CREATE INDEX "idx_businesses_created" ON "public"."businesses" USING "btree" ("created_at");



CREATE INDEX "idx_businesses_geo" ON "public"."businesses" USING "gist" ("geo");



CREATE INDEX "idx_carts_profile" ON "public"."carts" USING "btree" ("profile_id");



CREATE INDEX "idx_carts_profile_status" ON "public"."carts" USING "btree" ("profile_id", "status");



CREATE INDEX "idx_categories_menu_parent" ON "public"."categories" USING "btree" ("menu_id", "parent_category_id", "sort_order");



CREATE UNIQUE INDEX "idx_contacts_profile_unique" ON "public"."contacts" USING "btree" ("profile_id") WHERE ("profile_id" IS NOT NULL);



CREATE INDEX "idx_driver_availability_gist" ON "public"."driver_availability" USING "gist" ("loc");



CREATE INDEX "idx_driver_availability_loc" ON "public"."driver_availability" USING "gist" ("loc");



CREATE INDEX "idx_driver_status_geo" ON "public"."driver_status" USING "gist" ("location");



CREATE INDEX "idx_driver_status_last_seen" ON "public"."driver_status" USING "btree" ("last_seen");



CREATE INDEX "idx_driver_status_online" ON "public"."driver_status" USING "btree" ("online");



CREATE UNIQUE INDEX "idx_ibimina_members_active_user" ON "public"."ibimina_members" USING "btree" ("user_id") WHERE ("status" = 'active'::"text");



CREATE INDEX "idx_items_availability" ON "public"."items" USING "btree" ("bar_id", "is_available");



CREATE INDEX "idx_items_menu_category" ON "public"."items" USING "btree" ("menu_id", "category_id", "sort_order");



CREATE INDEX "idx_menu_items_snapshot_bar_category" ON "public"."menu_items_snapshot" USING "btree" ("bar_id", "category_id");



CREATE UNIQUE INDEX "idx_menu_items_snapshot_item" ON "public"."menu_items_snapshot" USING "btree" ("item_id");



CREATE INDEX "idx_momo_qr_requests_created_at" ON "public"."momo_qr_requests" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_momo_qr_requests_requester" ON "public"."momo_qr_requests" USING "btree" ("requester_wa_id", "created_at" DESC);



CREATE INDEX "idx_momo_qr_requests_user" ON "public"."momo_qr_requests" USING "btree" ("user_id");



CREATE INDEX "idx_momo_qr_requests_whatsapp" ON "public"."momo_qr_requests" USING "btree" ("whatsapp_e164");



CREATE INDEX "idx_notifications_status_created" ON "public"."notifications" USING "btree" ("status", "created_at");



CREATE INDEX "idx_ocr_jobs_status_created" ON "public"."ocr_jobs" USING "btree" ("status", "created_at" DESC);



CREATE INDEX "idx_order_events_order_created" ON "public"."order_events" USING "btree" ("order_id", "created_at" DESC);



CREATE INDEX "idx_orders_bar_status_created" ON "public"."orders" USING "btree" ("bar_id", "status", "created_at" DESC);



CREATE INDEX "idx_orders_profile" ON "public"."orders" USING "btree" ("profile_id");



CREATE INDEX "idx_send_queue_ready" ON "public"."send_queue" USING "btree" ("status", "next_attempt_at");



CREATE INDEX "idx_sessions_profile" ON "public"."sessions" USING "btree" ("profile_id");



CREATE INDEX "idx_sessions_wa_role" ON "public"."sessions" USING "btree" ("wa_id", "role");



CREATE INDEX "idx_trips_pickup" ON "public"."trips" USING "gist" ("pickup");



CREATE INDEX "idx_trips_role" ON "public"."trips" USING "btree" ("role", "vehicle_type");



CREATE INDEX "idx_wallet_earn_active" ON "public"."wallet_earn_actions" USING "btree" ("is_active");



CREATE INDEX "idx_wallet_redeem_active" ON "public"."wallet_redeem_options" USING "btree" ("is_active");



CREATE INDEX "idx_wallet_tx_profile" ON "public"."wallet_transactions" USING "btree" ("profile_id", "occurred_at" DESC);



CREATE INDEX "idx_webhook_logs_endpoint_time" ON "public"."webhook_logs" USING "btree" ("endpoint", "received_at" DESC);



CREATE INDEX "insurance_quotes_status_idx" ON "public"."insurance_quotes" USING "btree" ("status");



CREATE INDEX "insurance_quotes_user_idx" ON "public"."insurance_quotes" USING "btree" ("user_id");



CREATE INDEX "marketplace_categories_active_sort_idx" ON "public"."marketplace_categories" USING "btree" ("is_active", "sort_order", "id");



CREATE INDEX "momo_qr_requests_user_idx" ON "public"."momo_qr_requests" USING "btree" ("user_id", "created_at" DESC);



CREATE INDEX "notifications_status_idx" ON "public"."notifications" USING "btree" ("status");



CREATE INDEX "order_events_order_idx" ON "public"."order_events" USING "btree" ("order_id");



CREATE INDEX "order_events_type_idx" ON "public"."order_events" USING "btree" ("type");



CREATE INDEX "orders_bar_idx" ON "public"."orders" USING "btree" ("bar_id");



CREATE INDEX "orders_status_idx" ON "public"."orders" USING "btree" ("status");



CREATE INDEX "qr_tokens_station_idx" ON "public"."qr_tokens" USING "btree" ("station_id");



CREATE UNIQUE INDEX "qr_tokens_token_key" ON "public"."qr_tokens" USING "btree" ("token");



CREATE INDEX "referral_attributions_code_idx" ON "public"."referral_attributions" USING "btree" ("code");



CREATE UNIQUE INDEX "referral_attributions_joiner_unique" ON "public"."referral_attributions" USING "btree" ("joiner_user_id");



CREATE INDEX "referral_attributions_sharer_created_idx" ON "public"."referral_attributions" USING "btree" ("sharer_user_id", "credited", "created_at" DESC);



CREATE INDEX "send_logs_campaign_idx" ON "public"."send_logs" USING "btree" ("campaign_id");



CREATE INDEX "send_queue_campaign_idx" ON "public"."send_queue" USING "btree" ("campaign_id");



CREATE UNIQUE INDEX "stations_engencode_key" ON "public"."stations" USING "btree" ("engencode");



CREATE INDEX "stations_location_point_idx" ON "public"."stations" USING "gist" ("location_point");



CREATE INDEX "stations_name_idx" ON "public"."stations" USING "btree" ("name");



CREATE INDEX "trips_created_idx" ON "public"."trips" USING "btree" ("created_at");



CREATE INDEX "trips_dropoff_geog_idx" ON "public"."trips" USING "gist" ("dropoff");



CREATE INDEX "trips_dropoff_gix" ON "public"."trips" USING "gist" ("dropoff");



CREATE INDEX "trips_open_pickup_gix" ON "public"."trips" USING "gist" ("pickup") WHERE ("status" = 'open'::"text");



CREATE INDEX "trips_pickup_geog_idx" ON "public"."trips" USING "gist" ("pickup");



CREATE INDEX "trips_pickup_gix" ON "public"."trips" USING "gist" ("pickup");



CREATE INDEX "trips_role_idx" ON "public"."trips" USING "btree" ("role");



CREATE INDEX "trips_status_idx" ON "public"."trips" USING "btree" ("status");



CREATE INDEX "trips_status_role_idx" ON "public"."trips" USING "btree" ("status", "role");



CREATE INDEX "trips_vehicle_idx" ON "public"."trips" USING "btree" ("vehicle_type");



CREATE UNIQUE INDEX "uniq_marketplace_categories_name" ON "public"."marketplace_categories" USING "btree" ("name");



CREATE UNIQUE INDEX "uq_businesses_name_owner" ON "public"."businesses" USING "btree" ("name", "owner_whatsapp");



CREATE UNIQUE INDEX "uq_chat_state_user" ON "public"."chat_state" USING "btree" ("user_id");



CREATE UNIQUE INDEX "uq_marketplace_categories_name" ON "public"."marketplace_categories" USING "btree" ("name");



CREATE UNIQUE INDEX "uq_profiles_whatsapp" ON "public"."profiles" USING "btree" ("whatsapp_e164");



CREATE UNIQUE INDEX "uq_wa_events_wa_message_id" ON "public"."wa_events" USING "btree" ("wa_message_id");



CREATE INDEX "vendor_commissions_vendor_idx" ON "public"."vendor_commissions" USING "btree" ("vendor_profile_id", "status", "created_at" DESC);



CREATE INDEX "voice_call_outcomes_call_id_idx" ON "public"."voice_call_outcomes" USING "btree" ("call_id");



CREATE INDEX "voice_calls_agent_profile_idx" ON "public"."voice_calls" USING "btree" ("agent_profile");



CREATE INDEX "voice_calls_channel_idx" ON "public"."voice_calls" USING "btree" ("channel");



CREATE INDEX "voice_followups_call_id_idx" ON "public"."voice_followups" USING "btree" ("call_id");



CREATE INDEX "voice_followups_status_idx" ON "public"."voice_followups" USING "btree" ("status");



CREATE INDEX "voucher_events_type_idx" ON "public"."voucher_events" USING "btree" ("event_type");



CREATE INDEX "voucher_events_voucher_idx" ON "public"."voucher_events" USING "btree" ("voucher_id");



CREATE INDEX "voucher_redemptions_voucher_idx" ON "public"."voucher_redemptions" USING "btree" ("voucher_id", "created_at" DESC);



CREATE INDEX "vouchers_campaign_idx" ON "public"."vouchers" USING "btree" ("campaign_id");



CREATE UNIQUE INDEX "vouchers_code5_active_idx" ON "public"."vouchers" USING "btree" ("code5") WHERE ("status" = ANY (ARRAY['issued'::"text", 'sent'::"text", 'redeemed'::"text"]));



CREATE UNIQUE INDEX "vouchers_code5_key" ON "public"."vouchers" USING "btree" ("code5");



CREATE UNIQUE INDEX "vouchers_code_active_unique" ON "public"."vouchers" USING "btree" ("code_5") WHERE ("status" = ANY (ARRAY['issued'::"text", 'redeemed'::"text"]));



CREATE INDEX "vouchers_status_idx" ON "public"."vouchers" USING "btree" ("status");



CREATE INDEX "vouchers_user_idx" ON "public"."vouchers" USING "btree" ("user_id");



CREATE INDEX "wa_messages_created_at_idx" ON "public"."wa_messages" USING "btree" ("created_at");



CREATE INDEX "wa_messages_thread_idx" ON "public"."wa_messages" USING "btree" ("thread_id");



CREATE INDEX "wallet_ledger_user_created_idx" ON "public"."wallet_ledger" USING "btree" ("user_id", "created_at" DESC);



CREATE INDEX "wallet_ledger_user_idx" ON "public"."wallet_ledger" USING "btree" ("user_id", "created_at" DESC);



CREATE INDEX "wallet_redemptions_profile_idx" ON "public"."wallet_redemptions" USING "btree" ("profile_id", "requested_at" DESC);



CREATE INDEX "wallet_topups_momo_vendor_idx" ON "public"."wallet_topups_momo" USING "btree" ("vendor_profile_id", "status", "created_at" DESC);



CREATE OR REPLACE TRIGGER "agent_document_chunks_updated" BEFORE UPDATE ON "public"."agent_document_chunks" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "agent_toolkits_set_updated" BEFORE UPDATE ON "public"."agent_toolkits" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "audit_log_sync_admin_columns" BEFORE INSERT OR UPDATE ON "public"."audit_log" FOR EACH ROW EXECUTE FUNCTION "public"."audit_log_sync_admin_columns"();



CREATE OR REPLACE TRIGGER "notifications_sync_admin_columns" BEFORE INSERT OR UPDATE ON "public"."notifications" FOR EACH ROW EXECUTE FUNCTION "public"."notifications_sync_admin_columns"();



CREATE OR REPLACE TRIGGER "order_events_sync_admin_columns" BEFORE INSERT OR UPDATE ON "public"."order_events" FOR EACH ROW EXECUTE FUNCTION "public"."order_events_sync_admin_columns"();



CREATE OR REPLACE TRIGGER "orders_sync_admin_columns" BEFORE INSERT OR UPDATE ON "public"."orders" FOR EACH ROW EXECUTE FUNCTION "public"."orders_sync_admin_columns"();



CREATE OR REPLACE TRIGGER "trg_admin_sessions_updated" BEFORE UPDATE ON "public"."admin_sessions" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_app_config_updated" BEFORE UPDATE ON "public"."app_config" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_bar_numbers_updated" BEFORE UPDATE ON "public"."bar_numbers" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_bar_settings_updated" BEFORE UPDATE ON "public"."bar_settings" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_bar_tables_updated" BEFORE UPDATE ON "public"."bar_tables" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_bars_updated" BEFORE UPDATE ON "public"."bars" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_basket_invites_sync" AFTER INSERT OR UPDATE ON "public"."basket_invites" FOR EACH ROW EXECUTE FUNCTION "public"."fn_sync_basket_invites_to_baskets"();



CREATE OR REPLACE TRIGGER "trg_basket_members_sync" AFTER INSERT OR DELETE OR UPDATE ON "public"."basket_members" FOR EACH ROW EXECUTE FUNCTION "public"."fn_sync_basket_members_to_ibimina"();



CREATE OR REPLACE TRIGGER "trg_baskets_rate_limit" BEFORE INSERT ON "public"."baskets" FOR EACH ROW EXECUTE FUNCTION "public"."fn_assert_basket_create_rate_limit"();



CREATE OR REPLACE TRIGGER "trg_baskets_sync" AFTER INSERT OR DELETE OR UPDATE ON "public"."baskets" FOR EACH ROW EXECUTE FUNCTION "public"."fn_sync_baskets_to_ibimina"();



CREATE OR REPLACE TRIGGER "trg_baskets_updated" BEFORE UPDATE ON "public"."baskets" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_baskets_updated_v2" BEFORE UPDATE ON "public"."baskets" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_carts_updated" BEFORE UPDATE ON "public"."carts" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_categories_updated" BEFORE UPDATE ON "public"."categories" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_chat_state_updated" BEFORE UPDATE ON "public"."chat_state" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_contacts_updated" BEFORE UPDATE ON "public"."contacts" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_driver_status_updated" BEFORE UPDATE ON "public"."driver_status" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_item_modifiers_updated" BEFORE UPDATE ON "public"."item_modifiers" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_items_updated" BEFORE UPDATE ON "public"."items" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_menus_refresh_snapshot" AFTER UPDATE OF "status" ON "public"."menus" FOR EACH ROW WHEN (("new"."status" = 'published'::"public"."menu_status")) EXECUTE FUNCTION "public"."on_menu_publish_refresh"();



CREATE OR REPLACE TRIGGER "trg_menus_updated" BEFORE UPDATE ON "public"."menus" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_mobility_pro_access_updated" BEFORE UPDATE ON "public"."mobility_pro_access" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_notifications_updated" BEFORE UPDATE ON "public"."notifications" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_ocr_jobs_updated" BEFORE UPDATE ON "public"."ocr_jobs" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_orders_defaults" BEFORE INSERT ON "public"."orders" FOR EACH ROW EXECUTE FUNCTION "public"."orders_set_defaults"();



CREATE OR REPLACE TRIGGER "trg_orders_updated" BEFORE UPDATE ON "public"."orders" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_petrol_stations_updated" BEFORE UPDATE ON "public"."petrol_stations" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_profiles_updated" BEFORE UPDATE ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_sessions_updated" BEFORE UPDATE ON "public"."sessions" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_trips_updated" BEFORE UPDATE ON "public"."trips" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_vouchers_updated" BEFORE UPDATE ON "public"."vouchers" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "vouchers_sync_admin_columns" BEFORE INSERT OR UPDATE ON "public"."vouchers" FOR EACH ROW EXECUTE FUNCTION "public"."vouchers_sync_admin_columns"();



ALTER TABLE ONLY "public"."admin_alert_prefs"
    ADD CONSTRAINT "admin_alert_prefs_admin_user_id_fkey" FOREIGN KEY ("admin_user_id") REFERENCES "public"."profiles"("user_id");



ALTER TABLE ONLY "public"."admin_audit_log"
    ADD CONSTRAINT "admin_audit_log_admin_user_id_fkey" FOREIGN KEY ("admin_user_id") REFERENCES "public"."profiles"("user_id");



ALTER TABLE ONLY "public"."agent_chat_messages"
    ADD CONSTRAINT "agent_chat_messages_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "public"."agent_chat_sessions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."agent_chat_sessions"
    ADD CONSTRAINT "agent_chat_sessions_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("user_id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."agent_deployments"
    ADD CONSTRAINT "agent_deployments_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "public"."agent_personas"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."agent_deployments"
    ADD CONSTRAINT "agent_deployments_version_id_fkey" FOREIGN KEY ("version_id") REFERENCES "public"."agent_versions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."agent_document_chunks"
    ADD CONSTRAINT "agent_document_chunks_document_id_fkey" FOREIGN KEY ("document_id") REFERENCES "public"."agent_documents"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."agent_document_embeddings"
    ADD CONSTRAINT "agent_document_embeddings_document_id_fkey" FOREIGN KEY ("document_id") REFERENCES "public"."agent_documents"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."agent_document_vectors"
    ADD CONSTRAINT "agent_document_vectors_document_id_fkey" FOREIGN KEY ("document_id") REFERENCES "public"."agent_documents"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."agent_documents"
    ADD CONSTRAINT "agent_documents_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "public"."agent_personas"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."agent_runs"
    ADD CONSTRAINT "agent_runs_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "public"."agent_personas"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."agent_runs"
    ADD CONSTRAINT "agent_runs_version_id_fkey" FOREIGN KEY ("version_id") REFERENCES "public"."agent_versions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."agent_tasks"
    ADD CONSTRAINT "agent_tasks_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "public"."agent_personas"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."agent_versions"
    ADD CONSTRAINT "agent_versions_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "public"."agent_personas"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bar_numbers"
    ADD CONSTRAINT "bar_numbers_bar_id_fkey" FOREIGN KEY ("bar_id") REFERENCES "public"."bars"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bar_settings"
    ADD CONSTRAINT "bar_settings_bar_id_fkey" FOREIGN KEY ("bar_id") REFERENCES "public"."bars"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bar_tables"
    ADD CONSTRAINT "bar_tables_bar_id_fkey" FOREIGN KEY ("bar_id") REFERENCES "public"."bars"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."basket_contributions"
    ADD CONSTRAINT "basket_contributions_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("user_id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."basket_invites"
    ADD CONSTRAINT "basket_invites_ikimina_id_fkey" FOREIGN KEY ("ikimina_id") REFERENCES "public"."ibimina"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."basket_invites"
    ADD CONSTRAINT "basket_invites_issuer_member_id_fkey" FOREIGN KEY ("issuer_member_id") REFERENCES "public"."ibimina_members"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."basket_members"
    ADD CONSTRAINT "basket_members_basket_id_fkey" FOREIGN KEY ("basket_id") REFERENCES "public"."baskets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."basket_members"
    ADD CONSTRAINT "basket_members_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("user_id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."basket_members"
    ADD CONSTRAINT "basket_members_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("user_id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."baskets"
    ADD CONSTRAINT "baskets_owner_profile_id_fkey" FOREIGN KEY ("owner_profile_id") REFERENCES "public"."profiles"("user_id");



ALTER TABLE ONLY "public"."baskets_reminder_events"
    ADD CONSTRAINT "baskets_reminder_events_reminder_id_fkey" FOREIGN KEY ("reminder_id") REFERENCES "public"."baskets_reminders"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."baskets_reminders"
    ADD CONSTRAINT "baskets_reminders_ikimina_id_fkey" FOREIGN KEY ("ikimina_id") REFERENCES "public"."ibimina"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."baskets_reminders"
    ADD CONSTRAINT "baskets_reminders_member_id_fkey" FOREIGN KEY ("member_id") REFERENCES "public"."ibimina_members"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."baskets_reminders"
    ADD CONSTRAINT "baskets_reminders_notification_id_fkey" FOREIGN KEY ("notification_id") REFERENCES "public"."notifications"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."businesses"
    ADD CONSTRAINT "businesses_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."marketplace_categories"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."businesses"
    ADD CONSTRAINT "businesses_owner_user_id_fkey" FOREIGN KEY ("owner_user_id") REFERENCES "public"."profiles"("user_id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."call_consents"
    ADD CONSTRAINT "call_consents_call_id_fkey" FOREIGN KEY ("call_id") REFERENCES "public"."voice_calls"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."campaign_recipients"
    ADD CONSTRAINT "campaign_recipients_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "public"."campaigns"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."campaign_recipients"
    ADD CONSTRAINT "campaign_recipients_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "public"."contacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."campaign_targets"
    ADD CONSTRAINT "campaign_targets_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "public"."campaigns"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."campaign_targets"
    ADD CONSTRAINT "campaign_targets_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."cart_items"
    ADD CONSTRAINT "cart_items_cart_id_fkey" FOREIGN KEY ("cart_id") REFERENCES "public"."carts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."carts"
    ADD CONSTRAINT "carts_bar_id_fkey" FOREIGN KEY ("bar_id") REFERENCES "public"."bars"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."carts"
    ADD CONSTRAINT "carts_profile_fk" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("user_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_bar_id_fkey" FOREIGN KEY ("bar_id") REFERENCES "public"."bars"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_menu_id_fkey" FOREIGN KEY ("menu_id") REFERENCES "public"."menus"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_parent_category_id_fkey" FOREIGN KEY ("parent_category_id") REFERENCES "public"."categories"("id");



ALTER TABLE ONLY "public"."chat_state"
    ADD CONSTRAINT "chat_state_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("user_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."contacts"
    ADD CONSTRAINT "contacts_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("user_id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."contributions_ledger"
    ADD CONSTRAINT "contributions_ledger_ikimina_id_fkey" FOREIGN KEY ("ikimina_id") REFERENCES "public"."ibimina"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."contributions_ledger"
    ADD CONSTRAINT "contributions_ledger_member_id_fkey" FOREIGN KEY ("member_id") REFERENCES "public"."ibimina_members"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."driver_availability"
    ADD CONSTRAINT "driver_availability_driver_id_fkey" FOREIGN KEY ("driver_id") REFERENCES "public"."drivers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."driver_presence"
    ADD CONSTRAINT "driver_presence_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("user_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ibimina_accounts"
    ADD CONSTRAINT "ibimina_accounts_ikimina_id_fkey" FOREIGN KEY ("ikimina_id") REFERENCES "public"."ibimina"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ibimina_committee"
    ADD CONSTRAINT "ibimina_committee_ikimina_id_fkey" FOREIGN KEY ("ikimina_id") REFERENCES "public"."ibimina"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ibimina_committee"
    ADD CONSTRAINT "ibimina_committee_member_id_fkey" FOREIGN KEY ("member_id") REFERENCES "public"."ibimina_members"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ibimina_members"
    ADD CONSTRAINT "ibimina_members_ikimina_id_fkey" FOREIGN KEY ("ikimina_id") REFERENCES "public"."ibimina"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ibimina_members"
    ADD CONSTRAINT "ibimina_members_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("user_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ibimina"
    ADD CONSTRAINT "ibimina_owner_profile_id_fkey" FOREIGN KEY ("owner_profile_id") REFERENCES "public"."profiles"("user_id");



ALTER TABLE ONLY "public"."ibimina"
    ADD CONSTRAINT "ibimina_sacco_id_fkey" FOREIGN KEY ("sacco_id") REFERENCES "public"."saccos"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."ibimina_settings"
    ADD CONSTRAINT "ibimina_settings_ikimina_id_fkey" FOREIGN KEY ("ikimina_id") REFERENCES "public"."ibimina"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."insurance_documents"
    ADD CONSTRAINT "insurance_documents_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "public"."wa_contacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."insurance_documents"
    ADD CONSTRAINT "insurance_documents_intent_id_fkey" FOREIGN KEY ("intent_id") REFERENCES "public"."insurance_intents"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."insurance_intents"
    ADD CONSTRAINT "insurance_intents_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "public"."wa_contacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."insurance_media"
    ADD CONSTRAINT "insurance_media_lead_id_fkey" FOREIGN KEY ("lead_id") REFERENCES "public"."insurance_leads"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."insurance_media_queue"
    ADD CONSTRAINT "insurance_media_queue_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("user_id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."insurance_quotes"
    ADD CONSTRAINT "insurance_quotes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."item_modifiers"
    ADD CONSTRAINT "item_modifiers_item_id_fkey" FOREIGN KEY ("item_id") REFERENCES "public"."items"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."items"
    ADD CONSTRAINT "items_bar_id_fkey" FOREIGN KEY ("bar_id") REFERENCES "public"."bars"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."items"
    ADD CONSTRAINT "items_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."items"
    ADD CONSTRAINT "items_menu_id_fkey" FOREIGN KEY ("menu_id") REFERENCES "public"."menus"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."leaderboard_notifications"
    ADD CONSTRAINT "leaderboard_notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("user_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."mcp_tool_calls"
    ADD CONSTRAINT "mcp_tool_calls_call_id_fkey" FOREIGN KEY ("call_id") REFERENCES "public"."voice_calls"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."menus"
    ADD CONSTRAINT "menus_bar_id_fkey" FOREIGN KEY ("bar_id") REFERENCES "public"."bars"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "public"."conversations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."mobility_pro_access"
    ADD CONSTRAINT "mobility_pro_access_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("user_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."momo_parsed_txns"
    ADD CONSTRAINT "momo_parsed_txns_inbox_id_fkey" FOREIGN KEY ("inbox_id") REFERENCES "public"."momo_sms_inbox"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."momo_qr_requests"
    ADD CONSTRAINT "momo_qr_requests_user_fk" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("user_id") ON UPDATE CASCADE ON DELETE SET NULL;



ALTER TABLE ONLY "public"."momo_unmatched"
    ADD CONSTRAINT "momo_unmatched_parsed_id_fkey" FOREIGN KEY ("parsed_id") REFERENCES "public"."momo_parsed_txns"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "public"."orders"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."ocr_jobs"
    ADD CONSTRAINT "ocr_jobs_bar_id_fkey" FOREIGN KEY ("bar_id") REFERENCES "public"."bars"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ocr_jobs"
    ADD CONSTRAINT "ocr_jobs_menu_id_fkey" FOREIGN KEY ("menu_id") REFERENCES "public"."menus"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."order_events"
    ADD CONSTRAINT "order_events_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "public"."orders"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."order_items"
    ADD CONSTRAINT "order_items_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "public"."orders"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "orders_bar_id_fkey" FOREIGN KEY ("bar_id") REFERENCES "public"."bars"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "orders_profile_fk" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("user_id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "orders_source_cart_id_fkey" FOREIGN KEY ("source_cart_id") REFERENCES "public"."carts"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."qr_tokens"
    ADD CONSTRAINT "qr_tokens_station_id_fkey" FOREIGN KEY ("station_id") REFERENCES "public"."stations"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."referral_attributions"
    ADD CONSTRAINT "referral_attributions_code_fkey" FOREIGN KEY ("code") REFERENCES "public"."referral_links"("code") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."referral_attributions"
    ADD CONSTRAINT "referral_attributions_joiner_user_id_fkey" FOREIGN KEY ("joiner_user_id") REFERENCES "public"."profiles"("user_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."referral_attributions"
    ADD CONSTRAINT "referral_attributions_sharer_user_id_fkey" FOREIGN KEY ("sharer_user_id") REFERENCES "public"."profiles"("user_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."referral_links"
    ADD CONSTRAINT "referral_links_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("user_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ride_candidates"
    ADD CONSTRAINT "ride_candidates_driver_id_fkey" FOREIGN KEY ("driver_id") REFERENCES "public"."drivers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ride_candidates"
    ADD CONSTRAINT "ride_candidates_ride_id_fkey" FOREIGN KEY ("ride_id") REFERENCES "public"."rides"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."rides"
    ADD CONSTRAINT "rides_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "public"."wa_contacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."send_logs"
    ADD CONSTRAINT "send_logs_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "public"."campaigns"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."send_logs"
    ADD CONSTRAINT "send_logs_queue_id_fkey" FOREIGN KEY ("queue_id") REFERENCES "public"."send_queue"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."send_queue"
    ADD CONSTRAINT "send_queue_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "public"."campaigns"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."sessions"
    ADD CONSTRAINT "sessions_bar_id_fkey" FOREIGN KEY ("bar_id") REFERENCES "public"."bars"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."sessions"
    ADD CONSTRAINT "sessions_profile_fk" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("user_id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."station_numbers"
    ADD CONSTRAINT "station_numbers_station_id_fkey" FOREIGN KEY ("station_id") REFERENCES "public"."petrol_stations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("user_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."transcripts"
    ADD CONSTRAINT "transcripts_call_id_fkey" FOREIGN KEY ("call_id") REFERENCES "public"."voice_calls"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."vendor_commissions"
    ADD CONSTRAINT "vendor_commissions_broker_profile_id_fkey" FOREIGN KEY ("broker_profile_id") REFERENCES "public"."profiles"("user_id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."vendor_commissions"
    ADD CONSTRAINT "vendor_commissions_vendor_profile_id_fkey" FOREIGN KEY ("vendor_profile_id") REFERENCES "public"."profiles"("user_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."voice_call_outcomes"
    ADD CONSTRAINT "voice_call_outcomes_call_id_fkey" FOREIGN KEY ("call_id") REFERENCES "public"."voice_calls"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."voice_events"
    ADD CONSTRAINT "voice_events_call_id_fkey" FOREIGN KEY ("call_id") REFERENCES "public"."voice_calls"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."voice_followups"
    ADD CONSTRAINT "voice_followups_call_id_fkey" FOREIGN KEY ("call_id") REFERENCES "public"."voice_calls"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."voucher_events"
    ADD CONSTRAINT "voucher_events_actor_id_fkey" FOREIGN KEY ("actor_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."voucher_events"
    ADD CONSTRAINT "voucher_events_station_id_fkey" FOREIGN KEY ("station_id") REFERENCES "public"."stations"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."voucher_events"
    ADD CONSTRAINT "voucher_events_voucher_id_fkey" FOREIGN KEY ("voucher_id") REFERENCES "public"."vouchers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."voucher_redemptions"
    ADD CONSTRAINT "voucher_redemptions_station_id_fkey" FOREIGN KEY ("station_id") REFERENCES "public"."petrol_stations"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."voucher_redemptions"
    ADD CONSTRAINT "voucher_redemptions_voucher_id_fkey" FOREIGN KEY ("voucher_id") REFERENCES "public"."vouchers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."vouchers"
    ADD CONSTRAINT "vouchers_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."vouchers"
    ADD CONSTRAINT "vouchers_issued_by_admin_fkey" FOREIGN KEY ("issued_by_admin") REFERENCES "public"."profiles"("user_id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."vouchers"
    ADD CONSTRAINT "vouchers_redeemed_by_station_id_fkey" FOREIGN KEY ("redeemed_by_station_id") REFERENCES "public"."petrol_stations"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."vouchers"
    ADD CONSTRAINT "vouchers_station_scope_fkey" FOREIGN KEY ("station_scope") REFERENCES "public"."stations"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."vouchers"
    ADD CONSTRAINT "vouchers_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("user_id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."wa_messages"
    ADD CONSTRAINT "wa_messages_thread_id_fkey" FOREIGN KEY ("thread_id") REFERENCES "public"."wa_threads"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."wa_threads"
    ADD CONSTRAINT "wa_threads_call_id_fkey" FOREIGN KEY ("call_id") REFERENCES "public"."voice_calls"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."wallet_accounts"
    ADD CONSTRAINT "wallet_accounts_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("user_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."wallet_ledger"
    ADD CONSTRAINT "wallet_ledger_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("user_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."wallet_redemptions"
    ADD CONSTRAINT "wallet_redemptions_option_id_fkey" FOREIGN KEY ("option_id") REFERENCES "public"."wallet_redeem_options"("id");



ALTER TABLE ONLY "public"."wallet_redemptions"
    ADD CONSTRAINT "wallet_redemptions_processed_by_fkey" FOREIGN KEY ("processed_by") REFERENCES "public"."profiles"("user_id");



ALTER TABLE ONLY "public"."wallet_redemptions"
    ADD CONSTRAINT "wallet_redemptions_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("user_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."wallet_redemptions"
    ADD CONSTRAINT "wallet_redemptions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("user_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."wallet_topups_momo"
    ADD CONSTRAINT "wallet_topups_momo_vendor_profile_id_fkey" FOREIGN KEY ("vendor_profile_id") REFERENCES "public"."profiles"("user_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."wallet_transactions"
    ADD CONSTRAINT "wallet_transactions_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("user_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."wallets"
    ADD CONSTRAINT "wallets_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("user_id") ON DELETE CASCADE;












ALTER TABLE "public"."agent_chat_messages" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "agent_chat_messages_service_only" ON "public"."agent_chat_messages" USING (false) WITH CHECK (false);



ALTER TABLE "public"."agent_chat_sessions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "agent_chat_sessions_service_only" ON "public"."agent_chat_sessions" USING (false) WITH CHECK (false);



ALTER TABLE "public"."agent_deployments" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "agent_deployments_admin_manage" ON "public"."agent_deployments" USING (("auth"."role"() = 'service_role'::"text")) WITH CHECK (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "agent_doc_emb_admin_manage" ON "public"."agent_document_embeddings" USING (("auth"."role"() = 'service_role'::"text")) WITH CHECK (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "agent_doc_vec_admin_manage" ON "public"."agent_document_vectors" USING (("auth"."role"() = 'service_role'::"text")) WITH CHECK (("auth"."role"() = 'service_role'::"text"));



ALTER TABLE "public"."agent_document_chunks" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "agent_document_chunks_admin_manage" ON "public"."agent_document_chunks" USING (("auth"."role"() = 'service_role'::"text")) WITH CHECK (("auth"."role"() = 'service_role'::"text"));



ALTER TABLE "public"."agent_document_embeddings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."agent_document_vectors" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."agent_documents" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "agent_documents_admin_manage" ON "public"."agent_documents" USING (("auth"."role"() = 'service_role'::"text")) WITH CHECK (("auth"."role"() = 'service_role'::"text"));



ALTER TABLE "public"."agent_personas" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "agent_personas_admin_manage" ON "public"."agent_personas" USING (("auth"."role"() = 'service_role'::"text")) WITH CHECK (("auth"."role"() = 'service_role'::"text"));



ALTER TABLE "public"."agent_runs" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "agent_runs_admin_manage" ON "public"."agent_runs" USING (("auth"."role"() = 'service_role'::"text")) WITH CHECK (("auth"."role"() = 'service_role'::"text"));



ALTER TABLE "public"."agent_tasks" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "agent_tasks_admin_manage" ON "public"."agent_tasks" USING (("auth"."role"() = 'service_role'::"text")) WITH CHECK (("auth"."role"() = 'service_role'::"text"));



ALTER TABLE "public"."agent_toolkits" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "agent_toolkits_admin_manage" ON "public"."agent_toolkits" USING (("auth"."role"() = 'service_role'::"text")) WITH CHECK (("auth"."role"() = 'service_role'::"text"));



ALTER TABLE "public"."agent_versions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "agent_versions_admin_manage" ON "public"."agent_versions" USING (("auth"."role"() = 'service_role'::"text")) WITH CHECK (("auth"."role"() = 'service_role'::"text"));



ALTER TABLE "public"."app_config" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."audit_log" ENABLE ROW LEVEL SECURITY;
ALTER TABLE ONLY "public"."audit_log" FORCE ROW LEVEL SECURITY;


CREATE POLICY "audit_log_admin_read" ON "public"."audit_log"
    FOR SELECT
    USING (public.is_admin_reader());



CREATE POLICY "audit_log_admin_append" ON "public"."audit_log"
    FOR INSERT
    WITH CHECK (public.is_admin());














ALTER TABLE "public"."bar_numbers" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "bar_numbers_platform_full" ON "public"."bar_numbers" USING (("public"."auth_role"() = 'platform'::"text")) WITH CHECK (("public"."auth_role"() = 'platform'::"text"));



CREATE POLICY "bar_numbers_vendor_manage" ON "public"."bar_numbers" FOR INSERT WITH CHECK ((("public"."auth_role"() = 'vendor_manager'::"text") AND ("public"."auth_bar_id"() = "bar_id")));



CREATE POLICY "bar_numbers_vendor_select" ON "public"."bar_numbers" FOR SELECT USING ((("public"."auth_role"() = ANY (ARRAY['vendor_manager'::"text", 'vendor_staff'::"text"])) AND ("public"."auth_bar_id"() = "bar_id")));



CREATE POLICY "bar_numbers_vendor_update" ON "public"."bar_numbers" FOR UPDATE USING ((("public"."auth_role"() = 'vendor_manager'::"text") AND ("public"."auth_bar_id"() = "bar_id"))) WITH CHECK ((("public"."auth_role"() = 'vendor_manager'::"text") AND ("public"."auth_bar_id"() = "bar_id")));



ALTER TABLE "public"."bar_settings" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "bar_settings_platform_full" ON "public"."bar_settings" USING (("public"."auth_role"() = 'platform'::"text")) WITH CHECK (("public"."auth_role"() = 'platform'::"text"));



CREATE POLICY "bar_settings_vendor_rw" ON "public"."bar_settings" USING ((("public"."auth_role"() = 'vendor_manager'::"text") AND ("public"."auth_bar_id"() = "bar_id"))) WITH CHECK ((("public"."auth_role"() = 'vendor_manager'::"text") AND ("public"."auth_bar_id"() = "bar_id")));



ALTER TABLE "public"."bar_tables" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "bar_tables_customer_select" ON "public"."bar_tables" FOR SELECT USING (("public"."auth_role"() = 'customer'::"text"));



CREATE POLICY "bar_tables_platform_full" ON "public"."bar_tables" USING (("public"."auth_role"() = 'platform'::"text")) WITH CHECK (("public"."auth_role"() = 'platform'::"text"));



CREATE POLICY "bar_tables_vendor_rw" ON "public"."bar_tables" USING ((("public"."auth_role"() = 'vendor_manager'::"text") AND ("public"."auth_bar_id"() = "bar_id"))) WITH CHECK ((("public"."auth_role"() = 'vendor_manager'::"text") AND ("public"."auth_bar_id"() = "bar_id")));



CREATE POLICY "bar_tables_vendor_select" ON "public"."bar_tables" FOR SELECT USING ((("public"."auth_role"() = ANY (ARRAY['vendor_manager'::"text", 'vendor_staff'::"text"])) AND ("public"."auth_bar_id"() = "bar_id")));



ALTER TABLE "public"."bars" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "bars_platform_full" ON "public"."bars" USING (("public"."auth_role"() = 'platform'::"text")) WITH CHECK (("public"."auth_role"() = 'platform'::"text"));



CREATE POLICY "bars_vendor_select" ON "public"."bars" FOR SELECT USING ((("public"."auth_role"() = ANY (ARRAY['vendor_manager'::"text", 'vendor_staff'::"text"])) AND ("public"."auth_bar_id"() = "id")));



CREATE POLICY "bars_vendor_update" ON "public"."bars" FOR UPDATE USING ((("public"."auth_role"() = 'vendor_manager'::"text") AND ("public"."auth_bar_id"() = "id"))) WITH CHECK ((("public"."auth_role"() = 'vendor_manager'::"text") AND ("public"."auth_bar_id"() = "id")));



ALTER TABLE "public"."basket_contributions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "basket_contributions_select_related" ON "public"."basket_contributions" FOR SELECT USING ((("auth"."role"() = 'service_role'::"text") OR (("auth"."uid"() IS NOT NULL) AND (("profile_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."basket_members" "bm"
  WHERE (("bm"."basket_id" = "basket_contributions"."basket_id") AND (("bm"."profile_id" = "auth"."uid"()) OR ("bm"."user_id" = "auth"."uid"()) OR (COALESCE("bm"."whatsapp", ''::"text") = COALESCE("public"."profile_wa"("auth"."uid"()), ''::"text"))))))))));



ALTER TABLE "public"."basket_members" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "basket_members_block_writes" ON "public"."basket_members" USING (false) WITH CHECK (false);



CREATE POLICY "basket_members_delete_self" ON "public"."basket_members" FOR DELETE USING ((("auth"."role"() = 'service_role'::"text") OR (("auth"."uid"() IS NOT NULL) AND (("profile_id" = "auth"."uid"()) OR ("user_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."baskets" "b"
  WHERE (("b"."id" = "basket_members"."basket_id") AND ("b"."owner_profile_id" = "auth"."uid"()))))))));



CREATE POLICY "basket_members_insert_self" ON "public"."basket_members" FOR INSERT WITH CHECK ((("auth"."role"() = 'service_role'::"text") OR (("auth"."uid"() IS NOT NULL) AND ((COALESCE("user_id", "profile_id") = "auth"."uid"()) OR (COALESCE("public"."profile_wa"("auth"."uid"()), ''::"text") = COALESCE("whatsapp", ''::"text"))))));



CREATE POLICY "basket_members_read_all" ON "public"."basket_members" FOR SELECT USING (true);



CREATE POLICY "basket_members_select_related" ON "public"."basket_members" FOR SELECT USING ((("auth"."role"() = 'service_role'::"text") OR (("auth"."uid"() IS NOT NULL) AND (("profile_id" = "auth"."uid"()) OR ("user_id" = "auth"."uid"()) OR (COALESCE("whatsapp", ''::"text") = COALESCE("public"."profile_wa"("auth"."uid"()), ''::"text")) OR (EXISTS ( SELECT 1
   FROM "public"."baskets" "b"
  WHERE (("b"."id" = "basket_members"."basket_id") AND ("b"."owner_profile_id" = "auth"."uid"()))))))));



ALTER TABLE "public"."baskets" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "baskets_block_writes" ON "public"."baskets" USING (false) WITH CHECK (false);



CREATE POLICY "baskets_delete_owner" ON "public"."baskets" FOR DELETE USING ((("auth"."role"() = 'service_role'::"text") OR ("owner_profile_id" = "auth"."uid"())));



CREATE POLICY "baskets_insert_owner" ON "public"."baskets" FOR INSERT WITH CHECK ((("auth"."role"() = 'service_role'::"text") OR (("auth"."uid"() IS NOT NULL) AND ("owner_profile_id" = "auth"."uid"()))));



CREATE POLICY "baskets_mutate_owner" ON "public"."baskets" FOR UPDATE USING ((("auth"."role"() = 'service_role'::"text") OR ("owner_profile_id" = "auth"."uid"()))) WITH CHECK ((("auth"."role"() = 'service_role'::"text") OR ("owner_profile_id" = "auth"."uid"())));



CREATE POLICY "baskets_read_all" ON "public"."baskets" FOR SELECT USING (true);



CREATE POLICY "baskets_select_members" ON "public"."baskets" FOR SELECT USING ((("auth"."role"() = 'service_role'::"text") OR (("auth"."uid"() IS NOT NULL) AND (("owner_profile_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."basket_members" "bm"
  WHERE (("bm"."basket_id" = "baskets"."id") AND (("bm"."profile_id" = "auth"."uid"()) OR ("bm"."user_id" = "auth"."uid"()) OR ((COALESCE("bm"."whatsapp", ''::"text") <> ''::"text") AND ("bm"."whatsapp" = COALESCE("public"."profile_wa"("auth"."uid"()), ''::"text")))))))))));



ALTER TABLE "public"."businesses" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "businesses_block_writes" ON "public"."businesses" USING (false) WITH CHECK (false);



CREATE POLICY "businesses_read_all" ON "public"."businesses" FOR SELECT USING (true);



ALTER TABLE "public"."call_consents" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."campaign_targets" ENABLE ROW LEVEL SECURITY;
ALTER TABLE ONLY "public"."campaign_targets" FORCE ROW LEVEL SECURITY;


CREATE POLICY "campaign_targets_admin_manage" ON "public"."campaign_targets"
    FOR ALL
    USING (public.is_admin())
    WITH CHECK (public.is_admin());














ALTER TABLE "public"."campaigns" ENABLE ROW LEVEL SECURITY;
ALTER TABLE ONLY "public"."campaigns" FORCE ROW LEVEL SECURITY;


CREATE POLICY "campaigns_admin_manage" ON "public"."campaigns"
    FOR ALL
    USING (public.is_admin())
    WITH CHECK (public.is_admin());



CREATE POLICY "campaigns_admin_read" ON "public"."campaigns"
    FOR SELECT
    USING (public.is_admin_reader());




















ALTER TABLE "public"."cart_items" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "cart_items_customer_rw" ON "public"."cart_items" USING ((("public"."auth_role"() = 'customer'::"text") AND (EXISTS ( SELECT 1
   FROM "public"."carts" "c"
  WHERE (("c"."id" = "cart_items"."cart_id") AND ("c"."profile_id" = "public"."auth_profile_id"())))))) WITH CHECK ((("public"."auth_role"() = 'customer'::"text") AND (EXISTS ( SELECT 1
   FROM "public"."carts" "c"
  WHERE (("c"."id" = "cart_items"."cart_id") AND ("c"."profile_id" = "public"."auth_profile_id"()))))));



CREATE POLICY "cart_items_platform_full" ON "public"."cart_items" USING (("public"."auth_role"() = 'platform'::"text")) WITH CHECK (("public"."auth_role"() = 'platform'::"text"));



ALTER TABLE "public"."carts" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "carts_customer_rw" ON "public"."carts" USING ((("public"."auth_role"() = 'customer'::"text") AND ("public"."auth_profile_id"() = "profile_id"))) WITH CHECK ((("public"."auth_role"() = 'customer'::"text") AND ("public"."auth_profile_id"() = "profile_id")));



CREATE POLICY "carts_platform_full" ON "public"."carts" USING (("public"."auth_role"() = 'platform'::"text")) WITH CHECK (("public"."auth_role"() = 'platform'::"text"));



CREATE POLICY "carts_vendor_select" ON "public"."carts" FOR SELECT USING ((("public"."auth_role"() = ANY (ARRAY['vendor_manager'::"text", 'vendor_staff'::"text"])) AND ("public"."auth_bar_id"() = "bar_id")));



ALTER TABLE "public"."categories" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "categories_platform_full" ON "public"."categories" USING (("public"."auth_role"() = 'platform'::"text")) WITH CHECK (("public"."auth_role"() = 'platform'::"text"));



CREATE POLICY "categories_published_select" ON "public"."categories" FOR SELECT USING ((("public"."auth_role"() = ANY (ARRAY['customer'::"text", 'vendor_manager'::"text", 'vendor_staff'::"text"])) AND (("public"."auth_role"() = 'customer'::"text") OR ("public"."auth_bar_id"() = "bar_id"))));



CREATE POLICY "categories_vendor_manage" ON "public"."categories" USING ((("public"."auth_role"() = 'vendor_manager'::"text") AND ("public"."auth_bar_id"() = "bar_id"))) WITH CHECK ((("public"."auth_role"() = 'vendor_manager'::"text") AND ("public"."auth_bar_id"() = "bar_id")));



ALTER TABLE "public"."chat_sessions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."chat_state" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."conversations" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "deny_all_app_config" ON "public"."app_config" USING (false);



CREATE POLICY "deny_all_biz" ON "public"."businesses" USING (false);



CREATE POLICY "deny_all_chat_state" ON "public"."chat_state" USING (false);



CREATE POLICY "deny_all_cs" ON "public"."chat_sessions" USING (false);



CREATE POLICY "deny_all_driver_status" ON "public"."driver_status" USING (false);



CREATE POLICY "deny_all_il" ON "public"."insurance_leads" USING (false);



CREATE POLICY "deny_all_im" ON "public"."insurance_media" USING (false);



CREATE POLICY "deny_all_marketplace_categories" ON "public"."marketplace_categories" USING (false);



CREATE POLICY "deny_all_profiles" ON "public"."profiles" USING (false);



CREATE POLICY "deny_all_shops" ON "public"."shops" USING (false);



CREATE POLICY "deny_all_trips" ON "public"."trips" USING (false);



CREATE POLICY "deny_all_wa_events" ON "public"."wa_events" USING (false);



CREATE POLICY "deny_all_wa_in" ON "public"."wa_inbound" USING (false);



ALTER TABLE "public"."driver_availability" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."driver_presence" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "driver_presence_block_writes" ON "public"."driver_presence" USING (false) WITH CHECK (false);



CREATE POLICY "driver_presence_read" ON "public"."driver_presence" FOR SELECT USING (true);



CREATE POLICY "driver_presence_read_all" ON "public"."driver_presence" FOR SELECT USING (true);



ALTER TABLE "public"."driver_status" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."drivers" ENABLE ROW LEVEL SECURITY;





ALTER TABLE "public"."flow_submissions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "flow_submissions_platform_full" ON "public"."flow_submissions" USING (("public"."auth_role"() = 'platform'::"text")) WITH CHECK (("public"."auth_role"() = 'platform'::"text"));



CREATE POLICY "generic_platform_read" ON "public"."bars" FOR SELECT USING (("public"."auth_role"() = 'platform'::"text"));



ALTER TABLE "public"."idempotency_keys" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "idempotency_keys_rw" ON "public"."idempotency_keys" USING (("app"."current_role"() = ANY (ARRAY['admin'::"text", 'ops'::"text"]))) WITH CHECK (("app"."current_role"() = ANY (ARRAY['admin'::"text", 'ops'::"text"])));



ALTER TABLE "public"."insurance_documents" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."insurance_intents" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."insurance_leads" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "insurance_leads_block_writes" ON "public"."insurance_leads" USING (false) WITH CHECK (false);



CREATE POLICY "insurance_leads_read_all" ON "public"."insurance_leads" FOR SELECT USING (true);



ALTER TABLE "public"."insurance_media" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."insurance_quotes" ENABLE ROW LEVEL SECURITY;
ALTER TABLE ONLY "public"."insurance_quotes" FORCE ROW LEVEL SECURITY;


CREATE POLICY "insurance_quotes_admin_manage" ON "public"."insurance_quotes"
    FOR ALL
    USING (public.is_admin())
    WITH CHECK (public.is_admin());



CREATE POLICY "insurance_quotes_admin_read" ON "public"."insurance_quotes"
    FOR SELECT
    USING (public.is_admin_reader());



CREATE POLICY "insurance_quotes_owner_read" ON "public"."insurance_quotes"
    FOR SELECT
    USING ((auth.uid() IS NOT NULL) AND (auth.uid() = "user_id"));














ALTER TABLE "public"."item_modifiers" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "item_modifiers_platform_full" ON "public"."item_modifiers" USING (("public"."auth_role"() = 'platform'::"text")) WITH CHECK (("public"."auth_role"() = 'platform'::"text"));



CREATE POLICY "item_modifiers_vendor_rw" ON "public"."item_modifiers" USING ((("public"."auth_role"() = 'vendor_manager'::"text") AND ("public"."auth_bar_id"() = ( SELECT "items"."bar_id"
   FROM "public"."items"
  WHERE ("items"."id" = "item_modifiers"."item_id"))))) WITH CHECK ((("public"."auth_role"() = 'vendor_manager'::"text") AND ("public"."auth_bar_id"() = ( SELECT "items"."bar_id"
   FROM "public"."items"
  WHERE ("items"."id" = "item_modifiers"."item_id")))));



ALTER TABLE "public"."items" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "items_platform_full" ON "public"."items" USING (("public"."auth_role"() = 'platform'::"text")) WITH CHECK (("public"."auth_role"() = 'platform'::"text"));



CREATE POLICY "items_published_select" ON "public"."items" FOR SELECT USING ((("public"."auth_role"() = ANY (ARRAY['customer'::"text", 'vendor_manager'::"text", 'vendor_staff'::"text"])) AND (("public"."auth_role"() = 'customer'::"text") OR ("public"."auth_bar_id"() = "bar_id"))));



CREATE POLICY "items_vendor_manage" ON "public"."items" USING ((("public"."auth_role"() = 'vendor_manager'::"text") AND ("public"."auth_bar_id"() = "bar_id"))) WITH CHECK ((("public"."auth_role"() = 'vendor_manager'::"text") AND ("public"."auth_bar_id"() = "bar_id")));



ALTER TABLE "public"."marketplace_categories" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "mc_public_read_active" ON "public"."marketplace_categories" FOR SELECT TO "authenticated", "anon" USING ((COALESCE("is_active", true) = true));



ALTER TABLE "public"."mcp_tool_calls" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."menus" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "menus_platform_full" ON "public"."menus" USING (("public"."auth_role"() = 'platform'::"text")) WITH CHECK (("public"."auth_role"() = 'platform'::"text"));



CREATE POLICY "menus_published_select" ON "public"."menus" FOR SELECT USING ((("public"."auth_role"() = ANY (ARRAY['customer'::"text", 'vendor_manager'::"text", 'vendor_staff'::"text"])) AND (("public"."auth_role"() = 'customer'::"text") OR ("public"."auth_bar_id"() = "bar_id"))));



CREATE POLICY "menus_vendor_manage" ON "public"."menus" USING ((("public"."auth_role"() = 'vendor_manager'::"text") AND ("public"."auth_bar_id"() = "bar_id"))) WITH CHECK ((("public"."auth_role"() = 'vendor_manager'::"text") AND ("public"."auth_bar_id"() = "bar_id")));



ALTER TABLE "public"."messages" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "no_driver_presence_mod" ON "public"."driver_presence" USING (false) WITH CHECK (false);



CREATE POLICY "no_profiles_mod" ON "public"."profiles" USING (false) WITH CHECK (false);






CREATE POLICY "no_subscriptions_mod" ON "public"."subscriptions" USING (false) WITH CHECK (false);



CREATE POLICY "no_trips_mod" ON "public"."trips" USING (false) WITH CHECK (false);



ALTER TABLE "public"."notifications" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "notifications_delete" ON "public"."notifications" FOR DELETE USING (("app"."current_role"() = 'admin'::"text"));



CREATE POLICY "notifications_platform_full" ON "public"."notifications" USING (("public"."auth_role"() = 'platform'::"text")) WITH CHECK (("public"."auth_role"() = 'platform'::"text"));



CREATE POLICY "notifications_role_select" ON "public"."notifications" FOR SELECT USING (((("public"."auth_role"() = 'customer'::"text") AND ("public"."auth_wa_id"() = "to_wa_id")) OR (("public"."auth_role"() = ANY (ARRAY['vendor_manager'::"text", 'vendor_staff'::"text"])) AND (EXISTS ( SELECT 1
   FROM "public"."orders"
  WHERE (("orders"."id" = "notifications"."order_id") AND ("orders"."bar_id" = "public"."auth_bar_id"())))))));



CREATE POLICY "notifications_select" ON "public"."notifications" FOR SELECT USING (("app"."current_role"() = ANY (ARRAY['admin'::"text", 'ops'::"text"])));



CREATE POLICY "notifications_update" ON "public"."notifications" FOR UPDATE USING (("app"."current_role"() = ANY (ARRAY['admin'::"text", 'ops'::"text"]))) WITH CHECK (("app"."current_role"() = ANY (ARRAY['admin'::"text", 'ops'::"text"])));



ALTER TABLE "public"."ocr_jobs" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "ocr_jobs_platform_full" ON "public"."ocr_jobs" USING (("public"."auth_role"() = 'platform'::"text")) WITH CHECK (("public"."auth_role"() = 'platform'::"text"));



CREATE POLICY "ocr_jobs_vendor_select" ON "public"."ocr_jobs" FOR SELECT USING ((("public"."auth_role"() = 'vendor_manager'::"text") AND ("public"."auth_bar_id"() = "bar_id")));



ALTER TABLE "public"."order_events" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "order_events_block_writes" ON "public"."order_events" USING (false) WITH CHECK (false);



CREATE POLICY "order_events_customer_select" ON "public"."order_events" FOR SELECT USING ((("public"."auth_role"() = 'customer'::"text") AND (EXISTS ( SELECT 1
   FROM "public"."orders" "o"
  WHERE (("o"."id" = "order_events"."order_id") AND ("o"."profile_id" = "public"."auth_profile_id"()))))));



CREATE POLICY "order_events_platform_full" ON "public"."order_events" USING (("public"."auth_role"() = 'platform'::"text")) WITH CHECK (("public"."auth_role"() = 'platform'::"text"));



CREATE POLICY "order_events_read_all" ON "public"."order_events" FOR SELECT USING (true);



CREATE POLICY "order_events_vendor_rw" ON "public"."order_events" USING ((("public"."auth_role"() = ANY (ARRAY['vendor_manager'::"text", 'vendor_staff'::"text"])) AND (EXISTS ( SELECT 1
   FROM "public"."orders"
  WHERE (("orders"."id" = "order_events"."order_id") AND ("orders"."bar_id" = "public"."auth_bar_id"())))))) WITH CHECK ((("public"."auth_role"() = ANY (ARRAY['vendor_manager'::"text", 'vendor_staff'::"text"])) AND (EXISTS ( SELECT 1
   FROM "public"."orders"
  WHERE (("orders"."id" = "order_events"."order_id") AND ("orders"."bar_id" = "public"."auth_bar_id"()))))));



ALTER TABLE "public"."order_items" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "order_items_customer_select" ON "public"."order_items" FOR SELECT USING ((("public"."auth_role"() = 'customer'::"text") AND (EXISTS ( SELECT 1
   FROM "public"."orders" "o"
  WHERE (("o"."id" = "order_items"."order_id") AND ("o"."profile_id" = "public"."auth_profile_id"()))))));



CREATE POLICY "order_items_platform_full" ON "public"."order_items" USING (("public"."auth_role"() = 'platform'::"text")) WITH CHECK (("public"."auth_role"() = 'platform'::"text"));



CREATE POLICY "order_items_vendor_select" ON "public"."order_items" FOR SELECT USING ((("public"."auth_role"() = ANY (ARRAY['vendor_manager'::"text", 'vendor_staff'::"text"])) AND (EXISTS ( SELECT 1
   FROM "public"."orders"
  WHERE (("orders"."id" = "order_items"."order_id") AND ("orders"."bar_id" = "public"."auth_bar_id"()))))));



ALTER TABLE "public"."orders" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "orders_block_writes" ON "public"."orders" USING (false) WITH CHECK (false);



CREATE POLICY "orders_customer_select" ON "public"."orders" FOR SELECT USING ((("public"."auth_role"() = ANY (ARRAY['customer'::"text", 'platform'::"text"])) AND (("public"."auth_role"() = 'platform'::"text") OR ("public"."auth_profile_id"() = "profile_id"))));



CREATE POLICY "orders_platform_full" ON "public"."orders" USING (("public"."auth_role"() = 'platform'::"text")) WITH CHECK (("public"."auth_role"() = 'platform'::"text"));



CREATE POLICY "orders_read_all" ON "public"."orders" FOR SELECT USING (true);



CREATE POLICY "orders_vendor_rw" ON "public"."orders" USING ((("public"."auth_role"() = ANY (ARRAY['vendor_manager'::"text", 'vendor_staff'::"text"])) AND ("public"."auth_bar_id"() = "bar_id"))) WITH CHECK ((("public"."auth_role"() = ANY (ARRAY['vendor_manager'::"text", 'vendor_staff'::"text"])) AND ("public"."auth_bar_id"() = "bar_id")));



ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "profiles_block_writes" ON "public"."profiles" USING (false) WITH CHECK (false);



CREATE POLICY "profiles_read" ON "public"."profiles" FOR SELECT USING (true);



CREATE POLICY "profiles_read_all" ON "public"."profiles" FOR SELECT USING (true);



ALTER TABLE "public"."qr_tokens" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "qr_tokens_delete" ON "public"."qr_tokens" FOR DELETE USING (("app"."current_role"() = 'admin'::"text"));



CREATE POLICY "qr_tokens_insert" ON "public"."qr_tokens" FOR INSERT WITH CHECK (("app"."current_role"() = ANY (ARRAY['admin'::"text", 'ops'::"text"])));



CREATE POLICY "qr_tokens_select" ON "public"."qr_tokens" FOR SELECT USING (("app"."current_role"() = ANY (ARRAY['admin'::"text", 'ops'::"text", 'station'::"text"])));



CREATE POLICY "qr_tokens_update" ON "public"."qr_tokens" FOR UPDATE USING (("app"."current_role"() = ANY (ARRAY['admin'::"text", 'ops'::"text"]))) WITH CHECK (("app"."current_role"() = ANY (ARRAY['admin'::"text", 'ops'::"text"])));



ALTER TABLE "public"."ride_candidates" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."rides" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."sessions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "sessions_platform_full" ON "public"."sessions" USING (("public"."auth_role"() = 'platform'::"text")) WITH CHECK (("public"."auth_role"() = 'platform'::"text"));



CREATE POLICY "sessions_role_rw" ON "public"."sessions" USING ((("public"."auth_role"() = 'platform'::"text") OR (("public"."auth_role"() = 'customer'::"text") AND ("public"."auth_profile_id"() = "profile_id")))) WITH CHECK ((("public"."auth_role"() = 'platform'::"text") OR (("public"."auth_role"() = 'customer'::"text") AND ("public"."auth_profile_id"() = "profile_id"))));



ALTER TABLE "public"."settings" ENABLE ROW LEVEL SECURITY;
ALTER TABLE ONLY "public"."settings" FORCE ROW LEVEL SECURITY;


CREATE POLICY "settings_admin_manage" ON "public"."settings"
    FOR ALL
    USING (public.is_admin())
    WITH CHECK (public.is_admin());



CREATE POLICY "settings_admin_read" ON "public"."settings"
    FOR SELECT
    USING (public.is_admin_reader());























ALTER TABLE "public"."shops" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."stations" ENABLE ROW LEVEL SECURITY;
ALTER TABLE ONLY "public"."stations" FORCE ROW LEVEL SECURITY;


CREATE POLICY "stations_admin_manage" ON "public"."stations"
    FOR ALL
    USING (public.is_admin())
    WITH CHECK (public.is_admin());



CREATE POLICY "stations_admin_read" ON "public"."stations"
    FOR SELECT
    USING (public.is_admin_reader());



CREATE POLICY "stations_operator_read" ON "public"."stations"
    FOR SELECT
    USING (public.station_scope_matches("id"));














ALTER TABLE "public"."subscriptions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "subscriptions_block_writes" ON "public"."subscriptions" USING (false) WITH CHECK (false);



CREATE POLICY "subscriptions_read" ON "public"."subscriptions" FOR SELECT USING (true);



CREATE POLICY "subscriptions_read_all" ON "public"."subscriptions" FOR SELECT USING (true);



CREATE POLICY "svc_rw_call_consents" ON "public"."call_consents" USING (("auth"."role"() = 'service_role'::"text")) WITH CHECK (true);



CREATE POLICY "svc_rw_mcp_tool_calls" ON "public"."mcp_tool_calls" USING (("auth"."role"() = 'service_role'::"text")) WITH CHECK (true);



CREATE POLICY "svc_rw_transcripts" ON "public"."transcripts" USING (("auth"."role"() = 'service_role'::"text")) WITH CHECK (true);



CREATE POLICY "svc_rw_voice_calls" ON "public"."voice_calls" USING (("auth"."role"() = 'service_role'::"text")) WITH CHECK (true);



CREATE POLICY "svc_rw_voice_events" ON "public"."voice_events" USING (("auth"."role"() = 'service_role'::"text")) WITH CHECK (true);



CREATE POLICY "svc_rw_voice_memories" ON "public"."voice_memories" USING (("auth"."role"() = 'service_role'::"text")) WITH CHECK (true);



CREATE POLICY "svc_rw_wa_messages" ON "public"."wa_messages" USING (("auth"."role"() = 'service_role'::"text")) WITH CHECK (true);



CREATE POLICY "svc_rw_wa_threads" ON "public"."wa_threads" USING (("auth"."role"() = 'service_role'::"text")) WITH CHECK (true);



ALTER TABLE "public"."transcripts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."trips" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "trips_block_writes" ON "public"."trips" USING (false) WITH CHECK (false);



CREATE POLICY "trips_read" ON "public"."trips" FOR SELECT USING (true);



CREATE POLICY "trips_read_all" ON "public"."trips" FOR SELECT USING (true);



ALTER TABLE "public"."vendor_commissions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "vendor_commissions_self_select" ON "public"."vendor_commissions" FOR SELECT USING ((("auth"."uid"() IS NOT NULL) AND ("auth"."uid"() = "vendor_profile_id")));



CREATE POLICY "vendor_commissions_service_all" ON "public"."vendor_commissions" USING (("auth"."role"() = 'service_role'::"text")) WITH CHECK (("auth"."role"() = 'service_role'::"text"));



ALTER TABLE "public"."voice_call_outcomes" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "voice_call_outcomes_service_policy" ON "public"."voice_call_outcomes" USING (("auth"."role"() = 'service_role'::"text")) WITH CHECK (("auth"."role"() = 'service_role'::"text"));



ALTER TABLE "public"."voice_calls" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."voice_events" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."voice_followups" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "voice_followups_service_policy" ON "public"."voice_followups" USING (("auth"."role"() = 'service_role'::"text")) WITH CHECK (("auth"."role"() = 'service_role'::"text"));



ALTER TABLE "public"."voice_memories" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."voucher_events" ENABLE ROW LEVEL SECURITY;
ALTER TABLE ONLY "public"."voucher_events" FORCE ROW LEVEL SECURITY;


CREATE POLICY "voucher_events_admin_manage" ON "public"."voucher_events"
    FOR ALL
    USING (public.is_admin())
    WITH CHECK (public.is_admin());



CREATE POLICY "voucher_events_admin_read" ON "public"."voucher_events"
    FOR SELECT
    USING (public.is_admin_reader());



CREATE POLICY "voucher_events_station_read" ON "public"."voucher_events"
    FOR SELECT
    USING (public.station_scope_matches("station_id"));





ALTER TABLE "public"."vouchers" ENABLE ROW LEVEL SECURITY;
ALTER TABLE ONLY "public"."vouchers" FORCE ROW LEVEL SECURITY;


CREATE POLICY "vouchers_admin_manage" ON "public"."vouchers"
    FOR ALL
    USING (public.is_admin())
    WITH CHECK (public.is_admin());



CREATE POLICY "vouchers_admin_read" ON "public"."vouchers"
    FOR SELECT
    USING (public.is_admin_reader());



CREATE POLICY "vouchers_owner_read" ON "public"."vouchers"
    FOR SELECT
    USING ((auth.uid() IS NOT NULL) AND (auth.uid() = "user_id"));



CREATE POLICY "vouchers_station_read" ON "public"."vouchers"
    FOR SELECT
    USING ((public.station_scope_matches("station_scope")) OR (public.station_scope_matches("redeemed_by_station_id")));





ALTER TABLE "public"."wa_contacts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."wa_events" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."wa_inbound" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."wa_messages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."wa_threads" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."wallet_accounts" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "wallet_accounts_block_writes" ON "public"."wallet_accounts" USING (false) WITH CHECK (false);



CREATE POLICY "wallet_accounts_read_all" ON "public"."wallet_accounts" FOR SELECT USING (true);



ALTER TABLE "public"."wallet_redemptions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "wallet_redemptions_self_select" ON "public"."wallet_redemptions" FOR SELECT USING ((("auth"."uid"() IS NOT NULL) AND ("auth"."uid"() = "profile_id")));



CREATE POLICY "wallet_redemptions_service_all" ON "public"."wallet_redemptions" USING (("auth"."role"() = 'service_role'::"text")) WITH CHECK (("auth"."role"() = 'service_role'::"text"));



ALTER TABLE "public"."wallet_topups_momo" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "wallet_topups_momo_self_select" ON "public"."wallet_topups_momo" FOR SELECT USING ((("auth"."uid"() IS NOT NULL) AND ("auth"."uid"() = "vendor_profile_id")));



CREATE POLICY "wallet_topups_momo_service_all" ON "public"."wallet_topups_momo" USING (("auth"."role"() = 'service_role'::"text")) WITH CHECK (("auth"."role"() = 'service_role'::"text"));



ALTER TABLE "public"."wallet_transactions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "wallet_transactions_block_writes" ON "public"."wallet_transactions" USING (false) WITH CHECK (false);



CREATE POLICY "wallet_transactions_read_all" ON "public"."wallet_transactions" FOR SELECT USING (true);



ALTER TABLE "public"."webhook_logs" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "webhook_logs_platform_full" ON "public"."webhook_logs" USING (("public"."auth_role"() = 'platform'::"text")) WITH CHECK (("public"."auth_role"() = 'platform'::"text"));



REVOKE USAGE ON SCHEMA "public" FROM PUBLIC;
GRANT ALL ON SCHEMA "public" TO PUBLIC;
GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";
GRANT USAGE ON SCHEMA "public" TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."_touch_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."_touch_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."_touch_updated_at"() TO "service_role";
GRANT ALL ON FUNCTION "public"."_touch_updated_at"() TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."admin_sub_command"("_action" "text", "_reference" "text", "_actor" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."admin_sub_command"("_action" "text", "_reference" "text", "_actor" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_sub_command"("_action" "text", "_reference" "text", "_actor" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."admin_sub_command"("_action" "text", "_reference" "text", "_actor" "text") TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."admin_sub_list_pending"("_limit" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."admin_sub_list_pending"("_limit" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_sub_list_pending"("_limit" integer) TO "service_role";
GRANT ALL ON FUNCTION "public"."admin_sub_list_pending"("_limit" integer) TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."agent_doc_search_vec"("_agent_id" "uuid", "_embed" "text", "_top_k" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."agent_doc_search_vec"("_agent_id" "uuid", "_embed" "text", "_top_k" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."agent_doc_search_vec"("_agent_id" "uuid", "_embed" "text", "_top_k" integer) TO "service_role";
GRANT ALL ON FUNCTION "public"."agent_doc_search_vec"("_agent_id" "uuid", "_embed" "text", "_top_k" integer) TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."agent_vectors_summary"() TO "anon";
GRANT ALL ON FUNCTION "public"."agent_vectors_summary"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."agent_vectors_summary"() TO "service_role";
GRANT ALL ON FUNCTION "public"."agent_vectors_summary"() TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."audit_log_sync_admin_columns"() TO "anon";
GRANT ALL ON FUNCTION "public"."audit_log_sync_admin_columns"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."audit_log_sync_admin_columns"() TO "service_role";
GRANT ALL ON FUNCTION "public"."audit_log_sync_admin_columns"() TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."auth_bar_id"() TO "anon";
GRANT ALL ON FUNCTION "public"."auth_bar_id"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."auth_bar_id"() TO "service_role";
GRANT ALL ON FUNCTION "public"."auth_bar_id"() TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."auth_claim"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."auth_claim"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."auth_claim"("text") TO "service_role";
GRANT ALL ON FUNCTION "public"."auth_claim"("text") TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."auth_customer_id"() TO "anon";
GRANT ALL ON FUNCTION "public"."auth_customer_id"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."auth_customer_id"() TO "service_role";
GRANT ALL ON FUNCTION "public"."auth_customer_id"() TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."auth_profile_id"() TO "anon";
GRANT ALL ON FUNCTION "public"."auth_profile_id"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."auth_profile_id"() TO "service_role";
GRANT ALL ON FUNCTION "public"."auth_profile_id"() TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."auth_role"() TO "anon";
GRANT ALL ON FUNCTION "public"."auth_role"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."auth_role"() TO "service_role";
GRANT ALL ON FUNCTION "public"."auth_role"() TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."auth_wa_id"() TO "anon";
GRANT ALL ON FUNCTION "public"."auth_wa_id"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."auth_wa_id"() TO "service_role";
GRANT ALL ON FUNCTION "public"."auth_wa_id"() TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."basket_close"("_profile_id" "uuid", "_basket_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."basket_close"("_profile_id" "uuid", "_basket_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."basket_close"("_profile_id" "uuid", "_basket_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."basket_close"("_profile_id" "uuid", "_basket_id" "uuid") TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."basket_create"("_profile_id" "uuid", "_whatsapp" "text", "_name" "text", "_is_public" boolean, "_goal_minor" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."basket_create"("_profile_id" "uuid", "_whatsapp" "text", "_name" "text", "_is_public" boolean, "_goal_minor" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."basket_create"("_profile_id" "uuid", "_whatsapp" "text", "_name" "text", "_is_public" boolean, "_goal_minor" integer) TO "service_role";
GRANT ALL ON FUNCTION "public"."basket_create"("_profile_id" "uuid", "_whatsapp" "text", "_name" "text", "_is_public" boolean, "_goal_minor" integer) TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."basket_create"("_profile_id" "uuid", "_whatsapp" "text", "_name" "text", "_is_public" boolean, "_goal_minor" numeric) TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."basket_detail"("_profile_id" "uuid", "_basket_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."basket_detail"("_profile_id" "uuid", "_basket_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."basket_detail"("_profile_id" "uuid", "_basket_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."basket_detail"("_profile_id" "uuid", "_basket_id" "uuid") TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."basket_discover_nearby"("_profile_id" "uuid", "_lat" double precision, "_lng" double precision, "_limit" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."basket_discover_nearby"("_profile_id" "uuid", "_lat" double precision, "_lng" double precision, "_limit" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."basket_discover_nearby"("_profile_id" "uuid", "_lat" double precision, "_lng" double precision, "_limit" integer) TO "service_role";
GRANT ALL ON FUNCTION "public"."basket_discover_nearby"("_profile_id" "uuid", "_lat" double precision, "_lng" double precision, "_limit" integer) TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."basket_generate_qr"("_profile_id" "uuid", "_basket_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."basket_generate_qr"("_profile_id" "uuid", "_basket_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."basket_generate_qr"("_profile_id" "uuid", "_basket_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."basket_generate_qr"("_profile_id" "uuid", "_basket_id" "uuid") TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."basket_join_by_code"("_profile_id" "uuid", "_whatsapp" "text", "_code" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."basket_join_by_code"("_profile_id" "uuid", "_whatsapp" "text", "_code" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."basket_join_by_code"("_profile_id" "uuid", "_whatsapp" "text", "_code" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."basket_join_by_code"("_profile_id" "uuid", "_whatsapp" "text", "_code" "text") TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."basket_leave"("_profile_id" "uuid", "_basket_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."basket_leave"("_profile_id" "uuid", "_basket_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."basket_leave"("_profile_id" "uuid", "_basket_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."basket_leave"("_profile_id" "uuid", "_basket_id" "uuid") TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."basket_list_mine"("_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."basket_list_mine"("_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."basket_list_mine"("_profile_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."basket_list_mine"("_profile_id" "uuid") TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."dashboard_snapshot"() TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."fn_assert_basket_create_rate_limit"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_assert_basket_create_rate_limit"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_assert_basket_create_rate_limit"() TO "service_role";
GRANT ALL ON FUNCTION "public"."fn_assert_basket_create_rate_limit"() TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."fn_sync_basket_invites_to_baskets"() TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."fn_sync_basket_members_to_ibimina"() TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."fn_sync_baskets_to_ibimina"() TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."gate_pro_feature"("_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."gate_pro_feature"("_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gate_pro_feature"("_user_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."gate_pro_feature"("_user_id" "uuid") TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."generate_order_code"() TO "anon";
GRANT ALL ON FUNCTION "public"."generate_order_code"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."generate_order_code"() TO "service_role";
GRANT ALL ON FUNCTION "public"."generate_order_code"() TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."haversine_km"("lat1" double precision, "lng1" double precision, "lat2" double precision, "lng2" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."haversine_km"("lat1" double precision, "lng1" double precision, "lat2" double precision, "lng2" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."haversine_km"("lat1" double precision, "lng1" double precision, "lat2" double precision, "lng2" double precision) TO "service_role";
GRANT ALL ON FUNCTION "public"."haversine_km"("lat1" double precision, "lng1" double precision, "lat2" double precision, "lng2" double precision) TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."insurance_queue_media"("_profile_id" "uuid", "_wa_id" "text", "_storage_path" "text", "_mime_type" "text", "_caption" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."insurance_queue_media"("_profile_id" "uuid", "_wa_id" "text", "_storage_path" "text", "_mime_type" "text", "_caption" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."insurance_queue_media"("_profile_id" "uuid", "_wa_id" "text", "_storage_path" "text", "_mime_type" "text", "_caption" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."insurance_queue_media"("_profile_id" "uuid", "_wa_id" "text", "_storage_path" "text", "_mime_type" "text", "_caption" "text") TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."is_admin"() TO "anon";
GRANT ALL ON FUNCTION "public"."is_admin"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_admin"() TO "service_role";
GRANT ALL ON FUNCTION "public"."is_admin"() TO "wa_edge_role";
GRANT ALL ON FUNCTION "public"."is_admin_reader"() TO "anon";
GRANT ALL ON FUNCTION "public"."is_admin_reader"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_admin_reader"() TO "service_role";
GRANT ALL ON FUNCTION "public"."is_admin_reader"() TO "wa_edge_role";
GRANT ALL ON FUNCTION "public"."safe_cast_uuid"("input" text) TO "anon";
GRANT ALL ON FUNCTION "public"."safe_cast_uuid"("input" text) TO "authenticated";
GRANT ALL ON FUNCTION "public"."safe_cast_uuid"("input" text) TO "service_role";
GRANT ALL ON FUNCTION "public"."safe_cast_uuid"("input" text) TO "wa_edge_role";
GRANT ALL ON FUNCTION "public"."station_scope_matches"("target" uuid) TO "anon";
GRANT ALL ON FUNCTION "public"."station_scope_matches"("target" uuid) TO "authenticated";
GRANT ALL ON FUNCTION "public"."station_scope_matches"("target" uuid) TO "service_role";
GRANT ALL ON FUNCTION "public"."station_scope_matches"("target" uuid) TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."issue_basket_invite_token"("_basket_id" "uuid", "_created_by" "uuid", "_explicit_token" "text", "_ttl" interval) TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."km"("a" "public"."geography", "b" "public"."geography") TO "anon";
GRANT ALL ON FUNCTION "public"."km"("a" "public"."geography", "b" "public"."geography") TO "authenticated";
GRANT ALL ON FUNCTION "public"."km"("a" "public"."geography", "b" "public"."geography") TO "service_role";
GRANT ALL ON FUNCTION "public"."km"("a" "public"."geography", "b" "public"."geography") TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."mark_driver_served"("viewer_e164" "text", "driver_uuid" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."mark_driver_served"("viewer_e164" "text", "driver_uuid" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."mark_driver_served"("viewer_e164" "text", "driver_uuid" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."mark_driver_served"("viewer_e164" "text", "driver_uuid" "uuid") TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."mark_passenger_served"("viewer_e164" "text", "trip_uuid" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."mark_passenger_served"("viewer_e164" "text", "trip_uuid" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."mark_passenger_served"("viewer_e164" "text", "trip_uuid" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."mark_passenger_served"("viewer_e164" "text", "trip_uuid" "uuid") TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."mark_served"("_viewer" "text", "_kind" "text", "_target_pk" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."mark_served"("_viewer" "text", "_kind" "text", "_target_pk" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."mark_served"("_viewer" "text", "_kind" "text", "_target_pk" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."mark_served"("_viewer" "text", "_kind" "text", "_target_pk" "text") TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."marketplace_add_business"("_owner" "text", "_name" "text", "_description" "text", "_catalog" "text", "_lat" double precision, "_lng" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."marketplace_add_business"("_owner" "text", "_name" "text", "_description" "text", "_catalog" "text", "_lat" double precision, "_lng" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."marketplace_add_business"("_owner" "text", "_name" "text", "_description" "text", "_catalog" "text", "_lat" double precision, "_lng" double precision) TO "service_role";
GRANT ALL ON FUNCTION "public"."marketplace_add_business"("_owner" "text", "_name" "text", "_description" "text", "_catalog" "text", "_lat" double precision, "_lng" double precision) TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."match_agent_document_chunks"("query_embedding" "public"."vector", "target_agent_id" "uuid", "match_count" integer, "min_similarity" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."match_agent_document_chunks"("query_embedding" "public"."vector", "target_agent_id" "uuid", "match_count" integer, "min_similarity" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."match_agent_document_chunks"("query_embedding" "public"."vector", "target_agent_id" "uuid", "match_count" integer, "min_similarity" double precision) TO "service_role";
GRANT ALL ON FUNCTION "public"."match_agent_document_chunks"("query_embedding" "public"."vector", "target_agent_id" "uuid", "match_count" integer, "min_similarity" double precision) TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."match_drivers_for_trip_v2"("_trip_id" "uuid", "_limit" integer, "_prefer_dropoff" boolean, "_radius_m" integer, "_window_days" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."match_drivers_for_trip_v2"("_trip_id" "uuid", "_limit" integer, "_prefer_dropoff" boolean, "_radius_m" integer, "_window_days" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."match_drivers_for_trip_v2"("_trip_id" "uuid", "_limit" integer, "_prefer_dropoff" boolean, "_radius_m" integer, "_window_days" integer) TO "service_role";
GRANT ALL ON FUNCTION "public"."match_drivers_for_trip_v2"("_trip_id" "uuid", "_limit" integer, "_prefer_dropoff" boolean, "_radius_m" integer, "_window_days" integer) TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."match_passengers_for_trip_v2"("_trip_id" "uuid", "_limit" integer, "_prefer_dropoff" boolean, "_radius_m" integer, "_window_days" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."match_passengers_for_trip_v2"("_trip_id" "uuid", "_limit" integer, "_prefer_dropoff" boolean, "_radius_m" integer, "_window_days" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."match_passengers_for_trip_v2"("_trip_id" "uuid", "_limit" integer, "_prefer_dropoff" boolean, "_radius_m" integer, "_window_days" integer) TO "service_role";
GRANT ALL ON FUNCTION "public"."match_passengers_for_trip_v2"("_trip_id" "uuid", "_limit" integer, "_prefer_dropoff" boolean, "_radius_m" integer, "_window_days" integer) TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."mobility_buy_subscription"("_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."mobility_buy_subscription"("_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."mobility_buy_subscription"("_user_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."mobility_buy_subscription"("_user_id" "uuid") TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."nearby_businesses"("_lat" double precision, "_lng" double precision, "_viewer" "text", "_limit" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."nearby_businesses"("_lat" double precision, "_lng" double precision, "_viewer" "text", "_limit" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."nearby_businesses"("_lat" double precision, "_lng" double precision, "_viewer" "text", "_limit" integer) TO "service_role";
GRANT ALL ON FUNCTION "public"."nearby_businesses"("_lat" double precision, "_lng" double precision, "_viewer" "text", "_limit" integer) TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."nearest_drivers"("p_lat" double precision, "p_lng" double precision, "p_vehicle" "text", "p_limit" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."nearest_drivers"("p_lat" double precision, "p_lng" double precision, "p_vehicle" "text", "p_limit" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."nearest_drivers"("p_lat" double precision, "p_lng" double precision, "p_vehicle" "text", "p_limit" integer) TO "service_role";
GRANT ALL ON FUNCTION "public"."nearest_drivers"("p_lat" double precision, "p_lng" double precision, "p_vehicle" "text", "p_limit" integer) TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."notifications_sync_admin_columns"() TO "anon";
GRANT ALL ON FUNCTION "public"."notifications_sync_admin_columns"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notifications_sync_admin_columns"() TO "service_role";
GRANT ALL ON FUNCTION "public"."notifications_sync_admin_columns"() TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."on_menu_publish_refresh"() TO "anon";
GRANT ALL ON FUNCTION "public"."on_menu_publish_refresh"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."on_menu_publish_refresh"() TO "service_role";
GRANT ALL ON FUNCTION "public"."on_menu_publish_refresh"() TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."order_events_sync_admin_columns"() TO "anon";
GRANT ALL ON FUNCTION "public"."order_events_sync_admin_columns"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."order_events_sync_admin_columns"() TO "service_role";
GRANT ALL ON FUNCTION "public"."order_events_sync_admin_columns"() TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."orders_set_defaults"() TO "anon";
GRANT ALL ON FUNCTION "public"."orders_set_defaults"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."orders_set_defaults"() TO "service_role";
GRANT ALL ON FUNCTION "public"."orders_set_defaults"() TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."orders_sync_admin_columns"() TO "anon";
GRANT ALL ON FUNCTION "public"."orders_sync_admin_columns"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."orders_sync_admin_columns"() TO "service_role";
GRANT ALL ON FUNCTION "public"."orders_sync_admin_columns"() TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."profile_ref_code"("_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."profile_ref_code"("_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."profile_ref_code"("_profile_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."profile_ref_code"("_profile_id" "uuid") TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."profile_wa"("_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."profile_wa"("_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."profile_wa"("_profile_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."profile_wa"("_profile_id" "uuid") TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."publish_agent_version"("_agent_id" "uuid", "_version_id" "uuid", "_env" "public"."deploy_env") TO "anon";
GRANT ALL ON FUNCTION "public"."publish_agent_version"("_agent_id" "uuid", "_version_id" "uuid", "_env" "public"."deploy_env") TO "authenticated";
GRANT ALL ON FUNCTION "public"."publish_agent_version"("_agent_id" "uuid", "_version_id" "uuid", "_env" "public"."deploy_env") TO "service_role";
GRANT ALL ON FUNCTION "public"."publish_agent_version"("_agent_id" "uuid", "_version_id" "uuid", "_env" "public"."deploy_env") TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."purge_expired_served"() TO "anon";
GRANT ALL ON FUNCTION "public"."purge_expired_served"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."purge_expired_served"() TO "service_role";
GRANT ALL ON FUNCTION "public"."purge_expired_served"() TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."recent_businesses_near"("in_lat" double precision, "in_lng" double precision, "in_category_id" integer, "in_radius_km" numeric, "in_max" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."recent_businesses_near"("in_lat" double precision, "in_lng" double precision, "in_category_id" integer, "in_radius_km" numeric, "in_max" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."recent_businesses_near"("in_lat" double precision, "in_lng" double precision, "in_category_id" integer, "in_radius_km" numeric, "in_max" integer) TO "service_role";
GRANT ALL ON FUNCTION "public"."recent_businesses_near"("in_lat" double precision, "in_lng" double precision, "in_category_id" integer, "in_radius_km" numeric, "in_max" integer) TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."recent_drivers_near"("in_lat" double precision, "in_lng" double precision, "in_vehicle_type" "text", "in_radius_km" double precision, "in_max" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."recent_drivers_near"("in_lat" double precision, "in_lng" double precision, "in_vehicle_type" "text", "in_radius_km" double precision, "in_max" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."recent_drivers_near"("in_lat" double precision, "in_lng" double precision, "in_vehicle_type" "text", "in_radius_km" double precision, "in_max" integer) TO "service_role";
GRANT ALL ON FUNCTION "public"."recent_drivers_near"("in_lat" double precision, "in_lng" double precision, "in_vehicle_type" "text", "in_radius_km" double precision, "in_max" integer) TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."recent_drivers_near"("in_lat" double precision, "in_lng" double precision, "in_vehicle_type" "text", "in_radius_km" numeric, "in_max" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."recent_drivers_near"("in_lat" double precision, "in_lng" double precision, "in_vehicle_type" "text", "in_radius_km" numeric, "in_max" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."recent_drivers_near"("in_lat" double precision, "in_lng" double precision, "in_vehicle_type" "text", "in_radius_km" numeric, "in_max" integer) TO "service_role";
GRANT ALL ON FUNCTION "public"."recent_drivers_near"("in_lat" double precision, "in_lng" double precision, "in_vehicle_type" "text", "in_radius_km" numeric, "in_max" integer) TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."recent_passenger_trips_near"("in_lat" double precision, "in_lng" double precision, "in_vehicle_type" "text", "in_radius_km" double precision, "in_max" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."recent_passenger_trips_near"("in_lat" double precision, "in_lng" double precision, "in_vehicle_type" "text", "in_radius_km" double precision, "in_max" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."recent_passenger_trips_near"("in_lat" double precision, "in_lng" double precision, "in_vehicle_type" "text", "in_radius_km" double precision, "in_max" integer) TO "service_role";
GRANT ALL ON FUNCTION "public"."recent_passenger_trips_near"("in_lat" double precision, "in_lng" double precision, "in_vehicle_type" "text", "in_radius_km" double precision, "in_max" integer) TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."recent_passenger_trips_near"("in_lat" double precision, "in_lng" double precision, "in_vehicle_type" "text", "in_radius_km" numeric, "in_max" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."recent_passenger_trips_near"("in_lat" double precision, "in_lng" double precision, "in_vehicle_type" "text", "in_radius_km" numeric, "in_max" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."recent_passenger_trips_near"("in_lat" double precision, "in_lng" double precision, "in_vehicle_type" "text", "in_radius_km" numeric, "in_max" integer) TO "service_role";
GRANT ALL ON FUNCTION "public"."recent_passenger_trips_near"("in_lat" double precision, "in_lng" double precision, "in_vehicle_type" "text", "in_radius_km" numeric, "in_max" integer) TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."refresh_menu_items_snapshot"() TO "anon";
GRANT ALL ON FUNCTION "public"."refresh_menu_items_snapshot"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."refresh_menu_items_snapshot"() TO "service_role";
GRANT ALL ON FUNCTION "public"."refresh_menu_items_snapshot"() TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."round"("value" double precision, "ndigits" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."round"("value" double precision, "ndigits" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."round"("value" double precision, "ndigits" integer) TO "service_role";
GRANT ALL ON FUNCTION "public"."round"("value" double precision, "ndigits" integer) TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "service_role";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."upsert_agent_doc_vector"("_document_id" "uuid", "_chunk_index" integer, "_content" "text", "_embedding_json" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."upsert_agent_doc_vector"("_document_id" "uuid", "_chunk_index" integer, "_content" "text", "_embedding_json" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."upsert_agent_doc_vector"("_document_id" "uuid", "_chunk_index" integer, "_content" "text", "_embedding_json" "jsonb") TO "service_role";
GRANT ALL ON FUNCTION "public"."upsert_agent_doc_vector"("_document_id" "uuid", "_chunk_index" integer, "_content" "text", "_embedding_json" "jsonb") TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."vouchers_sync_admin_columns"() TO "anon";
GRANT ALL ON FUNCTION "public"."vouchers_sync_admin_columns"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."vouchers_sync_admin_columns"() TO "service_role";
GRANT ALL ON FUNCTION "public"."vouchers_sync_admin_columns"() TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."wallet_apply_delta"("p_user_id" "uuid", "p_delta" integer, "p_type" "text", "p_meta" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."wallet_apply_delta"("p_user_id" "uuid", "p_delta" integer, "p_type" "text", "p_meta" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."wallet_apply_delta"("p_user_id" "uuid", "p_delta" integer, "p_type" "text", "p_meta" "jsonb") TO "service_role";
GRANT ALL ON FUNCTION "public"."wallet_apply_delta"("p_user_id" "uuid", "p_delta" integer, "p_type" "text", "p_meta" "jsonb") TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."wallet_commission_pay"("_commission_id" "uuid", "_actor_vendor" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."wallet_commission_pay"("_commission_id" "uuid", "_actor_vendor" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."wallet_commission_pay"("_commission_id" "uuid", "_actor_vendor" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."wallet_commission_pay"("_commission_id" "uuid", "_actor_vendor" "uuid") TO "wa_edge_role";



GRANT ALL ON TABLE "public"."wallet_earn_actions" TO "anon";
GRANT ALL ON TABLE "public"."wallet_earn_actions" TO "authenticated";
GRANT ALL ON TABLE "public"."wallet_earn_actions" TO "service_role";



GRANT ALL ON FUNCTION "public"."wallet_earn_actions"("_profile_id" "uuid", "_limit" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."wallet_earn_actions"("_profile_id" "uuid", "_limit" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."wallet_earn_actions"("_profile_id" "uuid", "_limit" integer) TO "service_role";
GRANT ALL ON FUNCTION "public"."wallet_earn_actions"("_profile_id" "uuid", "_limit" integer) TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."wallet_momo_topup_credit"("_vendor_id" "uuid", "_amount" integer, "_reference" "text", "_metadata" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."wallet_momo_topup_credit"("_vendor_id" "uuid", "_amount" integer, "_reference" "text", "_metadata" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."wallet_momo_topup_credit"("_vendor_id" "uuid", "_amount" integer, "_reference" "text", "_metadata" "jsonb") TO "service_role";
GRANT ALL ON FUNCTION "public"."wallet_momo_topup_credit"("_vendor_id" "uuid", "_amount" integer, "_reference" "text", "_metadata" "jsonb") TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."wallet_redeem_execute"("_profile_id" "uuid", "_option_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."wallet_redeem_execute"("_profile_id" "uuid", "_option_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."wallet_redeem_execute"("_profile_id" "uuid", "_option_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."wallet_redeem_execute"("_profile_id" "uuid", "_option_id" "uuid") TO "wa_edge_role";



GRANT ALL ON TABLE "public"."wallet_redeem_options" TO "anon";
GRANT ALL ON TABLE "public"."wallet_redeem_options" TO "authenticated";
GRANT ALL ON TABLE "public"."wallet_redeem_options" TO "service_role";



GRANT ALL ON FUNCTION "public"."wallet_redeem_options"("_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."wallet_redeem_options"("_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."wallet_redeem_options"("_profile_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."wallet_redeem_options"("_profile_id" "uuid") TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."wallet_summary"("_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."wallet_summary"("_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."wallet_summary"("_profile_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."wallet_summary"("_profile_id" "uuid") TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."wallet_top_promoters"("_limit" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."wallet_top_promoters"("_limit" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."wallet_top_promoters"("_limit" integer) TO "service_role";
GRANT ALL ON FUNCTION "public"."wallet_top_promoters"("_limit" integer) TO "wa_edge_role";



GRANT ALL ON TABLE "public"."wallet_transactions" TO "anon";
GRANT ALL ON TABLE "public"."wallet_transactions" TO "authenticated";
GRANT ALL ON TABLE "public"."wallet_transactions" TO "service_role";



GRANT ALL ON FUNCTION "public"."wallet_transactions_recent"("_profile_id" "uuid", "_limit" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."wallet_transactions_recent"("_profile_id" "uuid", "_limit" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."wallet_transactions_recent"("_profile_id" "uuid", "_limit" integer) TO "service_role";
GRANT ALL ON FUNCTION "public"."wallet_transactions_recent"("_profile_id" "uuid", "_limit" integer) TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."wallet_transfer"("p_from" "uuid", "p_to" "uuid", "p_amount" integer, "p_reason" "text", "p_meta" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."wallet_transfer"("p_from" "uuid", "p_to" "uuid", "p_amount" integer, "p_reason" "text", "p_meta" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."wallet_transfer"("p_from" "uuid", "p_to" "uuid", "p_amount" integer, "p_reason" "text", "p_meta" "jsonb") TO "service_role";
GRANT ALL ON FUNCTION "public"."wallet_transfer"("p_from" "uuid", "p_to" "uuid", "p_amount" integer, "p_reason" "text", "p_meta" "jsonb") TO "wa_edge_role";



GRANT ALL ON FUNCTION "public"."wallet_vendor_summary"("_vendor_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."wallet_vendor_summary"("_vendor_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."wallet_vendor_summary"("_vendor_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."wallet_vendor_summary"("_vendor_id" "uuid") TO "wa_edge_role";



GRANT ALL ON TABLE "public"."admin_alert_prefs" TO "anon";
GRANT ALL ON TABLE "public"."admin_alert_prefs" TO "authenticated";
GRANT ALL ON TABLE "public"."admin_alert_prefs" TO "service_role";



GRANT ALL ON TABLE "public"."admin_audit_log" TO "anon";
GRANT ALL ON TABLE "public"."admin_audit_log" TO "authenticated";
GRANT ALL ON TABLE "public"."admin_audit_log" TO "service_role";



GRANT ALL ON TABLE "public"."admin_pin_sessions" TO "anon";
GRANT ALL ON TABLE "public"."admin_pin_sessions" TO "authenticated";
GRANT ALL ON TABLE "public"."admin_pin_sessions" TO "service_role";



GRANT ALL ON TABLE "public"."admin_sessions" TO "anon";
GRANT ALL ON TABLE "public"."admin_sessions" TO "authenticated";
GRANT ALL ON TABLE "public"."admin_sessions" TO "service_role";



GRANT ALL ON TABLE "public"."admin_submissions" TO "anon";
GRANT ALL ON TABLE "public"."admin_submissions" TO "authenticated";
GRANT ALL ON TABLE "public"."admin_submissions" TO "service_role";



GRANT ALL ON TABLE "public"."agent_chat_messages" TO "anon";
GRANT ALL ON TABLE "public"."agent_chat_messages" TO "authenticated";
GRANT ALL ON TABLE "public"."agent_chat_messages" TO "service_role";



GRANT ALL ON TABLE "public"."agent_chat_sessions" TO "anon";
GRANT ALL ON TABLE "public"."agent_chat_sessions" TO "authenticated";
GRANT ALL ON TABLE "public"."agent_chat_sessions" TO "service_role";



GRANT ALL ON TABLE "public"."agent_deployments" TO "anon";
GRANT ALL ON TABLE "public"."agent_deployments" TO "authenticated";
GRANT ALL ON TABLE "public"."agent_deployments" TO "service_role";



GRANT ALL ON TABLE "public"."agent_document_chunks" TO "anon";
GRANT ALL ON TABLE "public"."agent_document_chunks" TO "authenticated";
GRANT ALL ON TABLE "public"."agent_document_chunks" TO "service_role";



GRANT ALL ON TABLE "public"."agent_document_embeddings" TO "anon";
GRANT ALL ON TABLE "public"."agent_document_embeddings" TO "authenticated";
GRANT ALL ON TABLE "public"."agent_document_embeddings" TO "service_role";



GRANT ALL ON TABLE "public"."agent_document_vectors" TO "anon";
GRANT ALL ON TABLE "public"."agent_document_vectors" TO "authenticated";
GRANT ALL ON TABLE "public"."agent_document_vectors" TO "service_role";



GRANT ALL ON TABLE "public"."agent_documents" TO "anon";
GRANT ALL ON TABLE "public"."agent_documents" TO "authenticated";
GRANT ALL ON TABLE "public"."agent_documents" TO "service_role";



GRANT ALL ON TABLE "public"."agent_personas" TO "anon";
GRANT ALL ON TABLE "public"."agent_personas" TO "authenticated";
GRANT ALL ON TABLE "public"."agent_personas" TO "service_role";



GRANT ALL ON TABLE "public"."agent_runs" TO "anon";
GRANT ALL ON TABLE "public"."agent_runs" TO "authenticated";
GRANT ALL ON TABLE "public"."agent_runs" TO "service_role";



GRANT ALL ON TABLE "public"."agent_tasks" TO "anon";
GRANT ALL ON TABLE "public"."agent_tasks" TO "authenticated";
GRANT ALL ON TABLE "public"."agent_tasks" TO "service_role";



GRANT ALL ON TABLE "public"."agent_toolkits" TO "anon";
GRANT ALL ON TABLE "public"."agent_toolkits" TO "authenticated";
GRANT ALL ON TABLE "public"."agent_toolkits" TO "service_role";



GRANT ALL ON TABLE "public"."agent_versions" TO "anon";
GRANT ALL ON TABLE "public"."agent_versions" TO "authenticated";
GRANT ALL ON TABLE "public"."agent_versions" TO "service_role";



GRANT ALL ON TABLE "public"."app_config" TO "anon";
GRANT ALL ON TABLE "public"."app_config" TO "authenticated";
GRANT ALL ON TABLE "public"."app_config" TO "service_role";



GRANT ALL ON TABLE "public"."audit_log" TO "anon";
GRANT ALL ON TABLE "public"."audit_log" TO "authenticated";
GRANT ALL ON TABLE "public"."audit_log" TO "service_role";



GRANT ALL ON TABLE "public"."bar_numbers" TO "anon";
GRANT ALL ON TABLE "public"."bar_numbers" TO "authenticated";
GRANT ALL ON TABLE "public"."bar_numbers" TO "service_role";



GRANT ALL ON TABLE "public"."bar_settings" TO "anon";
GRANT ALL ON TABLE "public"."bar_settings" TO "authenticated";
GRANT ALL ON TABLE "public"."bar_settings" TO "service_role";



GRANT ALL ON TABLE "public"."bar_tables" TO "anon";
GRANT ALL ON TABLE "public"."bar_tables" TO "authenticated";
GRANT ALL ON TABLE "public"."bar_tables" TO "service_role";



GRANT ALL ON TABLE "public"."bars" TO "anon";
GRANT ALL ON TABLE "public"."bars" TO "authenticated";
GRANT ALL ON TABLE "public"."bars" TO "service_role";



GRANT ALL ON TABLE "public"."basket_contributions" TO "anon";
GRANT ALL ON TABLE "public"."basket_contributions" TO "authenticated";
GRANT ALL ON TABLE "public"."basket_contributions" TO "service_role";



GRANT ALL ON TABLE "public"."basket_members" TO "anon";
GRANT ALL ON TABLE "public"."basket_members" TO "authenticated";
GRANT ALL ON TABLE "public"."basket_members" TO "service_role";



GRANT ALL ON TABLE "public"."baskets" TO "anon";
GRANT ALL ON TABLE "public"."baskets" TO "authenticated";
GRANT ALL ON TABLE "public"."baskets" TO "service_role";



GRANT ALL ON TABLE "public"."baskets_reminder_events" TO "anon";
GRANT ALL ON TABLE "public"."baskets_reminder_events" TO "authenticated";
GRANT ALL ON TABLE "public"."baskets_reminder_events" TO "service_role";



GRANT ALL ON TABLE "public"."baskets_reminders" TO "anon";
GRANT ALL ON TABLE "public"."baskets_reminders" TO "authenticated";
GRANT ALL ON TABLE "public"."baskets_reminders" TO "service_role";



GRANT ALL ON TABLE "public"."businesses" TO "anon";
GRANT ALL ON TABLE "public"."businesses" TO "authenticated";
GRANT ALL ON TABLE "public"."businesses" TO "service_role";



GRANT ALL ON TABLE "public"."call_consents" TO "anon";
GRANT ALL ON TABLE "public"."call_consents" TO "authenticated";
GRANT ALL ON TABLE "public"."call_consents" TO "service_role";



GRANT ALL ON TABLE "public"."campaign_recipients" TO "anon";
GRANT ALL ON TABLE "public"."campaign_recipients" TO "authenticated";
GRANT ALL ON TABLE "public"."campaign_recipients" TO "service_role";



GRANT ALL ON SEQUENCE "public"."campaign_recipients_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."campaign_recipients_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."campaign_recipients_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."campaign_targets" TO "anon";
GRANT ALL ON TABLE "public"."campaign_targets" TO "authenticated";
GRANT ALL ON TABLE "public"."campaign_targets" TO "service_role";



GRANT ALL ON TABLE "public"."campaigns" TO "anon";
GRANT ALL ON TABLE "public"."campaigns" TO "authenticated";
GRANT ALL ON TABLE "public"."campaigns" TO "service_role";



GRANT ALL ON SEQUENCE "public"."campaigns_legacy_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."campaigns_legacy_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."campaigns_legacy_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."cart_items" TO "anon";
GRANT ALL ON TABLE "public"."cart_items" TO "authenticated";
GRANT ALL ON TABLE "public"."cart_items" TO "service_role";



GRANT ALL ON TABLE "public"."carts" TO "anon";
GRANT ALL ON TABLE "public"."carts" TO "authenticated";
GRANT ALL ON TABLE "public"."carts" TO "service_role";



GRANT ALL ON TABLE "public"."categories" TO "anon";
GRANT ALL ON TABLE "public"."categories" TO "authenticated";
GRANT ALL ON TABLE "public"."categories" TO "service_role";



GRANT ALL ON TABLE "public"."chat_sessions" TO "anon";
GRANT ALL ON TABLE "public"."chat_sessions" TO "authenticated";
GRANT ALL ON TABLE "public"."chat_sessions" TO "service_role";



GRANT ALL ON TABLE "public"."chat_state" TO "anon";
GRANT ALL ON TABLE "public"."chat_state" TO "authenticated";
GRANT ALL ON TABLE "public"."chat_state" TO "service_role";



GRANT ALL ON TABLE "public"."contacts" TO "anon";
GRANT ALL ON TABLE "public"."contacts" TO "authenticated";
GRANT ALL ON TABLE "public"."contacts" TO "service_role";



GRANT ALL ON SEQUENCE "public"."contacts_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."contacts_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."contacts_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."conversations" TO "anon";
GRANT ALL ON TABLE "public"."conversations" TO "authenticated";
GRANT ALL ON TABLE "public"."conversations" TO "service_role";



GRANT ALL ON TABLE "public"."driver_availability" TO "anon";
GRANT ALL ON TABLE "public"."driver_availability" TO "authenticated";
GRANT ALL ON TABLE "public"."driver_availability" TO "service_role";



GRANT ALL ON TABLE "public"."driver_presence" TO "anon";
GRANT ALL ON TABLE "public"."driver_presence" TO "authenticated";
GRANT ALL ON TABLE "public"."driver_presence" TO "service_role";



GRANT ALL ON TABLE "public"."driver_status" TO "anon";
GRANT ALL ON TABLE "public"."driver_status" TO "authenticated";
GRANT ALL ON TABLE "public"."driver_status" TO "service_role";



GRANT ALL ON TABLE "public"."drivers" TO "anon";
GRANT ALL ON TABLE "public"."drivers" TO "authenticated";
GRANT ALL ON TABLE "public"."drivers" TO "service_role";



GRANT ALL ON TABLE "public"."flow_submissions" TO "anon";
GRANT ALL ON TABLE "public"."flow_submissions" TO "authenticated";
GRANT ALL ON TABLE "public"."flow_submissions" TO "service_role";



GRANT ALL ON TABLE "public"."idempotency_keys" TO "anon";
GRANT ALL ON TABLE "public"."idempotency_keys" TO "authenticated";
GRANT ALL ON TABLE "public"."idempotency_keys" TO "service_role";



GRANT ALL ON TABLE "public"."insurance_documents" TO "anon";
GRANT ALL ON TABLE "public"."insurance_documents" TO "authenticated";
GRANT ALL ON TABLE "public"."insurance_documents" TO "service_role";



GRANT ALL ON TABLE "public"."insurance_intents" TO "anon";
GRANT ALL ON TABLE "public"."insurance_intents" TO "authenticated";
GRANT ALL ON TABLE "public"."insurance_intents" TO "service_role";



GRANT ALL ON TABLE "public"."insurance_leads" TO "anon";
GRANT ALL ON TABLE "public"."insurance_leads" TO "authenticated";
GRANT ALL ON TABLE "public"."insurance_leads" TO "service_role";



GRANT ALL ON TABLE "public"."insurance_media" TO "anon";
GRANT ALL ON TABLE "public"."insurance_media" TO "authenticated";
GRANT ALL ON TABLE "public"."insurance_media" TO "service_role";



GRANT ALL ON TABLE "public"."insurance_media_queue" TO "anon";
GRANT ALL ON TABLE "public"."insurance_media_queue" TO "authenticated";
GRANT ALL ON TABLE "public"."insurance_media_queue" TO "service_role";



GRANT ALL ON TABLE "public"."insurance_quotes" TO "anon";
GRANT ALL ON TABLE "public"."insurance_quotes" TO "authenticated";
GRANT ALL ON TABLE "public"."insurance_quotes" TO "service_role";



GRANT ALL ON TABLE "public"."item_modifiers" TO "anon";
GRANT ALL ON TABLE "public"."item_modifiers" TO "authenticated";
GRANT ALL ON TABLE "public"."item_modifiers" TO "service_role";



GRANT ALL ON TABLE "public"."items" TO "anon";
GRANT ALL ON TABLE "public"."items" TO "authenticated";
GRANT ALL ON TABLE "public"."items" TO "service_role";



GRANT ALL ON TABLE "public"."leaderboard_notifications" TO "anon";
GRANT ALL ON TABLE "public"."leaderboard_notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."leaderboard_notifications" TO "service_role";



GRANT ALL ON TABLE "public"."leaderboard_snapshots" TO "anon";
GRANT ALL ON TABLE "public"."leaderboard_snapshots" TO "authenticated";
GRANT ALL ON TABLE "public"."leaderboard_snapshots" TO "service_role";



GRANT ALL ON TABLE "public"."leaderboard_snapshots_v" TO "anon";
GRANT ALL ON TABLE "public"."leaderboard_snapshots_v" TO "authenticated";
GRANT ALL ON TABLE "public"."leaderboard_snapshots_v" TO "service_role";



GRANT ALL ON TABLE "public"."marketplace_categories" TO "anon";
GRANT ALL ON TABLE "public"."marketplace_categories" TO "authenticated";
GRANT ALL ON TABLE "public"."marketplace_categories" TO "service_role";



GRANT ALL ON SEQUENCE "public"."marketplace_categories_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."marketplace_categories_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."marketplace_categories_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."mcp_tool_calls" TO "anon";
GRANT ALL ON TABLE "public"."mcp_tool_calls" TO "authenticated";
GRANT ALL ON TABLE "public"."mcp_tool_calls" TO "service_role";



GRANT ALL ON TABLE "public"."menu_items_snapshot" TO "anon";
GRANT ALL ON TABLE "public"."menu_items_snapshot" TO "authenticated";
GRANT ALL ON TABLE "public"."menu_items_snapshot" TO "service_role";



GRANT ALL ON TABLE "public"."menus" TO "anon";
GRANT ALL ON TABLE "public"."menus" TO "authenticated";
GRANT ALL ON TABLE "public"."menus" TO "service_role";



GRANT ALL ON TABLE "public"."messages" TO "anon";
GRANT ALL ON TABLE "public"."messages" TO "authenticated";
GRANT ALL ON TABLE "public"."messages" TO "service_role";



GRANT ALL ON SEQUENCE "public"."messages_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."messages_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."messages_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."mobility_pro_access" TO "anon";
GRANT ALL ON TABLE "public"."mobility_pro_access" TO "authenticated";
GRANT ALL ON TABLE "public"."mobility_pro_access" TO "service_role";



GRANT ALL ON TABLE "public"."momo_qr_requests" TO "anon";
GRANT ALL ON TABLE "public"."momo_qr_requests" TO "authenticated";
GRANT ALL ON TABLE "public"."momo_qr_requests" TO "service_role";



GRANT ALL ON TABLE "public"."notifications" TO "anon";
GRANT ALL ON TABLE "public"."notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."notifications" TO "service_role";



GRANT ALL ON TABLE "public"."ocr_jobs" TO "anon";
GRANT ALL ON TABLE "public"."ocr_jobs" TO "authenticated";
GRANT ALL ON TABLE "public"."ocr_jobs" TO "service_role";



GRANT ALL ON SEQUENCE "public"."order_code_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."order_code_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."order_code_seq" TO "service_role";



GRANT ALL ON TABLE "public"."order_events" TO "anon";
GRANT ALL ON TABLE "public"."order_events" TO "authenticated";
GRANT ALL ON TABLE "public"."order_events" TO "service_role";



GRANT ALL ON TABLE "public"."order_items" TO "anon";
GRANT ALL ON TABLE "public"."order_items" TO "authenticated";
GRANT ALL ON TABLE "public"."order_items" TO "service_role";



GRANT ALL ON TABLE "public"."orders" TO "anon";
GRANT ALL ON TABLE "public"."orders" TO "authenticated";
GRANT ALL ON TABLE "public"."orders" TO "service_role";



GRANT ALL ON TABLE "public"."petrol_stations" TO "anon";
GRANT ALL ON TABLE "public"."petrol_stations" TO "authenticated";
GRANT ALL ON TABLE "public"."petrol_stations" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."promo_rules" TO "anon";
GRANT ALL ON TABLE "public"."promo_rules" TO "authenticated";
GRANT ALL ON TABLE "public"."promo_rules" TO "service_role";



GRANT ALL ON TABLE "public"."published_menus" TO "anon";
GRANT ALL ON TABLE "public"."published_menus" TO "authenticated";
GRANT ALL ON TABLE "public"."published_menus" TO "service_role";



GRANT ALL ON TABLE "public"."qr_tokens" TO "anon";
GRANT ALL ON TABLE "public"."qr_tokens" TO "authenticated";
GRANT ALL ON TABLE "public"."qr_tokens" TO "service_role";



GRANT ALL ON TABLE "public"."referral_attributions" TO "anon";
GRANT ALL ON TABLE "public"."referral_attributions" TO "authenticated";
GRANT ALL ON TABLE "public"."referral_attributions" TO "service_role";



GRANT ALL ON TABLE "public"."referral_clicks" TO "anon";
GRANT ALL ON TABLE "public"."referral_clicks" TO "authenticated";
GRANT ALL ON TABLE "public"."referral_clicks" TO "service_role";



GRANT ALL ON TABLE "public"."referral_links" TO "anon";
GRANT ALL ON TABLE "public"."referral_links" TO "authenticated";
GRANT ALL ON TABLE "public"."referral_links" TO "service_role";



GRANT ALL ON TABLE "public"."ride_candidates" TO "anon";
GRANT ALL ON TABLE "public"."ride_candidates" TO "authenticated";
GRANT ALL ON TABLE "public"."ride_candidates" TO "service_role";



GRANT ALL ON TABLE "public"."rides" TO "anon";
GRANT ALL ON TABLE "public"."rides" TO "authenticated";
GRANT ALL ON TABLE "public"."rides" TO "service_role";



GRANT ALL ON TABLE "public"."segments" TO "anon";
GRANT ALL ON TABLE "public"."segments" TO "authenticated";
GRANT ALL ON TABLE "public"."segments" TO "service_role";



GRANT ALL ON SEQUENCE "public"."segments_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."segments_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."segments_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."send_logs" TO "anon";
GRANT ALL ON TABLE "public"."send_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."send_logs" TO "service_role";



GRANT ALL ON SEQUENCE "public"."send_logs_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."send_logs_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."send_logs_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."send_queue" TO "anon";
GRANT ALL ON TABLE "public"."send_queue" TO "authenticated";
GRANT ALL ON TABLE "public"."send_queue" TO "service_role";



GRANT ALL ON SEQUENCE "public"."send_queue_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."send_queue_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."send_queue_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."sessions" TO "anon";
GRANT ALL ON TABLE "public"."sessions" TO "authenticated";
GRANT ALL ON TABLE "public"."sessions" TO "service_role";



GRANT ALL ON TABLE "public"."settings" TO "anon";
GRANT ALL ON TABLE "public"."settings" TO "authenticated";
GRANT ALL ON TABLE "public"."settings" TO "service_role";



GRANT ALL ON SEQUENCE "public"."settings_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."settings_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."settings_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."shops" TO "anon";
GRANT ALL ON TABLE "public"."shops" TO "authenticated";
GRANT ALL ON TABLE "public"."shops" TO "service_role";



GRANT ALL ON TABLE "public"."station_numbers" TO "anon";
GRANT ALL ON TABLE "public"."station_numbers" TO "authenticated";
GRANT ALL ON TABLE "public"."station_numbers" TO "service_role";



GRANT ALL ON TABLE "public"."stations" TO "anon";
GRANT ALL ON TABLE "public"."stations" TO "authenticated";
GRANT ALL ON TABLE "public"."stations" TO "service_role";



GRANT ALL ON TABLE "public"."subscriptions" TO "anon";
GRANT ALL ON TABLE "public"."subscriptions" TO "authenticated";
GRANT ALL ON TABLE "public"."subscriptions" TO "service_role";



GRANT ALL ON SEQUENCE "public"."subscriptions_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."subscriptions_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."subscriptions_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."templates" TO "anon";
GRANT ALL ON TABLE "public"."templates" TO "authenticated";
GRANT ALL ON TABLE "public"."templates" TO "service_role";



GRANT ALL ON SEQUENCE "public"."templates_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."templates_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."templates_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."transcripts" TO "anon";
GRANT ALL ON TABLE "public"."transcripts" TO "authenticated";
GRANT ALL ON TABLE "public"."transcripts" TO "service_role";



GRANT ALL ON TABLE "public"."trips" TO "anon";
GRANT ALL ON TABLE "public"."trips" TO "authenticated";
GRANT ALL ON TABLE "public"."trips" TO "service_role";



GRANT ALL ON TABLE "public"."vendor_commissions" TO "anon";
GRANT ALL ON TABLE "public"."vendor_commissions" TO "authenticated";
GRANT ALL ON TABLE "public"."vendor_commissions" TO "service_role";



GRANT ALL ON TABLE "public"."voice_calls" TO "anon";
GRANT ALL ON TABLE "public"."voice_calls" TO "authenticated";
GRANT ALL ON TABLE "public"."voice_calls" TO "service_role";



GRANT ALL ON TABLE "public"."voice_call_kpis" TO "anon";
GRANT ALL ON TABLE "public"."voice_call_kpis" TO "authenticated";
GRANT ALL ON TABLE "public"."voice_call_kpis" TO "service_role";



GRANT ALL ON TABLE "public"."voice_call_outcomes" TO "anon";
GRANT ALL ON TABLE "public"."voice_call_outcomes" TO "authenticated";
GRANT ALL ON TABLE "public"."voice_call_outcomes" TO "service_role";



GRANT ALL ON TABLE "public"."voice_events" TO "anon";
GRANT ALL ON TABLE "public"."voice_events" TO "authenticated";
GRANT ALL ON TABLE "public"."voice_events" TO "service_role";



GRANT ALL ON TABLE "public"."voice_followups" TO "anon";
GRANT ALL ON TABLE "public"."voice_followups" TO "authenticated";
GRANT ALL ON TABLE "public"."voice_followups" TO "service_role";



GRANT ALL ON TABLE "public"."voice_memories" TO "anon";
GRANT ALL ON TABLE "public"."voice_memories" TO "authenticated";
GRANT ALL ON TABLE "public"."voice_memories" TO "service_role";



GRANT ALL ON TABLE "public"."voucher_events" TO "anon";
GRANT ALL ON TABLE "public"."voucher_events" TO "authenticated";
GRANT ALL ON TABLE "public"."voucher_events" TO "service_role";



GRANT ALL ON TABLE "public"."voucher_redemptions" TO "anon";
GRANT ALL ON TABLE "public"."voucher_redemptions" TO "authenticated";
GRANT ALL ON TABLE "public"."voucher_redemptions" TO "service_role";



GRANT ALL ON TABLE "public"."vouchers" TO "anon";
GRANT ALL ON TABLE "public"."vouchers" TO "authenticated";
GRANT ALL ON TABLE "public"."vouchers" TO "service_role";



GRANT ALL ON TABLE "public"."wa_contacts" TO "anon";
GRANT ALL ON TABLE "public"."wa_contacts" TO "authenticated";
GRANT ALL ON TABLE "public"."wa_contacts" TO "service_role";



GRANT ALL ON TABLE "public"."wa_events" TO "anon";
GRANT ALL ON TABLE "public"."wa_events" TO "authenticated";
GRANT ALL ON TABLE "public"."wa_events" TO "service_role";



GRANT ALL ON TABLE "public"."wa_inbound" TO "anon";
GRANT ALL ON TABLE "public"."wa_inbound" TO "authenticated";
GRANT ALL ON TABLE "public"."wa_inbound" TO "service_role";



GRANT ALL ON TABLE "public"."wa_inbox" TO "anon";
GRANT ALL ON TABLE "public"."wa_inbox" TO "authenticated";
GRANT ALL ON TABLE "public"."wa_inbox" TO "service_role";



GRANT ALL ON SEQUENCE "public"."wa_inbox_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."wa_inbox_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."wa_inbox_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."wa_messages" TO "anon";
GRANT ALL ON TABLE "public"."wa_messages" TO "authenticated";
GRANT ALL ON TABLE "public"."wa_messages" TO "service_role";



GRANT ALL ON TABLE "public"."wa_threads" TO "anon";
GRANT ALL ON TABLE "public"."wa_threads" TO "authenticated";
GRANT ALL ON TABLE "public"."wa_threads" TO "service_role";



GRANT ALL ON TABLE "public"."wallet_accounts" TO "anon";
GRANT ALL ON TABLE "public"."wallet_accounts" TO "authenticated";
GRANT ALL ON TABLE "public"."wallet_accounts" TO "service_role";



GRANT ALL ON TABLE "public"."wallet_ledger" TO "anon";
GRANT ALL ON TABLE "public"."wallet_ledger" TO "authenticated";
GRANT ALL ON TABLE "public"."wallet_ledger" TO "service_role";



GRANT ALL ON SEQUENCE "public"."wallet_ledger_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."wallet_ledger_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."wallet_ledger_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."wallet_promoters" TO "anon";
GRANT ALL ON TABLE "public"."wallet_promoters" TO "authenticated";
GRANT ALL ON TABLE "public"."wallet_promoters" TO "service_role";



GRANT ALL ON TABLE "public"."wallet_redemptions" TO "anon";
GRANT ALL ON TABLE "public"."wallet_redemptions" TO "authenticated";
GRANT ALL ON TABLE "public"."wallet_redemptions" TO "service_role";



GRANT ALL ON TABLE "public"."wallet_topups_momo" TO "anon";
GRANT ALL ON TABLE "public"."wallet_topups_momo" TO "authenticated";
GRANT ALL ON TABLE "public"."wallet_topups_momo" TO "service_role";



GRANT ALL ON TABLE "public"."wallets" TO "anon";
GRANT ALL ON TABLE "public"."wallets" TO "authenticated";
GRANT ALL ON TABLE "public"."wallets" TO "service_role";



GRANT ALL ON TABLE "public"."webhook_logs" TO "anon";
GRANT ALL ON TABLE "public"."webhook_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."webhook_logs" TO "service_role";



GRANT ALL ON SEQUENCE "public"."webhook_logs_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."webhook_logs_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."webhook_logs_id_seq" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "wa_edge_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";




-- ---------------------------------------------------------------------------
-- Mobility domain RLS synchronization (generated from infra/supabase/policies)
-- ---------------------------------------------------------------------------
ALTER TABLE "public"."user_favorites" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."user_favorites" FORCE ROW LEVEL SECURITY;
CREATE POLICY "user_favorites_owner_rw" ON "public"."user_favorites"
  FOR ALL TO "authenticated"
  USING ((user_id = auth.uid()))
  WITH CHECK ((user_id = auth.uid()));
CREATE POLICY "user_favorites_service_rw" ON "public"."user_favorites"
  FOR ALL TO "service_role"
  USING (true)
  WITH CHECK (true);

ALTER TABLE "public"."driver_parking" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."driver_parking" FORCE ROW LEVEL SECURITY;
CREATE POLICY "driver_parking_owner_rw" ON "public"."driver_parking"
  FOR ALL TO "authenticated"
  USING ((driver_id = auth.uid()))
  WITH CHECK ((driver_id = auth.uid()));
CREATE POLICY "driver_parking_service_rw" ON "public"."driver_parking"
  FOR ALL TO "service_role"
  USING (true)
  WITH CHECK (true);

ALTER TABLE "public"."driver_availability" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."driver_availability" FORCE ROW LEVEL SECURITY;
CREATE POLICY "driver_availability_owner_rw" ON "public"."driver_availability"
  FOR ALL TO "authenticated"
  USING ((driver_id = auth.uid()))
  WITH CHECK ((driver_id = auth.uid()));
CREATE POLICY "driver_availability_service_rw" ON "public"."driver_availability"
  FOR ALL TO "service_role"
  USING (true)
  WITH CHECK (true);

ALTER TABLE "public"."recurring_trips" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."recurring_trips" FORCE ROW LEVEL SECURITY;
CREATE POLICY "recurring_trips_owner_rw" ON "public"."recurring_trips"
  FOR ALL TO "authenticated"
  USING ((user_id = auth.uid()))
  WITH CHECK ((user_id = auth.uid()));
CREATE POLICY "recurring_trips_service_rw" ON "public"."recurring_trips"
  FOR ALL TO "service_role"
  USING (true)
  WITH CHECK (true);

ALTER TABLE "public"."deeplink_tokens" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."deeplink_tokens" FORCE ROW LEVEL SECURITY;
CREATE POLICY "deeplink_tokens_service_rw" ON "public"."deeplink_tokens"
  FOR ALL TO "service_role"
  USING (true)
  WITH CHECK (true);
CREATE POLICY "deeplink_tokens_service_ro" ON "public"."deeplink_tokens"
  FOR SELECT TO "authenticated"
  USING ((created_by = auth.uid()));

ALTER TABLE "public"."deeplink_events" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."deeplink_events" FORCE ROW LEVEL SECURITY;
CREATE POLICY "deeplink_events_service_rw" ON "public"."deeplink_events"
  FOR ALL TO "service_role"
  USING (true)
  WITH CHECK (true);

ALTER TABLE "public"."router_logs" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."router_logs" FORCE ROW LEVEL SECURITY;
CREATE POLICY "router_logs_service_rw" ON "public"."router_logs"
  FOR ALL TO "service_role"
  USING (true)
  WITH CHECK (true);
CREATE POLICY "router_logs_authenticated_read" ON "public"."router_logs"
  FOR SELECT TO "authenticated"
  USING (true);
CREATE POLICY "router_logs_support_ro" ON "public"."router_logs"
  FOR SELECT TO "service_role"
  USING (true);

RESET ALL;
