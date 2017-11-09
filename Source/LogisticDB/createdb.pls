------------------------ TABLES AND CONSTRAINTS ----------------------------------------------------------

CREATE TABLE IF NOT EXISTS cities
(
	id serial PRIMARY KEY,
	name text NOT NULL UNIQUE
);

CREATE INDEX ON cities (id);
CREATE INDEX ON cities (name);

CREATE TABLE IF NOT EXISTS roads
(
	id serial  PRIMARY KEY,
	city_from integer NOT NULL,
	city_to integer  NOT NULL  CHECK (city_to != city_from),
	distance integer NOT NULL,
	UNIQUE (city_from, city_to)
);

CREATE INDEX ON roads (city_from);
CREATE INDEX ON roads (city_to);
CREATE INDEX ON roads (distance);

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
	price_per_km_ton double precision NOT NULL CHECK (price_per_km_ton > 0) 
);

CREATE INDEX ON cargotypes (id);
CREATE INDEX ON cargotypes (name);

CREATE TABLE IF NOT EXISTS carmodels
(
	id serial NOT NULL PRIMARY KEY,
	name text NOT NULL,
	cargotype_id integer NOT NULL,
	payload real NOT NULL CHECK (payload > 0),
	price_buy double precision NOT NULL CHECK (price_buy > 0),
	price_sell double precision NOT NULL CHECK (price_sell > 0),
	price_empty_per_km double precision NOT NULL  CHECK  (price_empty_per_km > 0),
	price_full_per_km double precision NOT NULL  CHECK  (price_full_per_km > 0),
	price_stand_per_day double precision NOT NULL CHECK (price_stand_per_day > 0),
    UNIQUE (name, cargotype_id)
);

CREATE INDEX ON carmodels (id);
CREATE INDEX ON carmodels (name);
CREATE INDEX ON carmodels (cargotype_id);
CREATE INDEX ON carmodels (payload);
CREATE INDEX ON carmodels (price_buy);
CREATE INDEX ON carmodels (price_sell);
CREATE INDEX ON carmodels (price_empty_per_km);
CREATE INDEX ON carmodels (price_full_per_km);
CREATE INDEX ON carmodels (price_stand_per_day);

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

CREATE INDEX ON cars (id);
CREATE INDEX ON cars (registration_number);
CREATE INDEX ON cars (carmodel_id);

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
  weight real DEFAULT 0 NOT NULL CHECK (weight >= 0),
  city_from integer NOT NULL,
  city_to integer NOT NULL CHECK (city_to != city_from),
  date_from date NOT NULL,
  date_to date NOT NULL CHECK (date_from <= date_to),
  reward double precision NOT NULL CHECK (reward >= 0),
  expense double precision NOT NULL CHECK (expense >= 0)
);

CREATE INDEX ON transactions (id);
CREATE INDEX ON transactions (car_id);
CREATE INDEX ON transactions (weight);
CREATE INDEX ON transactions (city_from);
CREATE INDEX ON transactions (city_to);
CREATE INDEX ON transactions (date_from);
CREATE INDEX ON transactions (date_to);
CREATE INDEX ON transactions (reward);
CREATE INDEX ON transactions (expense);

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

CREATE OR REPLACE FUNCTION max_date(IN _d1 date,  IN _d2 date)
RETURNS date
AS $$
BEGIN

    IF (_d1 IS NULL OR _d2 IS NULL)
    THEN
        RETURN COALESCE(_d1, _d2);
    END IF;
    IF _d1 > _d2 
    THEN 
        RETURN _d1;
    END IF;
    RETURN _d2;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION min_date(IN _d1 date,  IN _d2 date)
RETURNS date
AS $$
BEGIN
    IF (_d1 IS NULL OR _d2 IS NULL)
    THEN
        RETURN COALESCE(_d1, _d2);
    END IF;
    IF _d1 < _d2 
    THEN 
        RETURN _d1;
    END IF;
    RETURN _d2;
END
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_distance(IN _city_from integer, IN _city_to integer) 
RETURNS integer
AS $$
DECLARE
    r record;
