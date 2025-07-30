--- Force disconnect all other users (if you're an admin)
--SELECT pg_terminate_backend(pid)
--FROM pg_stat_activity
--WHERE datname = 'library_system_management'
--  AND pid <> pg_backend_pid();
---

-- ========================================================
-- 📚 LIBRARY MANAGEMENT SYSTEM
-- ========================================================

-- Drop the database if it exists, and Create a fresh new database
DROP DATABASE IF EXISTS Library_Management_System;
CREATE DATABASE Library_Management_System;

-- ========================================================
-- 🏗️ SCHEMA: TABLE CREATION
-- ========================================================

-- Drop in dependency-safe order
DROP TABLE IF EXISTS return_status;
DROP TABLE IF EXISTS issued_status;
DROP TABLE IF EXISTS books;
DROP TABLE IF EXISTS branch CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS members;

-- 1. Branch Table
CREATE TABLE branch (
    branch_id VARCHAR(10) PRIMARY KEY,
    manager_id VARCHAR(10),
    branch_address VARCHAR(50),
    contact_no VARCHAR(15)
);

-- 2. Members Table
CREATE TABLE members (
    member_id VARCHAR(10) PRIMARY KEY,
    member_name VARCHAR(50),
    member_address VARCHAR(50),
    reg_date DATE
);

-- 3. Employees Table
CREATE TABLE employees (
    emp_id VARCHAR(10) PRIMARY KEY,
    emp_name VARCHAR(50),
    position VARCHAR(20),
    salary FLOAT,
    branch_id VARCHAR(10)
);

-- 4. Books Table
CREATE TABLE books (
    isbn VARCHAR(25) PRIMARY KEY,
    book_title VARCHAR(75),
    category VARCHAR(20),
    rental_price FLOAT,
    status VARCHAR(10),
    author VARCHAR(50),
    publisher VARCHAR(50)
);

-- 5. Issued Status Table
CREATE TABLE issued_status (
    issued_id VARCHAR(10) PRIMARY KEY,
    issued_member_id VARCHAR(10),
    issued_book_name VARCHAR(75),
    issued_date DATE,
    issued_book_isbn VARCHAR(25),
    issued_emp_id VARCHAR(10)
);

-- 6. Return Status Table
CREATE TABLE return_status (
    return_id VARCHAR(10) PRIMARY KEY,
    issued_id VARCHAR(10),
    return_book_name VARCHAR(75),
    return_date DATE,
    return_book_isbn VARCHAR(25)
);
--select * from return_status; 

-- ========================================================
-- 🧹 DATA CLEANUP BEFORE ENFORCING CONSTRAINTS
-- ========================================================

-- Ensure return_status has valid book names & ISBNs
UPDATE return_status r
SET 
    return_book_name = i.issued_book_name,
    return_book_isbn = i.issued_book_isbn
FROM issued_status i
WHERE TRIM(r.issued_id) = TRIM(i.issued_id)
  AND (
    r.return_book_name IS DISTINCT FROM i.issued_book_name OR
    r.return_book_isbn IS DISTINCT FROM i.issued_book_isbn
  );

-- Remove invalid or orphaned returns
DELETE FROM return_status
WHERE issued_id IS NULL
   OR issued_id NOT IN (SELECT issued_id FROM issued_status);


-- ========================================================
-- 🔗 FOREIGN KEY CONSTRAINTS (AFTER CLEANUP)
-- ========================================================

-- Employees must belong to a valid branch
ALTER TABLE employees
ADD CONSTRAINT fk_employees_branch
FOREIGN KEY (branch_id) REFERENCES branch(branch_id);

-- Branch managers must exist in employees
ALTER TABLE branch
ADD CONSTRAINT fk_branch_manager
FOREIGN KEY (manager_id) REFERENCES employees(emp_id);

-- Book issue: member must exist
ALTER TABLE issued_status
ADD CONSTRAINT fk_issued_member
FOREIGN KEY (issued_member_id) REFERENCES members(member_id);

-- Book issue: book must exist
ALTER TABLE issued_status
ADD CONSTRAINT fk_issued_book
FOREIGN KEY (issued_book_isbn) REFERENCES books(isbn);

-- Book issue: issuing employee must exist
ALTER TABLE issued_status
ADD CONSTRAINT fk_issued_emp
FOREIGN KEY (issued_emp_id) REFERENCES employees(emp_id);

-- Book return: must refer to a valid issue
ALTER TABLE return_status
ADD CONSTRAINT fk_return_issued
FOREIGN KEY (issued_id) REFERENCES issued_status(issued_id);

-- Book return: must refer to a valid book
ALTER TABLE return_status
ADD CONSTRAINT fk_return_book
FOREIGN KEY (return_book_isbn) REFERENCES books(isbn);


-- ========================================================
-- 🎯 TASK 1: INSERT DATA (C in CRUD)
-- 📁 Goal: Add records to issued_status and return_status
-- ========================================================

INSERT INTO issued_status (
    issued_id, 
    issued_member_id, 
    issued_book_name, 
    issued_date, 
    issued_book_isbn, 
    issued_emp_id
)
VALUES
    ('IS101', 'C101', 'The Catcher in the Rye', DATE '2024-03-01', '978-0-553-29698-2', 'E101'),
    ('IS102', 'C102', 'Animal Farm', DATE '2024-03-03', '978-0-330-25864-8', 'E101'),
    ('IS103', 'C103', 'One Hundred Years of Solitude', DATE '2024-03-05', '978-0-14-118776-1', 'E102'),
    ('IS104', 'C104', 'The Great Gatsby', DATE '2024-03-07', '978-0-525-47535-5', 'E103'),
    ('IS105', 'C105', 'Jane Eyre', DATE '2024-03-09', '978-0-141-44171-6', 'E103');

INSERT INTO return_status (
    return_id,
    issued_id,
    return_book_name,
    return_date,
    return_book_isbn
)
VALUES
    ('RS101', 'IS101', 'The Catcher in the Rye', DATE '2024-06-15', '978-0-553-29698-2'),
    ('RS102', 'IS102', 'Animal Farm', DATE '2024-06-18', '978-0-330-25864-8'),
    ('RS103', 'IS103', 'One Hundred Years of Solitude', DATE '2024-06-20', '978-0-14-118776-1'),
    ('RS119', 'IS104', 'The Alchemist', DATE '2023-06-07', '978-0-307-37840-1'),
    ('RS120', 'IS105', 'Pride and Prejudice', DATE '2023-06-07', '978-0-14-143951-8');


-- ========================================================
-- 🎯 TASK 2: UPDATE MEMBER IDs FROM 'C' TO 'M' (U in CRUD)
-- 📁 Goal: Standardize ID format
-- ========================================================

-- Step 1: Drop foreign key temporarily
ALTER TABLE issued_status
DROP CONSTRAINT fk_issued_member;

-- Step 2: Update member IDs in both tables
UPDATE members
SET member_id = REPLACE(member_id, 'C', 'M');

UPDATE issued_status
SET issued_member_id = REPLACE(issued_member_id, 'C', 'M');

-- Step 3: Re-add the foreign key constraint
ALTER TABLE issued_status
ADD CONSTRAINT fk_issued_member
FOREIGN KEY (issued_member_id) REFERENCES members(member_id);

-- Step 4: Optional — confirm updates
SELECT * FROM issued_status WHERE issued_id BETWEEN 'IS101' AND 'IS105';
SELECT * FROM return_status WHERE return_id BETWEEN 'RS101' AND 'RS103';
SELECT * FROM members ORDER BY member_id;
SELECT * FROM issued_status ORDER BY issued_member_id;
SELECT * FROM return_status ORDER BY issued_id;





