CREATE TABLE users (  
id SERIAL PRIMARY KEY,  
name VARCHAR(100) NOT NULL,  
email VARCHAR(100) UNIQUE NOT NULL,  
    password VARCHAR(100) NOT NULL,  
    role VARCHAR(20) NOT NULL CHECK (role IN ('admin', 'doctor', 'patient')),  
    department VARCHAR(100),  
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP  
); 
 
CREATE TABLE appointments (  
    id SERIAL PRIMARY KEY,  
    patient_id INTEGER REFERENCES users(id),  
    doctor_id INTEGER REFERENCES users(id),  
    date TIMESTAMP NOT NULL,  
    description TEXT,  
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'cancelled')),  
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP  
); 
 
CREATE TABLE prescriptions (  
    id SERIAL PRIMARY KEY,  
    patient_id INTEGER REFERENCES users(id),  
    doctor_id INTEGER REFERENCES users(id),  
    medications TEXT NOT NULL,  
    instructions TEXT,  
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP  
); 
 
CREATE TABLE medical_history ( 
    id SERIAL PRIMARY KEY, 
    patient_id INTEGER REFERENCES users(id), 
    doctor_id INTEGER REFERENCES users(id), 
    diagnosis TEXT NOT NULL, 
    treatment TEXT, 
    allergies TEXT, 
    chronic_conditions TEXT, 
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP 
); 
 
CREATE TABLE departments ( 
    id SERIAL PRIMARY KEY, 
    name VARCHAR(100) UNIQUE NOT NULL, 
    head_id INTEGER REFERENCES users(id), 
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP 
); 
 -- 1. VIEW: Randevular ile ilgili hasta ve doktor isimleri 
CREATE OR REPLACE VIEW appointment_details AS 
SELECT  
    a.id, 
    p.name AS patient_name, 
    d.name AS doctor_name, 
    a.date, 
    a.description, 
    a.status, 
    a.created_at 
FROM appointments a 
JOIN users p ON a.patient_id = p.id 
JOIN users d ON a.doctor_id = d.id; 
 -- 2. INDEXLER: Tarih ve durum alanlarına indeks 
CREATE INDEX idx_appointments_date ON appointments(date); 
CREATE INDEX idx_appointments_status ON appointments(status); 
 -- 3. TRIGGERLAR: 
 -- Fonksiyon: Yeni randevu eklendiğinde created_at güncellemesi 
CREATE OR REPLACE FUNCTION set_appointment_created_at() 
RETURNS TRIGGER AS $$ 
BEGIN 
NEW.created_at := CURRENT_TIMESTAMP; 
RETURN NEW; 
END; 
$$ LANGUAGE plpgsql; 
CREATE TRIGGER trg_set_created_at 
BEFORE INSERT ON appointments 
FOR EACH ROW 
EXECUTE FUNCTION set_appointment_created_at(); -- Fonksiyon: Randevu durumu 'cancelled' olduğunda log tutma 
CREATE TABLE appointment_cancellations_log ( 
id SERIAL PRIMARY KEY, 
appointment_id INTEGER, 
cancelled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP 
); 
CREATE OR REPLACE FUNCTION log_appointment_cancellation() 
RETURNS TRIGGER AS $$ 
BEGIN 
IF NEW.status = 'cancelled' AND OLD.status <> 'cancelled' THEN 
INSERT INTO appointment_cancellations_log (appointment_id) VALUES (NEW.id); 
END IF; 
RETURN NEW; 
END; 
$$ LANGUAGE plpgsql; 
CREATE TRIGGER trg_log_cancellation 
AFTER UPDATE ON appointments 
FOR EACH ROW 
WHEN (OLD.status IS DISTINCT FROM NEW.status) 
EXECUTE FUNCTION log_appointment_cancellation(); 
