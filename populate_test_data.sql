-- =============================================================================
-- Populate test data for performance benchmarking
-- Modelled after the real HMS survey: N surveys (default 1), each with 50 waves
-- of 50k cases. Waves are 11 days long, fortnightly, starting Mon or Tue.
-- 40 waves completed, 1 in-progress, 9 future.
-- Each case has 2 QID links, 6 events (1 NEW_CASE + 5 random)
-- Each started collex has 11 entries in each MI table (production-shaped curve)
-- At 1 survey: 50 collex, 2.5M cases, 5M QID links, 15M events
-- Change num_surveys below to scale up or down.
--
-- WARNING: This populates only a few tables. If the query you want to test uses different
--  ones, you'll need to populate these as well (and maybe update this script while at it!).
--  Keep in mind this is a very coarse approximation of real life usage patterns.
--
-- Run against local docker-dev postgres:
--   make populate-test-data
--
-- WARNING: At 1 survey this takes ~10 GB disk space and ~20 minutes.
--          Scale is roughly linear with num_surveys.
-- =============================================================================

-- Configuration
\set num_surveys 1
\timing on

-- Check if the test data already exists
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM casev3.survey WHERE name LIKE 'HMS Performance Test%') THEN
      RAISE EXCEPTION 'Test data already exists.';
  END IF;
END $$;

-- Tuning for bulk load
SET maintenance_work_mem = '512MB';
SET work_mem = '256MB';

-- Drop indexes and FK constraints for faster bulk inserts
DROP INDEX IF EXISTS casev3.cases_case_ref_idx;
DROP INDEX IF EXISTS casev3.cases_collex_sample_idx;
DROP INDEX IF EXISTS casev3.event_caseid_idx;
DROP INDEX IF EXISTS casev3.qid_idx;
DROP INDEX IF EXISTS casev3.uac_qid_caseid_idx;
ALTER TABLE casev3.event DROP CONSTRAINT IF EXISTS FKhgvw8xq5panw486l3varef7pk;
ALTER TABLE casev3.event DROP CONSTRAINT IF EXISTS FKamu77co5m9upj2b3c1oun21er;
ALTER TABLE casev3.uac_qid_link DROP CONSTRAINT IF EXISTS FKngo7bm72f0focdujjma78t4nk;
ALTER TABLE casev3.cases DROP CONSTRAINT IF EXISTS FKrl77p02uu7a253tn2ro5mitv5;
ALTER TABLE casev3.uac_qid_link DROP CONSTRAINT IF EXISTS uac_qid_link_qid_key;

-- Generate surveys and collection exercises
-- 50 waves per survey, fortnightly (14 days apart), each 11 days long.
-- Wave 41 is in-progress; waves 1-40 are completed; waves 42-50 are future.
-- Each wave starts on Monday or Tuesday (randomised).
BEGIN;

INSERT INTO casev3.survey (
    id, name, sample_separator, sample_validation_rules,
    sample_with_header_row, sample_definition_url, metadata
)
SELECT
    ('aaaaaaaa-aaaa-aaaa-aaaa-' || LPAD(s::text, 12, '0'))::uuid,
    'HMS Performance Test ' || s,
    ',',
    '[
        {"columnName": "PARTICIPANT_ID",       "rules": [{"className": "uk.gov.ons.ssdc.common.validation.MandatoryRule"}]},
        {"columnName": "PORTAL_ID",            "rules": [{"className": "uk.gov.ons.ssdc.common.validation.MandatoryRule"}]},
        {"columnName": "EMAIL",                "rules": [{"className": "uk.gov.ons.ssdc.common.validation.MandatoryRule"}]},
        {"columnName": "LAST_NAME",            "rules": [{"className": "uk.gov.ons.ssdc.common.validation.MandatoryRule"}]},
        {"columnName": "FIRST_NAME",           "rules": [{"className": "uk.gov.ons.ssdc.common.validation.MandatoryRule"}]},
        {"columnName": "COHORT",               "rules": [{"className": "uk.gov.ons.ssdc.common.validation.MandatoryRule"}]},
        {"columnName": "PREVIOUS_COMPLETION",  "rules": [{"className": "uk.gov.ons.ssdc.common.validation.MandatoryRule"}]},
        {"columnName": "ADDRESS_LINE1",        "sensitive": true, "rules": [{"className": "uk.gov.ons.ssdc.common.validation.MandatoryRule"}]},
        {"columnName": "POSTCODE",             "sensitive": true, "rules": [{"className": "uk.gov.ons.ssdc.common.validation.MandatoryRule"}]},
        {"columnName": "PHONE_NUMBER",         "sensitive": true, "rules": [{"className": "uk.gov.ons.ssdc.common.validation.MandatoryRule"}]}
    ]'::jsonb,
    true,
    'https://example.com/sample-definition',
    '{}'::jsonb
