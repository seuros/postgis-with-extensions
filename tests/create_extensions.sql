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
CREATE EXTENSION IF NOT EXISTS h3; -- the world, tiled by bees
CREATE EXTENSION IF NOT EXISTS h3_postgis; -- bees that speak geometry
CREATE EXTENSION IF NOT EXISTS pgtap; -- the database grades its own homework
CREATE EXTENSION IF NOT EXISTS hypopg; -- indexes that exist only in dreams
CREATE EXTENSION IF NOT EXISTS pg_repack; -- tidy the heap without locking it
CREATE SCHEMA IF NOT EXISTS partman;
CREATE EXTENSION IF NOT EXISTS pg_partman SCHEMA partman; -- time, sliced RDS-style
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
WHERE extname IN ('postgis', 'postgis_raster', 'postgis_sfcgal', 'vector', 'pgrouting', 'pg_trgm',
				  'h3', 'h3_postgis', 'pgtap', 'hypopg', 'pg_repack', 'pg_partman');
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
-- H3: Hexagonal Pilgrim Density 🐝
--------------------------------------------------------------------------------
CREATE TABLE pilgrim_sightings
(
	id   SERIAL PRIMARY KEY,
	geom geometry(Point, 4326) NOT NULL
);

-- a deterministic 40x40 grid over Fez (all of it inside tile z10/497/408)
INSERT INTO pilgrim_sightings (geom)
SELECT ST_Point(-4.98 + (i % 40) * 0.001, 34.03 + (i / 40) * 0.001, 4326)
FROM generate_series(0, 1599) AS i;

SELECT h3_latlng_to_cell(geom, 8) AS cell, count(*) AS sightings
FROM pilgrim_sightings
GROUP BY cell
ORDER BY sightings DESC, cell
LIMIT 5;

DO
$$
DECLARE
	cells  bigint;
	strays bigint;
BEGIN
	SELECT count(DISTINCT h3_latlng_to_cell(geom, 8)) INTO cells FROM pilgrim_sightings;
	IF cells NOT BETWEEN 2 AND 100 THEN
		RAISE EXCEPTION 'h3: implausible binning, % res-8 cells for a ~4 km grid', cells;
	END IF;

	-- every point must sit inside the boundary of the cell it was binned into
	SELECT count(*) INTO strays
	FROM pilgrim_sightings
	WHERE NOT ST_Intersects(h3_cell_to_boundary_geometry(h3_latlng_to_cell(geom, 8)), geom);
	IF strays > 0 THEN
		RAISE EXCEPTION 'h3: % sightings fall outside their own cell', strays;
	END IF;
END
$$;

-- What a graticule density layer looks like: H3 bins clipped to an MVT tile
CREATE FUNCTION hex_density_tile(z integer, x integer, y integer, res integer DEFAULT 8)
	RETURNS bytea
	LANGUAGE sql
	STABLE
	PARALLEL SAFE
AS
$$
WITH bounds AS (SELECT ST_TileEnvelope(z, x, y) AS env),
	 hexes AS (SELECT h3_latlng_to_cell(s.geom, res) AS cell, count(*) AS sightings
			   FROM pilgrim_sightings s, bounds b
			   WHERE s.geom && ST_Transform(b.env, 4326)
			   GROUP BY 1),
	 mvt AS (SELECT h.cell::text AS h3, h.sightings,
					ST_AsMVTGeom(ST_Transform(h3_cell_to_boundary_geometry(h.cell), 3857), b.env) AS geom
			 FROM hexes h, bounds b)
SELECT ST_AsMVT(mvt, 'hexes')
FROM mvt
WHERE geom IS NOT NULL;
$$;

--------------------------------------------------------------------------------
-- pgTAP: The Database Grades Its Own Homework 📝
-- (finish(true) raises on any failure, so ON_ERROR_STOP fails the suite)
--------------------------------------------------------------------------------
BEGIN;
SELECT plan(6);

SELECT has_extension('h3');
SELECT has_function('hex_density_tile', ARRAY ['integer', 'integer', 'integer', 'integer']);
SELECT is(h3_get_resolution(h3_latlng_to_cell(ST_Point(-4.97, 34.04, 4326), 8)), 8,
		  'cells come back at the requested resolution');
SELECT is((SELECT count(*) FROM h3_grid_disk(h3_latlng_to_cell(ST_Point(-4.97, 34.04, 4326), 8), 1)), 7::bigint,
		  'a hexagon has six neighbours');
SELECT cmp_ok(length(hex_density_tile(10, 497, 408)), '>', 0, 'the Fez tile carries hexagons');
SELECT is(coalesce(length(hex_density_tile(10, 0, 0)), 0), 0, 'an ocean tile stays empty');

SELECT * FROM finish(true);
ROLLBACK;

--------------------------------------------------------------------------------
-- pg_partman: Time Slicing, RDS-Approved ⏱️🔪
--------------------------------------------------------------------------------
CREATE TABLE incense_readings
(
	ts     TIMESTAMPTZ NOT NULL,
	temple TEXT        NOT NULL,
	smoke  DOUBLE PRECISION
) PARTITION BY RANGE (ts);

