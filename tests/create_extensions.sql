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
CREATE EXTENSION postgis;
CREATE EXTENSION vector;
CREATE EXTENSION age;

--------------------------------------------------------------------------------
-- TABLE: spatial_data – Points of Doubt 🧭
--------------------------------------------------------------------------------

CREATE TABLE spatial_data (
  id   SERIAL PRIMARY KEY,
  name TEXT CHECK (name NOT ILIKE 'Bob'), -- Bob is forbidden
  geom geometry(Point, 4326)
);

-- Insert real and imaginary coordinates
INSERT INTO spatial_data (name, geom) VALUES
  ('Point A', ST_Point(-71.060316, 48.432044)),
  ('Point B', ST_Point(-70.060316, 47.432044)),
  ('The Abyss', ST_GeomFromEWKT('SRID=4326;POINT(-0.000000666 66.666666)'));

-- See who’s closest to the origin of all suffering
SELECT
  id, name,
  ST_AsText(geom) AS wkt,
  ST_Distance(geom, ST_SetSRID(ST_Point(0, 0), 4326)) AS distance_from_origin
FROM spatial_data
ORDER BY distance_from_origin;

--------------------------------------------------------------------------------
-- TABLE: vector_data – Philosophical Embeddings 🧠
--------------------------------------------------------------------------------
CREATE TABLE vector_data (
  id SERIAL PRIMARY KEY,
  label TEXT DEFAULT 'unnamed thoughtform',
  embedding vector(3)
);

-- Insert some vectors that represent failed startup ideas
INSERT INTO vector_data (embedding, label) VALUES
  ('[1, 1, 1]', 'AI‑powered incense recommendation'),
  ('[2, 2, 2]', 'Crypto for monks'),
  ('[3, 3, 3]', 'NFTs for ancient manuscripts');

-- Find the one that matches your existential crisis
SELECT label, embedding
FROM vector_data
ORDER BY embedding <-> '[1.5, 1.5, 1.5]'
LIMIT 1;

--------------------------------------------------------------------------------
-- Apache AGE: The Graph That Whispers 🌐🔮
--------------------------------------------------------------------------------
DO $$
BEGIN
  LOAD 'age';
-- Set the search path to include the Apache AGE catalog
SET search_path = ag_catalog, "$user", public;

-- Step 1: Create a new graph
PERFORM create_graph('social_graph');

-- Step 2: Create two vertices (nodes) with labels and properties
PERFORM *
FROM cypher('social_graph', $q$
CREATE (a:Person {name: 'Alice', age: 30}),
		(b:Person {name: 'Bob', age: 35})
$q$) AS (v agtype);

-- Step 3: Query the graph to verify the vertices were created
RAISE NOTICE 'Vertices in the graph:';
PERFORM *
FROM cypher('social_graph', $q$
MATCH (n:Person)
RETURN n
$q$) AS (v agtype);

-- Step 4: Create an edge (relationship) between Alice and Bob
PERFORM *
FROM cypher('social_graph', $q$
MATCH (a:Person), (b:Person)
WHERE a.name = 'Alice' AND b.name = 'Bob'
CREATE (a)-[e:KNOWS {relationship: 'Friends'}]->(b)
RETURN e
$q$) AS (e agtype);

-- Step 5: Query the graph to verify the relationship (edge) was created
RAISE NOTICE 'Edges in the graph:';
PERFORM *
FROM cypher('social_graph', $q$
MATCH (a:Person)-[e:KNOWS]->(b:Person)
RETURN a.name, b.name, e
$q$) AS (a_name text, b_name text, e agtype);
END$$;

--------------------------------------------------------------------------------
-- Temporal Hiccups: Create a table of dreams that fade too fast ⏳
--------------------------------------------------------------------------------
CREATE TABLE fleeting_dreams (
  id SERIAL PRIMARY KEY,
  dream TEXT,
  timestamp TIMESTAMPTZ DEFAULT now() + ((random() * 5 - 2.5) * INTERVAL '1 day')
);

INSERT INTO fleeting_dreams (dream)
SELECT unnest(ARRAY[
  'You can fly but only upward',
  'Everyone speaks SQL and you are mute',
  'All joins are cross joins',
  'You are a recursive CTE'
]);

-- Which dream will vanish next?
SELECT * FROM fleeting_dreams ORDER BY timestamp LIMIT 1;

--------------------------------------------------------------------------------
-- Diagnostics for a Reality Check 🧪
--------------------------------------------------------------------------------
SELECT version() AS postgres_version;

SELECT extname, extversion FROM pg_extension;

-- Drop the ephemeral
\c postgres
DROP DATABASE test;
