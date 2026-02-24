-- Create per-service databases
CREATE DATABASE noton_identity;
CREATE DATABASE noton_docs;
CREATE DATABASE noton_chat;
CREATE DATABASE noton_files;
CREATE DATABASE noton_automation;
CREATE DATABASE noton_assistant;
CREATE DATABASE noton_notifications;
CREATE DATABASE noton_n8n;

-- Enable pgvector extension for assistant DB
\c noton_assistant
CREATE EXTENSION IF NOT EXISTS vector;
