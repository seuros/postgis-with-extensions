\set VERBOSITY verbose
\set ON_ERROR_STOP on

--------------------------------------------------------------------------------
-- Database Initialization Ritual 🕯️
--------------------------------------------------------------------------------
DROP DATABASE IF EXISTS test;
CREATE DATABASE test;
\c test

--------------------------------------------------------------------------------
-- Extension Awakening Ceremony 🚪🪄
--------------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS postgis; -- spatial spells
CREATE EXTENSION IF NOT EXISTS postgis_raster; -- pixels with coordinates
CREATE EXTENSION IF NOT EXISTS postgis_sfcgal; -- 3D geometry sorcery
CREATE EXTENSION IF NOT EXISTS vector; -- tiny brains in columns
CREATE EXTENSION IF NOT EXISTS pg_trgm; -- fuzzy text matching
CREATE EXTENSION IF NOT EXISTS timescaledb; -- time bends here
CREATE SCHEMA IF NOT EXISTS pgrouting;
CREATE EXTENSION IF NOT EXISTS pgrouting SCHEMA pgrouting;
-- actual roads, not just vibes

-- pg_cron lives in cron.database_name (postgres); it is tested in the epilogue.

SET search_path = public, pgrouting, "$user";

--------------------------------------------------------------------------------
-- Crucial Diagnostics: Versions 🧪
--------------------------------------------------------------------------------
SELECT 'Running Initial Version Checks...' AS status_message;
SELECT version() AS postgres_version;
SELECT extname, extversion
FROM pg_extension
WHERE extname IN ('postgis', 'postgis_raster', 'postgis_sfcgal', 'vector', 'pgrouting', 'pg_trgm', 'timescaledb');
SELECT pgr_version();
SELECT postgis_full_version();

--------------------------------------------------------------------------------
-- TABLE: spatial_data – Points of Doubt 🧭
--------------------------------------------------------------------------------
CREATE TABLE spatial_data
(
	id   SERIAL PRIMARY KEY,
	name TEXT CHECK (name NOT ILIKE 'Bob'), -- Bob is forbidden
	geom geometry(Point, 4326)
);

INSERT INTO spatial_data (name, geom)
VALUES ('Point A', ST_Point(-71.060316, 48.432044)),
	   ('Point B', ST_Point(-70.060316, 47.432044)),
	   ('The Abyss', ST_GeomFromEWKT('SRID=4326;POINT(-0.000000666 66.666666)'));

SELECT id,
	   name,
	   ST_AsText(geom)                                     AS wkt,
	   ST_Distance(geom, ST_SetSRID(ST_Point(0, 0), 4326)) AS distance_from_origin
FROM spatial_data
ORDER BY distance_from_origin;

-- Raster: a 2x2 tile whose every pixel holds the answer
SELECT ST_Value(ST_AddBand(ST_MakeEmptyRaster(2, 2, 0, 0, 1), '8BUI'::text, 42), 1, 1) AS raster_spirit;

-- SFCGAL: extrude a square into a cube and weigh its soul
SELECT postgis_sfcgal_version() AS sfcgal_version;
SELECT CG_Volume(CG_MakeSolid(CG_Extrude(ST_MakeEnvelope(0, 0, 1, 1), 0, 0, 1))) AS cube_volume;

--------------------------------------------------------------------------------
-- TABLE: vector_data – Philosophical Embeddings 🧠
--------------------------------------------------------------------------------
CREATE TABLE vector_data
(
	id        SERIAL PRIMARY KEY,
	label     TEXT DEFAULT 'unnamed thoughtform',
	embedding vector(3)
);

INSERT INTO vector_data (embedding, label)
VALUES ('[1, 1, 1]', 'AI-powered incense recommendation'),
	   ('[2, 2, 2]', 'Crypto for monks'),
	   ('[3, 3, 3]', 'NFTs for ancient manuscripts');

CREATE INDEX ON vector_data USING hnsw (embedding vector_l2_ops);
SET enable_seqscan = off; -- make the planner walk the HNSW graph

SELECT label, embedding
FROM vector_data
ORDER BY embedding <-> '[2.9, 2.9, 2.9]'
LIMIT 1;

