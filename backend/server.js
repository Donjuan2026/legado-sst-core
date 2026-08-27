const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const sqlite3 = require('sqlite3').verbose();
const dotenv = require('dotenv');
const cors = require('cors');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Conexión a SQLite
const db = new sqlite3.Database('./legado.db', (err) => {
  if (err) {
    console.error('Error al conectar con SQLite:', err.message);
  } else {
    console.log('Conectado a la base de datos SQLite.');
  }
});

// Crear tabla de usuarios
db.run(`CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  nombre TEXT,
  perfil TEXT DEFAULT 'trabajador',
  verificado INTEGER DEFAULT 0,
  codigo_verificacion TEXT,
  creado_en TEXT DEFAULT (datetime('now'))
)`);

// Ruta de prueba
app.get('/', (req, res) => {
  res.json({ mensaje: 'API LEGADO funcionando' });
});

// Registro de usuario
app.post('/api/register', async (req, res) => {
  const { email, password, nombre, perfil } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Email y contraseña son obligatorios' });
  }
  if (password.length < 6) {
    return res.status(400).json({ error: 'La contraseña debe tener al menos 6 caracteres' });
  }

  db.get('SELECT email FROM users WHERE email = ?', [email], async (err, row) => {
    if (err) return res.status(500).json({ error: 'Error en la base de datos' });
    if (row) return res.status(400).json({ error: 'El email ya está registrado' });

    const hashedPassword = await bcrypt.hash(password, 10);

    db.run(
      'INSERT INTO users (email, password, nombre, perfil, verificado) VALUES (?, ?, ?, ?, 0)',
      [email, hashedPassword, nombre || '', perfil || 'trabajador'],
      function (err) {
        if (err) return res.status(500).json({ error: 'No se pudo registrar el usuario' });

        const token = jwt.sign(
          { id: this.lastID, email, perfil: perfil || 'trabajador' },
          process.env.JWT_SECRET,
          { expiresIn: '7d' }
        );

        res.status(201).json({
          mensaje: 'Usuario registrado correctamente',
          token,
          usuario: { id: this.lastID, email, perfil: perfil || 'trabajador' }
        });
      }
    );
  });
});

// Login de usuario
app.post('/api/login', (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Email y contraseña son obligatorios' });
  }

  db.get('SELECT * FROM users WHERE email = ?', [email], async (err, user) => {
    if (err) return res.status(500).json({ error: 'Error en la base de datos' });
    if (!user) return res.status(401).json({ error: 'Credenciales inválidas' });

    const passwordMatch = await bcrypt.compare(password, user.password);
    if (!passwordMatch) return res.status(401).json({ error: 'Credenciales inválidas' });

    const token = jwt.sign(
      { id: user.id, email: user.email, perfil: user.perfil },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      mensaje: 'Login exitoso',
      token,
      usuario: { id: user.id, email: user.email, perfil: user.perfil }
    });
  });
});

// Middleware para rutas protegidas
function verificarToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'Token no proporcionado' });

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ error: 'Token inválido' });
    req.user = user;
    next();
  });
}

// Ruta protegida de ejemplo
app.get('/api/perfil', verificarToken, (req, res) => {
  db.get('SELECT id, email, nombre, perfil, verificado FROM users WHERE id = ?', [req.user.id], (err, row) => {
    if (err || !row) return res.status(404).json({ error: 'Usuario no encontrado' });
    res.json({ usuario: row });
  });
});

// Iniciar servidor
app.listen(PORT, () => {
  console.log(`Servidor LEGADO escuchando en http://localhost:${PORT}`);
});
