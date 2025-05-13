const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// PostgreSQL bağlantısı
const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'hastane_db',
  password: process.env.DB_PASSWORD || 'bjk-1903',
  port: process.env.DB_PORT || 5432,
});

// JWT Secret
const JWT_SECRET = process.env.JWT_SECRET || 'gizli-anahtar';

// Middleware - Token doğrulama
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ message: 'Yetkilendirme başarısız' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ message: 'Geçersiz token' });
    }
    req.user = user;
    next();
  });
};

// Auth Routes
app.post('/api/auth/register', async (req, res) => {
  try {
    const { name, email, password, role, department } = req.body;
    const hashedPassword = await bcrypt.hash(password, 10);

    const result = await pool.query(
      'INSERT INTO users (name, email, password, role, department) VALUES ($1, $2, $3, $4, $5) RETURNING id, name, email, role, department',
      [name, email, hashedPassword, role, department]
    );

    const user = result.rows[0];
    const token = jwt.sign({ id: user.id, role: user.role }, JWT_SECRET);

    res.json({ token, user });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Kayıt işlemi başarısız' });
  }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    const user = result.rows[0];

    if (!user) {
      return res.status(401).json({ message: 'Geçersiz email veya şifre' });
    }

    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) {
      return res.status(401).json({ message: 'Geçersiz email veya şifre' });
    }

    const token = jwt.sign({ id: user.id, role: user.role }, JWT_SECRET);
    const { password: _, ...userWithoutPassword } = user;

    res.json({ token, user: userWithoutPassword });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Giriş işlemi başarısız' });
  }
});

// Appointment Routes
app.get('/api/appointments', authenticateToken, async (req, res) => {
  try {
    const { role, id } = req.user;
    let query = `
      SELECT a.*, 
        p.name as patient_name, 
        d.name as doctor_name,
        d.department
      FROM appointments a
      LEFT JOIN users p ON a.patient_id = p.id
      LEFT JOIN users d ON a.doctor_id = d.id
    `;

    if (role === 'doctor') {
      query += ' WHERE a.doctor_id = $1';
    } else if (role === 'patient') {
      query += ' WHERE a.patient_id = $1';
    }

    const result = await pool.query(query, role !== 'admin' ? [id] : []);
    res.json(result.rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Randevular yüklenemedi' });
  }
});

app.post('/api/appointments', authenticateToken, async (req, res) => {
  try {
    const { date, description, patientId, doctorId } = req.body;
    const result = await pool.query(
      'INSERT INTO appointments (date, description, patient_id, doctor_id) VALUES ($1, $2, $3, $4) RETURNING *',
      [date, description, patientId, doctorId]
    );
    res.json(result.rows[0]);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Randevu oluşturulamadı' });
  }
});

app.delete('/api/appointments/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    await pool.query('DELETE FROM appointments WHERE id = $1', [id]);
    res.json({ message: 'Randevu silindi' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Randevu silinemedi' });
  }
});

app.patch('/api/appointments/:id/status', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    const { role, id: userId } = req.user;

    // Sadece doktorlar randevu durumunu güncelleyebilir
    if (role !== 'doctor') {
      return res.status(403).json({ message: 'Bu işlem için yetkiniz yok' });
    }

    // Doktor sadece kendi randevularını güncelleyebilir
    const appointment = await pool.query(
      'SELECT * FROM appointments WHERE id = $1 AND doctor_id = $2',
      [id, userId]
    );

    if (appointment.rows.length === 0) {
      return res.status(404).json({ message: 'Randevu bulunamadı' });
    }

    const result = await pool.query(
      'UPDATE appointments SET status = $1 WHERE id = $2 RETURNING *',
      [status, id]
    );
    res.json(result.rows[0]);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Randevu durumu güncellenemedi' });
  }
});

// Prescription Routes
app.get('/api/prescriptions', authenticateToken, async (req, res) => {
  try {
    const { role, id } = req.user;
    let query = `
      SELECT p.*, 
        pat.name as patient_name, 
        doc.name as doctor_name
      FROM prescriptions p
      LEFT JOIN users pat ON p.patient_id = pat.id
      LEFT JOIN users doc ON p.doctor_id = doc.id
    `;

    if (role === 'doctor') {
      query += ' WHERE p.doctor_id = $1';
    } else if (role === 'patient') {
      query += ' WHERE p.patient_id = $1';
    }

    const result = await pool.query(query, role !== 'admin' ? [id] : []);
    res.json(result.rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Reçeteler yüklenemedi' });
  }
});

app.post('/api/prescriptions', authenticateToken, async (req, res) => {
  try {
    const { patientId, medications, instructions } = req.body;
    const doctorId = req.user.id;

    const result = await pool.query(
      'INSERT INTO prescriptions (patient_id, doctor_id, medications, instructions) VALUES ($1, $2, $3, $4) RETURNING *',
      [patientId, doctorId, medications, instructions]
    );
    res.json(result.rows[0]);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Reçete oluşturulamadı' });
  }
});

// Users Routes
app.get('/api/users/doctors', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, name, email, department FROM users WHERE role = $1',
      ['doctor']
    );
    res.json(result.rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Doktorlar yüklenemedi' });
  }
});

// Doktorun kendi hastalarını dönen endpoint
app.get('/api/users/my-patients', authenticateToken, async (req, res) => {
  try {
    const { role, id } = req.user;
    if (role !== 'doctor') {
      return res.status(403).json({ message: 'Sadece doktorlar hastalarını görebilir.' });
    }
    const result = await pool.query(
      `SELECT DISTINCT u.id, u.name, u.email
       FROM appointments a
       JOIN users u ON a.patient_id = u.id
       WHERE a.doctor_id = $1 AND a.status = 'confirmed'`,
      [id]
    );
    res.json(result.rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Hastalar yüklenemedi' });
  }
});

// Sunucuyu başlat
app.listen(port, () => {
  console.log(`Sunucu http://localhost:${port} adresinde çalışıyor`);
}); 