RESET enable_seqscan;

--------------------------------------------------------------------------------
-- TABLE: trgm_data – Fuzzy Text Matching 🔍
--------------------------------------------------------------------------------
CREATE TABLE trgm_data
(
	id   SERIAL PRIMARY KEY,
	name TEXT
);

CREATE INDEX idx_trgm_name_gin ON trgm_data USING GIN (name gin_trgm_ops);

INSERT INTO trgm_data (name)
VALUES ('PostgreSQL'), ('PostGIS'), ('pgvector'), ('pgRouting'), ('pg_trgm'),
	   ('Postgre'), ('postgres'), ('PgAdmin');

-- Test similarity function and % operator
SELECT 'pg_trgm similarity test' AS status_message;
SELECT name, similarity(name, 'postgre') AS sim
FROM trgm_data
WHERE name % 'postgre'
ORDER BY sim DESC;

-- Show trigrams for a string
SELECT 'pg_trgm trigrams display' AS status_message;
SELECT show_trgm('PostgreSQL') AS trigrams;

-- Test word_similarity
SELECT 'pg_trgm word similarity test' AS status_message;
SELECT name, word_similarity('post', name) AS word_sim
FROM trgm_data
ORDER BY word_sim DESC
LIMIT 3;

--------------------------------------------------------------------------------
-- pgRouting: Ley Line Navigation Ritual 🗺️🔮 (Revised for Core Functionality)
--------------------------------------------------------------------------------
-- Let's chart paths through a mystical network of ley lines!

CREATE TABLE ley_lines
(
	id                     SERIAL PRIMARY KEY,
	name                   TEXT,
	geom                   geometry(LineString, 4326),
	base_mana_cost         DOUBLE PRECISION,
	reverse_base_mana_cost DOUBLE PRECISION,
	stability_factor       DOUBLE PRECISION DEFAULT 1.0
);

COMMENT ON TABLE ley_lines IS 'Stores the segments of magical ley lines, their costs, and stability.';
COMMENT ON COLUMN ley_lines.stability_factor IS '1.0 for perfect stability. Higher values mean more turbulent (costly) paths.';

INSERT INTO ley_lines (name, geom, base_mana_cost, reverse_base_mana_cost, stability_factor)
VALUES ('Path of Whispering Zephyrs', ST_MakeLine(ST_MakePoint(-70, 40), ST_MakePoint(-60, 35)), 10, 10, 1.0),
	   ('Trail of Embers', ST_MakeLine(ST_MakePoint(-60, 35), ST_MakePoint(-50, 45)), 15, 15, 1.2),
	   ('Aquatic Current', ST_MakeLine(ST_MakePoint(-50, 45), ST_MakePoint(-65, 25)), 20, 25, 1.0),
	   ('Skybridge of Storms', ST_MakeLine(ST_MakePoint(-70, 40), ST_MakePoint(-50, 45)), 25, 25, 1.5),
	   ('Nexus Channel', ST_MakeLine(ST_MakePoint(-60, 35), ST_MakePoint(-55, 30)), 5, 5, 0.9),
	   ('Deep Fissure Flow', ST_MakeLine(ST_MakePoint(-55, 30), ST_MakePoint(-65, 25)), 8, 8, 1.1),
	   ('Shortcut to Ignis', ST_MakeLine(ST_MakePoint(-55, 30), ST_MakePoint(-50, 45)), 7, 7, 1.0);
-- Nexus to Ignis

-- Points of Interest (for finding closest vertices)
-- Aerthos (Sky Palace): ST_Point(-70, 40) -> Vertex for ID 1 in ley_lines_vertices_pgr (approx)
-- Sylva (Ancient Forest): ST_Point(-60, 35) -> Vertex for ID 2
-- Ignis (Volcanic Forge): ST_Point(-50, 45) -> Vertex for ID 3
-- Aquamar (Sunken Kingdom): ST_Point(-65, 25) -> Vertex for ID 4
-- Nexus (Convergence Point): ST_Point(-55, 30) -> Vertex for ID 5

