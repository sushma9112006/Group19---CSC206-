const express = require("express");
const cors = require("cors");
const { Pool } = require("pg");
const crypto = require("crypto");

const app = express();
app.use(cors());
app.use(express.json());

const pool = new Pool({
  user: "postgres",
  host: "localhost",
  database: "imei_db",
  password: "Srutha@2110",
  port: 3000,
});

pool.query("SELECT current_database()", (err, result) => {
  if (err) {
    console.error("DB check error:", err);
  } else {
    console.log("Connected database:", result.rows[0].current_database);
  }
});

pool.query(`
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
  )
`).catch((err) => {
  console.error("suspicious_devices table init error:", err.message);
});

pool.query(`
  ALTER TABLE friend_links
  ADD COLUMN IF NOT EXISTS display_name VARCHAR(100)
`).catch((err) => {
  console.error("friend_links display_name init error:", err.message);
});

function generateOtp() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

function buildFingerprint(data) {
  const raw = [
    data.device_model || "",
    data.brand || "",
    data.ram || "",
    data.rom || "",
    data.storage || "",
    data.network_type || "",
  ].join("|");

  return crypto.createHash("sha256").update(raw).digest("hex");
}

function extractTac(imei) {
  if (!imei || imei.length < 8) return null;
  return imei.slice(0, 8);
}

async function tacMatchesModel(tac, brand, model) {
  console.log("Checking TAC:", { tac, brand, model });

  const result = await pool.query(
    `SELECT 1
     FROM tac_catalog
     WHERE tac = $1
       AND LOWER(TRIM(brand)) = LOWER(TRIM($2))
       AND LOWER(TRIM(model)) = LOWER(TRIM($3))
     LIMIT 1`,
    [tac, brand, model]
  );

  console.log("TAC match rows:", result.rows.length);
  return result.rows.length > 0;
}

async function getUserByPhone(phone) {
  const result = await pool.query(
    `SELECT * FROM users WHERE phone = $1`,
    [phone]
  );
  return result.rows[0] || null;
}

async function getLatestDeviceByPhone(phone) {
  const result = await pool.query(
    `SELECT *
     FROM devices
     WHERE phone = $1
     ORDER BY created_at DESC
     LIMIT 1`,
    [phone]
  );
  return result.rows[0] || null;
}

async function ensureNonSuspiciousUser(phone) {
  const latestDevice = await getLatestDeviceByPhone(phone);

  if (latestDevice?.status === "suspicious") {
    return {
      blocked: true,
      message:
        "Suspicious devices cannot access friends or social features until cleared.",
      device: latestDevice,
    };
  }

  return { blocked: false, device: latestDevice };
}

async function createAlertIfMissing(userId, deviceId, message) {
  const existingAlert = await pool.query(
    `SELECT 1
     FROM alerts
     WHERE user_id = $1 AND device_id = $2 AND message = $3
     LIMIT 1`,
    [userId, deviceId, message]
  );

  if (!existingAlert.rows.length) {
    await pool.query(
      `INSERT INTO alerts (user_id, device_id, message)
       VALUES ($1, $2, $3)`,
      [userId, deviceId, message]
    );
  }
}

async function buildNextFriendName(userId) {
  const result = await pool.query(
    `SELECT COUNT(*)::int AS count
     FROM friend_links
     WHERE user_id = $1`,
    [userId]
  );

  return `Friend ${result.rows[0].count + 1}`;
}

async function resolveFriendName(userId, providedName) {
  const trimmed = providedName?.trim();
  if (trimmed) {
    return trimmed;
  }

  return buildNextFriendName(userId);
}

