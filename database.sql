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