FROM generate_series(1, :num_surveys) AS s;

INSERT INTO casev3.collection_exercise (
    id, survey_id, name, reference, start_date, end_date,
    collection_instrument_selection_rules, metadata
)
SELECT
    ('bbbbbbbb-bbbb-' || LPAD(s::text, 4, '0') || '-' || LPAD(w::text, 4, '0') || '-' || LPAD(s::text, 12, '0'))::uuid,
    ('aaaaaaaa-aaaa-aaaa-aaaa-' || LPAD(s::text, 12, '0'))::uuid,
    'HMS ' || s || ' Wave ' || w,
    'HMS' || s || '-W' || w,
    wave_start::timestamptz,
    (wave_start + 10)::timestamptz,
    '[]'::jsonb,
    '{}'::jsonb
FROM generate_series(1, :num_surveys) AS s
CROSS JOIN LATERAL (
    SELECT
        w,
        -- Anchor wave 41 to the Monday of the current week, then offset by
        -- 14 days per wave. Add 0 or 1 to land on Monday or Tuesday.
        date_trunc('week', CURRENT_DATE - 5)::date
            + (w - 41) * 14
            + floor(random() * 2)::int AS wave_start
    FROM generate_series(1, 50) AS w
) waves;

COMMIT;

-- Random value functions
CREATE OR REPLACE FUNCTION pg_temp.random_letters(count int) RETURNS text AS $$
    SELECT string_agg(chr(65 + floor(random() * 26)::int), '')
    FROM generate_series(1, count);
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION pg_temp.random_pick(arr text[]) RETURNS text AS $$
    SELECT arr[1 + floor(random() * array_length(arr, 1))::int];
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION pg_temp.random_int(a int, b int) RETURNS int AS $$
    SELECT floor(random() * b + a)::int;
$$ LANGUAGE sql;

-- Helper function to generate cases for a wave
CREATE OR REPLACE FUNCTION pg_temp.populate_cases(
    p_survey_num int,
    p_wave int,
    p_count int,
    p_case_ref_offset bigint
) RETURNS void AS $$
DECLARE
    v_collex_id uuid;
    -- Welsh names to test UTF-8 handling
    v_last_names text[] := ARRAY['Dafŷdd','Glyndŵr','Rhŷs','Smith','Jones','Williams','Brown','Taylor','Davies','Wilson','Evans','Thomas','Roberts','Johnson','Walker','Wright','Robinson','Thompson','White','Hughes','Edwards','Green','Hall','Lewis','Harris','Clarke','Patel','Jackson'];
    v_first_names text[] := ARRAY['Siân','Siôn','Llŷr','Eirlŷs','Owên','Gruffŷdd','Włodzimierz','Oliver','George','Harry','Jack','Jacob','Noah','Charlie','Thomas','Oscar','James','William','Leo','Alfie','Henry','Amelia','Olivia','Isla','Emily','Poppy','Ava','Jessica','Ella','Mia','Grace'];
    v_middle_names text[] := ARRAY['Ffion','Llŷr','James','Marie','Anne','John','Elizabeth','Rose','May','Lee','Jane','Robert'];
    v_streets text[] := ARRAY['Strŷd Fawr','Heol y Capêl','Ffordd Glyndŵr','Lôn y Felin','High Street','Church Road','Station Road','Park Avenue','Victoria Road','Manor Way','Kings Lane','Queens Drive','Mill Lane','The Green'];