app.post("/auth/send-otp", async (req, res) => {
  try {
    const { phone, purpose } = req.body;

    if (!phone || !purpose) {
      return res.status(400).json({ error: "phone and purpose are required" });
    }

    const otp = generateOtp();
    console.log(`Login OTP for ${phone}: ${otp}`);

    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

    await pool.query(
      `INSERT INTO otp_requests (phone, otp, purpose, expires_at, attempts_left, verified)
       VALUES ($1, $2, $3, $4, 3, FALSE)`,
      [phone, otp, purpose, expiresAt]
    );

    res.json({
      message: "OTP sent successfully",
      otp,
      expiresIn: "5 minutes",
      attemptsAllowed: 3,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post("/auth/verify-otp", async (req, res) => {
  try {
    const { phone, otp, purpose } = req.body;
    let loggedInUser = null;

    const result = await pool.query(
      `SELECT * FROM otp_requests
       WHERE phone = $1 AND purpose = $2 AND verified = FALSE
       ORDER BY created_at DESC
       LIMIT 1`,
      [phone, purpose]
    );

    if (!result.rows.length) {
      return res.status(404).json({ error: "No OTP request found" });
    }

    const row = result.rows[0];

    if (new Date() > row.expires_at) {
      return res.status(400).json({ error: "OTP expired" });
    }

    if (row.attempts_left <= 0) {
      return res.status(400).json({ error: "No attempts left" });
    }

    if (row.otp !== otp) {
      await pool.query(
        `UPDATE otp_requests
         SET attempts_left = attempts_left - 1
         WHERE id = $1`,
        [row.id]
      );
      return res.status(400).json({ error: "Invalid OTP" });
    }

    await pool.query(
      `UPDATE otp_requests SET verified = TRUE WHERE id = $1`,
      [row.id]
    );

    if (purpose === "login") {
      const userUpsert = await pool.query(
        `INSERT INTO users (phone, is_verified)
         VALUES ($1, TRUE)
         ON CONFLICT (phone)
         DO UPDATE SET is_verified = TRUE
         RETURNING *`,
        [phone]
      );

      loggedInUser = userUpsert.rows[0];

      const pendingLinks = await pool.query(
        `SELECT u.phone AS owner_phone
         FROM friend_links fl
         JOIN users u ON u.id = fl.user_id
         WHERE fl.friend_phone = $1 AND fl.verified = TRUE`,
        [phone]
      );

      for (const linkRow of pendingLinks.rows) {
        const reverseFriendName = await resolveFriendName(
          loggedInUser.id,
          null
        );

        await pool.query(
          `INSERT INTO friend_links (user_id, friend_phone, display_name, verified)
           VALUES ($1, $2, $3, TRUE)
           ON CONFLICT (user_id, friend_phone)
           DO UPDATE SET verified = TRUE,
                         display_name = COALESCE(friend_links.display_name, EXCLUDED.display_name)`,
          [loggedInUser.id, linkRow.owner_phone, reverseFriendName]
        );
      }
    }

    const latestDevice = await getLatestDeviceByPhone(phone);

    res.json({
      message: "OTP verified successfully",
      user: loggedInUser || null,
      latestDevice,
      requiresDeviceRegistration: !latestDevice,
      isSuspicious: latestDevice?.status === "suspicious",
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get("/auth/session/:phone", async (req, res) => {
  try {
    const { phone } = req.params;

    const user = await getUserByPhone(phone);
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    const latestDevice = await getLatestDeviceByPhone(phone);

    res.json({
      user,
      latestDevice,
      requiresDeviceRegistration: !latestDevice,
      isSuspicious: latestDevice?.status === "suspicious",
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post("/device/register", async (req, res) => {
  try {
    const {
      phone,
      device_model,
      brand,
      ram,
      rom,
      storage,
      network_type,
      imei,
    } = req.body;

    if (!phone || !device_model || !brand) {
      return res.status(400).json({ error: "phone, brand and device_model are required" });
    }

    const userRes = await pool.query(
      `SELECT * FROM users WHERE phone = $1`,
      [phone]
    );

    if (!userRes.rows.length) {
      return res.status(404).json({ error: "Verified user not found" });
    }

    const user = userRes.rows[0];
    const fingerprintHash = buildFingerprint({
      device_model,
      brand,
      ram,
      rom,
      storage,
      network_type,
    });

    let tac = null;
    let tacMatch = null;
    let status = "registered";

    if (imei) {
      tac = extractTac(imei);

      const flagged = await pool.query(
        `SELECT * FROM flagged_devices
         WHERE imei = $1 AND is_active = TRUE
         LIMIT 1`,
        [imei]
      );

      if (flagged.rows.length) {
        status = "stolen";
      } else {
        tacMatch = await tacMatchesModel(tac, brand, device_model);

        if (tacMatch) {
          status = "registered";
        } else {
          status = "suspicious";

          const existingImeiOwner = await pool.query(
            `SELECT *
             FROM devices
             WHERE imei = $1
               AND phone <> $2
             ORDER BY created_at ASC`,
            [imei, phone]
          );

          for (const originalDevice of existingImeiOwner.rows) {
            await createAlertIfMissing(
              originalDevice.user_id,
              originalDevice.id,
              "Your IMEI number may have been illegally cloned and used on another suspicious device."
            );
          }
        }
      }
    }

    const deviceInsert = await pool.query(
      `INSERT INTO devices (
        user_id, phone, device_model, brand, ram, rom, storage,
        network_type, fingerprint_hash, imei, tac, tac_matches_model, status
      ) VALUES (
        $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13
      )
      RETURNING *`,
      [
        user.id,
        phone,
        device_model,
        brand,
        ram,
        rom,
        storage,
        network_type,
        fingerprintHash,
        imei || null,
        tac,
        tacMatch,
        status,
      ]
    );

    if (status === "suspicious") {
      await pool.query(
        `INSERT INTO suspicious_devices (
          original_device_id, user_id, phone, imei, tac, device_model, brand,
          ram, rom, storage, network_type, fingerprint_hash, reason
        ) VALUES (
          $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13
        )`,
        [
          deviceInsert.rows[0].id,
          user.id,
          phone,
          imei || null,
          tac,
          device_model,
          brand,
          ram,
          rom,
          storage,
          network_type,
          fingerprintHash,
          "Device properties matched another registered device, but TAC and model validation failed.",
        ]
      );

      const similarDevices = await pool.query(
        `SELECT *
         FROM devices
         WHERE fingerprint_hash = $1
           AND phone <> $2`,
        [fingerprintHash, phone]
      );

      for (const row of similarDevices.rows) {
        await createAlertIfMissing(
          row.user_id,
          row.id,
          "A suspicious device with similar hardware details was registered using a different phone number."
        );
      }
    }

    if (status === "stolen") {
      return res.json({
        message: "This phone is a stolen phone",
        device: deviceInsert.rows[0],
      });
    }

    if (status === "suspicious") {
      return res.json({
        message: "Device is suspicious",
        device: deviceInsert.rows[0],
        allowSocialFeatures: false,
      });
    }

    res.json({
      message: "Registration successful",
      device: deviceInsert.rows[0],
      allowSocialFeatures: true,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post("/friends/send-link-otp", async (req, res) => {
  try {
    const { user_phone, friend_phone } = req.body;

    if (!user_phone || !friend_phone) {
      return res.status(400).json({ error: "user_phone and friend_phone are required" });
    }

    const accessCheck = await ensureNonSuspiciousUser(user_phone);
    if (accessCheck.blocked) {
      return res.status(403).json({ error: accessCheck.message });
    }

    const otp = generateOtp();
    console.log(`Friend link OTP for ${friend_phone}: ${otp}`);

    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

    await pool.query(
      `INSERT INTO otp_requests (phone, otp, purpose, expires_at, attempts_left, verified)
       VALUES ($1, $2, 'friend_link', $3, 3, FALSE)`,
      [friend_phone, otp, expiresAt]
    );

    res.json({
      message: "Friend OTP sent successfully",
      otp,
      expiresIn: "5 minutes",
      attemptsAllowed: 3,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post("/friends/verify-link-otp", async (req, res) => {
  try {
    const { user_phone, friend_phone, otp, friend_name } = req.body;

    const accessCheck = await ensureNonSuspiciousUser(user_phone);
    if (accessCheck.blocked) {
      return res.status(403).json({ error: accessCheck.message });
    }

    const otpRes = await pool.query(
      `SELECT * FROM otp_requests
       WHERE phone = $1 AND purpose = 'friend_link' AND verified = FALSE
       ORDER BY created_at DESC
       LIMIT 1`,
      [friend_phone]
    );

    if (!otpRes.rows.length) {
      return res.status(404).json({ error: "No friend link OTP found" });
    }

    const row = otpRes.rows[0];

    if (new Date() > row.expires_at) {
      return res.status(400).json({ error: "OTP expired" });
    }

    if (row.attempts_left <= 0) {
      return res.status(400).json({ error: "No attempts left" });
    }

    if (row.otp !== otp) {
      await pool.query(
        `UPDATE otp_requests SET attempts_left = attempts_left - 1 WHERE id = $1`,
        [row.id]
      );
      return res.status(400).json({ error: "Invalid OTP" });
    }

    await pool.query(
      `UPDATE otp_requests SET verified = TRUE WHERE id = $1`,
      [row.id]
    );

    const userRes = await pool.query(
      `SELECT * FROM users WHERE phone = $1`,
      [user_phone]
    );

    if (!userRes.rows.length) {
      return res.status(404).json({ error: "User not found" });
    }

    const currentUser = userRes.rows[0];
    const currentUserFriendName = await resolveFriendName(
      currentUser.id,
      friend_name
    );

    await pool.query(
      `INSERT INTO friend_links (user_id, friend_phone, display_name, verified)
       VALUES ($1, $2, $3, TRUE)
       ON CONFLICT (user_id, friend_phone)
       DO UPDATE SET verified = TRUE, display_name = EXCLUDED.display_name`,
      [currentUser.id, friend_phone, currentUserFriendName]
    );

    const friendRes = await pool.query(
      `SELECT * FROM users WHERE phone = $1`,
      [friend_phone]
    );

    if (friendRes.rows.length) {
      const reverseFriendName = await resolveFriendName(
        friendRes.rows[0].id,
        null
      );

      await pool.query(
        `INSERT INTO friend_links (user_id, friend_phone, display_name, verified)
         VALUES ($1, $2, $3, TRUE)
         ON CONFLICT (user_id, friend_phone)
         DO UPDATE SET verified = TRUE,
                       display_name = COALESCE(friend_links.display_name, EXCLUDED.display_name)`,
        [friendRes.rows[0].id, user_phone, reverseFriendName]
      );
    }

    res.json({
      message: friendRes.rows.length
        ? "Friend linked successfully in both directions"
        : "Friend linked successfully. Reverse link will appear when your friend joins",
      friendName: currentUserFriendName,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post("/friends/set-name", async (req, res) => {
  try {
    const { user_phone, friend_phone, friend_name } = req.body;

    if (!user_phone || !friend_phone) {
      return res.status(400).json({ error: "user_phone and friend_phone are required" });
    }

    const user = await getUserByPhone(user_phone);
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    const resolvedName = await resolveFriendName(user.id, friend_name);

    const result = await pool.query(
      `UPDATE friend_links
       SET display_name = $1
       WHERE user_id = $2 AND friend_phone = $3
       RETURNING friend_phone, display_name, verified, created_at`,
      [resolvedName, user.id, friend_phone]
    );

    if (!result.rows.length) {
      return res.status(404).json({ error: "Friend link not found" });
    }

    res.json({
      message: "Friend name updated successfully",
      friend: result.rows[0],
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get("/friends/:phone", async (req, res) => {
  try {
    const { phone } = req.params;

    const accessCheck = await ensureNonSuspiciousUser(phone);
    if (accessCheck.blocked) {
      return res.status(403).json({ error: accessCheck.message });
    }

    const userRes = await pool.query(
      `SELECT * FROM users WHERE phone = $1`,
      [phone]
    );

    if (!userRes.rows.length) {
      return res.status(404).json({ error: "User not found" });
    }

    const friendsRes = await pool.query(
      `SELECT friend_phone, display_name, verified, created_at
       FROM friend_links
       WHERE user_id = $1
       ORDER BY created_at DESC`,
      [userRes.rows[0].id]
    );

    res.json({ friends: friendsRes.rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post("/device/flag-lost", async (req, res) => {
  try {
    const { owner_phone, imei } = req.body;

    if (!owner_phone || !imei) {
      return res.status(400).json({ error: "owner_phone and imei are required" });
    }

    const accessCheck = await ensureNonSuspiciousUser(owner_phone);
    if (accessCheck.blocked) {
      return res.status(403).json({ error: accessCheck.message });
    }

    const ownerRes = await pool.query(
      `SELECT * FROM users WHERE phone = $1`,
      [owner_phone]
    );

    if (!ownerRes.rows.length) {
      return res.status(404).json({ error: "Owner not found" });
    }

    const owner = ownerRes.rows[0];

    const deviceRes = await pool.query(
      `SELECT * FROM devices
       WHERE imei = $1
       ORDER BY created_at DESC
       LIMIT 1`,
      [imei]
    );

    if (!deviceRes.rows.length) {
      return res.status(404).json({ error: "No device found with this IMEI" });
    }

    const device = deviceRes.rows[0];

    const linkRes = await pool.query(
      `SELECT * FROM friend_links
       WHERE user_id = $1 AND friend_phone = $2 AND verified = TRUE`,
      [owner.id, device.phone]
    );

    if (!linkRes.rows.length) {
      return res.status(403).json({ error: "You can only flag devices belonging to your verified friends" });
    }

    const alreadyFlagged = await pool.query(
      `SELECT * FROM flagged_devices
       WHERE imei = $1 AND is_active = TRUE
       LIMIT 1`,
      [imei]
    );

    if (alreadyFlagged.rows.length) {
      return res.status(400).json({ error: "Device already flagged" });
    }

    await pool.query(
      `UPDATE devices
       SET is_flagged = TRUE, status = 'flagged'
       WHERE id = $1`,
      [device.id]
    );

    await pool.query(
      `INSERT INTO flagged_devices (
        original_device_id, owner_phone, imei, tac, device_model, brand,
        ram, rom, storage, network_type, fingerprint_hash, is_active
      ) VALUES (
        $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,TRUE
      )`,
      [
        device.id,
        device.phone,
        device.imei,
        device.tac,
        device.device_model,
        device.brand,
        device.ram,
        device.rom,
        device.storage,
        device.network_type,
        device.fingerprint_hash,
      ]
    );

    await pool.query(
      `INSERT INTO lost_flags (device_id, flagged_by_user_id, flag_status)
       VALUES ($1, $2, 'flagged')`,
      [device.id, owner.id]
    );

    res.json({ message: "Device flagged as lost" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post("/device/unflag-lost", async (req, res) => {
  try {
    const { owner_phone, imei } = req.body;

    if (!owner_phone || !imei) {
      return res.status(400).json({ error: "owner_phone and imei are required" });
    }

    const accessCheck = await ensureNonSuspiciousUser(owner_phone);
    if (accessCheck.blocked) {
      return res.status(403).json({ error: accessCheck.message });
    }

    const ownerRes = await pool.query(
      `SELECT * FROM users WHERE phone = $1`,
      [owner_phone]
    );

    if (!ownerRes.rows.length) {
      return res.status(404).json({ error: "Owner not found" });
    }

    const owner = ownerRes.rows[0];

    const deviceRes = await pool.query(
      `SELECT * FROM devices
       WHERE imei = $1
       ORDER BY created_at DESC
       LIMIT 1`,
      [imei]
    );

    if (!deviceRes.rows.length) {
      return res.status(404).json({ error: "No device found with this IMEI" });
    }

    const device = deviceRes.rows[0];

    const linkRes = await pool.query(
      `SELECT * FROM friend_links
       WHERE user_id = $1 AND friend_phone = $2 AND verified = TRUE`,
      [owner.id, device.phone]
    );

    if (!linkRes.rows.length) {
      return res.status(403).json({ error: "You can only unflag devices belonging to your verified friends" });
    }

    const flaggedRes = await pool.query(
      `SELECT * FROM flagged_devices
       WHERE imei = $1 AND is_active = TRUE
       LIMIT 1`,
      [imei]
    );

    if (!flaggedRes.rows.length) {
      return res.status(400).json({ error: "Device is not flagged" });
    }

    await pool.query(
      `UPDATE devices
       SET is_flagged = FALSE, status = 'registered'
       WHERE id = $1`,
      [device.id]
    );

    await pool.query(
      `UPDATE flagged_devices
       SET is_active = FALSE, unflagged_at = NOW()
       WHERE imei = $1 AND is_active = TRUE`,
      [imei]
    );

    await pool.query(
      `INSERT INTO lost_flags (device_id, flagged_by_user_id, flag_status)
       VALUES ($1, $2, 'unflagged')`,
      [device.id, owner.id]
    );

    res.json({ message: "Device unflagged successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


app.post("/device/unregister", async (req, res) => {
  try {
    const { phone, imei } = req.body;

    if (!phone || !imei) {
      return res.status(400).json({ error: "phone and imei are required" });
    }

    const result = await pool.query(
      `DELETE FROM devices
       WHERE phone = $1 AND imei = $2
       RETURNING *`,
      [phone, imei]
    );

    if (!result.rows.length) {
      return res.status(404).json({ error: "No registered device found for this phone and IMEI" });
    }

    await pool.query(
      `UPDATE flagged_devices
       SET is_active = FALSE, unflagged_at = NOW()
       WHERE imei = $1 AND owner_phone = $2 AND is_active = TRUE`,
      [imei, phone]
    );

    res.json({ message: "Device unregistered successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get("/alerts/:phone", async (req, res) => {
  try {
    const { phone } = req.params;

    const userRes = await pool.query(
      `SELECT * FROM users WHERE phone = $1`,
      [phone]
    );

    if (!userRes.rows.length) {
      return res.status(404).json({ error: "User not found" });
    }

    const alertsRes = await pool.query(
      `SELECT * FROM alerts
       WHERE user_id = $1
       ORDER BY created_at DESC`,
      [userRes.rows[0].id]
    );

    res.json({ alerts: alertsRes.rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

const PORT = 4000;

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running on http://0.0.0.0:${PORT}`);
});