BEGIN
    IF ( _city_from =  _city_to) THEN
        RETURN 0;
    END IF;
    SELECT distance INTO r FROM 
        ((SELECT city_from, city_to, distance FROM roads WHERE city_from = _city_from AND city_to = _city_to)
    UNION ALL 
        (SELECT city_to AS city_from, city_from AS city_to, distance  FROM roads WHERE city_to = _city_from AND city_from = _city_to)) as d;
    RETURN r.distance;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_distance_in_days(IN _city_from integer, IN _city_to integer) 
RETURNS integer
AS $$
BEGIN
    RETURN (ceil(get_distance(_city_from, _city_to) / (24 * speed())) :: integer);
END;
$$ LANGUAGE plpgsql;

---------------------------------- VIEWS ----------------------------------------------------------------

CREATE OR REPLACE VIEW cars_view AS
SELECT c.id, c.registration_number, m.id as carmodel_id, m.name as carmodel_name, 
       t.name as cargotype_name, t.id as cargotype_id, m.payload, m.price_buy, m.price_sell,
       m.price_empty_per_km, m.price_full_per_km, m.price_stand_per_day,
       t1.date_from as date_buy, t2.date_from as date_sell  
       FROM cars AS c 
       INNER JOIN carmodels AS m ON c.carmodel_id = m.id
       INNER JOIN cargotypes AS t ON t.id = m.cargotype_id
       INNER JOIN transactions AS t1 ON c.id = t1.car_id AND t1.city_from = get_store_id()
       LEFT JOIN transactions AS t2 ON c.id = t2.car_id AND t2.city_to = get_store_id();

---------------------------------- FUNCTIONS -------------------------------------------------------------

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
    SELECT city_to, date_to INTO r.city_id, r.date FROM transactions WHERE car_id = _car_id AND date_to <= _date ORDER BY date_to DESC FETCH FIRST 1 ROWS ONLY;
    return r;
--RETURN r.id;
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
--RETURN r.id;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION buy_car(IN _carmodel_id integer, IN _number text, IN _city_id integer, _date date) 
    RETURNS VOID
AS $$
DECLARE
   _car_id integer;
   price record;
BEGIN
   SELECT price_buy INTO price FROM carmodels AS m WHERE m.id = _carmodel_id;
   INSERT INTO cars(registration_number, carmodel_id) VALUES (_number, _carmodel_id);
   SELECT id INTO STRICT _car_id FROM cars WHERE _number = registration_number;
   INSERT INTO transactions(car_id, city_from, city_to, date_from, date_to, reward, expense) VALUES (_car_id, get_store_id(), _city_id, _date, _date, 
   0, price.price_buy);
END
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sell_car(IN _car_id integer, _date date) 
    RETURNS VOID
AS $$
DECLARE
    price record;
BEGIN
    IF EXISTS (SELECT 1 FROM transactions WHERE car_id = _car_id AND date_to >= _date) THEN
        RAISE EXCEPTION 'There are some not finished transactions with this car at %', _date
        USING HINT = 'Please select more later date for selling.';
    END IF;
	IF EXISTS (SELECT 1 FROM transactions WHERE car_id = _car_id AND city_to = get_store_id()) THEN
        RAISE EXCEPTION 'This car has already been sold or will be sold soon.'
        USING HINT = 'Please select another car to buy.';
    END IF;
	SELECT price_sell INTO price FROM cars_view AS c WHERE c.id = _car_id;
    INSERT INTO transactions(car_id, city_from, city_to, date_from, date_to, reward, expense) VALUES (_car_id, (get_car_city_before(_car_id, _date)).city_id, get_store_id(), _date, _date,
	price.price_sell, 0);
