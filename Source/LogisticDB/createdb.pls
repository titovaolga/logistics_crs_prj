------------------------ TABLES AND CONSTRAINTS ----------------------------------------------------------

CREATE TABLE IF NOT EXISTS cities
(
	id serial PRIMARY KEY,
	name text NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS roads
(
	id serial  PRIMARY KEY,
	city_from integer NOT NULL,
	city_to integer  NOT NULL  CHECK (city_to != city_from),
	distance integer NOT NULL,
	UNIQUE (city_from, city_to)
);

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'roads_city_from_fkey') THEN
        ALTER TABLE roads
        ADD CONSTRAINT roads_city_from_fkey FOREIGN KEY (city_from)
        REFERENCES cities (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION;
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'roads_city_to_fkey') THEN
        ALTER TABLE roads
        ADD CONSTRAINT roads_city_to_fkey FOREIGN KEY (city_to)
        REFERENCES cities (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION;
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS cargotypes
(
	id serial PRIMARY KEY,
	name text NOT NULL UNIQUE,
	cost_per_km_ton double precision NOT NULL CHECK (cost_per_km_ton > 0) 
);


/*
CREATE TABLE IF NOT EXISTS cartypes
(
  id serial PRIMARY KEY,
  cargo_type text NOT NULL,
  cost_empty double precision NOT NULL CHECK (cost_empty > 0),
  cost_full double precision NOT NULL CHECK (cost_full > 0),
  cost_stand double precision NOT NULL,
  payload real NOT NULL CHECK (payload > 0)
);
*/

CREATE TABLE IF NOT EXISTS carmodels
(
	id serial NOT NULL PRIMARY KEY,
	name text NOT NULL,
	cargotype_id integer NOT NULL,
	payload real NOT NULL CHECK (payload > 0),
	cost_buy double precision NOT NULL CHECK (cost_buy > 0),
	cost_sell double precision NOT NULL CHECK (cost_sell > 0),
	cost_empty_per_km double precision NOT NULL  CHECK  (cost_empty_per_km > 0),
	cost_full_per_km double precision NOT NULL  CHECK  (cost_full_per_km > 0),
	cost_stand_per_day double precision NOT NULL CHECK (cost_stand_per_day > 0),
    UNIQUE (name, cargotype_id)
);

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'carmodels_cargotype_id_fkey') THEN
        ALTER TABLE carmodels
        ADD CONSTRAINT carmodels_cargotype_id_fkey FOREIGN KEY (cargotype_id)
        REFERENCES cargotypes (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION;
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS cars
(
  id serial NOT NULL PRIMARY KEY,
  registration_number text NOT NULL UNIQUE,
  carmodel_id integer NOT NULL
);


DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'cars_carmodel_id_fkey') THEN
        ALTER TABLE cars
        ADD CONSTRAINT cars_carmodel_id_fkey FOREIGN KEY (carmodel_id)
        REFERENCES carmodels (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION;
    END IF;
END $$;


CREATE TABLE IF NOT EXISTS transactions
(
  id serial NOT NULL PRIMARY KEY,
  car_id integer NOT NULL,
  is_full boolean DEFAULT FALSE,
  city_from integer NOT NULL,
  city_to integer NOT NULL CHECK (city_to != city_from),
  date_from date NOT NULL,
  date_to date NOT NULL CHECK (date_from <= date_to)
);


DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'transactions_cars_id_fkey') THEN
        ALTER TABLE transactions
        ADD CONSTRAINT transactions_cars_id_fkey FOREIGN KEY (car_id)
        REFERENCES cars (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION;
    END IF;
END $$;


---------------------------------- BASIC FUNCTIONS ------------------------------------------------------

CREATE OR REPLACE FUNCTION  speed() RETURNS real AS $$
BEGIN
   RETURN 90;
END
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_cities() 
    RETURNS TABLE (
        id integer,
        name text
    )
AS $$ 
BEGIN
    RETURN QUERY 
        SELECT c.id, c.name  
            FROM cities AS c
            WHERE c.name != 'store'
            ORDER BY c.name;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_store_id() 
    RETURNS integer
AS $$
DECLARE
   r record;
BEGIN
    SELECT id INTO STRICT r FROM cities WHERE cities.name = 'store';
    RETURN r.id;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_city_id(IN _name text) 
    RETURNS integer
AS $$
DECLARE
   r record;
BEGIN
    SELECT id INTO STRICT r FROM cities WHERE cities.name = _name;
    RETURN r.id;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_cargotype_id(IN _name text) 
    RETURNS integer
AS $$
DECLARE
   r record;
BEGIN
    SELECT id INTO STRICT r FROM cargotypes WHERE name = _name;
    RETURN r.id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_cargotype_name(IN _id integer) 
    RETURNS text
AS $$
DECLARE
   r record;
BEGIN
    SELECT name INTO STRICT r FROM cargotypes WHERE id = _id;
    RETURN r.name;
END;
$$ LANGUAGE plpgsql;


---------------------------------- VIEWS ----------------------------------------------------------------

CREATE OR REPLACE VIEW cars_view AS
SELECT c.id, c.registration_number, m.id as carmodel_id, m.name as carmodel_name, 
       t.name as cargotype_name, t.id as cargotype_id, m.payload, m.cost_empty_per_km, m.cost_full_per_km, m.cost_stand_per_day,
       t1.date_from as date_buy, t2.date_from as date_sell  
       FROM cars AS c 
       INNER JOIN carmodels AS m ON c.carmodel_id = m.id
       INNER JOIN cargotypes AS t ON t.id = m.cargotype_id
       INNER JOIN transactions AS t1 ON c.id = t1.car_id AND t1.city_from = get_store_id()
       LEFT JOIN transactions AS t2 ON c.id = t2.car_id AND t2.city_to = get_store_id();

---------------------------------- FUNCTIONS -------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_distance_in_days(IN _city_from integer, IN _city_to integer) 
RETURNS integer
AS $$
DECLARE
    r record;
BEGIN
    IF ( _city_from =  _city_to) THEN
        RETURN 0;
    END IF;
    SELECT (ceil(distance / (24 * speed())) :: integer) as distance_in_days INTO r FROM 
        ((SELECT city_from, city_to, distance FROM roads WHERE city_from = _city_from AND city_to = _city_to)
    UNION ALL 
        (SELECT city_to AS city_from, city_from AS city_to, distance  FROM roads WHERE city_to = _city_from AND city_from = _city_to)) as d;
    RETURN r.distance_in_days;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'city_id_date') THEN 
        CREATE TYPE city_id_date AS (city_id integer, "date" date);
    END IF;
