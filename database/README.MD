Dưới đây là file `README.md` chuyên nghiệp cho database của bạn. Nội dung phù hợp để đưa lên GitHub trong project **robot-vision-control-system** (phần Database).

---

# 🤖 Robot Vision Control System – Database

PostgreSQL 18 schema for a **Robot Vision & Control Platform**, designed to manage:

- Robot fleet status & telemetry
- Vision detection results (YOLO / AI models)
- Navigation path planning
- Task scheduling & execution
- Centralized system logging

---

## 📌 Overview

This database supports a modular robotic system architecture:

```
Vision Module (Python / YOLO)
        ↓
Control Server (C# / C++ / API)
        ↓
PostgreSQL Database
        ↓
Dashboard / Monitoring UI
```

The schema is optimized for:

- Real-time robot monitoring
- Efficient task queue management
- AI detection result storage (JSONB)
- Operational analytics & logging

---

## 🗄️ Database Version

- **PostgreSQL 18**
- Extension used:
    - `uuid-ossp` (UUID generation)

```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

---

# 📊 Schema Design

## 1️⃣ `robots`

Stores robot master data and real-time status.

### Key Features

- UUID primary key
- Status constraints
- Battery validation (0–100)
- Geographic position (lat/lng)
- Network address (INET type)
- Operational metrics

### Status Values

```
IDLE
RUNNING
ERROR
MAINTENANCE
CHARGING
```

---

## 2️⃣ `vision_detections`

Stores AI detection results from camera processing.

### Design Highlights

- Linked to robot (ON DELETE CASCADE)
- `detected_objects` stored as JSONB
- Model version tracking
- Performance tracking (processing_time_ms)

### Example JSON Structure

```json
[
    {
        "class": "pallet",
        "confidence": 0.95,
        "bbox": [100, 150, 300, 400]
    }
]
```

This allows flexible storage of YOLO / DL model outputs.

---

## 3️⃣ `navigation_paths`

Stores planned and executed movement paths.

### Path Status

```
PLANNED
EXECUTING
COMPLETED
FAILED
```

Waypoints are stored as JSONB for flexibility.

---

## 4️⃣ `task_queue`

Central task management system.

### Priority System

- 1 (lowest)
- 10 (highest)

### Status Lifecycle

```
PENDING
ASSIGNED
IN_PROGRESS
COMPLETED
FAILED
CANCELLED
```

Optimized index for:

- Pending tasks by priority
- Active tasks per robot

---

## 5️⃣ `system_logs`

Central logging table.

Supports:

- Multi-service logging
- Robot-linked logs
- JSON metadata storage
- Log level filtering

### Log Levels

```
DEBUG
INFO
WARNING
ERROR
CRITICAL
```

---

# ⚡ Performance Optimization

The schema includes **partial indexes** for high-frequency queries.

### Examples

```sql
CREATE INDEX idx_task_priority
ON task_queue(priority DESC, created_at ASC)
WHERE status = 'PENDING';
```

```sql
CREATE INDEX idx_robots_battery
ON robots(battery_level)
WHERE battery_level < 30;
```

These improve:

- Task scheduler performance
- Low battery alerts
- Active robot filtering
- Real-time dashboards

---

# 🌱 Seed Data Included

The schema provides:

- 3 sample robots
- 1 sample vision detection
- 1 sample task

Useful for:

- Local testing
- Demo for recruiters
- API integration testing

---

# 🔐 Permissions

Currently granted to:

```sql
postgres
```

For production, it is recommended to:

- Create dedicated roles:
    - `robot_app_user`
    - `robot_readonly_user`

- Apply least-privilege principle

---

# 📈 Suggested Future Improvements

If scaling to production:

- Add TimescaleDB for telemetry time-series
- Add PostGIS for advanced geo queries
- Partition `system_logs` by date
- Add trigger for auto-update `updated_at`
- Add event-driven architecture (Kafka / Redis)

---

# 🧠 Architectural Philosophy

This database is designed with:

- Clean relational modeling
- Flexible JSON storage for AI outputs
- Constraint-based data validation
- High-performance partial indexing
- Production-ready extensibility

---

# 🚀 Use Cases

- Warehouse AGV management
- Factory robotic arms
- Smart logistics systems
- Vision-based automation
- Fleet monitoring dashboards
