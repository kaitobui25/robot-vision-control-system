# Database Setup Guide

## 1. Create Database

psql -U postgres

CREATE DATABASE robot_control_db;
\c robot_control_db

## 2. Run Schema Initialization

\i database/init.sql

## 3. Verify

\dt
SELECT \* FROM robots;

## Notes

- PostgreSQL 15 required
- PostGIS extension required
- Default port: 5432

## Architecture Notes

- robots: stores robot state & telemetry
- vision_detections: stores AI detection results in JSONB
- navigation_paths: track planned & executed paths
- task_queue: priority-based task scheduling
- system_logs: microservice-level logging
