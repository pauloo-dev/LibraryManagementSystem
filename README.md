# 📚 Library Management System — SQL Portfolio Project

Welcome to the **Library Management System**, a SQL-based project designed to simulate the operations of a small to mid-sized library using PostgreSQL. This project showcases not only relational database modeling but also how structured SQL queries can be used to manage, maintain, and extract business insights from library operations.

---

## 🚀 Project Summary

- **Goal:** Simulate a real-world library scenario using relational SQL modeling.
- **Tools:** PostgreSQL, Excel (for data import), pgAdmin, ERD design (Connections.png).
- **Scope:** Schema design, data population, constraints enforcement, and detailed querying tasks covering CRUD, joins, aggregations, analytics, and administration.

This system handles **branches**, **employees**, **members**, **books**, **issued and returned books**, along with integrity enforcement via foreign keys and data validation logic.

---

## 🗃️ Data & Entity Relationships

The ERD (`Connections.png`) defines relationships between:

- **Branches** and **Employees** (with managers),
- **Books** and their issue/return statuses,
- **Members** who borrow and return books,
- Foreign key integrity across all transactional tables.

---

## 🏗️ 1. Database & Schema Setup

This section creates the core database and tables, enforces referential constraints, and prepares the foundation of the system.

**Key Actions:**

