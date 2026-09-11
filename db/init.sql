-- The database as it exists before node-pg-migrate is involved.
--
-- Nothing here is unusual: the app keeps its tables in its own schema, `app`,
-- and the role's default search_path points there. So psql, pgAdmin and the
-- app all find `users` and `business_profile` without writing `app.` in front.

CREATE SCHEMA app;

ALTER ROLE app_user SET search_path TO app, public;

-- Tables that existed before the project adopted migrations.
CREATE TABLE app.users (
  id serial PRIMARY KEY,
  name varchar(255)
);

CREATE TABLE app.business_profile (
  id serial PRIMARY KEY,
  business_description varchar(255)
);
