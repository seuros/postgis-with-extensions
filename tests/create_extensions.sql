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
CREATE EXTENSION IF NOT EXISTS vector; -- tiny brains in columns
CREATE SCHEMA IF NOT EXISTS pgrouting;
CREATE EXTENSION IF NOT EXISTS pgrouting SCHEMA pgrouting;
-- actual roads, not just vibes

-- Load other extensions
CREATE EXTENSION IF NOT EXISTS age;
LOAD 'age';

SET search_path = public, pgrouting, ag_catalog, "$user";

--------------------------------------------------------------------------------
-- Crucial Diagnostics: Versions 🧪
--------------------------------------------------------------------------------
SELECT 'Running Initial Version Checks...' AS status_message;
SELECT version() AS postgres_version;
SELECT extname, extversion
FROM pg_extension
WHERE extname IN ('postgis', 'vector', 'pgrouting', 'age');
SELECT pgr_version();

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

SELECT label, embedding
FROM vector_data
ORDER BY embedding <-> '[1.5, 1.5, 1.5]'
LIMIT 1;

--------------------------------------------------------------------------------
-- Apache AGE: The Graph That Whispers 🌐🔮
--------------------------------------------------------------------------------
DO
$$
	BEGIN
		PERFORM create_graph('social_graph');
		PERFORM *
		FROM cypher('social_graph',
					$q$ CREATE (a:Person {name: 'Alice', age: 30}), (b:Person {name: 'Bob', age: 35}) $q$) AS (v agtype);
		RAISE NOTICE 'Vertices in the graph:';
		PERFORM * FROM cypher('social_graph', $q$ MATCH (n:Person) RETURN n $q$) AS (v agtype);
		PERFORM *
		FROM cypher('social_graph',
					$q$ MATCH (a:Person), (b:Person) WHERE a.name = 'Alice' AND b.name = 'Bob' CREATE (a)-[e:KNOWS {relationship: 'Friends'}]->(b) RETURN e $q$) AS (e agtype);
		RAISE NOTICE 'Edges in the graph:';
		PERFORM *
		FROM cypher('social_graph',
					$q$ MATCH (a:Person)-[e:KNOWS]->(b:Person) RETURN a.name, b.name, e $q$) AS (a_name text, b_name text, e agtype);
	END
$$;

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

SELECT pgrouting.pgr_createTopology('ley_lines', 0.00001, 'geom', 'id', 'source', 'target');
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
-- Final Diagnostics Check
--------------------------------------------------------------------------------
SELECT 'Running Final Version Checks...' AS status_message;
SELECT version() AS postgres_version_final_check;
SELECT extname, extversion
FROM pg_extension
WHERE extname IN ('postgis', 'vector', 'pgrouting', 'age');
SELECT pgr_version() AS pgr_version_final_check;

--------------------------------------------------------------------------------
-- Epilogue: Drop the ephemeral and tip your DBA 🎤
--------------------------------------------------------------------------------
\c postgres
DROP DATABASE test;
