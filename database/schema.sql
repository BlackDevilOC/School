-- Enable Row Level Security
ALTER DATABASE postgres SET "app.settings.jwt_secret" = 'YOUR_JWT_SECRET';

-- Create enum types
CREATE TYPE user_role AS ENUM ('admin', 'teacher', 'student');
CREATE TYPE student_type AS ENUM ('class', 'course');
CREATE TYPE payment_status AS ENUM ('pending', 'paid', 'overdue');
CREATE TYPE payment_method AS ENUM ('cash', 'bank_transfer', 'online');

-- Create teachers table
CREATE TABLE teachers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    subject VARCHAR(50) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    base_salary DECIMAL(10,2) NOT NULL,
    joining_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create students table
CREATE TABLE students (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    father_name VARCHAR(100) NOT NULL,
    student_type student_type NOT NULL,
    class_grade VARCHAR(10),
    roll_number INTEGER NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    course_name VARCHAR(50),
    batch_number VARCHAR(20),
    admission_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_student_type CHECK (
        (student_type = 'class' AND class_grade IS NOT NULL AND course_name IS NULL AND batch_number IS NULL) OR
        (student_type = 'course' AND class_grade IS NULL AND course_name IS NOT NULL AND batch_number IS NOT NULL)
    )
);

-- Create attendance table
CREATE TABLE attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    type VARCHAR(10) NOT NULL CHECK (type IN ('student', 'teacher')),
    date DATE NOT NULL,
    status VARCHAR(10) NOT NULL CHECK (status IN ('present', 'absent', 'late', 'excused')),
    remarks TEXT,
    class_grade VARCHAR(10),
    course_name VARCHAR(50),
    batch_number VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, date)
);

-- Create fee_structure table
CREATE TABLE fee_structure (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_type student_type NOT NULL,
    class_grade VARCHAR(10),
    course_name VARCHAR(50),
    amount DECIMAL(10,2) NOT NULL,
    valid_from DATE NOT NULL,
    valid_until DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create student_fees table
CREATE TABLE student_fees (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID REFERENCES students(id) ON DELETE CASCADE,
    fee_structure_id UUID REFERENCES fee_structure(id),
    month DATE NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    due_date DATE NOT NULL,
    status payment_status NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create fee_payments table
CREATE TABLE fee_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_fee_id UUID REFERENCES student_fees(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    payment_date DATE NOT NULL,
    payment_method payment_method NOT NULL,
    transaction_reference VARCHAR(50),
    remarks TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better query performance
CREATE INDEX idx_attendance_date ON attendance(date);
CREATE INDEX idx_attendance_user ON attendance(user_id);
CREATE INDEX idx_student_fees_month ON student_fees(month);
CREATE INDEX idx_fee_payments_date ON fee_payments(payment_date);

-- Create RLS Policies
ALTER TABLE teachers ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE fee_structure ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE fee_payments ENABLE ROW LEVEL SECURITY;

-- Create policies for public access (you may want to restrict this in production)
CREATE POLICY "Allow public access" ON teachers FOR ALL USING (true);
CREATE POLICY "Allow public access" ON students FOR ALL USING (true);
CREATE POLICY "Allow public access" ON attendance FOR ALL USING (true);
CREATE POLICY "Allow public access" ON fee_structure FOR ALL USING (true);
CREATE POLICY "Allow public access" ON student_fees FOR ALL USING (true);
CREATE POLICY "Allow public access" ON fee_payments FOR ALL USING (true);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers to automatically update updated_at
CREATE TRIGGER update_teachers_updated_at
    BEFORE UPDATE ON teachers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_students_updated_at
    BEFORE UPDATE ON students
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_attendance_updated_at
    BEFORE UPDATE ON attendance
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_fee_structure_updated_at
    BEFORE UPDATE ON fee_structure
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_student_fees_updated_at
    BEFORE UPDATE ON student_fees
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column(); 