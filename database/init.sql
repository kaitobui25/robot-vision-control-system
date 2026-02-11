-- ===========================
-- ROBOT VISION CONTROL SYSTEM
-- PostgreSQL 18 Database Schema
-- ===========================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============ TABLES ============
CREATE TABLE robots (
    robot_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    robot_name VARCHAR(100) NOT NULL,
    robot_type VARCHAR(50) NOT NULL,
    
    -- Status
    status VARCHAR(20) DEFAULT 'IDLE' 
        CHECK (status IN ('IDLE', 'RUNNING', 'ERROR', 'MAINTENANCE', 'CHARGING')),
    battery_level INT CHECK (battery_level BETWEEN 0 AND 100),
    
    -- Location (simple coordinates)
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    current_zone VARCHAR(50),
    
    -- Technical
    ip_address INET,
    
    -- Metrics
    total_distance_km DECIMAL(10,2) DEFAULT 0,
    error_count INT DEFAULT 0,
    last_error_timestamp TIMESTAMPTZ,
    
    -- Timestamps
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE vision_detections (
    detection_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    robot_id UUID REFERENCES robots(robot_id) ON DELETE CASCADE,
    
    image_path TEXT NOT NULL,
    detected_objects JSONB NOT NULL,
    confidence_threshold DECIMAL(3,2) DEFAULT 0.50,
    
    detection_timestamp TIMESTAMPTZ DEFAULT NOW(),
    processing_time_ms INT,
    model_version VARCHAR(20) NOT NULL
);

CREATE TABLE navigation_paths (
    path_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    robot_id UUID REFERENCES robots(robot_id) ON DELETE CASCADE,
    
    start_lat DECIMAL(10,7) NOT NULL,
    start_lng DECIMAL(10,7) NOT NULL,
    end_lat DECIMAL(10,7) NOT NULL,
    end_lng DECIMAL(10,7) NOT NULL,
    waypoints JSONB,
    
    path_status VARCHAR(20) DEFAULT 'PLANNED' 
        CHECK (path_status IN ('PLANNED', 'EXECUTING', 'COMPLETED', 'FAILED')),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

CREATE TABLE task_queue (
    task_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    robot_id UUID REFERENCES robots(robot_id) ON DELETE SET NULL,
    
    task_type VARCHAR(50) NOT NULL,
    task_data JSONB,
    priority INT DEFAULT 5 CHECK (priority BETWEEN 1 AND 10),
    
    status VARCHAR(20) DEFAULT 'PENDING' 
        CHECK (status IN ('PENDING', 'ASSIGNED', 'IN_PROGRESS', 'COMPLETED', 'FAILED', 'CANCELLED')),
    
    error_message TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    assigned_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ
);

CREATE TABLE system_logs (
    log_id BIGSERIAL PRIMARY KEY,
    log_level VARCHAR(10) NOT NULL 
        CHECK (log_level IN ('DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL')),
    source_service VARCHAR(50) NOT NULL,
    robot_id UUID REFERENCES robots(robot_id) ON DELETE SET NULL,
    
    message TEXT NOT NULL,
    additional_data JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============ INDEXES ============
CREATE INDEX idx_robots_status ON robots(status) WHERE is_active = TRUE;
CREATE INDEX idx_robots_zone ON robots(current_zone) WHERE is_active = TRUE;
CREATE INDEX idx_robots_battery ON robots(battery_level) WHERE battery_level < 30;

CREATE INDEX idx_vision_robot ON vision_detections(robot_id);
CREATE INDEX idx_vision_timestamp ON vision_detections(detection_timestamp DESC);

CREATE INDEX idx_nav_robot ON navigation_paths(robot_id);
CREATE INDEX idx_nav_created ON navigation_paths(created_at DESC);

CREATE INDEX idx_task_status ON task_queue(status) WHERE status IN ('PENDING', 'ASSIGNED');
CREATE INDEX idx_task_robot ON task_queue(robot_id) WHERE status != 'COMPLETED';
CREATE INDEX idx_task_priority ON task_queue(priority DESC, created_at ASC) WHERE status = 'PENDING';

CREATE INDEX idx_logs_robot ON system_logs(robot_id, created_at DESC) WHERE robot_id IS NOT NULL;
CREATE INDEX idx_logs_created ON system_logs(created_at DESC);
CREATE INDEX idx_logs_level ON system_logs(log_level);

-- ============ SEED DATA ============
INSERT INTO robots (
    robot_name, robot_type, battery_level,
    latitude, longitude, current_zone,
    ip_address, status
) VALUES
    ('Warehouse Bot 1', 'AGV', 85, 10.8, 106.8, 'WAREHOUSE_A', '192.168.1.101', 'IDLE'),
    ('Warehouse Bot 2', 'AGV', 92, 10.85, 106.85, 'LOADING_DOCK', '192.168.1.102', 'CHARGING'),
    ('Packaging Arm 1', 'ARM', 100, 10.82, 106.83, 'PACKAGING_ZONE', '192.168.1.103', 'RUNNING');

INSERT INTO vision_detections (robot_id, image_path, detected_objects, model_version)
VALUES (
    (SELECT robot_id FROM robots WHERE robot_name = 'Warehouse Bot 1'),
    '/images/warehouse_scan_001.jpg',
    '[{"class":"pallet","confidence":0.95,"bbox":[100,150,300,400]},{"class":"box","confidence":0.87,"bbox":[350,200,500,350]}]'::jsonb,
    'v1.2.0'
);

INSERT INTO task_queue (robot_id, task_type, task_data, priority, status)
VALUES (
    (SELECT robot_id FROM robots WHERE robot_name = 'Warehouse Bot 1'),
    'MOVE_TO_LOCATION',
    '{"target_zone":"LOADING_DOCK","target_lat":10.85,"target_lng":106.85}'::jsonb,
    8, 'PENDING'
);

-- ============ PERMISSIONS ============
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;