END
$$ LANGUAGE plpgsql;

 
CREATE OR REPLACE FUNCTION find_cars_for_transaction(IN _cargotype_id integer, IN _weight real, IN _city_id_from integer, IN _city_id_to integer, IN _date date)
RETURNS TABLE (car_id integer, expense real) 
AS $$
BEGIN
    RETURN QUERY
    WITH tmp AS (SELECT cv.id, get_car_city_before(cv.id, _date) as city_before, get_car_city_after(cv.id, _date + get_distance_in_days(_city_id_from, _city_id_to)) as city_after
    FROM cars_view AS cv
    WHERE cv.cargotype_id = _cargotype_id AND cv.payload >= _weight AND (cv.date_sell IS NULL OR cv.date_sell > _date + get_distance_in_days(_city_id_from, _city_id_to))
        AND 
        NOT EXISTS (SELECT 1 FROM transactions AS t WHERE t.car_id = cv.id AND t.date_from <= _date AND _date < t.date_to)
    ) 
    SELECT id, transaction_expense(id, _weight, _city_id_from, _city_id_to, _date) AS expense FROM tmp
       WHERE 
         (_date - (tmp.city_before).date) >= get_distance_in_days((tmp.city_before).city_id, _city_id_from)
         AND
         (tmp.city_after IS NULL OR ((tmp.city_after).date - (_date + get_distance_in_days(_city_id_from, _city_id_to))) >= get_distance_in_days(_city_id_to, (tmp.city_after).city_id));       
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION transaction_expense(IN _car_id integer, IN _weight real, IN _city_id_from integer, IN _city_id_to integer, IN _date date)
RETURNS real
AS $$
DECLARE
    r_price record;
BEGIN
    SELECT cv.price_empty_per_km, cv.price_full_per_km, ct.price_per_km_ton INTO r_price FROM cars_view AS cv INNER JOIN cargotypes AS ct ON cv.cargotype_id = ct.id WHERE cv.id = _car_id; 
    RETURN (get_distance(_city_id_from, _city_id_to) * r_price.price_full_per_km * _weight + 
           (get_distance((get_car_city_before(_car_id, _date)).city_id, _city_id_from) + 
           get_distance(_city_id_to, COALESCE((get_car_city_after(_car_id, _date + get_distance_in_days(_city_id_from, _city_id_to))).city_id, _city_id_to))) * r_price.price_empty_per_km);
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION make_transaction(IN _car_id integer, IN _weight real, IN _city_id_from integer, IN _city_id_to integer, IN _date date)
    RETURNS VOID
AS $$
DECLARE
    r_price record;
BEGIN
    SELECT cv.price_empty_per_km, cv.price_full_per_km, ct.price_per_km_ton INTO r_price FROM cars_view AS cv INNER JOIN cargotypes AS ct ON cv.cargotype_id = ct.id WHERE cv.id = _car_id; 
    
	IF (get_car_city_before(_car_id, _date)).city_id != _city_id_from
	THEN
		INSERT INTO transactions(car_id, city_from, city_to, date_from, date_to, reward, expense) 
		VALUES (_car_id, (get_car_city_before(_car_id, _date)).city_id, _city_id_from,
		_date - get_distance_in_days((get_car_city_before(_car_id, _date)).city_id, _city_id_from), _date,
		 0, get_distance((get_car_city_before(_car_id, _date)).city_id, _city_id_from) * r_price.price_empty_per_km);
	END IF;

	INSERT INTO transactions(car_id, weight, city_from, city_to, date_from, date_to, reward, expense) 
	VALUES (_car_id, _weight, _city_id_from, _city_id_to, 
		_date, 
		_date + get_distance_in_days(_city_id_from, _city_id_to), 
		get_distance(_city_id_from, _city_id_to) * r_price.price_per_km_ton * _weight, 
		get_distance(_city_id_from, _city_id_to) * r_price.price_full_per_km);
	
	IF (get_car_city_after(_car_id, _date + get_distance_in_days(_city_id_from, _city_id_to))).city_id IS NOT NULL AND (get_car_city_after(_car_id, _date + get_distance_in_days(_city_id_from, _city_id_to))).city_id !=  _city_id_to
	THEN
		INSERT INTO transactions(car_id, city_from, city_to, date_from, date_to, reward, expense) 
		VALUES (_car_id, _city_id_to, (get_car_city_after(_car_id, _date + get_distance_in_days(_city_id_from, _city_id_to))).city_id, 
		_date + get_distance_in_days(_city_id_from, _city_id_to),
		_date + get_distance_in_days(_city_id_from, _city_id_to) + get_distance_in_days(_city_id_to, (get_car_city_after(_car_id, _date + get_distance_in_days(_city_id_from, _city_id_to))).city_id),
		0, get_distance(_city_id_to, (get_car_city_after(_car_id, _date + get_distance_in_days(_city_id_from, _city_id_to))).city_id) * r_price.price_empty_per_km);
	END IF;
	
END
$$ LANGUAGE plpgsql;