ALTER TABLE ley_lines
	ADD COLUMN IF NOT EXISTS source INTEGER;
ALTER TABLE ley_lines
	ADD COLUMN IF NOT EXISTS target INTEGER;

-- pgr_createTopology was removed in pgRouting 4.0.0
-- Use pgr_extractVertices instead
SELECT * INTO ley_lines_vertices_pgr
FROM pgrouting.pgr_extractVertices('SELECT id, geom FROM ley_lines ORDER BY id');

-- Create spatial index on vertices
CREATE INDEX ON ley_lines_vertices_pgr USING GIST (geom);
ALTER TABLE ley_lines_vertices_pgr RENAME COLUMN geom TO the_geom;

-- Update source/target columns using vertex IDs
UPDATE ley_lines l SET source = v.id
FROM ley_lines_vertices_pgr v
WHERE ST_DWithin(ST_StartPoint(l.geom), v.the_geom, 0.00001);

UPDATE ley_lines l SET target = v.id
FROM ley_lines_vertices_pgr v
WHERE ST_DWithin(ST_EndPoint(l.geom), v.the_geom, 0.00001);

SELECT 'Ley Line Network Topology Created!' AS status_message;

--------------------------------------------------------------------------------
-- Test 1: Classic Pilgrimage - pgr_dijkstra (Node to Node Journey) 🧙‍♂️🏞️
-- From the Sky Palace of Aerthos to the Sunken Kingdom of Aquamar
--------------------------------------------------------------------------------
SELECT 'Test 1.1: Calculating classic pilgrimage route (Aerthos to Aquamar) using pgr_dijkstra...' AS status_message;
WITH sky_palace_node AS ( -- Aerthos is near the start of 'Path of Whispering Zephyrs'
	SELECT id FROM ley_lines_vertices_pgr ORDER BY the_geom <-> ST_SetSRID(ST_Point(-70, 40), 4326) LIMIT 1),
	 sunken_kingdom_node AS ( -- Aquamar is near the end of 'Deep Fissure Flow' / 'Aquatic Current'
		 SELECT id FROM ley_lines_vertices_pgr ORDER BY the_geom <-> ST_SetSRID(ST_Point(-65, 25), 4326) LIMIT 1)
SELECT di.seq,
	   di.path_seq,
	   di.node,
	   di.edge,
	   di.cost     AS segment_mana_cost,
	   di.agg_cost AS total_mana_cost_so_far,
	   ll.name     AS ley_line_name
FROM pgrouting.pgr_dijkstra(
		 'SELECT id, source, target, base_mana_cost * stability_factor AS cost, reverse_base_mana_cost * stability_factor AS reverse_cost FROM ley_lines',
		 (SELECT id FROM sky_palace_node),
		 (SELECT id FROM sunken_kingdom_node),
		 directed := false
	 ) AS di
		 LEFT JOIN ley_lines ll ON di.edge = ll.id
ORDER BY di.seq;

SELECT 'Test 1.2: Visualizing classic pilgrimage route geometry...' AS status_message;
WITH sky_palace_node AS (SELECT id
						 FROM ley_lines_vertices_pgr
						 ORDER BY the_geom <-> ST_SetSRID(ST_Point(-70, 40), 4326)
						 LIMIT 1),
	 sunken_kingdom_node AS (SELECT id
							 FROM ley_lines_vertices_pgr
							 ORDER BY the_geom <-> ST_SetSRID(ST_Point(-65, 25), 4326)
							 LIMIT 1),
	 path_geoms AS (SELECT ll.geom
					FROM pgrouting.pgr_dijkstra(
							 'SELECT id, source, target, base_mana_cost * stability_factor AS cost, reverse_base_mana_cost * stability_factor AS reverse_cost FROM ley_lines',
							 (SELECT id FROM sky_palace_node),
							 (SELECT id FROM sunken_kingdom_node),
							 directed := false
						 ) AS di
							 JOIN ley_lines ll ON di.edge = ll.id
					WHERE di.edge != -1)
SELECT ST_AsText(ST_LineMerge(ST_Collect(geom))) AS pilgrimage_route_geom_wkt
FROM path_geoms;

