CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS settings (
  user_id TEXT NOT NULL REFERENCES users(id),
  key TEXT NOT NULL,
  value TEXT NOT NULL,
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  PRIMARY KEY (user_id, key)
);

CREATE TABLE IF NOT EXISTS characters (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  name TEXT NOT NULL,
  avatar_initial TEXT,
  description TEXT DEFAULT '',
  personality TEXT DEFAULT '',
  backstory TEXT DEFAULT '',
  orientation TEXT DEFAULT '',
  custom_orientation TEXT DEFAULT '',
  relationship_modes TEXT DEFAULT '[]',
  custom_relationship TEXT DEFAULT '',
  involved_characters TEXT DEFAULT '[]',
  kinks TEXT DEFAULT '[]',
  pure_love_mode INTEGER DEFAULT 0,
  model_provider TEXT DEFAULT '',
  model_api_key TEXT DEFAULT '',
  model_name TEXT DEFAULT '',
  model_base_url TEXT DEFAULT '',
  -- 独立生图配置（角色级，与聊天模型分离；前端 CharacterModelSettings 已使用）
  image_model TEXT DEFAULT '',
  image_api_key TEXT DEFAULT '',
  image_base_url TEXT DEFAULT '',
  -- 语音配置（角色级）
  voice_id TEXT DEFAULT '',
  voice_mode TEXT DEFAULT 'off',
  tts_model TEXT DEFAULT '',
  elevenlabs_api_key TEXT DEFAULT '',
  tts_enabled INTEGER DEFAULT 0,
  stt_enabled INTEGER DEFAULT 0,
  chat_space_id TEXT DEFAULT '',
  status TEXT DEFAULT 'pending',
  is_default INTEGER DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS character_memories (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  chat_space_id TEXT NOT NULL,
  text TEXT NOT NULL,
  embedding TEXT,
  embedding_model TEXT,
  semantic_type TEXT DEFAULT 'event',
  importance REAL DEFAULT 0.5,
  reference_message_id TEXT,
  archived INTEGER DEFAULT 0,
  last_accessed DATETIME,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  -- 记忆锁定 / 热度衰减 / 矛盾检测（代码已使用，旧库需走下面的 ALTER 补列）
  pinned INTEGER DEFAULT 0,
  heat REAL DEFAULT 1.0,
  decay_factor REAL DEFAULT 0.02,
  superseded INTEGER DEFAULT 0,
  superseded_at TEXT,
  superseded_by TEXT
);

-- Migration: add new columns to existing table (D1 compatible, no non-constant defaults)
-- 注意：每条 ALTER 都是幂等的安全写法——如果列已存在会报错，可忽略那条单独的报错继续执行下一条。
ALTER TABLE character_memories ADD COLUMN embedding TEXT;
ALTER TABLE character_memories ADD COLUMN embedding_model TEXT;
ALTER TABLE character_memories ADD COLUMN semantic_type TEXT DEFAULT 'event';
ALTER TABLE character_memories ADD COLUMN importance REAL DEFAULT 0.5;
ALTER TABLE character_memories ADD COLUMN reference_message_id TEXT;
ALTER TABLE character_memories ADD COLUMN archived INTEGER DEFAULT 0;
ALTER TABLE character_memories ADD COLUMN last_accessed DATETIME;
ALTER TABLE character_memories ADD COLUMN updated_at DATETIME;
-- 记忆锁定 / 热度 / 矛盾检测（修复 schema 与代码不一致：代码里已在用但旧 schema 没声明）
ALTER TABLE character_memories ADD COLUMN pinned INTEGER DEFAULT 0;
ALTER TABLE character_memories ADD COLUMN heat REAL DEFAULT 1.0;
ALTER TABLE character_memories ADD COLUMN decay_factor REAL DEFAULT 0.02;
ALTER TABLE character_memories ADD COLUMN superseded INTEGER DEFAULT 0;
ALTER TABLE character_memories ADD COLUMN superseded_at TEXT;
ALTER TABLE character_memories ADD COLUMN superseded_by TEXT;

CREATE TABLE IF NOT EXISTS messages (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  chat_space_id TEXT NOT NULL,
  conversation_id TEXT NOT NULL,
  session_id TEXT,
  role TEXT NOT NULL,
  content TEXT NOT NULL,
  quote TEXT,
  reasoning_content TEXT DEFAULT '',
  reasoning_source TEXT,
  reasoning_visible INTEGER DEFAULT 0,
  response_group_id TEXT,
  status TEXT DEFAULT 'sent',
  read_by_user INTEGER DEFAULT 1,
  read_by_du INTEGER DEFAULT 1,
  excluded_from_context INTEGER DEFAULT 0,
  deleted_at TEXT,
  superseded_at TEXT,
  meta TEXT DEFAULT '{}',
  created_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_messages_user_chat ON messages(user_id, chat_space_id);
CREATE INDEX IF NOT EXISTS idx_messages_created ON messages(created_at);
CREATE INDEX IF NOT EXISTS idx_memories_user_space ON character_memories(user_id, chat_space_id);
CREATE INDEX IF NOT EXISTS idx_characters_user ON characters(user_id);

-- Migration: 补齐 characters 表缺失的列（独立生图 + 语音配置）。
-- 旧库执行，列已存在时该条 ALTER 会报错，忽略即可。
ALTER TABLE characters ADD COLUMN image_model TEXT DEFAULT '';
ALTER TABLE characters ADD COLUMN image_api_key TEXT DEFAULT '';
ALTER TABLE characters ADD COLUMN image_base_url TEXT DEFAULT '';
ALTER TABLE characters ADD COLUMN voice_mode TEXT DEFAULT 'off';
ALTER TABLE characters ADD COLUMN tts_model TEXT DEFAULT '';
ALTER TABLE characters ADD COLUMN elevenlabs_api_key TEXT DEFAULT '';