------------------------------ REPORTS ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION car_stay_coef(IN _car_id integer, IN _date_from date,  IN _date_to date) 
RETURNS real
AS $$
DECLARE 
    in_way integer;
    cv record;
BEGIN
   SELECT date_buy, date_sell INTO cv FROM cars_view WHERE id = _car_id; 
   SELECT SUM(min_date(date_to, _date_to) - max_date(date_from, _date_from)) INTO in_way FROM
   transactions WHERE car_id = _car_id AND date_from < _date_to AND date_to >= _date_from;
   RETURN (1::real) - (in_way:: real) / (min_date(_date_to, cv.date_sell) - max_date(_date_from, cv.date_buy));
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION stay_coef_report( IN _date_from date,  IN _date_to date) 
RETURNS TABLE (registration_number text,
               carmodel_name text,
               cargotype_name text,
               payload real,
               coef real)
AS $$
BEGIN
    RETURN QUERY
    WITH rep AS
    (
        SELECT cv.registration_number, cv.carmodel_name, cv.cargotype_name, cv.payload,
               car_stay_coef(id, _date_from, _date_to) AS coef
        FROM cars_view AS cv
    )
    (SELECT * FROM rep) UNION ALL
    (SELECT 'Total' AS registration_number, null AS carmodel_name,
                        null AS cargotype_name, null AS payload, AVG(r.coef)::real AS coef FROM rep AS r);
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION car_useless_run_coef(IN _car_id integer, IN _date_from date,  IN _date_to date) 
RETURNS real
AS $$
DECLARE 
     useless_run integer;
     usefull_run integer;
     cv record;
BEGIN
    SELECT date_buy, date_sell INTO cv FROM cars_view WHERE id = _car_id; 
    SELECT SUM(get_distance(city_from, city_to)) INTO useless_run FROM transactions
    WHERE car_id = _car_id AND date_from < _date_to AND date_to >= _date_from AND weight = 0;
 
    SELECT SUM(get_distance(city_from, city_to)) INTO usefull_run FROM transactions
    WHERE car_id = _car_id AND date_from < _date_to AND date_to >= _date_from AND weight > 0;
    RAISE NOTICE 'useless_run % usefull_run %', useless_run, usefull_run;
    IF (useless_run = 0 AND usefull_run = 0) THEN
        RETURN 0::real;
    END IF;
    RETURN (useless_run::real) / (useless_run + usefull_run);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION useless_run_report( IN _date_from date,  IN _date_to date) 
RETURNS TABLE (registration_number text,
               carmodel_name text,
               cargotype_name text,
               payload real,
               coef real)
AS $$
DECLARE 
     useless_run integer;
     usefull_run integer;
     total_coef real;
BEGIN
    SELECT SUM(get_distance(city_from, city_to)) INTO useless_run FROM transactions
    WHERE date_from < _date_to AND date_to >= _date_from AND weight = 0;

    SELECT SUM(get_distance(city_from, city_to)) INTO usefull_run FROM transactions
    WHERE  date_from < _date_to AND date_to >= _date_from AND weight > 0;
    IF (useless_run = 0 AND usefull_run = 0) THEN
        total_coef := 0::real;
    ELSE
        total_coef := (useless_run::real) / (useless_run + usefull_run);
    END IF; 

    RETURN QUERY
    (
        SELECT cv.registration_number, cv.carmodel_name, cv.cargotype_name, cv.payload,
               car_useless_run_coef(id, _date_from, _date_to) AS coef
        FROM cars_view AS cv
    ) UNION ALL
    (SELECT 'Total' AS registration_number, null AS carmodel_name,
                        null AS cargotype_name, null AS payload, total_coef AS coef);
END
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION popular_cargoes() 
RETURNS TABLE (cargotype_id integer, sum_weight real)
AS $$
BEGIN
	DROP TABLE IF EXISTS tmp;
	CREATE TEMP TABLE tmp AS
	SELECT t.car_id, t.weight, m.cargotype_id FROM transactions AS t INNER JOIN cars AS c ON c.id = t.car_id INNER JOIN carmodels AS m ON c.carmodel_id = m.id;

	RETURN QUERY
	SELECT tmp.cargotype_id, sum(weight) AS sum_weight FROM tmp GROUP BY tmp.cargotype_id ORDER BY sum_weight DESC;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION popular_cities() 
