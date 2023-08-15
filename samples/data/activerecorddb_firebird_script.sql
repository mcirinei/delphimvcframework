CREATE TABLE articles (
	id integer GENERATED BY DEFAULT AS IDENTITY,
	description varchar(100) NOT NULL,
	price integer NOT NULL,
	CONSTRAINT articles_pkey PRIMARY KEY (id)
);

CREATE TABLE customers (
	id integer GENERATED BY DEFAULT AS IDENTITY,
	code varchar(20),
	description varchar(200),
	city varchar(200),
	rating INTEGER,	
	NOTE BLOB SUB_TYPE 1,	
	CONSTRAINT customers_pk PRIMARY KEY (id)
);

CREATE TABLE CUSTOMERS_WITH_GUID (
	IDGUID VARCHAR(38) NOT NULL,
	CODE VARCHAR(20),
	DESCRIPTION VARCHAR(200),
	CITY VARCHAR(200),
	NOTE BLOB SUB_TYPE TEXT,
	RATING INTEGER,
	CONSTRAINT CUSTOMERS_WITH_GUID_PK PRIMARY KEY (IDGUID)
);

CREATE TABLE customers_plain (
    id integer NOT NULL,
    code varchar(20),
    description varchar(200),
    city varchar(200),
    note blob sub_type text,
    rating smallint,
    creation_time time,
    creation_date date,    	
    CONSTRAINT customers_plain_pk PRIMARY KEY (id)
);

CREATE TABLE customers_with_code (
    code varchar(20) NOT null primary key,
    description varchar(200),
    city varchar(200),
    NOTE BLOB SUB_TYPE 1,
    rating smallint
);

CREATE TABLE order_details (
	id integer GENERATED BY DEFAULT AS IDENTITY,
	id_order integer NOT NULL,
	id_article integer NOT NULL,
	unit_price numeric(18,2) NOT NULL,
	discount integer DEFAULT 0 NOT NULL ,
	quantity integer NOT NULL,
	description varchar(200) NOT NULL,
	total numeric(18,2) NOT NULL,
	CONSTRAINT order_details_pkey PRIMARY KEY (id)
);

CREATE TABLE orders (
	id integer GENERATED BY DEFAULT AS IDENTITY,
	id_customer integer NOT NULL,
	order_date date NOT NULL,
	total numeric(18,4) NOT NULL,
	CONSTRAINT orders_pkey PRIMARY KEY (id)
);


-- public.people definition

-- Drop table

-- DROP TABLE public.people;

CREATE TABLE people (
	id integer GENERATED BY DEFAULT AS IDENTITY,
	last_name varchar(100) NOT NULL,
	first_name varchar(100) NOT NULL,
	dob date NOT NULL,
	full_name varchar(80) NOT NULL,
	is_male BOOLEAN DEFAULT TRUE NOT NULL,
	note  blob sub_type TEXT,
	photo blob sub_type binary,
	person_type varchar(40),
	salary number(18,4),
	annual_bonus number(18,4),
	CONSTRAINT people_pkey PRIMARY KEY (id)
);

create table phones (
  id integer GENERATED BY DEFAULT AS IDENTITY,
  phone_number varchar(200) not null,
  number_type varchar(200) not null,  
  dob date,
  id_person integer not null references people(id)
);

ALTER TABLE orders ADD CONSTRAINT orders_customers_fk FOREIGN KEY (id_customer) REFERENCES customers(id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE order_details ADD CONSTRAINT order_details_orders_fk FOREIGN KEY (id_order) REFERENCES orders(id) ON DELETE CASCADE ON UPDATE CASCADE;