BEGIN
    v_collex_id := ('bbbbbbbb-bbbb-' || LPAD(p_survey_num::text, 4, '0') || '-' || LPAD(p_wave::text, 4, '0') || '-' || LPAD(p_survey_num::text, 12, '0'))::uuid;

    -- Insert cases, returning IDs for UAC/QID link and event generation
    WITH inserted_cases AS (
        INSERT INTO casev3.cases (
            id, case_ref, created_at, last_updated_at,
            invalid, refusal_received, collection_exercise_id,
            sample, sample_sensitive
        )
        SELECT
            gen_random_uuid(),
            p_case_ref_offset + row_num,
            NOW() - (random() * interval '90 days'),
            NOW(),
            (random() < 0.02),
            CASE
                WHEN random() < 0.95 THEN NULL
                WHEN random() < 0.50 THEN 'HARD_REFUSAL'
                WHEN random() < 0.80 THEN 'SOFT_REFUSAL'
                ELSE 'EXTRAORDINARY_REFUSAL'
            END,
            v_collex_id,
            jsonb_build_object(
                'PARTICIPANT_ID', 'P' || LPAD((p_case_ref_offset + row_num)::text, 8, '0'),
                'PORTAL_ID', 'PTL' || LPAD((row_num % 5000)::text, 5, '0'),
                'PARTICIPANT_WINDOW_ID', 'W' || LPAD((p_case_ref_offset + row_num)::text, 8, '0'),
                'EMAIL', 'participant.' || (p_case_ref_offset + row_num) || '@example.nhs.uk',
                'LAST_NAME', pg_temp.random_pick(v_last_names),
                'FIRST_NAME', pg_temp.random_pick(v_first_names),
                'MIDDLE_NAME', CASE WHEN random() < 0.3 THEN '' ELSE pg_temp.random_pick(v_middle_names) END,
                'COLLEX_OPEN_DATE', to_char(DATE '2025-01-01' + pg_temp.random_int(0, 90), 'YYYY-MM-DD'),
                'COLLEX_CLOSE_DATE', to_char(DATE '2025-04-01' + pg_temp.random_int(0, 90), 'YYYY-MM-DD'),
                'WINDOW_START_DATE', to_char(DATE '2025-01-01' + pg_temp.random_int(0, 30), 'YYYY-MM-DD'),
                'WINDOW_CLOSE_DATE', to_char(DATE '2025-02-01' + pg_temp.random_int(0, 60), 'YYYY-MM-DD'),
                'COHORT', pg_temp.random_int(1, 3)::text,
                'PREVIOUS_COMPLETION', CASE WHEN random() < 0.5 THEN 'YES' ELSE 'NO' END
            ),
            jsonb_build_object(
                'ADDRESS_LINE1', pg_temp.random_int(1, 200) || ' ' || pg_temp.random_pick(v_streets),
                'POSTCODE', pg_temp.random_letters(2) || pg_temp.random_int(10, 90) || ' ' || pg_temp.random_int(0, 9) || pg_temp.random_letters(2),
                'PHONE_NUMBER', '07' || LPAD(pg_temp.random_int(0, 999999999)::text, 9, '0')
            )
        FROM generate_series(1, p_count) AS row_num
        RETURNING id, case_ref, created_at
    ),
    -- Generate 2 UAC/QID links per case
    inserted_qid_links AS (
        INSERT INTO casev3.uac_qid_link (
            id, qid, uac, uac_hash, caze_id,
            collection_instrument_url, active, eq_launched, receipt_received,
            created_at, last_updated_at
        )
        SELECT
            gen_random_uuid(),
            LPAD(case_ref::text, 12, '0') || LPAD(qid_num::text, 4, '0'),
            md5(case_ref::text || '-' || qid_num::text),
            md5(qid_num::text || '-' || case_ref::text),
            id,
            'https://eq.example.com/session',
            (random() < 0.9),
            (random() < 0.3),
            (random() < 0.4),
            NOW() - (random() * interval '90 days'),
            NOW()
        FROM inserted_cases
        CROSS JOIN generate_series(1, 2) AS qid_num
        RETURNING 1
    )
    -- Generate 6 events per case (1 NEW_CASE + 5 random)
    INSERT INTO casev3.event (
        id, channel, correlation_id, created_by, date_time,
        description, message_id, message_timestamp, payload,
        processed_at, source, type, caze_id
    )
    SELECT
        gen_random_uuid(),
        CASE WHEN event_num = 1 THEN 'RM'
             ELSE pg_temp.random_pick(ARRAY['RM','EQ','RH','CC'])
        END,
        gen_random_uuid(),
        'system',
        CASE WHEN event_num = 1 THEN created_at
             ELSE created_at + (random() * interval '90 days')
        END,
        CASE WHEN event_num = 1 THEN 'Case created'
             ELSE 'Auto-generated test event'
        END,
        gen_random_uuid(),
        CASE WHEN event_num = 1 THEN created_at
             ELSE created_at + (random() * interval '90 days')
        END,
        NULL,
        NOW(),
        CASE WHEN event_num = 1 THEN 'CASE_PROCESSOR'
             ELSE pg_temp.random_pick(ARRAY['CASE_PROCESSOR','RECEIPT_SERVICE','RH_SERVICE','CONTACT_CENTRE'])
        END,
        CASE WHEN event_num = 1 THEN 'NEW_CASE'
             ELSE pg_temp.random_pick(ARRAY['RECEIPT','REFUSAL','EQ_LAUNCH','INVALID_CASE','UAC_AUTHENTICATION','PRINT_FULFILMENT','UPDATE_SAMPLE','SMS_FULFILMENT','EMAIL_FULFILMENT','DEACTIVATE_UAC'])
        END,
        id
    FROM inserted_cases
    CROSS JOIN generate_series(1, 6) AS event_num;