RETURNS TABLE (city integer, sum_weight real)
AS $$
BEGIN
	DROP TABLE IF EXISTS tmp;
	CREATE TEMP TABLE tmp AS
	SELECT t.weight, t.city_from, t.city_to FROM transactions AS t 
	WHERE t.city_from != get_store_id() AND t.city_to != get_store_id();

	RETURN QUERY
	SELECT city_from, sum(weight) AS sum_weight FROM tmp GROUP BY tmp.city_from ORDER BY sum_weight DESC;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION financial_report() 
RETURNS TABLE (car_id integer, date_from date, date_to date, reward double precision, expense double precision, carmodel_name text, cargotype_name text, source text)
AS $$
DECLARE
status record;
BEGIN
	RETURN QUERY
	SELECT t.car_id AS car_id, t.date_from AS date_from, t.date_to AS date_to, t.reward AS reward, t.expense AS expense, 
	cm.name AS carmodel_name, ct.name AS cargotype_name,
	CASE WHEN t.city_from = get_store_id() THEN 'Buy car' WHEN t.city_to = get_store_id() THEN 'Sell car' ELSE 'Transaction' END as source
	FROM transactions AS t INNER JOIN cars AS c ON t.car_id = c.id
	INNER JOIN carmodels AS cm ON c.carmodel_id = cm.id
	INNER JOIN cargotypes AS ct ON cm.cargotype_id = ct.id
	WHERE date_part('year', t.date_from) = date_part('year', CURRENT_DATE);
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

INSERT INTO cargotypes(name, price_per_km_ton) 
VALUES
('sand',20),
('boxes',30),
('liquid',50),
('gas',80)
ON CONFLICT DO NOTHING;

INSERT INTO carmodels
(name, cargotype_id, payload, price_buy, price_sell, price_empty_per_km, price_full_per_km, price_stand_per_day) VALUES
('Kamaz' , get_cargotype_id('sand'), 20, 2.5e6, 1.5e5, 30, 35, 500),
('Kamaz' , get_cargotype_id('boxes'), 20, 2.5e6, 1.5e6, 30, 35, 500),
('Scania', get_cargotype_id('liquid'), 25, 6.5e6, 4.5e6, 27, 33, 700),
('Scania', get_cargotype_id('gas'), 30, 8.5e6, 5.5e6, 27, 33, 700),
('Gazel' , get_cargotype_id('boxes'), 1.5, 9e5, 5e5, 20, 35, 300)
ON CONFLICT DO NOTHING;



/*CREATE OR REPLACE FUNCTION transaction_expense2(IN _car_id integer, IN _weight real, IN _city_id_from integer, IN _city_id_to integer, IN _date date)
RETURNS real
AS $$
DECLARE
   r_dist record;
   r_price record;
   price1 real = 0;
   price2 real = 0;
   price3 real = 0;
BEGIN
	SELECT price_empty_per_km, price_full_per_km INTO r_price FROM cars AS c 
    INNER JOIN carmodels AS cm ON c.carmodel_id = cm.id 
	WHERE c.id = _car_id;	

	IF (get_car_city_before(_car_id, _date)).city_id != _city_id_from
	THEN
        SELECT distance INTO r_dist FROM 
            ((SELECT city_from, city_to, distance FROM roads WHERE city_from = (get_car_city_before(_car_id, _date)).city_id AND city_to = _city_id_from)
        UNION ALL 
            (SELECT city_to AS city_from, city_from AS city_to, distance FROM roads WHERE city_to = (get_car_city_before(_car_id, _date)).city_id AND city_from = _city_id_from)) as d;
	    price1 := r_price.price_empty_per_km * r_dist.distance;
	END IF;

	SELECT distance INTO r_dist FROM 
        ((SELECT city_from, city_to, distance FROM roads WHERE city_from = _city_id_from AND city_to = _city_id_to)
    UNION ALL 
        (SELECT city_to AS city_from, city_from AS city_to, distance FROM roads WHERE city_to = _city_id_from AND city_from = _city_id_to)) as d;
	price2 := r_price.price_full_per_km * r_dist.distance * _weight;

	IF _city_id_to != (get_car_city_after(_car_id, _date)).city_id
	THEN
        SELECT distance INTO r_dist FROM 
            ((SELECT city_from, city_to, distance FROM roads WHERE city_from = (get_car_city_after(_car_id, _date)).city_id AND city_to = _city_id_to)
        UNION ALL 
            (SELECT city_to AS city_from, city_from AS city_to, distance FROM roads WHERE city_to = (get_car_city_after(_car_id, _date)).city_id AND city_from = _city_id_to)) as d;

	    price3 := r_price.price_empty_per_km * r_dist.distance;
	END IF;

	RETURN price1 + price2 + price3;
END;
$$ LANGUAGE plpgsql;
*/