END $$;


CREATE OR REPLACE FUNCTION get_car_city_before(IN _car_id integer, IN _date date) 
    RETURNS city_id_date
AS $$
DECLARE
    r city_id_date;
BEGIN
    SELECT city_to, date_to INTO r.city_id, r.date FROM transactions WHERE car_id = _car_id AND date_to <= _date ORDER BY date_to FETCH FIRST 1 ROWS ONLY;
    return r;
RETURN r.id;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_car_city_after(IN _car_id integer, IN _date date) 
    RETURNS city_id_date
AS $$
DECLARE
    r city_id_date;
BEGIN
    SELECT city_from, date_from INTO r.city_id, r.date FROM transactions WHERE car_id = _car_id AND date_from >= _date ORDER BY date_from FETCH FIRST 1 ROWS ONLY;
    return r;
RETURN r.id;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION buy_car(IN _carmodel_id integer, IN _number text, IN _city_id integer, _date date) 
    RETURNS VOID
AS $$
DECLARE
   _car_id integer;
BEGIN
   INSERT INTO cars(registration_number, carmodel_id) VALUES (_number, _carmodel_id);
   SELECT id INTO STRICT _car_id FROM cars WHERE _number = registration_number;
   INSERT INTO transactions(car_id, city_from, city_to, date_from, date_to) VALUES (_car_id, get_store_id(), _city_id, _date, _date);
END
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sell_car(IN _car_id integer, _date date) 
    RETURNS VOID
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM transactions WHERE car_id = _car_id AND date_to > _date) THEN
        RAISE EXCEPTION 'There are some not finished transactions with this car at %', _date
        USING HINT = 'Please select more later date for selling.';
    END IF;
    INSERT INTO transactions(car_id, city_from, city_to, date_from, date_to) VALUES (_car_id, (get_car_city_before(_car_id, _date)).city_id, get_store_id(), _date, _date);
