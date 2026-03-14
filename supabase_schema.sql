-- ============================================================
-- CampusFlow AI — Supabase SQL Schema (Idempotent)
-- Safe to run multiple times — uses IF NOT EXISTS / DO NOTHING
-- Run in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- TABLE 1: students
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS students (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_uid     UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  student_id   TEXT UNIQUE NOT NULL,
  name         TEXT NOT NULL,
  email        TEXT,
  role         TEXT NOT NULL DEFAULT 'student',   -- student / staff / hod / tutor / officer / admin
  department   TEXT NOT NULL DEFAULT 'General',
  year         INTEGER NOT NULL DEFAULT 1,
  hostel       BOOLEAN NOT NULL DEFAULT FALSE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE students ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to make this idempotent
DO $$ BEGIN
  DROP POLICY IF EXISTS "Students can view own profile" ON students;
  DROP POLICY IF EXISTS "Students can update own profile" ON students;
  DROP POLICY IF EXISTS "Authenticated users can insert own profile" ON students;
  DROP POLICY IF EXISTS "Allow all authenticated reads" ON students;
END $$;

-- All authenticated users can read student profiles (needed for staff to view student data)
CREATE POLICY "Allow all authenticated reads"
  ON students FOR SELECT
  USING (true);

CREATE POLICY "Students can update own profile"
  ON students FOR UPDATE
  USING (auth.uid() = auth_uid);

CREATE POLICY "Authenticated users can insert own profile"
  ON students FOR INSERT
  WITH CHECK (auth.uid() = auth_uid);

-- ────────────────────────────────────────────────────────────
-- TABLE 2: clearance_requests
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS clearance_requests (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id       TEXT NOT NULL REFERENCES students(student_id),
  clearance_type   TEXT NOT NULL,
  library_status   TEXT NOT NULL DEFAULT 'pending',
  hostel_status    TEXT NOT NULL DEFAULT 'pending',
  accounts_status  TEXT NOT NULL DEFAULT 'pending',
  lab_status       TEXT NOT NULL DEFAULT 'pending',
  mess_status      TEXT NOT NULL DEFAULT 'pending',
  tutor_status     TEXT NOT NULL DEFAULT 'pending',
  overall_status   TEXT NOT NULL DEFAULT 'pending',
  remarks          TEXT,
  estimated_completion TIMESTAMPTZ,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE clearance_requests ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  DROP POLICY IF EXISTS "Students can view own clearance requests" ON clearance_requests;
  DROP POLICY IF EXISTS "Students can create own clearance requests" ON clearance_requests;
  DROP POLICY IF EXISTS "Authenticated can view all clearances" ON clearance_requests;
  DROP POLICY IF EXISTS "Authenticated can insert clearances" ON clearance_requests;
  DROP POLICY IF EXISTS "Authenticated can update clearances" ON clearance_requests;
END $$;

-- All authenticated users can read (staff need to view all requests)
CREATE POLICY "Authenticated can view all clearances"
  ON clearance_requests FOR SELECT
  USING (true);

-- Students can create clearance requests
CREATE POLICY "Authenticated can insert clearances"
  ON clearance_requests FOR INSERT
  WITH CHECK (true);

-- Staff can update clearance statuses (approve/reject)
CREATE POLICY "Authenticated can update clearances"
  ON clearance_requests FOR UPDATE
  USING (true);

-- ────────────────────────────────────────────────────────────
-- TABLE 3: issues
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS issues (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id   TEXT NOT NULL REFERENCES students(student_id),
  title        TEXT NOT NULL,
  category     TEXT NOT NULL DEFAULT 'general',
  description  TEXT NOT NULL,
  location     TEXT,
  image_url    TEXT,
  status       TEXT NOT NULL DEFAULT 'logged',
  assigned_to  TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE issues ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  DROP POLICY IF EXISTS "Students can view own issues" ON issues;
  DROP POLICY IF EXISTS "Students can create issues" ON issues;
  DROP POLICY IF EXISTS "Authenticated can view all issues" ON issues;
  DROP POLICY IF EXISTS "Authenticated can insert issues" ON issues;
  DROP POLICY IF EXISTS "Authenticated can update issues" ON issues;
END $$;

CREATE POLICY "Authenticated can view all issues"
  ON issues FOR SELECT
  USING (true);

CREATE POLICY "Authenticated can insert issues"
  ON issues FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Authenticated can update issues"
  ON issues FOR UPDATE
  USING (true);

-- ────────────────────────────────────────────────────────────
-- TABLE 4: opportunities
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS opportunities (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title        TEXT NOT NULL,
  type         TEXT NOT NULL DEFAULT 'general',
  description  TEXT NOT NULL,
  eligibility  TEXT,
  deadline     DATE,
  apply_url    TEXT,
  posted_by    TEXT,
  department   TEXT,
  match_score  INTEGER NOT NULL DEFAULT 50,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Scholarship Officer extra columns
ALTER TABLE opportunities
  ADD COLUMN IF NOT EXISTS amount           NUMERIC,
  ADD COLUMN IF NOT EXISTS requires_income_cert BOOLEAN DEFAULT FALSE;

ALTER TABLE opportunities ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  DROP POLICY IF EXISTS "Authenticated users can view opportunities" ON opportunities;
  DROP POLICY IF EXISTS "Authenticated can view opportunities" ON opportunities;
  DROP POLICY IF EXISTS "Authenticated can insert opportunities" ON opportunities;
  DROP POLICY IF EXISTS "Authenticated can update opportunities" ON opportunities;
END $$;

CREATE POLICY "Authenticated can view opportunities"
  ON opportunities FOR SELECT
  USING (true);

CREATE POLICY "Authenticated can insert opportunities"
  ON opportunities FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Authenticated can update opportunities"
  ON opportunities FOR UPDATE
  USING (true);

-- ────────────────────────────────────────────────────────────
-- TABLE 5: documents
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS documents (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id   TEXT NOT NULL REFERENCES students(student_id),
  document_type TEXT NOT NULL,
  file_url     TEXT NOT NULL,
  verified     BOOLEAN NOT NULL DEFAULT FALSE,
  issued_on    TIMESTAMPTZ,
  expires_on   TIMESTAMPTZ,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  DROP POLICY IF EXISTS "Students can view own documents" ON documents;
  DROP POLICY IF EXISTS "Students can upload documents" ON documents;
  DROP POLICY IF EXISTS "Authenticated can view documents" ON documents;
  DROP POLICY IF EXISTS "Authenticated can insert documents" ON documents;
END $$;

CREATE POLICY "Authenticated can view documents"
  ON documents FOR SELECT
  USING (true);

CREATE POLICY "Authenticated can insert documents"
  ON documents FOR INSERT
  WITH CHECK (true);

-- ────────────────────────────────────────────────────────────
-- TABLE 6: campus_notifications
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS campus_notifications (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id   TEXT NOT NULL REFERENCES students(student_id),
  type         TEXT NOT NULL DEFAULT 'system',
  title        TEXT NOT NULL,
  message      TEXT NOT NULL,
  read         BOOLEAN NOT NULL DEFAULT FALSE,
  action_url   TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE campus_notifications ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  DROP POLICY IF EXISTS "Students can view own notifications" ON campus_notifications;
  DROP POLICY IF EXISTS "Students can update own notifications" ON campus_notifications;
  DROP POLICY IF EXISTS "Authenticated users can insert notifications" ON campus_notifications;
  DROP POLICY IF EXISTS "Authenticated can view notifications" ON campus_notifications;
  DROP POLICY IF EXISTS "Authenticated can insert notifications" ON campus_notifications;
  DROP POLICY IF EXISTS "Authenticated can update notifications" ON campus_notifications;
END $$;

CREATE POLICY "Authenticated can view notifications"
  ON campus_notifications FOR SELECT
  USING (true);

CREATE POLICY "Authenticated can insert notifications"
  ON campus_notifications FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Authenticated can update notifications"
  ON campus_notifications FOR UPDATE
  USING (true);

-- ────────────────────────────────────────────────────────────
-- EXPANDED STUDENT PROFILE COLUMNS
-- ────────────────────────────────────────────────────────────

-- Dues
ALTER TABLE students
  ADD COLUMN IF NOT EXISTS library_fine    NUMERIC NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS hostel_dues     NUMERIC NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS lab_fees        NUMERIC NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS tuition_balance NUMERIC NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS mess_dues       NUMERIC NOT NULL DEFAULT 0;

-- Basic Identity
ALTER TABLE students
  ADD COLUMN IF NOT EXISTS admission_number  TEXT,
  ADD COLUMN IF NOT EXISTS gender            TEXT,
  ADD COLUMN IF NOT EXISTS date_of_birth     DATE,
  ADD COLUMN IF NOT EXISTS blood_group       TEXT,
  ADD COLUMN IF NOT EXISTS profile_image_url TEXT;

-- Academic Information
ALTER TABLE students
  ADD COLUMN IF NOT EXISTS course       TEXT,
  ADD COLUMN IF NOT EXISTS branch       TEXT,
  ADD COLUMN IF NOT EXISTS semester     INTEGER,
  ADD COLUMN IF NOT EXISTS batch_year   INTEGER,
  ADD COLUMN IF NOT EXISTS roll_number  TEXT,
  ADD COLUMN IF NOT EXISTS tutor_name   TEXT;

-- Contact Information
ALTER TABLE students
  ADD COLUMN IF NOT EXISTS phone        TEXT,
  ADD COLUMN IF NOT EXISTS alt_phone    TEXT,
  ADD COLUMN IF NOT EXISTS address      TEXT,
  ADD COLUMN IF NOT EXISTS city         TEXT,
  ADD COLUMN IF NOT EXISTS state        TEXT,
  ADD COLUMN IF NOT EXISTS postal_code  TEXT;

-- Hostel Details
ALTER TABLE students
  ADD COLUMN IF NOT EXISTS hostel_name  TEXT,
  ADD COLUMN IF NOT EXISTS room_number  TEXT,
  ADD COLUMN IF NOT EXISTS block_floor  TEXT,
  ADD COLUMN IF NOT EXISTS warden_name  TEXT;

-- Parent / Guardian
ALTER TABLE students
  ADD COLUMN IF NOT EXISTS father_name    TEXT,
  ADD COLUMN IF NOT EXISTS mother_name    TEXT,
  ADD COLUMN IF NOT EXISTS parent_phone   TEXT,
  ADD COLUMN IF NOT EXISTS guardian_name  TEXT,
  ADD COLUMN IF NOT EXISTS guardian_phone TEXT;

-- Government / Identity
ALTER TABLE students
  ADD COLUMN IF NOT EXISTS aadhaar_number  TEXT,
  ADD COLUMN IF NOT EXISTS national_id     TEXT,
  ADD COLUMN IF NOT EXISTS passport_number TEXT;

-- Social Category
ALTER TABLE students
  ADD COLUMN IF NOT EXISTS religion        TEXT,
  ADD COLUMN IF NOT EXISTS caste           TEXT,
  ADD COLUMN IF NOT EXISTS category        TEXT DEFAULT 'General',
  ADD COLUMN IF NOT EXISTS minority_status BOOLEAN DEFAULT FALSE;

-- Income certificate
ALTER TABLE students
  ADD COLUMN IF NOT EXISTS income_certificate_available BOOLEAN DEFAULT FALSE;

-- System flag
ALTER TABLE students
  ADD COLUMN IF NOT EXISTS profile_completed BOOLEAN NOT NULL DEFAULT FALSE;

-- ============================================================
-- SEED DATA — matches mock data, uses UPSERT to update existing rows
-- ============================================================

-- Students with full profile data
INSERT INTO students (student_id, name, email, role, department, year, hostel,
  library_fine, hostel_dues, lab_fees, tuition_balance, mess_dues,
  course, semester, tutor_name, phone, category, income_certificate_available, profile_completed)
VALUES
  ('STU-001001', 'Arjun Sharma',  'arjun.sharma@campus.edu',  'student', 'Computer Science',              3, TRUE,
    150, 2400, 0, 0, 800,
    'BTech', 6, 'Dr. R. Krishnan (CSE Tutor)', '9876543210', 'OBC', TRUE, TRUE),
  ('STU-001002', 'Priya Nair',    'priya.nair@campus.edu',    'student', 'Electronics & Communication',   2, FALSE,
    0, 0, 500, 12000, 0,
    'BTech', 4, 'Dr. S. Patel (ECE Tutor)', NULL, 'SC', TRUE, TRUE),
  ('STU-001003', 'Ravi Kumar',    'ravi.kumar@campus.edu',    'student', 'MBA',                           1, TRUE,
    0, 0, 0, 0, 0,
    'MBA', 2, 'Dr. L. Reddy (MBA Tutor)', '9123456780', 'General', FALSE, TRUE)
ON CONFLICT (student_id) DO UPDATE SET
  name = EXCLUDED.name,
  email = EXCLUDED.email,
  department = EXCLUDED.department,
  year = EXCLUDED.year,
  hostel = EXCLUDED.hostel,
  library_fine = EXCLUDED.library_fine,
  hostel_dues = EXCLUDED.hostel_dues,
  lab_fees = EXCLUDED.lab_fees,
  tuition_balance = EXCLUDED.tuition_balance,
  mess_dues = EXCLUDED.mess_dues,
  course = EXCLUDED.course,
  semester = EXCLUDED.semester,
  tutor_name = EXCLUDED.tutor_name,
  phone = EXCLUDED.phone,
  category = EXCLUDED.category,
  income_certificate_available = EXCLUDED.income_certificate_available,
  profile_completed = EXCLUDED.profile_completed;

-- Opportunities
INSERT INTO opportunities (title, type, description, eligibility, deadline, apply_url, posted_by, match_score)
VALUES
  ('Merit-cum-Means Scholarship 2026', 'scholarship', 'Annual scholarship for students with excellent academic performance and financial need.', 'CGPA ≥ 8.5, Annual family income < ₹5,00,000', '2026-03-22', 'https://campus.edu/scholarships/mcm-2026', 'Scholarship Cell', 92),
  ('Google Summer of Code 2026',       'internship',  'Contribute to open-source projects with mentorship from Google engineers.',             'CS/IT students, Year 2+',                     '2026-04-05', 'https://summerofcode.withgoogle.com',       'Placement Cell',   88),
  ('TCS Recruitment Drive — On-Campus', 'placement',  'Campus placement drive for final year students. Package: ₹7-12 LPA.',                  'Final year, CGPA ≥ 7.0, No active backlogs',  '2026-03-28', NULL,                                       'Placement Cell',   75),
  ('National Hackathon — HackIndia 2026', 'competition', 'Build innovative solutions in 48 hours. Prizes worth ₹5,00,000.',                  'All departments, Team of 2-4',                 '2026-03-18', 'https://hackindia.xyz',                     'Student Council',  85),
  ('AI & Machine Learning Bootcamp',   'workshop',    '3-day intensive workshop on ML fundamentals with hands-on projects.',                  'CS/ECE students, Year 2+',                     '2026-03-25', NULL,                                       'CSE Department',   90)
ON CONFLICT DO NOTHING;

-- Notifications
INSERT INTO campus_notifications (student_id, type, title, message, read)
VALUES
  ('STU-001001', 'due_reminder',     'Hostel Dues Reminder',        'Your hostel dues of ₹2,400 are due by April 1st. Avoid late fees by paying before the deadline.', FALSE),
  ('STU-001001', 'clearance_update', 'Bonafide Certificate Update', 'Library and Accounts have approved your bonafide certificate request. Waiting for Hostel and Tutor.', FALSE),
  ('STU-001001', 'opportunity',      'New Scholarship Available',   'Merit-cum-Means Scholarship 2026 applications are now open. Deadline: March 22nd.', TRUE),
  ('STU-001001', 'alert',            'HackIndia 2026 — Deadline Soon!', 'Registration for HackIndia 2026 closes on March 18th. Don''t miss out!', FALSE),
  ('STU-001001', 'alert',            'Hackathon Alert',             'HackIndia 2026 registration closing soon!', FALSE),
  ('STU-001002', 'due_reminder',     'Tuition Balance Alert',       'Your tuition balance of ₹12,000 is due by March 31st.', FALSE),
  ('STU-001003', 'system',           'Welcome to CampusFlow!',      'Your account has been set up. Explore all the features available to you.', FALSE)
ON CONFLICT DO NOTHING;

-- Sample clearance request
INSERT INTO clearance_requests (student_id, clearance_type, library_status, hostel_status, accounts_status, lab_status, mess_status, tutor_status, overall_status, remarks)
VALUES
  ('STU-001001', 'bonafide_certificate', 'approved', 'pending', 'approved', 'approved', 'approved', 'pending', 'in_progress', 'Library and Accounts approved. Awaiting Hostel and Tutor verification.')
ON CONFLICT DO NOTHING;

-- Sample documents
INSERT INTO documents (student_id, document_type, file_url, verified, issued_on, expires_on)
VALUES
  ('STU-001001', 'id_card',       'https://campus.edu/docs/STU-001001/id_card.pdf',           TRUE, '2024-08-01', '2027-07-31'),
  ('STU-001001', 'fee_receipt',   'https://campus.edu/docs/STU-001001/fee_receipt_sem5.pdf',   TRUE, '2026-01-15', NULL),
  ('STU-001001', 'mark_sheet',    'https://campus.edu/docs/STU-001001/marksheet_sem4.pdf',     TRUE, '2025-12-20', NULL),
  ('STU-001002', 'id_card',       'https://campus.edu/docs/STU-001002/id_card.pdf',           TRUE, '2025-08-01', '2027-07-31'),
  ('STU-001002', 'enrollment_certificate', 'https://campus.edu/docs/STU-001002/enrollment.pdf', TRUE, '2025-08-15', NULL),
  ('STU-001003', 'id_card',       'https://campus.edu/docs/STU-001003/id_card.pdf',           TRUE, '2026-01-10', '2028-07-31')
ON CONFLICT DO NOTHING;

-- ============================================================
-- AUTO-GENERATED STUDENT IDs
-- ============================================================
CREATE SEQUENCE IF NOT EXISTS student_id_seq START WITH 1004;

CREATE OR REPLACE FUNCTION generate_student_id()
RETURNS TEXT AS $$
DECLARE next_val INTEGER;
BEGIN
  next_val := nextval('student_id_seq');
  RETURN 'STU-' || LPAD(next_val::TEXT, 6, '0');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- SUPABASE REALTIME
-- ============================================================
-- Safely add tables to realtime publication (ignore if already added)
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE clearance_requests;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE campus_notifications;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE opportunities;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE issues;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE students;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