/*CREATE OR REPLACE FUNCTION coef_stay_for_each_car() 
RETURNS real
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

CREATE OR REPLACE FUNCTION coef_stay_for_car(IN _date_1 date, IN _date_2 date) 
RETURNS TABLE (car integer, coef real) 
AS $$
BEGIN
	DROP TABLE IF EXISTS tmp;
	CREATE TEMP TABLE tmp AS
--	SELECT t.car_id, LEAST(date_to, _date_2) - GREATEST(date_from, _date_1) as days
	SELECT t.car_id, CASE WHEN date_to < _date_2 THEN date_to ELSE _date_2 END as date_f,
	CASE WHEN date_from > _date_1 THEN date_from ELSE _date_1 END as date_t
	FROM transactions AS t
	WHERE ( _date_1 < date_to AND _date_2 > date_from);

	DROP TABLE IF EXISTS in_way;
	CREATE TEMP TABLE in_way AS
		SELECT tmp.car_id, sum(date_t - date_f) as days_in_way FROM tmp
		GROUP BY tmp.car_id;

	SELECT in_way.car_id as car_id, CASE WHEN days_in_way != 0 THEN ( _date_2 - _date_1 - days_in_way) * 1.0 / days_in_way ELSE 0.000001 END as coef FROM in_way ORDER BY in_way.car_id;
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
RETURNS TABLE (car_id integer, coef real) 
AS $$
BEGIN
	DROP TABLE IF EXISTS tmp;
	CREATE TEMP TABLE tmp AS
		SELECT t.car_id, 
		(SELECT distance FROM 
        ((SELECT city_from, city_to, distance FROM roads WHERE city_from = t.city_from AND city_to = t.city_to)
		UNION ALL 
        (SELECT city_to AS city_from, city_from AS city_to, distance FROM roads WHERE city_to = t.city_from AND city_from = t.city_to)) as d) as dist,
		t.weight
		FROM transactions as t
		WHERE date_part('year', date_from) = date_part('year', CURRENT_DATE);

	DROP TABLE IF EXISTS way_full;
	CREATE TEMP TABLE way_full AS
		SELECT tmp.car_id, sum(dist) as dist_full FROM tmp
		WHERE weight > 0
		GROUP BY tmp.car_id;

	DROP TABLE IF EXISTS way_empty;
	CREATE TEMP TABLE way_empty AS
		SELECT tmp.car_id, sum(dist) as dist_empty FROM tmp
		WHERE weight = 0
		GROUP BY tmp.car_id;
		
	SELECT CASE WHEN dist_full != 0 THEN dist_empty * 1.0 / dist_full ELSE 1000 END as coef FROM way_empty INNER JOIN way_full ON way_empty.car_id = way_full.car_id;
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
		weight
		FROM transactions as t
		WHERE date_part('year', date_from) = date_part('year', CURRENT_DATE);

	DROP TABLE IF EXISTS way_full;
	CREATE TEMP TABLE way_full AS
		SELECT car_id, sum(dist) as dist_full FROM tmp
		WHERE weight > 0
		GROUP BY car_id;

	DROP TABLE IF EXISTS way_empty;
	CREATE TEMP TABLE way_empty AS
		SELECT car_id, sum(dist) as dist_empty FROM tmp
		WHERE weight = 0
		GROUP BY car_id;
		
	SELECT sum(dist_empty) * 1.0 / sum(dist_full) as coef FROM way_empty INNER JOIN way_full ON way_empty.car_id = way_full.car_id;
END;
$$ LANGUAGE plpgsql;*/