--------------------------------------------------------------------------------
-- Test 2: Reachable Ley Lines - pgr_drivingDistance 🌐⏳
-- Find all ley line nodes reachable from Nexus within 12 mana cost
--------------------------------------------------------------------------------
SELECT 'Test 2.1: Finding reachable nodes from Nexus (max 12 mana cost) using pgr_drivingDistance...' AS status_message;
WITH nexus_node AS (SELECT id
					FROM ley_lines_vertices_pgr
					ORDER BY the_geom <-> ST_SetSRID(ST_Point(-55, 30), 4326)
					LIMIT 1)
SELECT dd.seq,
	   dd.node,
	   dd.edge,
	   dd.cost     AS mana_to_reach_edge_start,
	   dd.agg_cost AS total_mana_to_reach_node,
	   v.the_geom  AS node_location,
	   ll.name     AS via_ley_line
FROM pgrouting.pgr_drivingDistance(
		 'SELECT id, source, target, base_mana_cost * stability_factor AS cost FROM ley_lines', -- Use single cost for driving distance
		 (SELECT id FROM nexus_node),
		 12, -- Maximum mana cost
		 directed := false
	 ) AS dd
		 JOIN ley_lines_vertices_pgr v ON dd.node = v.id
		 LEFT JOIN ley_lines ll ON dd.edge = ll.id
ORDER BY dd.agg_cost, dd.seq;

--------------------------------------------------------------------------------
-- Test 3: Alternative Routes - pgr_kSP (k-Shortest Path) 🔄🔀
-- Find the top 3 shortest mana paths from Aerthos to Ignis
--------------------------------------------------------------------------------
SELECT 'Test 3.1: Finding Top 3 shortest paths (Aerthos to Ignis) using pgr_kSP...' AS status_message;
WITH aerthos_node AS (SELECT id
					  FROM ley_lines_vertices_pgr
					  ORDER BY the_geom <-> ST_SetSRID(ST_Point(-70, 40), 4326)
					  LIMIT 1),
	 ignis_node AS (SELECT id
					FROM ley_lines_vertices_pgr
					ORDER BY the_geom <-> ST_SetSRID(ST_Point(-50, 45), 4326)
					LIMIT 1)
SELECT ksp.path_id,  -- Identifies which of the k paths this row belongs to
	   ksp.path_seq, -- Sequence of this step within its path
	   ksp.node,
	   ksp.edge,
	   ksp.cost     AS segment_mana_cost,
	   ksp.agg_cost AS total_mana_cost_for_path,
	   ll.name      AS ley_line_name
FROM pgrouting.pgr_kSP(
		 'SELECT id, source, target, base_mana_cost * stability_factor AS cost, reverse_base_mana_cost * stability_factor AS reverse_cost FROM ley_lines',
		 (SELECT id FROM aerthos_node),
		 (SELECT id FROM ignis_node),
		 3, -- Number of shortest paths to find (k)
		 directed := false
	 ) AS ksp
		 LEFT JOIN ley_lines ll ON ksp.edge = ll.id
ORDER BY ksp.path_id, ksp.path_seq;

SELECT 'Test 3.2: Visualizing the Top 3 shortest paths (Aerthos to Ignis)...' AS status_message;
WITH aerthos_node AS (SELECT id
					  FROM ley_lines_vertices_pgr
					  ORDER BY the_geom <-> ST_SetSRID(ST_Point(-70, 40), 4326)
					  LIMIT 1),
	 ignis_node AS (SELECT id
					FROM ley_lines_vertices_pgr
					ORDER BY the_geom <-> ST_SetSRID(ST_Point(-50, 45), 4326)
					LIMIT 1),
	 all_ksp_segments AS (SELECT ksp.path_id, ll.geom
						  FROM pgrouting.pgr_kSP(
								   'SELECT id, source, target, base_mana_cost * stability_factor AS cost, reverse_base_mana_cost * stability_factor AS reverse_cost FROM ley_lines',
								   (SELECT id FROM aerthos_node),
								   (SELECT id FROM ignis_node),
								   3,
								   directed := false
							   ) AS ksp
								   JOIN ley_lines ll ON ksp.edge = ll.id
						  WHERE ksp.edge != -1)