END;
$$ LANGUAGE plpgsql;

-- Populate cases: N surveys x 50 waves x 50k cases each
CREATE OR REPLACE PROCEDURE pg_temp.populate_all_cases(p_num_surveys int) AS $$
DECLARE
    s int;
    w int;
    base_offset bigint;
BEGIN
    FOR s IN 1..p_num_surveys LOOP
        FOR w IN 1..50 LOOP
            base_offset := ((s - 1)::bigint * 50 + (w - 1)::bigint) * 50000;
            PERFORM pg_temp.populate_cases(s, w, 50000, base_offset);
            COMMIT;
            RAISE NOTICE 'Survey %, Wave % complete', s, w;
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

CALL pg_temp.populate_all_cases(:num_surveys);

-- Rebuild indexes and FK constraints
CREATE INDEX cases_case_ref_idx ON casev3.cases (case_ref);
CREATE INDEX cases_collex_sample_idx ON casev3.cases
    USING GIN (
        collection_exercise_id,
        casev3.flatten_sample_for_search(sample, sample_sensitive) public.gin_trgm_ops
    ) WITH (fastupdate = off);
CREATE INDEX event_caseid_idx ON casev3.event (caze_id);
CREATE INDEX qid_idx ON casev3.uac_qid_link (qid);
CREATE INDEX uac_qid_caseid_idx ON casev3.uac_qid_link (caze_id);
ALTER TABLE casev3.uac_qid_link ADD CONSTRAINT uac_qid_link_qid_key UNIQUE (qid);
ALTER TABLE casev3.event ADD CONSTRAINT FKhgvw8xq5panw486l3varef7pk FOREIGN KEY (caze_id) REFERENCES casev3.cases;
ALTER TABLE casev3.event ADD CONSTRAINT FKamu77co5m9upj2b3c1oun21er FOREIGN KEY (uac_qid_link_id) REFERENCES casev3.uac_qid_link;
ALTER TABLE casev3.cases ADD CONSTRAINT FKrl77p02uu7a253tn2ro5mitv5 FOREIGN KEY (collection_exercise_id) REFERENCES casev3.collection_exercise;
ALTER TABLE casev3.uac_qid_link ADD CONSTRAINT FKngo7bm72f0focdujjma78t4nk FOREIGN KEY (caze_id) REFERENCES casev3.cases;
ANALYZE casev3.cases;
ANALYZE casev3.event;
ANALYZE casev3.uac_qid_link;

-- =============================================================================
-- Populate MI snapshot tables
-- Curve is made too look similar to past HMS surveys.
-- All 11 snapshots are generated for every collex (including in-progress wave 3)
-- so there is no need to run the MI exporter locally.
-- NOTE: MI snapshots are random and do not reflect actual case state.
-- Email and export file requests use two pack codes per collex.
-- =============================================================================

-- Cumulative fractions derived from 24 waves of production HMS data.
-- Each value is the fraction of total cases receipted/launched by that day offset.
CREATE TEMPORARY TABLE hms_cumulative_curve (
    day_offset   int PRIMARY KEY,
    receipted_frac numeric(6,4) NOT NULL,
    launched_frac  numeric(6,4) NOT NULL
);
INSERT INTO hms_cumulative_curve VALUES
    (0,  0.0935, 0.0952),
    (1,  0.1992, 0.2026),
    (2,  0.3270, 0.3325),
    (3,  0.4164, 0.4232),
    (4,  0.4717, 0.4793),
    (5,  0.5330, 0.5416),
    (6,  0.5998, 0.6096),
    (7,  0.6423, 0.6512),
    (8,  0.6576, 0.6640),
    (9,  0.6633, 0.6670),
    (10, 0.6659, 0.6670);

-- mi_response_rate: one snapshot per collex per day, production-shaped curve.
-- All 11 snapshots are generated for every collex (including future waves) so
-- there is no need to run the MI exporter locally.
-- Per-collex scale factor (0.8-1.2) gives each collex a different total response rate.
-- NOTE: MI snapshots are synthetic and do not reflect actual case/UAC state.
INSERT INTO casev3.mi_response_rate (
    collection_exercise_id, snapshot_date, receipted_count, launched_count, total_case_count, created_at
)
SELECT
    ce.id,
    ce.start_date::date + c.day_offset,
    FLOOR(50000 * c.receipted_frac * scale)::int,
    FLOOR(50000 * c.launched_frac  * scale)::int,
    50000,
    NOW()
