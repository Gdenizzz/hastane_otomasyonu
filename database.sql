-- Users tablosu
 CREATE TABLE users ( 
id SERIAL PRIMARY KEY, 
name VARCHAR(100) NOT NULL, 
email VARCHAR(100) UNIQUE NOT NULL, 
password VARCHAR(100) NOT NULL, 
role VARCHAR(20) NOT NULL CHECK (role IN ('admin', 'doctor', 'patient')), 
department VARCHAR(100), 
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP 
); -- Appointments tablosu
 CREATE TABLE appointments ( 
id SERIAL PRIMARY KEY, 
patient_id INTEGER REFERENCES users(id), 
doctor_id INTEGER REFERENCES users(id), 
date TIMESTAMP NOT NULL, 
description TEXT, 
status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 
'confirmed', 'cancelled')), 
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP 
); -- Prescriptions tablosu
 CREATE TABLE prescriptions ( 
id SERIAL PRIMARY KEY, 
patient_id INTEGER REFERENCES users(id), 
doctor_id INTEGER REFERENCES users(id), 
medications TEXT NOT NULL, 
instructions TEXT, 
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP 
);

CREATE TABLE hastane_adi(
id SERIAL PRIMARY KEY,
name VARCHAR(150) NOT NULL UNIQUE,
address TEXT
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);