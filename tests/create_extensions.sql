\set VERBOSITY verbose
\set ON_ERROR_STOP on

-- Drop the database if it exists
DROP DATABASE IF EXISTS test;

CREATE DATABASE test;
\c test


SELECT * FROM pg_available_extensions;

-- Enable the PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;

-- Create a table with a PostGIS geometry column
CREATE TABLE spatial_data (
							  id SERIAL PRIMARY KEY,
							  name VARCHAR(50),
							  geom GEOMETRY(Point, 4326)
);

-- Insert a point into the table
INSERT INTO spatial_data (name, geom)
VALUES
	('Point A', ST_GeomFromText('POINT(-71.060316 48.432044)', 4326)),
	('Point B', ST_GeomFromText('POINT(-70.060316 47.432044)', 4326));

-- Query to select the points and their distances
SELECT name, ST_AsText(geom), ST_Distance(geom, ST_GeomFromText('POINT(-71.060316 48.432044)', 4326)) AS distance
FROM spatial_data;


-- Enable the pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Create a table with a vector column
CREATE TABLE vector_data (
							 id SERIAL PRIMARY KEY,
							 embedding VECTOR(3)
);

-- Insert some vectors
INSERT INTO vector_data (embedding)
VALUES
	('[1, 1, 1]'),
	('[2, 2, 2]'),
	('[3, 3, 3]');

-- Query for the vector closest to [1.5, 1.5, 1.5]
SELECT id, embedding
FROM vector_data
ORDER BY embedding <-> '[1.5, 1.5, 1.5]'
	LIMIT 1;


-- Enable the AGE extension
CREATE EXTENSION IF NOT EXISTS age;
LOAD 'age';

SET search_path = ag_catalog, "$user", public;

-- Step 1: Create a new graph
SELECT create_graph('social_graph');

-- Step 2: Create two vertices (nodes) with labels and properties
SELECT *
FROM cypher('social_graph', $$
	CREATE (a:Person {name: 'Alice', age: 30}),
			(b:Person {name: 'Bob', age: 35})
				$$) as (v agtype);

-- Step 3: Query the graph to verify the vertices were created
SELECT *
FROM cypher('social_graph', $$
	MATCH (n:Person)
	RETURN n
$$) as (v agtype);

-- Step 4: Create an edge (relationship) between Alice and Bob
SELECT *
FROM cypher('social_graph', $$
	MATCH (a:Person), (b:Person)
				WHERE a.name = 'Alice' AND b.name = 'Bob'
				CREATE (a)-[e:KNOWS {relationship: 'Friends'}]->(b)
    RETURN e
$$) as (e agtype);

-- Step 5: Query the graph to verify the relationship (edge) was created
SELECT *
FROM cypher('social_graph', $$
	MATCH (a:Person)-[e:KNOWS]->(b:Person)
	RETURN a.name, b.name, e
				$$) as (a_name text, b_name text, e agtype);

\c postgres
DROP DATABASE test;