END
$$ LANGUAGE plpgsql;

 
CREATE OR REPLACE FUNCTION find_cars_for_transaction(IN _cargotype_id integer, IN _weight real, IN _city_id_from integer, IN _city_id_to integer, IN _date date)
RETURNS TABLE (car_id integer, cost real) 
AS $$
BEGIN
    DROP TABLE IF EXISTS tmp;
    CREATE TEMP TABLE tmp AS
    SELECT cv.id, get_car_city_before(cv.id, _date) as city_before, get_car_city_after(cv.id, _date) as city_after
    FROM cars_view AS cv
    WHERE cv.cargotype_id = _cargotype_id AND cv.payload >= _weight AND (cv.date_sell IS NULL OR cv.date_sell <= _date)
        AND 
        NOT EXISTS (SELECT 1 FROM transactions AS t WHERE t.car_id = cv.id AND t.date_from <= _date AND _date < t.date_to);
    RETURN QUERY

    SELECT id, transaction_cost(id, _weight, _city_id_from, _city_id_to, _date) AS cost FROM tmp
       WHERE 
         (_date - (tmp.city_before).date) >= get_distance_in_days((tmp.city_before).city_id, _city_id_from)
         AND
         (tmp.city_after IS NULL OR ((tmp.city_after).date - (_date + get_distance_in_days(_city_id_from, _city_id_to))) >= get_distance_in_days(_city_id_to, (tmp.city_after).city_id));       
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION transaction_cost(IN _car_id integer, IN _weight real, IN _city_id_from integer, IN _city_id_to integer, IN _date date)
RETURNS real
AS $$
DECLARE
   r_dist record;
   r_cost record;
   cost1 real = 0;
   cost2 real = 0;
   cost3 real = 0;
BEGIN
	SELECT cost_empty_per_km, cost_full_per_km INTO r_cost FROM cars AS c 
    INNER JOIN carmodels AS cm ON c.carmodel_id = cm.id 
	WHERE c.id = _car_id;	

	IF (get_car_city_before(_car_id, _date)).city_id != _city_id_from
	THEN

	SELECT distance INTO r_dist FROM 
        ((SELECT city_from, city_to, distance FROM roads WHERE city_from = (get_car_city_before(_car_id, _date)).city_id AND city_to = _city_id_from)
    UNION ALL 
        (SELECT city_to AS city_from, city_from AS city_to, distance FROM roads WHERE city_to = (get_car_city_before(_car_id, _date)).city_id AND city_from = _city_id_from)) as d;

	cost1 := r_cost.cost_empty_per_km * r_dist.distance;
	END IF;

	SELECT distance INTO r_dist FROM 
        ((SELECT city_from, city_to, distance FROM roads WHERE city_from = _city_id_from AND city_to = _city_id_to)
    UNION ALL 
        (SELECT city_to AS city_from, city_from AS city_to, distance FROM roads WHERE city_to = _city_id_from AND city_from = _city_id_to)) as d;

	cost2 := r_cost.cost_full_per_km * r_dist.distance * _weight;

	IF _city_id_to != (get_car_city_after(_car_id, _date)).city_id
	THEN

	SELECT distance INTO r_dist FROM 
        ((SELECT city_from, city_to, distance FROM roads WHERE city_from = (get_car_city_after(_car_id, _date)).city_id AND city_to = _city_id_to)
    UNION ALL 
        (SELECT city_to AS city_from, city_from AS city_to, distance FROM roads WHERE city_to = (get_car_city_after(_car_id, _date)).city_id AND city_from = _city_id_to)) as d;

	cost3 := r_cost.cost_empty_per_km * r_dist.distance;
	END IF;

	RETURN cost1 + cost2 + cost3;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION make_transaction(IN _car_id integer, IN _city_id_from integer, IN _city_id_to integer, IN _date date)
    RETURNS VOID
