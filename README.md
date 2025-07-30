<h1>📚 Library Management System — SQL</h1>

![LMS](images/LMS.jpg)

Welcome to the **Library Management System**, a SQL-based project designed to simulate the operations of a small to mid-sized library using PostgreSQL. This project showcases not only relational database modeling but also how structured SQL queries can be used to manage, maintain, and extract business insights from library operations.

---
## 📑 Table of Contents

1. [📚 Project Overview](#-library-management-system--sql-portfolio-project)
2. [🚀 Project Summary](#-project-summary)
3. [🗃️ Data & Entity Relationships](#️-data--entity-relationships)
4. [🏗️ 1. Database & Schema Setup](#️-1-database--schema-setup)
   - [🧹 Data Cleaning: Aligning Return Records](#-data-cleaning-aligning-return-records-with-issued-data)
   - [🔗 Enforcing Data Integrity](#-enforcing-data-integrity-applying-foreign-key-constraints)
5. [🛠️ 2. Basic CRUD Operations](#️-2-basic-crud-operations-across-core-tables)
6. [🔗 3. Join Queries Across Multiple Tables](#-3-join-queries-across-multiple-tables)
7. [📊 4. Analytics & Business Reporting](#-4-analytics--business-reporting)
8. [🔍 5. Advanced Filtering & Integrity Checks](#-5-advanced-filtering--integrity-checks)
9. [⚙️ 6. Maintenance & Admin Operations](#️-6-maintenance--admin-operations)



## 🚀 Project Summary

- **Goal:** Simulate a real-world library scenario using relational SQL modeling.
- **Tools:** PostgreSQL, Excel (for data import), pgAdmin, ERD design (Connections.png).
- **Scope:** Schema design, data population, constraints enforcement, and detailed querying tasks covering CRUD, joins, aggregations, analytics, and administration.

This system handles **branches**, **employees**, **members**, **books**, **issued and returned books**, along with integrity enforcement via foreign keys and data validation logic.

---

## 🗃️ Data & Entity Relationships

The ERD (`Connections.png`) defines relationships between:
![Table_Connections](Connections.png)

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
```

### 🧹 Data Cleaning: Aligning Return Records with Issued Data

Before enforcing foreign key constraints and running queries, it's essential to clean the data to ensure consistency across tables — particularly between `issued_status` and `return_status`.

In real-world scenarios, data entry errors may lead to discrepancies where the book name or ISBN in the return records does not match the original issued record. This step ensures that:

- The `return_status` table reflects accurate book names and ISBNs as recorded during issuance.
- All return entries are backed by a valid `issued_id` from the `issued_status` table.
- Any records in `return_status` with missing or invalid `issued_id` values are removed to maintain referential integrity.

This cleanup is crucial because it prevents violations when we apply foreign key constraints and ensures our analytical queries operate on reliable data.

```sql
-- Align return book names and ISBNs with issued book records
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

-- Remove return records with null or unmatched issued IDs
DELETE FROM return_status
WHERE issued_id IS NULL
   OR issued_id NOT IN (SELECT issued_id FROM issued_status);
```


### 🔗 Enforcing Data Integrity: Applying Foreign Key Constraints

After cleaning and aligning the data across related tables, the next crucial step is to enforce **referential integrity** through foreign key constraints. This ensures that the relationships between tables remain valid and consistent over time — preventing invalid inserts, updates, or deletions that could break the logical structure of the database.

Foreign keys help maintain real-world logic, such as:
- An employee must be assigned to an existing branch.
- A branch must have a valid manager (who is an employee).
- Issued and returned books must be tied to actual members, books, and employees.
- Returned books must refer to a valid issuance record.

By applying these constraints, we protect the database from data anomalies and promote long-term stability and reliability.

The following SQL statements add foreign key constraints across the relevant tables:

```sql
-- Ensure each employee is linked to an existing branch
ALTER TABLE employees
ADD CONSTRAINT fk_employees_branch
FOREIGN KEY (branch_id) REFERENCES branch(branch_id);

-- Ensure each branch is managed by a valid employee
ALTER TABLE branch
ADD CONSTRAINT fk_branch_manager
FOREIGN KEY (manager_id) REFERENCES employees(emp_id);

-- Ensure books are issued to valid members
ALTER TABLE issued_status
ADD CONSTRAINT fk_issued_member
FOREIGN KEY (issued_member_id) REFERENCES members(member_id);

-- Ensure only existing books can be issued
ALTER TABLE issued_status
ADD CONSTRAINT fk_issued_book
FOREIGN KEY (issued_book_isbn) REFERENCES books(isbn);

-- Ensure only valid employees can issue books
ALTER TABLE issued_status
ADD CONSTRAINT fk_issued_emp
FOREIGN KEY (issued_emp_id) REFERENCES employees(emp_id);

-- Ensure returns refer to valid issuance records
ALTER TABLE return_status
ADD CONSTRAINT fk_return_issued
FOREIGN KEY (issued_id) REFERENCES issued_status(issued_id);

-- Ensure returned books exist in the library's catalog
ALTER TABLE return_status
ADD CONSTRAINT fk_return_book
FOREIGN KEY (return_book_isbn) REFERENCES books(isbn);
```

---

### 🛠️ 2. Basic CRUD Operations Across Core Tables

In any relational database system, **CRUD** operations—**Create, Read, Update, Delete**—form the foundation of how users interact with data. This section demonstrates how to perform these essential operations on key tables within the library database, namely: `branch`, `members`, and `employees`.

The examples below simulate **real-world administrative tasks**, such as:
- Adding or removing a branch from the system.
- Viewing member records.
- Promoting an employee to a managerial role and assigning them to a branch.

These operations are not only routine but also critical for the **ongoing maintenance** of the library system. Each query has been written with clarity and purpose to reflect a specific business action that could occur in a real organization.

```sql
-- ✅ 1. Add a new branch to the library network
INSERT INTO branch VALUES ('B006', 'E101', 'Downtown Street 45', '+254712345678');

-- ✅ 2. Remove a branch by its unique branch ID
DELETE FROM branch WHERE branch_id = 'B006';

-- ✅ 3. View all registered library members
SELECT * FROM members;

-- ✅ 4. 📌 Objective: Promote employee E111 to Manager and assign them to manage Branch B001

-- Step 1: Assign E111 as the new manager of Branch B001
UPDATE branch
SET manager_id = 'E111'
WHERE branch_id = 'B001';

-- Step 2: Reflect the employee's promotion and reassignment
UPDATE employees
SET
    position = 'Manager',
    salary = salary + 5000,
    branch_id = 'B001'
WHERE emp_id = 'E111';
```

---

## 🔗 3. Join Queries Across Multiple Tables

In this section, we perform SQL JOIN operations to retrieve information that spans across multiple related tables. These queries demonstrate how data from the `books`, `members`, `employees`, `branch`, `issued_status`, and `return_status` tables can be combined to give a more holistic view of the library system operations. We focus on tracking book issuance and return activity, as well as understanding employee-branch relationships.

1. **Issued Book Details with Member and Employee Info**  
   This query retrieves all issued books, the members who borrowed them, and the employees who issued them. It uses `JOIN` to connect `issued_status` with `members`, `books`, and `employees`, while filtering only employees in roles relevant to issuing books.

2. **Returned Book History**  
   This query displays all returned books, including their titles, ISBNs, the date they were issued, and the return dates. It uses data from `return_status`, `issued_status`, and `books` to provide a complete view of the return transaction.

3. **Employees and Their Assigned Branches**  
   This query lists all employees along with their assigned branch's address. It joins the `employees` table with the `branch` table using `branch_id`.

```sql
-- 🔄 5. Display all issued books along with the names of the members who borrowed them and the employees who issued them
SELECT
    i.issued_id,                          -- ID of the book issue record
    m.member_name AS issued_to,          -- Member who received the book
    b.book_title,                        -- Title of the book issued
    e.emp_name AS who_issued,            -- Employee who issued the book
    e.position AS as_who,                -- Employee's position (e.g., Librarian)
    i.issued_date                        -- Date the book was issued
FROM issued_status i
JOIN books b ON i.issued_book_isbn = b.isbn          -- Get book details
JOIN members m ON m.member_id = i.issued_member_id   -- Get member details
JOIN employees e ON e.emp_id = i.issued_emp_id       -- Get employee details
WHERE e.position IN ('Librarian', 'Assistant');

-- 🔄 6. Retrieve a list of all returned books, including their titles, ISBNs, dates of issue, and corresponding return dates
SELECT 
    r.return_id,
    b.book_title AS returned_book,
    b.isbn AS isbn,
    i.issued_date AS date_issued,
    r.return_date AS date_returned
FROM return_status r
JOIN issued_status i ON i.issued_id = r.issued_id
JOIN books b ON r.return_book_isbn = b.isbn;

-- 🔄 7. List all employees along with their branch info
SELECT
    e.emp_id,
    e.emp_name,
    e.position,
    b.branch_address
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