SELECT path_id, ST_AsText(ST_LineMerge(ST_Collect(geom))) AS ksp_route_geom_wkt
FROM all_ksp_segments
GROUP BY path_id
ORDER BY path_id;


SELECT 'pgRouting Ley Line Core Functionality Test Complete!' AS status_message;
--------------------------------------------------------------------------------
-- End of pgRouting Ritual
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Temporal Hiccups: Dreams that vanish too fast ⏳
--------------------------------------------------------------------------------
CREATE TABLE fleeting_dreams
(
	id        SERIAL PRIMARY KEY,
	dream     TEXT,
	timestamp TIMESTAMPTZ DEFAULT now() + ((random() * 5 - 2.5) * INTERVAL '1 day')
);

INSERT INTO fleeting_dreams (dream)
SELECT unnest(ARRAY [
	'You can fly but only upward', 'Everyone speaks SQL and you are mute',
	'All joins are cross joins', 'You are a recursive CTE'
	]);
SELECT *
FROM fleeting_dreams
ORDER BY timestamp
LIMIT 1;

--------------------------------------------------------------------------------
-- TimescaleDB: Hypertables & Columnstore ⏱️
-- (columnstore is TSL-licensed: this fails on an Apache-only build)
--------------------------------------------------------------------------------
CREATE TABLE incense_readings
(
	ts     TIMESTAMPTZ NOT NULL,
	temple TEXT        NOT NULL,
	smoke  DOUBLE PRECISION
);

SELECT create_hypertable('incense_readings', by_range('ts', INTERVAL '1 day'));

INSERT INTO incense_readings (ts, temple, smoke)
SELECT ts, temple, extract(HOUR FROM ts) -- smoke follows the sun; compresses well
FROM generate_series(now() - INTERVAL '3 days', now(), INTERVAL '1 minute') AS ts,
	 unnest(ARRAY ['Kyoto', 'Lhasa', 'Fez']) AS temple;

ALTER TABLE incense_readings SET (
	timescaledb.enable_columnstore = true,
	timescaledb.segmentby = 'temple'
	);

SELECT count(compress_chunk(c)) AS chunks_sent_to_columnstore
FROM show_chunks('incense_readings') c;

DO
$$
BEGIN
	IF NOT EXISTS (SELECT 1
				   FROM timescaledb_information.chunks
				   WHERE hypertable_name = 'incense_readings'
					 AND is_compressed) THEN
		RAISE EXCEPTION 'timescaledb columnstore did not compress any chunk';
	END IF;
END
$$;

SELECT temple, count(*) AS readings, round(avg(smoke)::numeric, 2) AS avg_smoke
FROM incense_readings
GROUP BY temple
ORDER BY temple;

--------------------------------------------------------------------------------
-- Final Diagnostics Check
--------------------------------------------------------------------------------
SELECT 'Running Final Version Checks...' AS status_message;
SELECT version() AS postgres_version_final_check;
SELECT extname, extversion
FROM pg_extension
WHERE extname IN ('postgis', 'postgis_raster', 'postgis_sfcgal', 'vector', 'pgrouting', 'pg_trgm', 'timescaledb');
SELECT pgr_version() AS pgr_version_final_check;

--------------------------------------------------------------------------------
-- Epilogue: Drop the ephemeral and tip your DBA 🎤
--------------------------------------------------------------------------------
\c postgres
DROP DATABASE test;

--------------------------------------------------------------------------------
-- pg_cron: Scheduled Rituals 🕰️ (must live in cron.database_name = postgres)
--------------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS pg_cron;
SELECT extname, extversion FROM pg_extension WHERE extname = 'pg_cron';
SELECT cron.schedule('nightly-incense', '0 3 * * *', 'SELECT 1') AS job_id;

DO
$$
BEGIN
	IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'nightly-incense') THEN
		RAISE EXCEPTION 'pg_cron job was not scheduled';
	END IF;
END
$$;

SELECT cron.unschedule('nightly-incense');
DROP EXTENSION pg_cron;