AS $$
BEGIN
	IF (get_car_city_before(_car_id, _date)).city_id != _city_id_from
	THEN
		INSERT INTO transactions(car_id, city_from, city_to, date_from, date_to) VALUES (_car_id, (get_car_city_before(_car_id, _date)).city_id, _city_id_from,
		_date, 
		_date + get_distance_in_days((get_car_city_before(_car_id, _date)).city_id, _city_id_from));
		INSERT INTO transactions(car_id, is_full, city_from, city_to, date_from, date_to) VALUES (_car_id, TRUE, _city_id_from, _city_id_to, 
		_date + get_distance_in_days((get_car_city_before(_car_id, _date)).city_id, _city_id_from), 
		_date + get_distance_in_days((get_car_city_before(_car_id, _date)).city_id, _city_id_from) + get_distance_in_days(_city_id_from, _city_id_to));
	
		IF _city_id_to != (get_car_city_after(_car_id, _date)).city_id
		THEN
			INSERT INTO transactions(car_id, city_from, city_to, date_from, date_to) VALUES (_car_id, _city_id_to, (get_car_city_after(_car_id, _date)).city_id, 
			_date + get_distance_in_days((get_car_city_before(_car_id, _date)).city_id, _city_id_from) + get_distance_in_days(_city_id_from, _city_id_to),
			_date + get_distance_in_days((get_car_city_before(_car_id, _date)).city_id, _city_id_from) + get_distance_in_days(_city_id_from, _city_id_to) + get_distance_in_days(_city_id_to, (get_car_city_after(_car_id, _date)).city_id));
		END IF;
	ELSE
		INSERT INTO transactions(car_id, is_full, city_from, city_to, date_from, date_to) VALUES (_car_id, TRUE, _city_id_from, _city_id_to, 
		_date, 
		_date + get_distance_in_days(_city_id_from, _city_id_to));
			
		IF _city_id_to != (get_car_city_after(_car_id, _date)).city_id  
		THEN
			INSERT INTO transactions(car_id, city_from, city_to, date_from, date_to) VALUES (_car_id, _city_id_to, (get_car_city_after(_car_id, _date)).city_id, 
			_date + get_distance_in_days(_city_id_from, _city_id_to),
			_date + get_distance_in_days(_city_id_from, _city_id_to) + get_distance_in_days(_city_id_to, (get_car_city_after(_car_id, _date)).city_id));
		END IF;
	END IF;
END
$$ LANGUAGE plpgsql;

------------------------------ REPORTS ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION coef_stay_for_each_car() 
RETURNS VOID
AS $$
BEGIN
	DROP TABLE IF EXISTS tmp;
	CREATE TEMP TABLE tmp AS
		SELECT car_id, date_to - date_from as days
		FROM transactions
		WHERE date_part('year', date_from) = date_part('year', CURRENT_DATE);

    DROP TABLE IF EXISTS in_way;
	CREATE TEMP TABLE in_way AS
		SELECT car_id, sum(days) as days_in_way FROM tmp
		GROUP BY car_id;

   SELECT car_id, 1 - days_in_way / 365.0 as coef FROM in_way ORDER BY car_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION coef_stay_for_all() 
RETURNS VOID
AS $$
BEGIN
	DROP TABLE IF EXISTS tmp;
	CREATE TEMP TABLE tmp AS
		SELECT car_id, date_to - date_from as days
		FROM transactions
		WHERE date_part('year', date_from) = date_part('year', CURRENT_DATE);

    DROP TABLE IF EXISTS in_way;
	CREATE TEMP TABLE in_way AS
		SELECT car_id, sum(days) as days_in_way FROM tmp
		GROUP BY car_id;

   SELECT 1 - sum(days_in_way) / 365.0 as coef FROM in_way;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION coef_useless_run_for_each_car() 
RETURNS VOID
AS $$
BEGIN
	DROP TABLE IF EXISTS tmp;
	CREATE TEMP TABLE tmp AS
		SELECT car_id, 
		(SELECT distance FROM 
        ((SELECT city_from, city_to, distance FROM roads WHERE city_from = t.city_from AND city_to = t.city_to)
		UNION ALL 
        (SELECT city_to AS city_from, city_from AS city_to, distance FROM roads WHERE city_to = t.city_from AND city_from = t.city_to)) as d) as dist,
		is_full
		FROM transactions as t
		WHERE date_part('year', date_from) = date_part('year', CURRENT_DATE);

	DROP TABLE IF EXISTS way_full;
	CREATE TEMP TABLE way_full AS
		SELECT car_id, sum(dist) as dist_full FROM tmp
		WHERE is_full = TRUE
		GROUP BY car_id;

	DROP TABLE IF EXISTS way_empty;
	CREATE TEMP TABLE way_empty AS
		SELECT car_id, sum(dist) as dist_empty FROM tmp
		WHERE is_full = FALSE
		GROUP BY car_id;
		
	SELECT *, dist_empty * 1.0 / dist_full as coef FROM way_empty INNER JOIN way_full ON way_empty.car_id = way_full.car_id;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION coef_useless_run_for_all() 