SELECT partman.create_parent(
	p_parent_table := 'public.incense_readings',
	p_control := 'ts',
	p_interval := '1 day',
	p_premake := 4,
	p_start_partition := (now() - INTERVAL '4 days')::date::text
	);

INSERT INTO incense_readings (ts, temple, smoke)
SELECT ts, temple, extract(HOUR FROM ts) -- smoke follows the sun
FROM generate_series(now() - INTERVAL '3 days', now(), INTERVAL '1 minute') AS ts,
	 unnest(ARRAY ['Kyoto', 'Lhasa', 'Fez']) AS temple;

SELECT partman.run_maintenance('public.incense_readings');

SELECT partition_tablename FROM partman.show_partitions('public.incense_readings');

DO
$$
BEGIN
	IF (SELECT count(*) FROM partman.show_partitions('public.incense_readings')) < 8 THEN
		RAISE EXCEPTION 'pg_partman did not pre-make the daily partitions';
	END IF;
	IF EXISTS (SELECT 1 FROM partman.check_default()) THEN
		RAISE EXCEPTION 'pg_partman: readings fell into the default partition';
	END IF;
END
$$;

SELECT temple, count(*) AS readings, round(avg(smoke)::numeric, 2) AS avg_smoke
FROM incense_readings
GROUP BY temple
ORDER BY temple;

--------------------------------------------------------------------------------
-- HypoPG: Would an Index Help? Ask Without Building One 👻
-- (btree/BRIN/hash/bloom only: hypothetical GiST is not supported)
--------------------------------------------------------------------------------
CREATE TABLE tile_requests
(
	id   SERIAL PRIMARY KEY,
	zoom INTEGER NOT NULL,
	x    INTEGER NOT NULL,
	y    INTEGER NOT NULL
);

INSERT INTO tile_requests (zoom, x, y)
SELECT i % 20, i, i
FROM generate_series(1, 100000) AS i;
ANALYZE tile_requests;

SELECT indexname FROM hypopg_create_index('CREATE INDEX ON tile_requests (x)');
SELECT index_name, am_name, pg_size_pretty(hypopg_relation_size(indexrelid)) AS would_cost
FROM hypopg_list_indexes;

DO
$$
DECLARE
	line      text;
	uses_hypo boolean := false;
BEGIN
	FOR line IN EXECUTE 'EXPLAIN SELECT * FROM tile_requests WHERE x = 4242' LOOP
		RAISE NOTICE '%', line;
		uses_hypo := uses_hypo OR line LIKE '%<%>btree_tile_requests_x%';
	END LOOP;
	IF NOT uses_hypo THEN
		RAISE EXCEPTION 'hypopg: the planner ignored the hypothetical index';
	END IF;
END
$$;

SELECT hypopg_reset();

--------------------------------------------------------------------------------
-- pg_repack: Re-shelving the Scrolls in Spatial Order, No Lock Held 📜
-- (runs the client from this container; PG* env comes from docker-compose)
--------------------------------------------------------------------------------
CREATE TABLE scattered_scrolls
(
	id      SERIAL PRIMARY KEY,
	geohash TEXT                  NOT NULL,
	geom    geometry(Point, 4326) NOT NULL
);

-- scrambled insert order, so heap order has nothing to do with location
INSERT INTO scattered_scrolls (geohash, geom)
SELECT ST_GeoHash(g, 8), g
FROM (SELECT ST_Point((i * 7919 % 360) - 180, (i * 104729 % 170) - 85, 4326) AS g
	  FROM generate_series(1, 5000) AS i) s;

CREATE TEMP TABLE repack_witness AS
SELECT pg_relation_filenode('scattered_scrolls') AS filenode;

\! pg_repack --dbname=test --table=public.scattered_scrolls --order-by=geohash

DO
$$
DECLARE
	out_of_order bigint;
BEGIN
	IF pg_relation_filenode('scattered_scrolls') = (SELECT filenode FROM repack_witness) THEN
		RAISE EXCEPTION 'pg_repack did not rewrite scattered_scrolls';
	END IF;

	SELECT count(*) INTO out_of_order
	FROM (SELECT geohash < lag(geohash) OVER (ORDER BY ctid) AS regressed FROM scattered_scrolls) t
	WHERE regressed;
	IF out_of_order > 0 THEN
		RAISE EXCEPTION 'pg_repack: % scrolls are not in geohash order on disk', out_of_order;
	END IF;
END
$$;

--------------------------------------------------------------------------------
-- Final Diagnostics Check
--------------------------------------------------------------------------------
SELECT 'Running Final Version Checks...' AS status_message;
SELECT version() AS postgres_version_final_check;
SELECT extname, extversion
FROM pg_extension
WHERE extname IN ('postgis', 'postgis_raster', 'postgis_sfcgal', 'vector', 'pgrouting', 'pg_trgm',
				  'h3', 'h3_postgis', 'pgtap', 'hypopg', 'pg_repack', 'pg_partman');
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