FROM (
    SELECT id, start_date, 0.8 + 0.4 * random() AS scale
    FROM casev3.collection_exercise
    WHERE name LIKE 'HMS %'
) ce
CROSS JOIN hms_cumulative_curve c;

-- mi_email_request: two pack codes per collex per day
-- Per-(collex, pack_code) scale factor gives each combination a distinct volume.
INSERT INTO casev3.mi_email_request (
    collection_exercise_id, pack_code, snapshot_date, daily_email_requests, total_email_requests, created_at
)
SELECT
    id,
    pack_code,
    snapshot_date,
    daily,
    SUM(daily) OVER (PARTITION BY id, pack_code ORDER BY snapshot_date) AS total_email_requests,
    NOW()
FROM (
    SELECT
        ce.id,
        pc.pack_code,
        ce.start_date::date + c.day_offset AS snapshot_date,
        FLOOR((30 + 170 * first_value(random()) OVER (PARTITION BY ce.id, pc.pack_code ORDER BY c.day_offset)) * (0.8 + 0.4 * random()))::int AS daily
    FROM casev3.collection_exercise ce
    CROSS JOIN hms_cumulative_curve c
    CROSS JOIN (VALUES ('PACK_EMAIL_A'), ('PACK_EMAIL_B')) AS pc(pack_code)
    WHERE ce.name LIKE 'HMS %'
) sub;

-- mi_export_file_request: two pack codes per collex per day
-- Same pattern as email requests.
INSERT INTO casev3.mi_export_file_request (
    collection_exercise_id, pack_code, snapshot_date, daily_export_file_requests, total_export_file_requests, created_at
)
SELECT
    id,
    pack_code,
    snapshot_date,
    daily,
    SUM(daily) OVER (PARTITION BY id, pack_code ORDER BY snapshot_date) AS total_export_file_requests,
    NOW()
FROM (
    SELECT
        ce.id,
        pc.pack_code,
        ce.start_date::date + c.day_offset AS snapshot_date,
        FLOOR((20 + 130 * first_value(random()) OVER (PARTITION BY ce.id, pc.pack_code ORDER BY c.day_offset)) * (0.8 + 0.4 * random()))::int AS daily
    FROM casev3.collection_exercise ce
    CROSS JOIN hms_cumulative_curve c
    CROSS JOIN (VALUES ('PACK_EXPORT_A'), ('PACK_EXPORT_B')) AS pc(pack_code)
    WHERE ce.name LIKE 'HMS %'
) sub;

DROP TABLE hms_cumulative_curve;

-- action_rule: 3 cohorts x 2 waves (Notification + Reminder) = 6 EMAIL rules per collex.
-- Notification emails fire on days 0, 1, 2 (one cohort per day).
-- Reminder emails fire on days 5, 6, 7.
-- Completed waves are marked COMPLETED; in-progress and future are SCHEDULED.
INSERT INTO casev3.action_rule (
    id, action_rule_status, created_by, description,
    email_column, has_triggered, trigger_date_time, type,
    collection_exercise_id, email_template_pack_code
)
SELECT
    gen_random_uuid(),
    CASE WHEN ce.end_date < NOW() THEN 'COMPLETED' ELSE 'SCHEDULED' END,
    'system',
    'Cohort ' || cohort || ' ' || wave_type || ' Email - English',
    'EMAIL',
    ce.end_date < NOW(),
    ce.start_date + (day_offset || ' days')::interval + interval '10 hours',
    'EMAIL',
    ce.id,
    pack_code
FROM casev3.collection_exercise ce
CROSS JOIN (VALUES
    (1, 0, 'Notification', 'MNE_EN_HMS'),
    (2, 1, 'Notification', 'MNE_EN_HMS'),
    (3, 2, 'Notification', 'MNE_EN_HMS'),
    (1, 5, 'Reminder',     'MRE_EN_HMS'),
    (2, 6, 'Reminder',     'MRE_EN_HMS'),
    (3, 7, 'Reminder',     'MRE_EN_HMS')
) AS ar(cohort, day_offset, wave_type, pack_code)
WHERE ce.name LIKE 'HMS %';

ANALYZE casev3.mi_response_rate;
ANALYZE casev3.mi_email_request;
ANALYZE casev3.mi_export_file_request;
ANALYZE casev3.action_rule;