- Recreate the full database (`Library_Management_System`) from scratch.
- Drop all existing tables in dependency-safe order.
- Create six primary tables: `branch`, `members`, `employees`, `books`, `issued_status`, `return_status`.
- Import Excel data into corresponding tables (handled via pgAdmin's GUI).
- Clean and validate the `return_status` table before foreign key constraints.
- Apply all foreign key constraints after cleaning to avoid referential errors.

```sql
-- Create database and schema
DROP DATABASE IF EXISTS Library_Management_System;
CREATE DATABASE Library_Management_System;

-- Drop tables if they exist (in proper dependency order)
DROP TABLE IF EXISTS return_status;
DROP TABLE IF EXISTS issued_status;
DROP TABLE IF EXISTS books;
DROP TABLE IF EXISTS branch CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS members;

-- Create each table (6 total)
CREATE TABLE branch (
    branch_id VARCHAR(10) PRIMARY KEY,
    manager_id VARCHAR(10),
    branch_address VARCHAR(50),
    contact_no VARCHAR(15)
);

CREATE TABLE members (
    member_id VARCHAR(10) PRIMARY KEY,
    member_name VARCHAR(50),
    member_address VARCHAR(50),
    reg_date DATE
);

CREATE TABLE employees (
    emp_id VARCHAR(10) PRIMARY KEY,
    emp_name VARCHAR(50),
    position VARCHAR(20),
    salary FLOAT,
    branch_id VARCHAR(10)
);

CREATE TABLE books (
    isbn VARCHAR(25) PRIMARY KEY,
    book_title VARCHAR(75),
    category VARCHAR(20),
    rental_price FLOAT,
    status VARCHAR(10),
    author VARCHAR(50),
    publisher VARCHAR(50)
);

CREATE TABLE issued_status (
    issued_id VARCHAR(10) PRIMARY KEY,
    issued_member_id VARCHAR(10),
    issued_book_name VARCHAR(75),
    issued_date DATE,
    issued_book_isbn VARCHAR(25),
    issued_emp_id VARCHAR(10)
);

CREATE TABLE return_status (
    return_id VARCHAR(10) PRIMARY KEY,
    issued_id VARCHAR(10),
    return_book_name VARCHAR(75),
    return_date DATE,
    return_book_isbn VARCHAR(25)
);

-- Data cleanup: align return data with issued data
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

DELETE FROM return_status
WHERE issued_id IS NULL
   OR issued_id NOT IN (SELECT issued_id FROM issued_status);

-- Apply foreign key constraints
ALTER TABLE employees
ADD CONSTRAINT fk_employees_branch
FOREIGN KEY (branch_id) REFERENCES branch(branch_id);

ALTER TABLE branch
ADD CONSTRAINT fk_branch_manager
FOREIGN KEY (manager_id) REFERENCES employees(emp_id);

ALTER TABLE issued_status
ADD CONSTRAINT fk_issued_member
FOREIGN KEY (issued_member_id) REFERENCES members(member_id);

ALTER TABLE issued_status
ADD CONSTRAINT fk_issued_book
FOREIGN KEY (issued_book_isbn) REFERENCES books(isbn);

ALTER TABLE issued_status
ADD CONSTRAINT fk_issued_emp
FOREIGN KEY (issued_emp_id) REFERENCES employees(emp_id);

ALTER TABLE return_status
ADD CONSTRAINT fk_return_issued
FOREIGN KEY (issued_id) REFERENCES issued_status(issued_id);

ALTER TABLE return_status
ADD CONSTRAINT fk_return_book
FOREIGN KEY (return_book_isbn) REFERENCES books(isbn);
```

---

## ✍️ 2. Data Entry & Updates (CRUD)

This section demonstrates CRUD capabilities through inserts, updates, and deletes. It also standardizes member IDs and shows admin operations.

**Key Highlights:**

- Insert book issues and returns.
- Standardize `member_id` format from "C" to "M".
- Promote employee to manager and reassign branches.
- Insert and delete test branches.

```sql
-- Insert issued and returned books
INSERT INTO issued_status (...) VALUES (...);
INSERT INTO return_status (...) VALUES (...);

-- Update member IDs from C to M (requires dropping FK temporarily)
ALTER TABLE issued_status DROP CONSTRAINT fk_issued_member;
UPDATE members SET member_id = REPLACE(member_id, 'C', 'M');
UPDATE issued_status SET issued_member_id = REPLACE(issued_member_id, 'C', 'M');
ALTER TABLE issued_status ADD CONSTRAINT fk_issued_member
FOREIGN KEY (issued_member_id) REFERENCES members(member_id);

-- CRUD samples
INSERT INTO branch VALUES ('B006', 'E101', 'Downtown Street 45', '+254712345678');
DELETE FROM branch WHERE branch_id = 'B006';

-- Promote employee
UPDATE branch SET manager_id = 'E111' WHERE branch_id = 'B001';
UPDATE employees
SET position = 'Manager', salary = salary + 5000, branch_id = 'B001'
WHERE emp_id = 'E111';
```

---

## 🔗 3. Join Queries: Insights Across Tables

To get actionable insights, multiple join queries were used across the six tables.

**Business Scenarios Covered:**

- Track who issued which book to which member.
- Track all returns and compare with issue data.
- Map employee to their branch locations.

```sql
-- Issued books with member and employee info
SELECT ... FROM issued_status
JOIN books ON ...
JOIN members ON ...
JOIN employees ON ...
WHERE employees.position IN ('Librarian', 'Assistant');

-- Returned books with issue and return dates
SELECT ... FROM return_status
JOIN issued_status ON ...
JOIN books ON ...;

-- Employee to branch mapping
SELECT e.emp_id, e.emp_name, e.position, b.branch_address
FROM employees e
JOIN branch b ON e.branch_id = b.branch_id;
```

---

## 📊 4. Analytics & Business Reporting

Analytical queries help answer business-level questions, such as performance metrics, inventory stats, and top contributors.

**Insights Extracted:**

- Total issued vs returned books.
- Book availability status breakdown.
- Most active employees and members.

```sql
-- Count issued and returned books
SELECT 
    (SELECT COUNT(*) FROM issued_status) AS total_issued_books,
    (SELECT COUNT(*) FROM return_status) AS total_returned_books;

-- Availability by status
SELECT status, COUNT(*) FROM books GROUP BY status;

-- Top issuer employees
SELECT emp_name, COUNT(*) AS books_issued
FROM employees JOIN issued_status ON ...
GROUP BY emp_name
ORDER BY books_issued DESC;

-- Most frequent member
SELECT member_name, COUNT(*) AS total_borrowed
FROM members JOIN issued_status ON ...
GROUP BY member_name
ORDER BY total_borrowed DESC
LIMIT 1;
```

---

## 🔍 5. Advanced Filtering & Integrity Checks

Complex filters were applied to validate data integrity and trace unusual behavior.

**Use Cases:**

- Detect overdue returns.
- List books never issued.
- Identify idle employees or incomplete returns.

```sql
-- Overdue returns (> 7 days)
SELECT ... FROM return_status
JOIN issued_status ON ...
WHERE return_date - issued_date > 7;

-- Books never issued
SELECT * FROM books
WHERE isbn NOT IN (SELECT issued_book_isbn FROM issued_status);

-- Employees with no activity
SELECT * FROM employees
WHERE emp_id NOT IN (SELECT issued_emp_id FROM issued_status);

-- Members with unreturned books
SELECT DISTINCT m.member_id, m.member_name
FROM members m
JOIN issued_status i ON ...
WHERE i.issued_id NOT IN (SELECT issued_id FROM return_status);
```

---

## ⚙️ 6. Maintenance & Admin Operations

Simulate day-to-day operational updates and reporting requirements.

**Examples:**

- Set returned books to available.
- Identify extreme overdue returns.
- Summarize employees per branch.

```sql
-- Mark returned books as available
UPDATE books
SET status = CASE
    WHEN isbn IN (SELECT return_book_isbn FROM return_status) THEN 'available'
    ELSE 'unavailable'
END;

-- Overdue > 14 days
SELECT ... FROM return_status
JOIN issued_status ON ...
WHERE return_date - issued_date > 14;

-- Employees per branch
SELECT branch_id, branch_address, COUNT(*) AS total_employees
FROM branch
LEFT JOIN employees ON ...
GROUP BY branch_id;
```

---



