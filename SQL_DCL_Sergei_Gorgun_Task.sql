--1. Create a new user with the username "rentaluser" and the password "rentalpassword". Give the user the ability to connect to the database but no other permissions.
DO
$$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles
      WHERE rolname = 'rentaluser'
   ) THEN
      CREATE USER rentaluser WITH PASSWORD 'rentalpassword';
   END IF;
END
$$;

GRANT CONNECT ON DATABASE dvdrental TO rentaluser;

--Check for rentaluser: 

--connect to the database as user rentaluser with password rentalpassword

--2. Grant "rentaluser" SELECT permission for the "customer" table. Сheck to make sure this permission works correctly—write a SQL query to select all customers.
GRANT SELECT ON TABLE public.customer TO rentaluser;
--Check for rental user
--SELECT * FROM public.customer;

--3. Create a new user group called "rental" and add "rentaluser" to the group.
DO
$$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles
      WHERE rolname = 'rental'
   ) THEN
      CREATE ROLE rental;
   END IF;
END
$$;

DO $$
BEGIN
   IF NOT EXISTS (
      SELECT 1
      FROM pg_auth_members
      WHERE roleid = (SELECT oid FROM pg_roles WHERE rolname = 'rental')
        AND member = (SELECT oid FROM pg_roles WHERE rolname = 'rentaluser')
   ) THEN
      GRANT rental TO rentaluser;
   END IF;
END $$;


--4. Grant the "rental" group INSERT and UPDATE permissions for the "rental" table. Insert a new row and update one existing row in the "rental" table under that role. 
GRANT INSERT, UPDATE, SELECT ON TABLE public.rental TO rental;
GRANT USAGE, SELECT ON SEQUENCE public.rental_rental_id_seq TO rental;

--Check for rentaluser:

--SET ROLE rentaluser;

--INSERT INTO public.rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
--VALUES ('2024-06-01 10:00:00', 2, 2, '2024-06-08 10:00:00', 2, CURRENT_TIMESTAMP);

--UPDATE public.rental
--SET return_date = '2024-06-09 10:00:00', last_update = CURRENT_TIMESTAMP
--WHERE rental_id = 2;

--5. Revoke the "rental" group's INSERT permission for the "rental" table. Try to insert new rows into the "rental" table make sure this action is denied.
REVOKE INSERT ON TABLE public.rental FROM rental;
--Check for rentaluser
--INSERT INTO public.rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
--VALUES ('2024-06-01 10:00:00', 4, 4, '2024-06-08 10:00:00', 4, CURRENT_TIMESTAMP);

--6. Create a personalized role for any customer already existing in the dvd_rental database. The name of the role name must be client_{first_name}_{last_name} (omit curly brackets). The customer's payment and rental history must not be empty. Configure that role so that the customer can only access their own data in the "rental" and "payment" tables. Write a query to make sure this user sees only their own data.
-- Create a personalized role for the customer MARY SMITH
DO $$ 
BEGIN
    BEGIN
        EXECUTE 'CREATE ROLE client_MARY_SMITH WITH LOGIN PASSWORD ''password''';    
        EXECUTE 'GRANT SELECT ON TABLE public.rental TO client_MARY_SMITH';
        EXECUTE 'GRANT SELECT ON TABLE public.payment TO client_MARY_SMITH';
    EXCEPTION
        WHEN duplicate_object THEN
            RAISE NOTICE 'Role client_MARY_SMITH already exists, skipping creation.';
    END;
END $$;

-- Enable RLS on rental table
ALTER TABLE public.rental ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rental FORCE ROW LEVEL SECURITY;

-- Create policy for rental table
DO $$
BEGIN
    BEGIN
        EXECUTE 'CREATE POLICY rental_policy_MARY_SMITH
                 ON public.rental
                 FOR SELECT
                 USING (customer_id = 6)';
    EXCEPTION
        WHEN duplicate_object THEN
            RAISE NOTICE 'Policy rental_policy_MARY_SMITH already exists, skipping creation.';
    END;
END $$;

-- Enable RLS on payment table
ALTER TABLE public.payment ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment FORCE ROW LEVEL SECURITY;

-- Create policy for payment table
DO $$
BEGIN
    BEGIN
        EXECUTE 'CREATE POLICY payment_policy_MARY_SMITH
                 ON public.payment
                 FOR SELECT
                 USING (customer_id = 6)';
    EXCEPTION
        WHEN duplicate_object THEN
            RAISE NOTICE 'Policy payment_policy_MARY_SMITH already exists, skipping creation.';
    END;
END $$;

-- Test the role
-- Connect to the database as client_MARY_SMITH with password password

-- Query to check rental data
-- SELECT * FROM public.rental;

-- Query to check payment data
-- SELECT * FROM public.payment;