RETURNS VOID
AS $$
BEGIN
	DROP TABLE IF EXISTS tmp;
	CREATE TEMP TABLE tmp AS
		SELECT car_id, 
		(SELECT distance FROM 
        ((SELECT city_from, city_to, distance FROM roads WHERE city_from = t.city_from AND city_to = t.city_to)
		UNION ALL 
        (SELECT city_to AS city_from, city_from AS city_to, distance FROM roads WHERE city_to = t.city_from AND city_from = t.city_to)) as d) as dist,
		is_full
		FROM transactions as t
		WHERE date_part('year', date_from) = date_part('year', CURRENT_DATE);

	DROP TABLE IF EXISTS way_full;
	CREATE TEMP TABLE way_full AS
		SELECT car_id, sum(dist) as dist_full FROM tmp
		WHERE is_full = TRUE
		GROUP BY car_id;

	DROP TABLE IF EXISTS way_empty;
	CREATE TEMP TABLE way_empty AS
		SELECT car_id, sum(dist) as dist_empty FROM tmp
		WHERE is_full = FALSE
		GROUP BY car_id;
		
	SELECT sum(dist_empty) * 1.0 / sum(dist_full) as coef FROM way_empty INNER JOIN way_full ON way_empty.car_id = way_full.car_id;
END;
$$ LANGUAGE plpgsql;

------------------------------ FILLING DATABASE ------------------------------------------------------------------

INSERT INTO cities(name) VALUES
('store'), ('Msk'), ('Spb'), ('Ekb'), ('Nsk'), ('Sochi'), ('Vladivostok')
ON CONFLICT DO NOTHING;

INSERT INTO roads(city_from, city_to, distance) VALUES
(get_store_id(), get_city_id('Msk'), 0),
(get_store_id(), get_city_id('Spb'), 0),
(get_store_id(), get_city_id('Ekb'), 0),
(get_store_id(), get_city_id('Nsk'), 0),
(get_store_id(), get_city_id('Sochi'), 0),
(get_store_id(), get_city_id('Vladivostok'), 0),

(get_city_id('Msk'), get_city_id('Spb'), 650),
(get_city_id('Msk'), get_city_id('Ekb'), 1400),
(get_city_id('Msk'), get_city_id('Nsk'), 2800),
(get_city_id('Msk'), get_city_id('Sochi'), 1350),
(get_city_id('Msk'), get_city_id('Vladivostok'), 6400),

(get_city_id('Spb'), get_city_id('Ekb'), 1800),
(get_city_id('Spb'), get_city_id('Nsk'), 3150),
(get_city_id('Spb'), get_city_id('Sochi'), 1950),
(get_city_id('Spb'), get_city_id('Vladivostok'), 6550),

(get_city_id('Ekb'), get_city_id('Nsk'), 1450),
(get_city_id('Ekb'), get_city_id('Sochi'), 2100),
(get_city_id('Ekb'), get_city_id('Vladivostok'), 5100),

(get_city_id('Nsk'), get_city_id('Sochi'), 3350),
(get_city_id('Nsk'), get_city_id('Vladivostok'), 3800),

(get_city_id('Sochi'), get_city_id('Vladivostok'), 7100)
ON CONFLICT DO NOTHING;

INSERT INTO cargotypes(name, cost_per_km_ton) 
VALUES
('sand', 50),
('boxes', 60),
('liquid', 65),
('gas', 80)
ON CONFLICT DO NOTHING;

INSERT INTO carmodels
(name, cargotype_id, payload, cost_buy, cost_sell, cost_empty_per_km, cost_full_per_km, cost_stand_per_day) VALUES
('Kamaz' , get_cargotype_id('sand'), 20, 2.5e6, 1.5e5, 30, 35, 500),
('Kamaz' , get_cargotype_id('boxes'), 20, 2.5e6, 1.5e6, 30, 35, 500),
('Scania', get_cargotype_id('liquid'), 25, 6.5e6, 4.5e6, 27, 33, 700),
('Scania', get_cargotype_id('gas'), 30, 8.5e6, 5.5e6, 27, 33, 700),
('Gazel' , get_cargotype_id('boxes'), 1.5, 9e5, 5e5, 20, 35, 300)
ON CONFLICT DO NOTHING;
