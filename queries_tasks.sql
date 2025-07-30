-- =======================================================================================================
-- 📌 BASIC CRUD QUERIES FOR EACH TABLE
-- =======================================================================================================

-- ✅ 1. INSERT INTO branch
INSERT INTO branch VALUES ('B006', 'E101', 'Downtown Street 45', '+254712345678');
-- ✅ 2. DELETE a branch by branch_id
DELETE FROM branch WHERE branch_id = 'B006';

-- ✅ 3. SELECT FROM members
SELECT * FROM members;

-- ✅ 4.📌 Objective: Promote employee E111 to Manager and set them as the manager of Branch B001
-- Update branch table to assign new manager
UPDATE branch
SET manager_id = 'E111'
WHERE branch_id = 'B001';

-- Promote employee by updating position, salary, and branch assignment
UPDATE employees
SET
    position = 'Manager',
    salary = salary + 5000,
    branch_id = 'B001'
WHERE emp_id = 'E111';


-- ============================================================
-- 📌 JOIN QUERIES (COMBINED INFO FROM MULTIPLE TABLES)
-- ============================================================

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
JOIN employees e ON e.emp_id = i.issued_emp_id      -- Get employee details
WHERE e.position IN ('Librarian', 'Assistant');


-- 🔄 6. Retrieve a list of all returned books, including their titles, ISBNs, dates of issue, and corresponding return dates
SELECT 
	r.return_id,
	b.book_title As returned_book,
	b.isbn As isbn,
	i.issued_date As date_issued,
	r.return_date As date_returned
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

-- ============================================================
-- 📌 AGGREGATIONS & ANALYSIS QUERIES
-- ============================================================

-- 📊 8 & 9. Retrieve the total number of issued and returned books
SELECT 
    (SELECT COUNT(*) FROM issued_status) AS total_issued_books,
    (SELECT COUNT(*) FROM return_status) AS total_returned_books;


-- 📊 10. Count how many books are available vs issued
SELECT 
    status,
    COUNT(*) AS count
FROM books
GROUP BY status;

-- 📊 11. List top employees by number of books issued
SELECT 
    e.emp_name,
    COUNT(isd.issued_id) AS books_issued
FROM employees e
JOIN issued_status isd ON e.emp_id = isd.issued_emp_id
GROUP BY e.emp_name
ORDER BY books_issued DESC;

-- 📊 12. Find the member who borrowed the most books
SELECT
    m.member_name,
    COUNT(isd.issued_id) AS total_borrowed
FROM members m
JOIN issued_status isd ON m.member_id = isd.issued_member_id
GROUP BY m.member_name
ORDER BY total_borrowed DESC
LIMIT 1;

-- ============================================================
-- 📌 ADVANCED FILTERS
-- ============================================================

-- 🔍 13. Identify Overdue Returns: List all books that were returned after 7 days from issue date
SELECT
    rs.return_id,
    rs.return_book_name,
    rs.return_date,
    isd.issued_date,
    (rs.return_date - isd.issued_date) AS days_borrowed
FROM return_status rs
JOIN issued_status isd ON rs.issued_id = isd.issued_id
WHERE (rs.return_date - isd.issued_date) > 7;

-- 🔍 14. Show books that have never been issued
SELECT *
FROM books
WHERE isbn NOT IN (SELECT issued_book_isbn FROM issued_status);

-- 🔍 15. List employees who have not issued any book
SELECT *
FROM employees
WHERE emp_id NOT IN (SELECT issued_emp_id FROM issued_status);

-- 🔍 16. List members who have not returned all their books
SELECT DISTINCT m.member_id, m.member_name
FROM members m
JOIN issued_status isd ON m.member_id = isd.issued_member_id
WHERE isd.issued_id NOT IN (SELECT issued_id FROM return_status);

-- ============================================================
-- 📌 MAINTENANCE / ADMIN
-- ============================================================

-- ⚙️ 17. Change status of returned books to 'available'
UPDATE books
SET status = CASE
    WHEN isbn IN (SELECT return_book_isbn FROM return_status) THEN 'available'
    ELSE 'unavailble'
END;
SELECT * FROM books;

-- ⚙️ 18. Get details of overdue returns (more than 14 days)
SELECT
    rs.return_id,
    rs.return_book_name,
    isd.issued_date,
    rs.return_date,
    (rs.return_date - isd.issued_date) AS days_late
FROM return_status rs
JOIN issued_status isd ON rs.issued_id = isd.issued_id
WHERE (rs.return_date - isd.issued_date) > 14;

-- ⚙️ 19. List all branches and the number of employees at each
SELECT 
	b.branch_id,
	b.branch_address,
	COUNT(e.emp_id) AS total_employees
FROM branch b
LEFT JOIN employees e ON b.branch_id = e.branch_id
GROUP BY b.branch_id;