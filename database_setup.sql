CREATE DATABASE imei_db;

\c imei_db;

CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  phone VARCHAR(15) NOT NULL UNIQUE,
  is_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS otp_requests (
  id SERIAL PRIMARY KEY,
  phone VARCHAR(15) NOT NULL,
  otp VARCHAR(10) NOT NULL,
  purpose VARCHAR(50) NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  attempts_left INT DEFAULT 3,
  verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS devices (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(id) ON DELETE CASCADE,
  phone VARCHAR(15) NOT NULL,
  device_model VARCHAR(100) NOT NULL,
  brand VARCHAR(100) NOT NULL,
  ram VARCHAR(50),
  rom VARCHAR(50),
  storage VARCHAR(50),
  network_type VARCHAR(50),
  fingerprint_hash TEXT NOT NULL,
  imei VARCHAR(20),
  tac VARCHAR(8),
  tac_matches_model BOOLEAN,
  status VARCHAR(30) DEFAULT 'registered',
  is_flagged BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS friend_links (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(id) ON DELETE CASCADE,
  friend_phone VARCHAR(15) NOT NULL,
  display_name VARCHAR(100),
  verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE (user_id, friend_phone)
);

CREATE TABLE IF NOT EXISTS flagged_devices (
  id SERIAL PRIMARY KEY,
  original_device_id INT REFERENCES devices(id) ON DELETE SET NULL,
  owner_phone VARCHAR(15) NOT NULL,
  imei VARCHAR(20) NOT NULL,
  tac VARCHAR(8),
  device_model VARCHAR(100),
  brand VARCHAR(100),
  ram VARCHAR(50),
  rom VARCHAR(50),
  storage VARCHAR(50),
  network_type VARCHAR(50),
  fingerprint_hash TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  unflagged_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS lost_flags (
  id SERIAL PRIMARY KEY,
  device_id INT REFERENCES devices(id) ON DELETE CASCADE,
  flagged_by_user_id INT REFERENCES users(id) ON DELETE CASCADE,
  flag_status VARCHAR(30) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS alerts (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(id) ON DELETE CASCADE,
  device_id INT REFERENCES devices(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tac_catalog (
  id SERIAL PRIMARY KEY,
  tac VARCHAR(8) NOT NULL,
  brand VARCHAR(100) NOT NULL,
  model VARCHAR(100) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE (tac, brand, model)
);

CREATE TABLE IF NOT EXISTS suspicious_devices (
  id SERIAL PRIMARY KEY,
  original_device_id INT REFERENCES devices(id) ON DELETE SET NULL,
  user_id INT REFERENCES users(id) ON DELETE CASCADE,
  phone VARCHAR(15) NOT NULL,
  imei VARCHAR(20),
  tac VARCHAR(8),
  device_model VARCHAR(100),
  brand VARCHAR(100),
  ram VARCHAR(50),
  rom VARCHAR(50),
  storage VARCHAR(50),
  network_type VARCHAR(50),
  fingerprint_hash TEXT NOT NULL,
  reason TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_devices_phone ON devices(phone);
CREATE INDEX IF NOT EXISTS idx_devices_imei ON devices(imei);
CREATE INDEX IF NOT EXISTS idx_devices_fingerprint_hash ON devices(fingerprint_hash);
CREATE INDEX IF NOT EXISTS idx_friend_links_user_id ON friend_links(user_id);
CREATE INDEX IF NOT EXISTS idx_flagged_devices_imei ON flagged_devices(imei);
CREATE INDEX IF NOT EXISTS idx_alerts_user_id ON alerts(user_id);

INSERT INTO tac_catalog (tac, brand, model)
VALUES
  ('49015420', 'Apple', 'iPhone 13'),
  ('35678901', 'Samsung', 'Galaxy A14'),
  ('35081449', 'Samsung', 'Galaxy M1565B'),
  ('86753090', 'OnePlus', 'Nord CE 3'),
  ('12345678', 'Xiaomi', 'Redmi Note 12')
ON CONFLICT (tac, brand, model) DO NOTHING;
