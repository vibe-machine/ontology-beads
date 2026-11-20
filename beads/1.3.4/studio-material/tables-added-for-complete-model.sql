-- Table definitions from Beads tag v1.3.4, internal/storage/schema/migrations/ (the files named below),
-- for the tables behind questions 24 to 46. Later migrations that add or drop columns are included.

-- ===== internal/storage/schema/migrations/0001_create_issues.up.sql =====
CREATE TABLE IF NOT EXISTS issues (
    id VARCHAR(255) PRIMARY KEY,
    content_hash VARCHAR(64),
    title VARCHAR(500) NOT NULL,
    description TEXT NOT NULL,
    design TEXT NOT NULL,
    acceptance_criteria TEXT NOT NULL,
    notes TEXT NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'open',
    priority INT NOT NULL DEFAULT 2,
    issue_type VARCHAR(32) NOT NULL DEFAULT 'task',
    assignee VARCHAR(255),
    estimated_minutes INT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255) DEFAULT '',
    owner VARCHAR(255) DEFAULT '',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    closed_at DATETIME,
    closed_by_session VARCHAR(255) DEFAULT '',
    external_ref VARCHAR(255),
    spec_id VARCHAR(1024),
    compaction_level INT DEFAULT 0,
    compacted_at DATETIME,
    compacted_at_commit VARCHAR(64),
    original_size INT,
    sender VARCHAR(255) DEFAULT '',
    ephemeral TINYINT(1) DEFAULT 0,
    wisp_type VARCHAR(32) DEFAULT '',
    pinned TINYINT(1) DEFAULT 0,
    is_template TINYINT(1) DEFAULT 0,
    mol_type VARCHAR(32) DEFAULT '',
    work_type VARCHAR(32) DEFAULT 'mutex',
    source_system VARCHAR(255) DEFAULT '',
    metadata JSON DEFAULT (JSON_OBJECT()),
    source_repo VARCHAR(512) DEFAULT '',
    close_reason TEXT DEFAULT '',
    event_kind VARCHAR(32) DEFAULT '',
    actor VARCHAR(255) DEFAULT '',
    target VARCHAR(255) DEFAULT '',
    payload TEXT DEFAULT '',
    await_type VARCHAR(32) DEFAULT '',
    await_id VARCHAR(255) DEFAULT '',
    timeout_ns BIGINT DEFAULT 0,
    waiters TEXT DEFAULT '',
    hook_bead VARCHAR(255) DEFAULT '',
    role_bead VARCHAR(255) DEFAULT '',
    agent_state VARCHAR(32) DEFAULT '',
    last_activity DATETIME,
    role_type VARCHAR(32) DEFAULT '',
    rig VARCHAR(255) DEFAULT '',
    due_at DATETIME,
    defer_until DATETIME,
    INDEX idx_issues_status (status),
    INDEX idx_issues_priority (priority),
    INDEX idx_issues_issue_type (issue_type),
    INDEX idx_issues_assignee (assignee),
    INDEX idx_issues_created_at (created_at),
    INDEX idx_issues_spec_id (spec_id),
    INDEX idx_issues_external_ref (external_ref)
);

-- ===== internal/storage/schema/migrations/0002_create_dependencies.up.sql =====
CREATE TABLE IF NOT EXISTS dependencies (
    issue_id VARCHAR(255) NOT NULL,
    depends_on_id VARCHAR(255) NOT NULL,
    type VARCHAR(32) NOT NULL DEFAULT 'blocks',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255) NOT NULL,
    metadata JSON DEFAULT (JSON_OBJECT()),
    thread_id VARCHAR(255) DEFAULT '',
    PRIMARY KEY (issue_id, depends_on_id),
    INDEX idx_dependencies_issue (issue_id),
    INDEX idx_dependencies_depends_on (depends_on_id),
    INDEX idx_dependencies_depends_on_type (depends_on_id, type),
    INDEX idx_dependencies_thread (thread_id),
    CONSTRAINT fk_dep_issue FOREIGN KEY (issue_id) REFERENCES issues(id) ON DELETE CASCADE
);

-- ===== internal/storage/schema/migrations/0012_create_routes.up.sql =====
CREATE TABLE IF NOT EXISTS routes (
    prefix VARCHAR(32) PRIMARY KEY,
    path VARCHAR(512) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ===== internal/storage/schema/migrations/0014_create_interactions.up.sql =====
CREATE TABLE IF NOT EXISTS interactions (
    id VARCHAR(32) PRIMARY KEY,
    kind VARCHAR(64) NOT NULL,
    created_at DATETIME NOT NULL,
    actor VARCHAR(255),
    issue_id VARCHAR(255),
    model VARCHAR(255),
    prompt TEXT,
    response TEXT,
    error TEXT,
    tool_name VARCHAR(255),
    exit_code INT,
    parent_id VARCHAR(32),
    label VARCHAR(64),
    reason TEXT,
    extra JSON,
    INDEX idx_interactions_kind (kind),
    INDEX idx_interactions_created_at (created_at),
    INDEX idx_interactions_issue_id (issue_id),
    INDEX idx_interactions_parent_id (parent_id)
);

-- ===== internal/storage/schema/migrations/0017_create_ready_issues_view.up.sql =====
CREATE OR REPLACE VIEW ready_issues AS
WITH RECURSIVE
  blocked_directly AS (
    SELECT DISTINCT d.issue_id
    FROM dependencies d
    WHERE d.type = 'blocks'
      AND EXISTS (
        SELECT 1 FROM issues blocker
        WHERE blocker.id = d.depends_on_id
          AND blocker.status NOT IN ('closed', 'pinned')
      )
  ),
  blocked_transitively AS (
    SELECT issue_id, 0 as depth
    FROM blocked_directly
    UNION ALL
    SELECT d.issue_id, bt.depth + 1
    FROM blocked_transitively bt
    JOIN dependencies d ON d.depends_on_id = bt.issue_id
    WHERE d.type = 'parent-child'
      AND bt.depth < 50
  )
SELECT i.*
FROM issues i
LEFT JOIN blocked_transitively bt ON bt.issue_id = i.id
WHERE i.status = 'open'
  AND (i.ephemeral = 0 OR i.ephemeral IS NULL)
  AND bt.issue_id IS NULL
  AND (i.defer_until IS NULL OR i.defer_until <= NOW())
  AND NOT EXISTS (
    SELECT 1 FROM dependencies d_parent
    JOIN issues parent ON parent.id = d_parent.depends_on_id
    WHERE d_parent.issue_id = i.id
      AND d_parent.type = 'parent-child'
      AND parent.defer_until IS NOT NULL
      AND parent.defer_until > NOW()
  );

-- ===== internal/storage/schema/migrations/0020_create_wisps.up.sql =====
CREATE TABLE IF NOT EXISTS wisps (
    id VARCHAR(255) PRIMARY KEY,
    content_hash VARCHAR(64),
    title VARCHAR(500) NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    design TEXT NOT NULL DEFAULT '',
    acceptance_criteria TEXT NOT NULL DEFAULT '',
    notes TEXT NOT NULL DEFAULT '',
    status VARCHAR(32) NOT NULL DEFAULT 'open',
    priority INT NOT NULL DEFAULT 2,
    issue_type VARCHAR(32) NOT NULL DEFAULT 'task',
    assignee VARCHAR(255),
    estimated_minutes INT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255) DEFAULT '',
    owner VARCHAR(255) DEFAULT '',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    closed_at DATETIME,
    closed_by_session VARCHAR(255) DEFAULT '',
    external_ref VARCHAR(255),
    spec_id VARCHAR(1024),
    compaction_level INT DEFAULT 0,
    compacted_at DATETIME,
    compacted_at_commit VARCHAR(64),
    original_size INT,
    sender VARCHAR(255) DEFAULT '',
    ephemeral TINYINT(1) DEFAULT 0,
    wisp_type VARCHAR(32) DEFAULT '',
    pinned TINYINT(1) DEFAULT 0,
    is_template TINYINT(1) DEFAULT 0,
    mol_type VARCHAR(32) DEFAULT '',
    work_type VARCHAR(32) DEFAULT 'mutex',
    source_system VARCHAR(255) DEFAULT '',
    metadata JSON DEFAULT (JSON_OBJECT()),
    source_repo VARCHAR(512) DEFAULT '',
    close_reason TEXT DEFAULT '',
    event_kind VARCHAR(32) DEFAULT '',
    actor VARCHAR(255) DEFAULT '',
    target VARCHAR(255) DEFAULT '',
    payload TEXT DEFAULT '',
    await_type VARCHAR(32) DEFAULT '',
    await_id VARCHAR(255) DEFAULT '',
    timeout_ns BIGINT DEFAULT 0,
    waiters TEXT DEFAULT '',
    hook_bead VARCHAR(255) DEFAULT '',
    role_bead VARCHAR(255) DEFAULT '',
    agent_state VARCHAR(32) DEFAULT '',
    last_activity DATETIME,
    role_type VARCHAR(32) DEFAULT '',
    rig VARCHAR(255) DEFAULT '',
    due_at DATETIME,
    defer_until DATETIME,
    INDEX idx_wisps_status (status),
    INDEX idx_wisps_priority (priority),
    INDEX idx_wisps_issue_type (issue_type),
    INDEX idx_wisps_assignee (assignee),
    INDEX idx_wisps_created_at (created_at),
    INDEX idx_wisps_spec_id (spec_id),
    INDEX idx_wisps_external_ref (external_ref)
);

-- ===== internal/storage/schema/migrations/0021_create_wisp_auxiliary.up.sql =====
CREATE TABLE IF NOT EXISTS wisp_labels (
    issue_id VARCHAR(255) NOT NULL,
    label VARCHAR(255) NOT NULL,
    PRIMARY KEY (issue_id, label),
    INDEX idx_wisp_labels_label (label)
);

CREATE TABLE IF NOT EXISTS wisp_dependencies (
    id CHAR(36) NOT NULL DEFAULT (UUID()) PRIMARY KEY,
    issue_id VARCHAR(255) NOT NULL,
    depends_on_issue_id VARCHAR(255) NULL,
    depends_on_wisp_id VARCHAR(255) NULL,
    depends_on_external VARCHAR(255) NULL,
    type VARCHAR(32) NOT NULL DEFAULT 'blocks',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255) DEFAULT '',
    metadata JSON DEFAULT (JSON_OBJECT()),
    thread_id VARCHAR(255) DEFAULT '',
    UNIQUE KEY uk_wisp_dep_issue_target (issue_id, depends_on_issue_id),
    UNIQUE KEY uk_wisp_dep_wisp_target (issue_id, depends_on_wisp_id),
    UNIQUE KEY uk_wisp_dep_external_target (issue_id, depends_on_external),
    INDEX idx_wisp_dep_type_issue (type, depends_on_issue_id),
    INDEX idx_wisp_dep_type_wisp (type, depends_on_wisp_id),
    INDEX idx_wisp_dep_type_external (type, depends_on_external),
    CONSTRAINT fk_wisp_dep_issue FOREIGN KEY (issue_id) REFERENCES wisps(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_wisp_dep_wisp_target FOREIGN KEY (depends_on_wisp_id) REFERENCES wisps(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_wisp_dep_issue_target FOREIGN KEY (depends_on_issue_id) REFERENCES issues(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT ck_wisp_dep_one_target CHECK ((depends_on_issue_id IS NOT NULL) + (depends_on_wisp_id IS NOT NULL) + (depends_on_external IS NOT NULL) = 1)
);

CREATE TABLE IF NOT EXISTS wisp_events (
    id CHAR(36) NOT NULL PRIMARY KEY DEFAULT (UUID()),
    issue_id VARCHAR(255) NOT NULL,
    event_type VARCHAR(32) NOT NULL,
    actor VARCHAR(255) DEFAULT '',
    old_value TEXT DEFAULT '',
    new_value TEXT DEFAULT '',
    comment TEXT DEFAULT '',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_wisp_events_issue (issue_id)
);

CREATE TABLE IF NOT EXISTS wisp_comments (
    id CHAR(36) NOT NULL PRIMARY KEY DEFAULT (UUID()),
    issue_id VARCHAR(255) NOT NULL,
    author VARCHAR(255) DEFAULT '',
    text TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_wisp_comments_issue (issue_id)
);

-- ===== internal/storage/schema/migrations/0022_wisp_dep_type_index.up.sql =====
SET @sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'wisp_dependencies') > 0,
    'CREATE INDEX IF NOT EXISTS idx_wisp_dep_type ON wisp_dependencies (type)',
    'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_split_targets = (
    SELECT COUNT(*) = 3
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'wisp_dependencies'
      AND COLUMN_NAME IN ('depends_on_issue_id', 'depends_on_wisp_id', 'depends_on_external')
);
SET @sql = IF(@has_split_targets,
    'CREATE INDEX IF NOT EXISTS idx_wisp_dep_type_issue ON wisp_dependencies (type, depends_on_issue_id)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@has_split_targets,
    'CREATE INDEX IF NOT EXISTS idx_wisp_dep_type_wisp ON wisp_dependencies (type, depends_on_wisp_id)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@has_split_targets,
    'CREATE INDEX IF NOT EXISTS idx_wisp_dep_type_external ON wisp_dependencies (type, depends_on_external)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ===== internal/storage/schema/migrations/0024_create_custom_status_type_tables.up.sql =====
CREATE TABLE IF NOT EXISTS custom_statuses (
    name VARCHAR(64) PRIMARY KEY,
    category VARCHAR(32) NOT NULL DEFAULT 'unspecified'
);

CREATE TABLE IF NOT EXISTS custom_types (
    name VARCHAR(64) PRIMARY KEY
);

-- ===== internal/storage/schema/migrations/0025_update_ready_issues_view.up.sql =====
CREATE OR REPLACE VIEW ready_issues AS
WITH RECURSIVE
  blocked_directly AS (
    SELECT DISTINCT d.issue_id
    FROM dependencies d
    WHERE d.type = 'blocks'
      AND EXISTS (
        SELECT 1 FROM issues blocker
        WHERE blocker.id = d.depends_on_id
          AND blocker.status NOT IN ('closed', 'pinned')
      )
  ),
  blocked_transitively AS (
    SELECT issue_id, 0 as depth
    FROM blocked_directly
    UNION ALL
    SELECT d.issue_id, bt.depth + 1
    FROM blocked_transitively bt
    JOIN dependencies d ON d.depends_on_id = bt.issue_id
    WHERE d.type = 'parent-child'
      AND bt.depth < 50
  )
SELECT i.*
FROM issues i
LEFT JOIN blocked_transitively bt ON bt.issue_id = i.id
WHERE (
    i.status = 'open'
    OR i.status IN (SELECT name FROM custom_statuses WHERE category = 'active')
  )
  AND (i.ephemeral = 0 OR i.ephemeral IS NULL)
  AND bt.issue_id IS NULL
  AND (i.defer_until IS NULL OR i.defer_until <= UTC_TIMESTAMP())
  AND NOT EXISTS (
    SELECT 1 FROM dependencies d_parent
    JOIN issues parent ON parent.id = d_parent.depends_on_id
    WHERE d_parent.issue_id = i.id
      AND d_parent.type = 'parent-child'
      AND parent.defer_until IS NOT NULL
      AND parent.defer_until > UTC_TIMESTAMP()
  );

-- ===== internal/storage/schema/migrations/0026_update_blocked_issues_view.up.sql =====
CREATE OR REPLACE VIEW blocked_issues AS
WITH done_frozen AS (
    SELECT name FROM custom_statuses WHERE category IN ('done', 'frozen')
)
SELECT
    i.*,
    (SELECT COUNT(*)
     FROM dependencies d
     WHERE d.issue_id = i.id
       AND d.type = 'blocks'
       AND EXISTS (
         SELECT 1 FROM issues blocker
         WHERE blocker.id = d.depends_on_id
           AND blocker.status NOT IN ('closed', 'pinned')
           AND blocker.status NOT IN (SELECT name FROM done_frozen)
       )
    ) as blocked_by_count
FROM issues i
WHERE i.status NOT IN ('closed', 'pinned')
  AND i.status NOT IN (SELECT name FROM done_frozen)
  AND EXISTS (
    SELECT 1 FROM dependencies d
    WHERE d.issue_id = i.id
      AND d.type = 'blocks'
      AND EXISTS (
        SELECT 1 FROM issues blocker
        WHERE blocker.id = d.depends_on_id
          AND blocker.status NOT IN ('closed', 'pinned')
          AND blocker.status NOT IN (SELECT name FROM done_frozen)
      )
  );

-- ===== internal/storage/schema/migrations/0034_add_spec_id_column.up.sql =====
-- spec_id column
SET @needs_add = (
    SELECT IF(COUNT(*) = 0, 1, 0)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'issues'
      AND COLUMN_NAME = 'spec_id'
);
SET @sql = IF(@needs_add = 1,
    'ALTER TABLE issues ADD COLUMN spec_id VARCHAR(1024)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- idx_issues_spec_id index
SET @needs_index = (
    SELECT IF(COUNT(*) = 0, 1, 0)
    FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'issues'
      AND INDEX_NAME = 'idx_issues_spec_id'
);
SET @sql = IF(@needs_index = 1,
    'CREATE INDEX idx_issues_spec_id ON issues(spec_id)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ===== internal/storage/schema/migrations/0035_migrate_infra_to_wisps.up.sql =====
SET @shared_cols = (
    SELECT GROUP_CONCAT(COLUMN_NAME ORDER BY ORDINAL_POSITION SEPARATOR ', ')
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'wisps'
      AND COLUMN_NAME IN (
          SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
          WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'issues'
      )
);
SET @sql = IF(@shared_cols IS NULL OR @shared_cols = '',
    'SELECT 1',
    CONCAT('INSERT IGNORE INTO wisps (', @shared_cols, ') SELECT ', @shared_cols,
           ' FROM issues WHERE issue_type IN (''agent'', ''rig'', ''role'', ''message'')')
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'wisps') > 0,
    'UPDATE wisps SET ephemeral = 1 WHERE issue_type IN (''agent'', ''rig'', ''role'', ''message'')',
    'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'wisp_labels') > 0,
    'INSERT IGNORE INTO wisp_labels (issue_id, label) SELECT l.issue_id, l.label FROM labels l JOIN issues i ON i.id = l.issue_id WHERE i.issue_type IN (''agent'', ''rig'', ''role'', ''message'')',
    'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_split_wisp_dependencies = (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'wisp_dependencies'
      AND COLUMN_NAME IN ('depends_on_issue_id', 'depends_on_wisp_id', 'depends_on_external')
);
SET @sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'wisp_dependencies') > 0,
    IF(
        @has_split_wisp_dependencies = 3,
        'INSERT IGNORE INTO wisp_dependencies (issue_id, depends_on_issue_id, depends_on_wisp_id, depends_on_external, type, created_at, created_by, metadata, thread_id) SELECT d.issue_id, CASE WHEN d.depends_on_id LIKE ''external:%'' THEN NULL WHEN EXISTS (SELECT 1 FROM wisps w WHERE w.id = d.depends_on_id) THEN NULL WHEN EXISTS (SELECT 1 FROM issues target_issue WHERE target_issue.id = d.depends_on_id) THEN d.depends_on_id ELSE NULL END, CASE WHEN d.depends_on_id LIKE ''external:%'' THEN NULL WHEN EXISTS (SELECT 1 FROM wisps w WHERE w.id = d.depends_on_id) THEN d.depends_on_id ELSE NULL END, CASE WHEN d.depends_on_id LIKE ''external:%'' THEN d.depends_on_id WHEN NOT EXISTS (SELECT 1 FROM wisps w WHERE w.id = d.depends_on_id) AND NOT EXISTS (SELECT 1 FROM issues target_issue WHERE target_issue.id = d.depends_on_id) THEN d.depends_on_id ELSE NULL END, d.type, d.created_at, d.created_by, d.metadata, d.thread_id FROM dependencies d JOIN issues i ON i.id = d.issue_id WHERE i.issue_type IN (''agent'', ''rig'', ''role'', ''message'')',
        'INSERT IGNORE INTO wisp_dependencies (issue_id, depends_on_id, type, created_at, created_by, metadata, thread_id) SELECT d.issue_id, d.depends_on_id, d.type, d.created_at, d.created_by, d.metadata, d.thread_id FROM dependencies d JOIN issues i ON i.id = d.issue_id WHERE i.issue_type IN (''agent'', ''rig'', ''role'', ''message'')'
    ),
    'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'wisp_events') > 0,
    'INSERT IGNORE INTO wisp_events (id, issue_id, event_type, actor, old_value, new_value, comment, created_at) SELECT e.id, e.issue_id, e.event_type, e.actor, e.old_value, e.new_value, e.comment, e.created_at FROM events e JOIN issues i ON i.id = e.issue_id WHERE i.issue_type IN (''agent'', ''rig'', ''role'', ''message'')',
    'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'wisp_comments') > 0,
    'INSERT IGNORE INTO wisp_comments (id, issue_id, author, text, created_at) SELECT c.id, c.issue_id, c.author, c.text, c.created_at FROM comments c JOIN issues i ON i.id = c.issue_id WHERE i.issue_type IN (''agent'', ''rig'', ''role'', ''message'')',
    'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'wisp_comments') > 0,
    'DELETE c FROM comments c JOIN issues i ON i.id = c.issue_id WHERE i.issue_type IN (''agent'', ''rig'', ''role'', ''message'')',
    'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'wisp_events') > 0,
    'DELETE e FROM events e JOIN issues i ON i.id = e.issue_id WHERE i.issue_type IN (''agent'', ''rig'', ''role'', ''message'')',
    'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'wisp_dependencies') > 0,
    'DELETE d FROM dependencies d JOIN issues i ON i.id = d.issue_id WHERE i.issue_type IN (''agent'', ''rig'', ''role'', ''message'')',
    'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'wisp_labels') > 0,
    'DELETE l FROM labels l JOIN issues i ON i.id = l.issue_id WHERE i.issue_type IN (''agent'', ''rig'', ''role'', ''message'')',
    'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'wisps') > 0,
    'DELETE FROM issues WHERE issue_type IN (''agent'', ''rig'', ''role'', ''message'')',
    'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ===== internal/storage/schema/migrations/0041_split_dependencies_target.up.sql =====
DELETE FROM dolt_nonlocal_tables;
CALL DOLT_COMMIT('-Am', 'disable nonlocal tables for fk migrations');
SET FOREIGN_KEY_CHECKS = 0;

SET @needs_drop_old_fk = (
    SELECT IF(COUNT(*) > 0, 1, 0)
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'dependencies'
      AND CONSTRAINT_NAME = 'fk_dep_depends_on'
);
SET @sql = IF(@needs_drop_old_fk = 1,
    'ALTER TABLE dependencies DROP FOREIGN KEY fk_dep_depends_on',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @needs_migrate = (
    SELECT IF(COUNT(*) = 0, 1, 0)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'dependencies'
      AND COLUMN_NAME = 'depends_on_wisp_id'
);

SET @sql = IF(@needs_migrate = 1,
    'ALTER TABLE dependencies ADD COLUMN depends_on_issue_id VARCHAR(255) NULL',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'ALTER TABLE dependencies ADD COLUMN depends_on_wisp_id VARCHAR(255) NULL',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'ALTER TABLE dependencies ADD COLUMN depends_on_external VARCHAR(255) NULL',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'UPDATE dependencies SET depends_on_external = depends_on_id WHERE depends_on_id LIKE ''external:%''',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @wisps_exists = (
    SELECT IF(COUNT(*) > 0, 1, 0)
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'wisps'
);
SET @sql = IF(@needs_migrate = 1 AND @wisps_exists = 1,
    'UPDATE dependencies d JOIN wisps w ON w.id = d.depends_on_id SET d.depends_on_wisp_id = d.depends_on_id WHERE d.depends_on_external IS NULL',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'UPDATE dependencies d JOIN issues i ON i.id = d.depends_on_id SET d.depends_on_issue_id = d.depends_on_id WHERE d.depends_on_external IS NULL AND d.depends_on_wisp_id IS NULL',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'UPDATE dependencies SET depends_on_external = depends_on_id WHERE depends_on_external IS NULL AND depends_on_wisp_id IS NULL AND depends_on_issue_id IS NULL',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'ALTER TABLE dependencies DROP INDEX idx_dependencies_depends_on',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'ALTER TABLE dependencies DROP INDEX idx_dependencies_depends_on_type',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'ALTER TABLE dependencies DROP PRIMARY KEY',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'ALTER TABLE dependencies DROP COLUMN depends_on_id',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- NOTE: the FK on depends_on_issue_id must be added BEFORE the generated
-- depends_on_id column exists. Dolt 2.0.6 rejects adding a foreign key on the
-- base column of a stored generated column (errno 1105). The final schema is
-- identical to adding it last.
SET @sql = IF(@needs_migrate = 1,
    'ALTER TABLE dependencies ADD CONSTRAINT fk_dep_issue_target FOREIGN KEY (depends_on_issue_id) REFERENCES issues(id) ON DELETE CASCADE ON UPDATE CASCADE',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'ALTER TABLE dependencies ADD COLUMN depends_on_id VARCHAR(255) AS (COALESCE(depends_on_issue_id, depends_on_wisp_id, depends_on_external)) STORED',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'ALTER TABLE dependencies ADD PRIMARY KEY (issue_id, depends_on_id)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'ALTER TABLE dependencies ADD INDEX idx_dep_wisp_target (depends_on_wisp_id)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'ALTER TABLE dependencies ADD INDEX idx_dep_issue_target (depends_on_issue_id)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'ALTER TABLE dependencies ADD INDEX idx_dep_external_target (depends_on_external)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'ALTER TABLE dependencies ADD INDEX idx_dep_type_target (type, depends_on_id)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'ALTER TABLE dependencies ADD CONSTRAINT ck_dep_one_target CHECK ((depends_on_issue_id IS NOT NULL) + (depends_on_wisp_id IS NOT NULL) + (depends_on_external IS NOT NULL) = 1)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET FOREIGN_KEY_CHECKS = 1;

-- ===== internal/storage/schema/migrations/0043_drop_dependencies_generated_column.up.sql =====
-- NOTE (gastownhall/beads#4259): this migration introduces the surrogate
-- `id CHAR(36) ... DEFAULT (UUID())` primary key below. UUID() is per-clone-random
-- and makes the dependencies table merge-unsafe across Dolt clones. The fix lives
-- in migration 0050 + the rekeyDependencyIDs backfill, which derive id
-- deterministically from (issue_id, target) and drop this random default. As a
-- belt-and-suspenders for clones that have NOT yet applied this migration, the
-- random default is also dropped at the end of this file, so a freshly migrated
-- clone reaches the no-default schema directly here rather than only at 0050.
SET FOREIGN_KEY_CHECKS = 0;

SET @needs_drop = (
    SELECT IF(COUNT(*) > 0, 1, 0)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'dependencies'
      AND COLUMN_NAME = 'depends_on_id'
);

SET @has_idx_type_target = (
    SELECT IF(COUNT(*) > 0, 1, 0)
    FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'dependencies'
      AND INDEX_NAME = 'idx_dep_type_target'
);

SET @sql = IF(@needs_drop = 1 AND @has_idx_type_target = 1,
    'ALTER TABLE dependencies DROP INDEX idx_dep_type_target',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_fk_issue_target = (
    SELECT IF(COUNT(*) > 0, 1, 0)
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'dependencies'
      AND CONSTRAINT_NAME = 'fk_dep_issue_target'
);
SET @sql = IF(@needs_drop = 1 AND @has_fk_issue_target = 1,
    'ALTER TABLE dependencies DROP FOREIGN KEY fk_dep_issue_target',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_fk_issue = (
    SELECT IF(COUNT(*) > 0, 1, 0)
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'dependencies'
      AND CONSTRAINT_NAME = 'fk_dep_issue'
);
SET @sql = IF(@needs_drop = 1 AND @has_fk_issue = 1,
    'ALTER TABLE dependencies DROP FOREIGN KEY fk_dep_issue',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_drop = 1,
    'ALTER TABLE dependencies DROP PRIMARY KEY',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_drop = 1,
    'ALTER TABLE dependencies DROP COLUMN depends_on_id',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_drop = 1,
    'ALTER TABLE dependencies ADD COLUMN id CHAR(36) NOT NULL DEFAULT (UUID()) PRIMARY KEY FIRST',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_drop = 1,
    'ALTER TABLE dependencies ADD UNIQUE KEY uk_dep_issue_target (issue_id, depends_on_issue_id)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_drop = 1,
    'ALTER TABLE dependencies ADD UNIQUE KEY uk_dep_wisp_target (issue_id, depends_on_wisp_id)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_drop = 1,
    'ALTER TABLE dependencies ADD UNIQUE KEY uk_dep_external_target (issue_id, depends_on_external)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_drop = 1,
    'ALTER TABLE dependencies ADD INDEX idx_dep_type_issue (type, depends_on_issue_id)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_drop = 1,
    'ALTER TABLE dependencies ADD INDEX idx_dep_type_wisp (type, depends_on_wisp_id)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_drop = 1,
    'ALTER TABLE dependencies ADD INDEX idx_dep_type_external (type, depends_on_external)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_drop = 1 AND @has_fk_issue = 1,
    'ALTER TABLE dependencies ADD CONSTRAINT fk_dep_issue FOREIGN KEY (issue_id) REFERENCES issues(id) ON DELETE CASCADE ON UPDATE CASCADE',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_drop = 1 AND @has_fk_issue_target = 1,
    'ALTER TABLE dependencies ADD CONSTRAINT fk_dep_issue_target FOREIGN KEY (depends_on_issue_id) REFERENCES issues(id) ON DELETE CASCADE ON UPDATE CASCADE',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- #4259: drop the per-clone-random DEFAULT (UUID()) so the application's
-- deterministic id (set explicitly at every insert site) is the only source of
-- the primary key. Guarded on COLUMN_DEFAULT so it is idempotent and a no-op when
-- the default is already gone (e.g. after migration 0050 has run). The existing
-- rows' transient random ids are rewritten by the rekeyDependencyIDs backfill.
SET @id_has_default = (
    SELECT IF(COUNT(*) > 0, 1, 0)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'dependencies'
      AND COLUMN_NAME = 'id'
      AND COLUMN_DEFAULT IS NOT NULL
);
SET @sql = IF(@id_has_default = 1,
    'ALTER TABLE dependencies ALTER COLUMN id DROP DEFAULT',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET FOREIGN_KEY_CHECKS = 1;

-- ===== internal/storage/schema/migrations/0044_update_views_drop_depends_on_id.up.sql =====
CREATE OR REPLACE VIEW ready_issues AS
WITH RECURSIVE
  blocked_directly AS (
    SELECT DISTINCT d.issue_id
    FROM dependencies d
    WHERE d.type = 'blocks'
      AND EXISTS (
        SELECT 1 FROM issues blocker
        WHERE blocker.id = d.depends_on_issue_id
          AND blocker.status NOT IN ('closed', 'pinned')
      )
  ),
  blocked_transitively AS (
    SELECT issue_id, 0 as depth
    FROM blocked_directly
    UNION ALL
    SELECT d.issue_id, bt.depth + 1
    FROM blocked_transitively bt
    JOIN dependencies d ON d.depends_on_issue_id = bt.issue_id
    WHERE d.type = 'parent-child'
      AND bt.depth < 50
  )
SELECT i.*
FROM issues i
LEFT JOIN blocked_transitively bt ON bt.issue_id = i.id
WHERE (
    i.status = 'open'
    OR i.status IN (SELECT name FROM custom_statuses WHERE category = 'active')
  )
  AND (i.ephemeral = 0 OR i.ephemeral IS NULL)
  AND bt.issue_id IS NULL
  AND (i.defer_until IS NULL OR i.defer_until <= UTC_TIMESTAMP())
  AND NOT EXISTS (
    SELECT 1 FROM dependencies d_parent
    JOIN issues parent ON parent.id = d_parent.depends_on_issue_id
    WHERE d_parent.issue_id = i.id
      AND d_parent.type = 'parent-child'
      AND parent.defer_until IS NOT NULL
      AND parent.defer_until > UTC_TIMESTAMP()
  );

-- ===== internal/storage/schema/migrations/0045_update_blocked_view_drop_depends_on_id.up.sql =====
CREATE OR REPLACE VIEW blocked_issues AS
WITH done_frozen AS (
    SELECT name FROM custom_statuses WHERE category IN ('done', 'frozen')
)
SELECT
    i.*,
    (SELECT COUNT(*)
     FROM dependencies d
     WHERE d.issue_id = i.id
       AND d.type = 'blocks'
       AND EXISTS (
         SELECT 1 FROM issues blocker
         WHERE blocker.id = d.depends_on_issue_id
           AND blocker.status NOT IN ('closed', 'pinned')
           AND blocker.status NOT IN (SELECT name FROM done_frozen)
       )
    ) as blocked_by_count
FROM issues i
WHERE i.status NOT IN ('closed', 'pinned')
  AND i.status NOT IN (SELECT name FROM done_frozen)
  AND EXISTS (
    SELECT 1 FROM dependencies d
    WHERE d.issue_id = i.id
      AND d.type = 'blocks'
      AND EXISTS (
        SELECT 1 FROM issues blocker
        WHERE blocker.id = d.depends_on_issue_id
          AND blocker.status NOT IN ('closed', 'pinned')
          AND blocker.status NOT IN (SELECT name FROM done_frozen)
      )
  );

-- ===== internal/storage/schema/migrations/0047_recompute_mixed_is_blocked.up.sql =====
SET FOREIGN_KEY_CHECKS = 0;

-- Some released 1.0.x databases have main schema migrations through 0046 but
-- have not yet run the ignored/local-table migration that splits
-- wisp_dependencies.depends_on_id into issue/wisp/external target columns.
-- This main migration reads those split columns below, so normalize the
-- ignored table first. The ignored 0003/0005 migrations are idempotent and
-- will no-op/drop the generated compatibility column afterwards.
SET @wisp_dependencies_needs_split = (
    SELECT IF(
        (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
         WHERE TABLE_SCHEMA = DATABASE()
           AND TABLE_NAME = 'wisp_dependencies'
           AND COLUMN_NAME = 'depends_on_id') > 0
        AND
        (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
         WHERE TABLE_SCHEMA = DATABASE()
           AND TABLE_NAME = 'wisp_dependencies'
           AND COLUMN_NAME = 'depends_on_wisp_id') = 0,
        1, 0)
);

SET @sql = IF(@wisp_dependencies_needs_split = 1,
    'ALTER TABLE wisp_dependencies ADD COLUMN depends_on_issue_id VARCHAR(255) NULL',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@wisp_dependencies_needs_split = 1,
    'ALTER TABLE wisp_dependencies ADD COLUMN depends_on_wisp_id VARCHAR(255) NULL',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@wisp_dependencies_needs_split = 1,
    'ALTER TABLE wisp_dependencies ADD COLUMN depends_on_external VARCHAR(255) NULL',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@wisp_dependencies_needs_split = 1,
    'UPDATE wisp_dependencies SET depends_on_external = depends_on_id WHERE depends_on_id LIKE ''external:%''',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@wisp_dependencies_needs_split = 1,
    'UPDATE wisp_dependencies wd JOIN wisps w ON w.id = wd.depends_on_id SET wd.depends_on_wisp_id = wd.depends_on_id WHERE wd.depends_on_external IS NULL',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@wisp_dependencies_needs_split = 1,
    'UPDATE wisp_dependencies wd JOIN issues i ON i.id = wd.depends_on_id SET wd.depends_on_issue_id = wd.depends_on_id WHERE wd.depends_on_external IS NULL AND wd.depends_on_wisp_id IS NULL',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@wisp_dependencies_needs_split = 1,
    'UPDATE wisp_dependencies SET depends_on_external = depends_on_id WHERE depends_on_external IS NULL AND depends_on_wisp_id IS NULL AND depends_on_issue_id IS NULL',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@wisp_dependencies_needs_split = 1,
    'ALTER TABLE wisp_dependencies DROP INDEX idx_wisp_dep_depends',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@wisp_dependencies_needs_split = 1,
    'ALTER TABLE wisp_dependencies DROP INDEX idx_wisp_dep_type_depends',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@wisp_dependencies_needs_split = 1,
    'ALTER TABLE wisp_dependencies DROP PRIMARY KEY',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@wisp_dependencies_needs_split = 1,
    'ALTER TABLE wisp_dependencies DROP COLUMN depends_on_id',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@wisp_dependencies_needs_split = 1,
    'ALTER TABLE wisp_dependencies ADD INDEX idx_wisp_dep_wisp_target (depends_on_wisp_id)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@wisp_dependencies_needs_split = 1,
    'ALTER TABLE wisp_dependencies ADD INDEX idx_wisp_dep_issue_target (depends_on_issue_id)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@wisp_dependencies_needs_split = 1,
    'ALTER TABLE wisp_dependencies ADD INDEX idx_wisp_dep_external_target (depends_on_external)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@wisp_dependencies_needs_split = 1,
    'ALTER TABLE wisp_dependencies ADD CONSTRAINT fk_wisp_dep_wisp_target FOREIGN KEY (depends_on_wisp_id) REFERENCES wisps(id) ON DELETE CASCADE ON UPDATE CASCADE',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@wisp_dependencies_needs_split = 1,
    'ALTER TABLE wisp_dependencies ADD CONSTRAINT fk_wisp_dep_issue_target FOREIGN KEY (depends_on_issue_id) REFERENCES issues(id) ON DELETE CASCADE ON UPDATE CASCADE',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@wisp_dependencies_needs_split = 1,
    'ALTER TABLE wisp_dependencies ADD CONSTRAINT ck_wisp_dep_one_target CHECK ((depends_on_issue_id IS NOT NULL) + (depends_on_wisp_id IS NOT NULL) + (depends_on_external IS NOT NULL) = 1)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@wisp_dependencies_needs_split = 1,
    'ALTER TABLE wisp_dependencies ADD COLUMN depends_on_id VARCHAR(255) AS (COALESCE(depends_on_issue_id, depends_on_wisp_id, depends_on_external)) STORED',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@wisp_dependencies_needs_split = 1,
    'ALTER TABLE wisp_dependencies ADD PRIMARY KEY (issue_id, depends_on_id)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@wisp_dependencies_needs_split = 1,
    'ALTER TABLE wisp_dependencies ADD INDEX idx_wisp_dep_type_target (type, depends_on_id)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@wisp_dependencies_needs_split = 1,
    'ALTER TABLE wisp_dependencies ADD CONSTRAINT fk_wisp_dep_issue FOREIGN KEY (issue_id) REFERENCES wisps(id) ON DELETE CASCADE ON UPDATE CASCADE',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET FOREIGN_KEY_CHECKS = 1;

UPDATE issues SET is_blocked = 0;

WITH RECURSIVE
  directly_blocked(kind, id) AS (
    SELECT DISTINCT 'issue', i.id
    FROM issues i
    WHERE i.status NOT IN ('closed', 'pinned')
      AND (
        EXISTS (
          SELECT 1
          FROM dependencies d
          JOIN issues t ON t.id = d.depends_on_issue_id
          WHERE d.issue_id = i.id
            AND d.type IN ('blocks', 'conditional-blocks')
            AND t.status NOT IN ('closed', 'pinned')
        )
        OR EXISTS (
          SELECT 1
          FROM dependencies d
          JOIN wisps t ON t.id = d.depends_on_wisp_id
          WHERE d.issue_id = i.id
            AND d.type IN ('blocks', 'conditional-blocks')
            AND t.status NOT IN ('closed', 'pinned')
        )
        OR EXISTS (
          SELECT 1
          FROM dependencies d
          WHERE d.issue_id = i.id
            AND d.type = 'waits-for'
            AND (
              EXISTS (
                SELECT 1
                FROM dependencies cd
                JOIN issues child ON child.id = cd.issue_id
                WHERE cd.type = 'parent-child'
                  AND (
                    (d.depends_on_issue_id IS NOT NULL AND cd.depends_on_issue_id = d.depends_on_issue_id)
                    OR (d.depends_on_wisp_id IS NOT NULL AND cd.depends_on_wisp_id = d.depends_on_wisp_id)
                  )
                  AND child.status NOT IN ('closed', 'pinned')
              )
              OR EXISTS (
                SELECT 1
                FROM wisp_dependencies cd
                JOIN wisps child ON child.id = cd.issue_id
                WHERE cd.type = 'parent-child'
                  AND (
                    (d.depends_on_issue_id IS NOT NULL AND cd.depends_on_issue_id = d.depends_on_issue_id)
                    OR (d.depends_on_wisp_id IS NOT NULL AND cd.depends_on_wisp_id = d.depends_on_wisp_id)
                  )
                  AND child.status NOT IN ('closed', 'pinned')
              )
            )
            AND NOT (
              JSON_UNQUOTE(JSON_EXTRACT(d.metadata, '$.gate')) = 'any-children'
              AND (
                EXISTS (
                  SELECT 1
                  FROM dependencies cd
                  JOIN issues child ON child.id = cd.issue_id
                  WHERE cd.type = 'parent-child'
                    AND (
                      (d.depends_on_issue_id IS NOT NULL AND cd.depends_on_issue_id = d.depends_on_issue_id)
                      OR (d.depends_on_wisp_id IS NOT NULL AND cd.depends_on_wisp_id = d.depends_on_wisp_id)
                    )
                    AND child.status = 'closed'
                )
                OR EXISTS (
                  SELECT 1
                  FROM wisp_dependencies cd
                  JOIN wisps child ON child.id = cd.issue_id
                  WHERE cd.type = 'parent-child'
                    AND (
                      (d.depends_on_issue_id IS NOT NULL AND cd.depends_on_issue_id = d.depends_on_issue_id)
                      OR (d.depends_on_wisp_id IS NOT NULL AND cd.depends_on_wisp_id = d.depends_on_wisp_id)
                    )
                    AND child.status = 'closed'
                )
              )
            )
        )
      )
    UNION
    SELECT DISTINCT 'wisp', w.id
    FROM wisps w
    WHERE w.status NOT IN ('closed', 'pinned')
      AND (
        EXISTS (
          SELECT 1
          FROM wisp_dependencies d
          JOIN issues t ON t.id = d.depends_on_issue_id
          WHERE d.issue_id = w.id
            AND d.type IN ('blocks', 'conditional-blocks')
            AND t.status NOT IN ('closed', 'pinned')
        )
        OR EXISTS (
          SELECT 1
          FROM wisp_dependencies d
          JOIN wisps t ON t.id = d.depends_on_wisp_id
          WHERE d.issue_id = w.id
            AND d.type IN ('blocks', 'conditional-blocks')
            AND t.status NOT IN ('closed', 'pinned')
        )
        OR EXISTS (
          SELECT 1
          FROM wisp_dependencies d
          WHERE d.issue_id = w.id
            AND d.type = 'waits-for'
            AND (
              EXISTS (
                SELECT 1
                FROM dependencies cd
                JOIN issues child ON child.id = cd.issue_id
                WHERE cd.type = 'parent-child'
                  AND (
                    (d.depends_on_issue_id IS NOT NULL AND cd.depends_on_issue_id = d.depends_on_issue_id)
                    OR (d.depends_on_wisp_id IS NOT NULL AND cd.depends_on_wisp_id = d.depends_on_wisp_id)
                  )
                  AND child.status NOT IN ('closed', 'pinned')
              )
              OR EXISTS (
                SELECT 1
                FROM wisp_dependencies cd
                JOIN wisps child ON child.id = cd.issue_id
                WHERE cd.type = 'parent-child'
                  AND (
                    (d.depends_on_issue_id IS NOT NULL AND cd.depends_on_issue_id = d.depends_on_issue_id)
                    OR (d.depends_on_wisp_id IS NOT NULL AND cd.depends_on_wisp_id = d.depends_on_wisp_id)
                  )
                  AND child.status NOT IN ('closed', 'pinned')
              )
            )
            AND NOT (
              JSON_UNQUOTE(JSON_EXTRACT(d.metadata, '$.gate')) = 'any-children'
              AND (
                EXISTS (
                  SELECT 1
                  FROM dependencies cd
                  JOIN issues child ON child.id = cd.issue_id
                  WHERE cd.type = 'parent-child'
                    AND (
                      (d.depends_on_issue_id IS NOT NULL AND cd.depends_on_issue_id = d.depends_on_issue_id)
                      OR (d.depends_on_wisp_id IS NOT NULL AND cd.depends_on_wisp_id = d.depends_on_wisp_id)
                    )
                    AND child.status = 'closed'
                )
                OR EXISTS (
                  SELECT 1
                  FROM wisp_dependencies cd
                  JOIN wisps child ON child.id = cd.issue_id
                  WHERE cd.type = 'parent-child'
                    AND (
                      (d.depends_on_issue_id IS NOT NULL AND cd.depends_on_issue_id = d.depends_on_issue_id)
                      OR (d.depends_on_wisp_id IS NOT NULL AND cd.depends_on_wisp_id = d.depends_on_wisp_id)
                    )
                    AND child.status = 'closed'
                )
              )
            )
        )
      )
  ),
  reachable(kind, id) AS (
    SELECT kind, id FROM directly_blocked
    UNION
    SELECT 'issue', d.issue_id
    FROM reachable r
    JOIN dependencies d
      ON d.type = 'parent-child'
     AND (
       (r.kind = 'issue' AND d.depends_on_issue_id = r.id)
       OR (r.kind = 'wisp' AND d.depends_on_wisp_id = r.id)
     )
    JOIN issues child ON child.id = d.issue_id
    WHERE child.status NOT IN ('closed', 'pinned')
    UNION
    SELECT 'wisp', d.issue_id
    FROM reachable r
    JOIN wisp_dependencies d
      ON d.type = 'parent-child'
     AND (
       (r.kind = 'issue' AND d.depends_on_issue_id = r.id)
       OR (r.kind = 'wisp' AND d.depends_on_wisp_id = r.id)
     )
    JOIN wisps child ON child.id = d.issue_id
    WHERE child.status NOT IN ('closed', 'pinned')
  )
UPDATE issues
SET is_blocked = 1
WHERE id IN (SELECT id FROM reachable WHERE kind = 'issue')
  AND status NOT IN ('closed', 'pinned');

-- ===== internal/storage/schema/migrations/0050_dependencies_deterministic_id.up.sql =====
-- Migration 0050: make dependencies.id a clone-stable, merge-safe primary key.
--
-- gastownhall/beads#4259. Migration 0043 gave the dependencies table a surrogate
-- primary key `id CHAR(36) NOT NULL DEFAULT (UUID())`. UUID() is per-clone-random,
-- so two clones that create the same logical edge -- or that apply 0043
-- independently -- end up with the same row under two different primary keys.
-- Dolt then either refuses the merge ("cannot merge because table dependencies
-- has different primary keys in its common ancestor") or pulls in both rows and
-- trips the uk_dep_* unique keys. Either way `bd dolt pull` breaks with no
-- bd-level recovery.
--
-- The application now derives id deterministically from the natural edge key
-- (issue_id, target) at every insert site, and the upgrade backfill
-- (rekeyDependencyIDs, run from MigrateUp right after this migration) rewrites
-- existing rows' random ids to the deterministic value. This migration does the
-- *schema* half, and is the convergence point every clone reaches when upgrading
-- to the fixed release, whatever its 0043 outcome:
--
--   (1) Drop the random DEFAULT so any future insert that forgets to set id
--       fails loudly (NOT NULL violation) instead of silently re-forking the key.
--   (2) Idempotently re-assert the natural-identity unique keys so a clone whose
--       0043 no-opped on a divergent pre-state converges to the same schema.
--
-- It is intentionally unconditional and idempotent (safe to re-run): it does not
-- probe whether 0043 ran a particular branch, it just asserts the canonical end
-- state. wisp_dependencies is deliberately left alone here: it is dolt-ignored
-- (never merged) and recreated from its 0021 definition by EnsureIgnoredTables,
-- so its (dormant) default cannot be durably dropped by a migration; all wisp
-- insert sites set id explicitly and the backfill re-keys its existing rows.

SET FOREIGN_KEY_CHECKS = 0;

-- (1) Drop the per-clone-random surrogate default. Guarded on COLUMN_DEFAULT so
-- re-running (or running on a clone that never had the default) is a no-op.
SET @has_default = (
    SELECT IF(COUNT(*) > 0, 1, 0)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'dependencies'
      AND COLUMN_NAME = 'id'
      AND COLUMN_DEFAULT IS NOT NULL
);
SET @sql = IF(@has_default = 1,
    'ALTER TABLE dependencies ALTER COLUMN id DROP DEFAULT',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- (2) Re-assert the natural-identity unique keys. These already exist after a
-- normal 0043; IF NOT EXISTS makes re-running harmless and repairs a clone whose
-- 0043 branch left one missing. (issue_id, <one typed target>) is the identity
-- the deterministic id is derived from; `type` is deliberately not part of it.
CREATE UNIQUE INDEX IF NOT EXISTS uk_dep_issue_target ON dependencies (issue_id, depends_on_issue_id);
CREATE UNIQUE INDEX IF NOT EXISTS uk_dep_wisp_target ON dependencies (issue_id, depends_on_wisp_id);
CREATE UNIQUE INDEX IF NOT EXISTS uk_dep_external_target ON dependencies (issue_id, depends_on_external);

SET FOREIGN_KEY_CHECKS = 1;

-- ===== internal/storage/schema/migrations/0052_add_date_indexes.up.sql =====
-- Replace the single-column status index with a (status, updated_at) composite
-- and add a defer_until index (D4v2 query plan). Guarded against the current
-- schema so the migration is idempotent: a clone may have its schema_migrations
-- row for this version regressed without its DDL rolled back (see bd-4mpy7
-- remote_behind_schema_gates), in which case the designated migrator re-applies
-- this file and it must not error on already-present/already-absent indexes.

-- Drop the old single-column status index only if it is still present.
SET @has_old = (
    SELECT IF(COUNT(*) > 0, 1, 0)
    FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'issues'
      AND INDEX_NAME = 'idx_issues_status'
);
SET @sql = IF(@has_old = 1, 'DROP INDEX idx_issues_status ON issues', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Create the (status, updated_at) composite index only if missing.
SET @needs_su = (
    SELECT IF(COUNT(*) = 0, 1, 0)
    FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'issues'
      AND INDEX_NAME = 'idx_issues_status_updated_at'
);
SET @sql = IF(@needs_su = 1, 'CREATE INDEX idx_issues_status_updated_at ON issues (status, updated_at)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Create the defer_until index only if missing.
SET @needs_du = (
    SELECT IF(COUNT(*) = 0, 1, 0)
    FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'issues'
      AND INDEX_NAME = 'idx_issues_defer_until'
);
SET @sql = IF(@needs_du = 1, 'CREATE INDEX idx_issues_defer_until ON issues (defer_until)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ===== internal/storage/schema/migrations/0053_repair_rig_wisps.up.sql =====
-- Repair rig identity beads that earlier defaults routed into the ephemeral
-- wisps tier. Rig beads are durable issue state: keep type=rig hidden from
-- ready work in application code, but promote existing rows back to issues.
--
-- Main migrations can run before clone-local ignored migrations have
-- materialized wisp tables in older workspaces. Treat that state as a no-op:
-- there are no local rig wisps to repair yet, and ignored migrations will
-- create the local tables later in the same pass.

SET FOREIGN_KEY_CHECKS = 0;

SET @has_wisps = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'wisps'
);
SET @has_wisp_labels = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'wisp_labels'
);
SET @has_wisp_dependencies = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'wisp_dependencies'
);
SET @has_wisp_dependencies_id = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'wisp_dependencies'
      AND COLUMN_NAME = 'id'
);
SET @has_wisp_events = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'wisp_events'
);
SET @has_wisp_comments = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'wisp_comments'
);
SET @has_wisp_child_counters = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'wisp_child_counters'
);

SET @sql = IF(@has_wisps > 0,
    'INSERT IGNORE INTO issues (id, content_hash, title, description, design, acceptance_criteria, notes, status, priority, issue_type, assignee, estimated_minutes, created_at, created_by, owner, updated_at, closed_at, closed_by_session, external_ref, spec_id, compaction_level, compacted_at, compacted_at_commit, original_size, sender, ephemeral, wisp_type, pinned, is_template, mol_type, work_type, source_system, metadata, source_repo, close_reason, event_kind, actor, target, payload, await_type, await_id, timeout_ns, waiters, hook_bead, role_bead, agent_state, last_activity, role_type, rig, due_at, defer_until, no_history, started_at) SELECT id, content_hash, title, description, design, acceptance_criteria, notes, status, priority, issue_type, assignee, estimated_minutes, created_at, created_by, owner, updated_at, closed_at, closed_by_session, external_ref, spec_id, compaction_level, compacted_at, compacted_at_commit, original_size, sender, ephemeral, wisp_type, pinned, is_template, mol_type, work_type, source_system, metadata, source_repo, close_reason, event_kind, actor, target, payload, await_type, await_id, timeout_ns, waiters, hook_bead, role_bead, agent_state, last_activity, role_type, rig, due_at, defer_until, no_history, started_at FROM wisps WHERE issue_type = ''rig''',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@has_wisps > 0,
    'UPDATE issues SET ephemeral = 0 WHERE issue_type = ''rig'' AND id IN (SELECT id FROM wisps WHERE issue_type = ''rig'')',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@has_wisps > 0 AND @has_wisp_labels > 0,
    'INSERT IGNORE INTO labels (issue_id, label) SELECT wl.issue_id, wl.label FROM wisp_labels wl JOIN wisps w ON w.id = wl.issue_id WHERE w.issue_type = ''rig''',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@has_wisps > 0 AND @has_wisp_dependencies > 0,
    IF(@has_wisp_dependencies_id > 0,
        'INSERT IGNORE INTO dependencies (id, issue_id, depends_on_issue_id, depends_on_wisp_id, depends_on_external, type, created_at, created_by, metadata, thread_id) SELECT wd.id, wd.issue_id, wd.depends_on_issue_id, wd.depends_on_wisp_id, wd.depends_on_external, wd.type, wd.created_at, wd.created_by, wd.metadata, wd.thread_id FROM wisp_dependencies wd JOIN wisps w ON w.id = wd.issue_id WHERE w.issue_type = ''rig''',
        'INSERT IGNORE INTO dependencies (id, issue_id, depends_on_issue_id, depends_on_wisp_id, depends_on_external, type, created_at, created_by, metadata, thread_id) SELECT CONCAT(SUBSTR(MD5(CONCAT(wd.issue_id, CHAR(31), COALESCE(wd.depends_on_issue_id, wd.depends_on_wisp_id, wd.depends_on_external))), 1, 8), ''-'', SUBSTR(MD5(CONCAT(wd.issue_id, CHAR(31), COALESCE(wd.depends_on_issue_id, wd.depends_on_wisp_id, wd.depends_on_external))), 9, 4), ''-'', SUBSTR(MD5(CONCAT(wd.issue_id, CHAR(31), COALESCE(wd.depends_on_issue_id, wd.depends_on_wisp_id, wd.depends_on_external))), 13, 4), ''-'', SUBSTR(MD5(CONCAT(wd.issue_id, CHAR(31), COALESCE(wd.depends_on_issue_id, wd.depends_on_wisp_id, wd.depends_on_external))), 17, 4), ''-'', SUBSTR(MD5(CONCAT(wd.issue_id, CHAR(31), COALESCE(wd.depends_on_issue_id, wd.depends_on_wisp_id, wd.depends_on_external))), 21, 12)), wd.issue_id, wd.depends_on_issue_id, wd.depends_on_wisp_id, wd.depends_on_external, wd.type, wd.created_at, wd.created_by, wd.metadata, wd.thread_id FROM wisp_dependencies wd JOIN wisps w ON w.id = wd.issue_id WHERE w.issue_type = ''rig'''
    ),
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@has_wisps > 0 AND @has_wisp_events > 0,
    'INSERT IGNORE INTO events (id, issue_id, event_type, actor, old_value, new_value, comment, created_at) SELECT we.id, we.issue_id, we.event_type, we.actor, we.old_value, we.new_value, we.comment, we.created_at FROM wisp_events we JOIN wisps w ON w.id = we.issue_id WHERE w.issue_type = ''rig''',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@has_wisps > 0 AND @has_wisp_comments > 0,
    'INSERT IGNORE INTO comments (id, issue_id, author, text, created_at) SELECT wc.id, wc.issue_id, wc.author, wc.text, wc.created_at FROM wisp_comments wc JOIN wisps w ON w.id = wc.issue_id WHERE w.issue_type = ''rig''',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@has_wisps > 0 AND @has_wisp_child_counters > 0,
    'INSERT IGNORE INTO child_counters (parent_id, last_child) SELECT wcc.parent_id, wcc.last_child FROM wisp_child_counters wcc JOIN wisps w ON w.id = wcc.parent_id WHERE w.issue_type = ''rig''',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@has_wisps > 0 AND @has_wisp_child_counters > 0,
    'UPDATE child_counters cc JOIN wisp_child_counters wcc ON wcc.parent_id = cc.parent_id JOIN wisps w ON w.id = wcc.parent_id SET cc.last_child = GREATEST(cc.last_child, wcc.last_child) WHERE w.issue_type = ''rig''',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@has_wisps > 0 AND @has_wisp_dependencies > 0,
    'DELETE wd FROM wisp_dependencies wd JOIN wisps w ON w.id = wd.issue_id WHERE w.issue_type = ''rig''',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@has_wisps > 0,
    'REPLACE INTO dependencies (id, issue_id, depends_on_issue_id, depends_on_wisp_id, depends_on_external, type, created_at, created_by, metadata, thread_id) SELECT d.id, d.issue_id, d.depends_on_wisp_id, NULL, d.depends_on_external, d.type, d.created_at, d.created_by, d.metadata, d.thread_id FROM dependencies d JOIN wisps w ON w.id = d.depends_on_wisp_id WHERE w.issue_type = ''rig''',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@has_wisps > 0 AND @has_wisp_dependencies > 0,
    IF(@has_wisp_dependencies_id > 0,
        'REPLACE INTO wisp_dependencies (id, issue_id, depends_on_issue_id, depends_on_wisp_id, depends_on_external, type, created_at, created_by, metadata, thread_id) SELECT wd.id, wd.issue_id, wd.depends_on_wisp_id, NULL, wd.depends_on_external, wd.type, wd.created_at, wd.created_by, wd.metadata, wd.thread_id FROM wisp_dependencies wd JOIN wisps w ON w.id = wd.depends_on_wisp_id WHERE w.issue_type = ''rig''',
        'REPLACE INTO wisp_dependencies (issue_id, depends_on_issue_id, depends_on_wisp_id, depends_on_external, type, created_at, created_by, metadata, thread_id) SELECT wd.issue_id, wd.depends_on_wisp_id, NULL, wd.depends_on_external, wd.type, wd.created_at, wd.created_by, wd.metadata, wd.thread_id FROM wisp_dependencies wd JOIN wisps w ON w.id = wd.depends_on_wisp_id WHERE w.issue_type = ''rig'''
    ),
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@has_wisps > 0 AND @has_wisp_labels > 0,
    'DELETE wl FROM wisp_labels wl JOIN wisps w ON w.id = wl.issue_id WHERE w.issue_type = ''rig''',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@has_wisps > 0 AND @has_wisp_events > 0,
    'DELETE we FROM wisp_events we JOIN wisps w ON w.id = we.issue_id WHERE w.issue_type = ''rig''',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@has_wisps > 0 AND @has_wisp_comments > 0,
    'DELETE wc FROM wisp_comments wc JOIN wisps w ON w.id = wc.issue_id WHERE w.issue_type = ''rig''',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@has_wisps > 0 AND @has_wisp_child_counters > 0,
    'DELETE wcc FROM wisp_child_counters wcc JOIN wisps w ON w.id = wcc.parent_id WHERE w.issue_type = ''rig''',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@has_wisps > 0,
    'DELETE FROM wisps WHERE issue_type = ''rig''',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET FOREIGN_KEY_CHECKS = 1;

-- ===== internal/storage/schema/migrations/0054_add_lease_columns.up.sql =====
-- Dead-worker recovery (Gas Station v1.1, wy-5r9j): give a claim a lease.
--
-- A claim was previously permanent — a worker that died mid-task stranded its
-- issue in_progress forever. These columns let a claim expire:
--
--   lease_expires_at  the wall-clock instant after which the claim is stale and
--                     a reaper (bd reclaim) may revert the issue to ready.
--   heartbeat_at      the last time the lease owner proved it was still alive.
--   row_lock          a random BIGINT rewritten by EVERY mutating path on the
--                     row. Dolt has no real row locking and merges concurrent
--                     writes cell-by-cell, so a heartbeat (touching heartbeat_at)
--                     and a close (touching status) would otherwise silently
--                     cell-merge instead of conflicting. Forcing every writer to
--                     also rewrite this one shared cell turns those into a
--                     1213/1205 serialization conflict that withRetryTx replays —
--                     the difference between exactly-once and a lost close.
--
-- Guarded so the migration is idempotent on a schema_migrations row that
-- regressed without its DDL rolled back (see 0052/0046). assignee doubles as the
-- lease owner; no new owner column is needed.

-- issues.lease_expires_at
SET @needs_add = (
    SELECT IF(COUNT(*) = 0, 1, 0)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'issues'
      AND COLUMN_NAME = 'lease_expires_at'
);
SET @sql = IF(@needs_add = 1,
    'ALTER TABLE issues ADD COLUMN lease_expires_at DATETIME',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- issues.heartbeat_at
SET @needs_add = (
    SELECT IF(COUNT(*) = 0, 1, 0)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'issues'
      AND COLUMN_NAME = 'heartbeat_at'
);
SET @sql = IF(@needs_add = 1,
    'ALTER TABLE issues ADD COLUMN heartbeat_at DATETIME',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- issues.row_lock
SET @needs_add = (
    SELECT IF(COUNT(*) = 0, 1, 0)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'issues'
      AND COLUMN_NAME = 'row_lock'
);
SET @sql = IF(@needs_add = 1,
    'ALTER TABLE issues ADD COLUMN row_lock BIGINT NOT NULL DEFAULT 0',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- idx_issues_lease: the reaper scans in_progress issues by lease_expires_at.
SET @needs_index = (
    SELECT IF(COUNT(*) = 0, 1, 0)
    FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'issues'
      AND INDEX_NAME = 'idx_issues_lease'
);
SET @sql = IF(@needs_index = 1,
    'CREATE INDEX idx_issues_lease ON issues (status, lease_expires_at)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- wisps mirror the issues lease columns so the shared issueops claim/heartbeat
-- SQL (which routes by table name) works uniformly. Wisps are ephemeral and are
-- never reclaimed, but the columns must exist for the shared UPDATEs to bind.
-- Guarded on the wisps table existing (older workspaces created issues-only).
SET @has_wisps = (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'wisps'
);

SET @needs_add = IF(@has_wisps > 0 AND
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'wisps'
          AND COLUMN_NAME = 'lease_expires_at') = 0,
    1, 0);
SET @sql = IF(@needs_add = 1,
    'ALTER TABLE wisps ADD COLUMN lease_expires_at DATETIME',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @needs_add = IF(@has_wisps > 0 AND
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'wisps'
          AND COLUMN_NAME = 'heartbeat_at') = 0,
    1, 0);
SET @sql = IF(@needs_add = 1,
    'ALTER TABLE wisps ADD COLUMN heartbeat_at DATETIME',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @needs_add = IF(@has_wisps > 0 AND
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'wisps'
          AND COLUMN_NAME = 'row_lock') = 0,
    1, 0);
SET @sql = IF(@needs_add = 1,
    'ALTER TABLE wisps ADD COLUMN row_lock BIGINT NOT NULL DEFAULT 0',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ===== internal/storage/schema/migrations/0055_move_leases_to_table.up.sql =====
-- Move claim leases out of the versioned issues table into an ephemeral
-- leases table (bd-lrgn1).
--
-- lease_expires_at / heartbeat_at as issues columns meant every claim and
-- every heartbeat was an issues-row UPDATE -> a Dolt commit. At fleet scale
-- that coordination chatter was the dominant source of unbounded reachable
-- history and of the constant write traffic that starves large catch-up
-- merges. The new leases table is registered dolt_ignored (seeded by
-- MigrateUp's doltIgnorePatterns before this migration runs), so claims mint
-- exactly one commit (the status/assignee transition — history-worthy) and
-- heartbeats mint none.
--
-- Leases are deliberately node-local: dolt_ignored tables do not replicate,
-- which matches what leases already were in reality — only enforceable on the
-- replica that granted them. Cross-machine claim VISIBILITY still rides
-- status/assignee on issues. row_lock STAYS on issues/wisps: it is the
-- general write-serialization cell for status/ownership races, not a lease
-- column (see issueops/lease.go freshRowLock).
--
-- Fresh clones never run this migration (the schema_migrations cursor arrives
-- at-latest); they materialize the leases table via ignored migration 0012.
-- Everything here is guarded so a re-run, or a run against a workspace in any
-- intermediate state, is a no-op (see 0052/0046 precedent).

-- 1. Create the leases table if this workspace does not have one yet. The
-- __temp__ + conditional RENAME dance (see ignored/0001) keeps the CREATE
-- idempotent; __temp__leases never survives this migration step.
DROP TABLE IF EXISTS __temp__leases;
CREATE TABLE __temp__leases (
    issue_id VARCHAR(255) PRIMARY KEY,
    holder VARCHAR(255) NOT NULL,
    granted_at DATETIME NOT NULL,
    lease_expires_at DATETIME NOT NULL,
    heartbeat_at DATETIME NOT NULL,
    INDEX idx_leases_expires (lease_expires_at)
);
SET @exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'leases');
SET @sql = IF(@exists = 0, 'RENAME TABLE __temp__leases TO leases', 'DROP TABLE __temp__leases');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 2. Move live lease values out of the issues columns. Only rows that are an
-- actual live claim carry a lease; granted_at/heartbeat_at fall back to
-- updated_at when heartbeat_at was never stamped. INSERT IGNORE: an existing
-- lease row (e.g. from a partially-applied earlier run) wins.
SET @has_col = (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'issues'
      AND COLUMN_NAME = 'lease_expires_at'
);
SET @sql = IF(@has_col > 0,
    'INSERT IGNORE INTO leases (issue_id, holder, granted_at, lease_expires_at, heartbeat_at)
     SELECT id, assignee, COALESCE(heartbeat_at, updated_at), lease_expires_at, COALESCE(heartbeat_at, updated_at)
     FROM issues
     WHERE lease_expires_at IS NOT NULL
       AND status = ''in_progress''
       AND COALESCE(assignee, '''') != ''''',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 3. Drop the lease index and columns from issues. One combined ALTER (each
-- ALTER is a table rewrite; fresh chains run 0054 add + 0055 drop, so keep
-- this cheap). Clauses are guarded individually so a partially-applied
-- earlier run re-runs as a no-op.
SET @has_index = (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'issues'
      AND INDEX_NAME = 'idx_issues_lease'
);
SET @has_lease_col = (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'issues'
      AND COLUMN_NAME = 'lease_expires_at'
);
SET @has_hb_col = (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'issues'
      AND COLUMN_NAME = 'heartbeat_at'
);
SET @clauses = CONCAT_WS(', ',
    IF(@has_index > 0, 'DROP INDEX idx_issues_lease', NULL),
    IF(@has_lease_col > 0, 'DROP COLUMN lease_expires_at', NULL),
    IF(@has_hb_col > 0, 'DROP COLUMN heartbeat_at', NULL));
SET @sql = IF(@clauses = '', 'SELECT 1', CONCAT('ALTER TABLE issues ', @clauses));
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 4. Drop the (never-reclaimed, now entirely unread) lease columns from wisps.
-- Wisps are never leased work; their claims get no lease row. row_lock stays:
-- the shared claim/close/update SQL still rewrites it on wisps rows. Guarded
-- on the wisps table existing AND carrying the columns — fresh clones build
-- wisps from ignored/0001, which never had them.
SET @has_wisps = (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'wisps'
);

SET @has_lease_col = IF(@has_wisps > 0,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'wisps'
          AND COLUMN_NAME = 'lease_expires_at'),
    0);
SET @has_hb_col = IF(@has_wisps > 0,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'wisps'
          AND COLUMN_NAME = 'heartbeat_at'),
    0);
SET @clauses = CONCAT_WS(', ',
    IF(@has_lease_col > 0, 'DROP COLUMN lease_expires_at', NULL),
    IF(@has_hb_col > 0, 'DROP COLUMN heartbeat_at', NULL));
SET @sql = IF(@clauses = '', 'SELECT 1', CONCAT('ALTER TABLE wisps ', @clauses));
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ===== internal/storage/schema/migrations/0058_heal_wisp_dependencies_split_constraints.up.sql =====
-- Migration 0058: heal wisp_dependencies constraints missed by the 0047
-- delegate repair path (#4555 residual, mybd-mq9b, discovered while closing
-- gastownhall/beads#4878's review coverage gaps).
--
-- migration_repairs.go's ensureWispDependenciesSplitTargets (dispatched from
-- 0047's preMigrationRepair when wisps AND wisp_dependencies both already
-- exist -- the "delegate" branch, as opposed to recreating either table from
-- scratch) adds wisp_dependencies' three split-target columns
-- (depends_on_issue_id/depends_on_wisp_id/depends_on_external) and backfills
-- them from the legacy depends_on_id column, but does not add the
-- fk_wisp_dep_wisp_target/fk_wisp_dep_issue_target foreign keys or the
-- ck_wisp_dep_one_target CHECK constraint those columns need. Those three
-- constraints are added by two OTHER migrations, but both only fire under
-- conditions the delegate path itself defeats:
--   - ignored/0003_split_wisp_dependencies_target's own inline split (which
--     adds all three) is gated on depends_on_wisp_id being ABSENT; the
--     delegate already added it, so 0003 takes its no-op branch.
--   - ignored/0005_drop_wisp_dependencies_generated_column only RESTORES a
--     foreign key if it detects that exact constraint present BEFORE its own
--     drop of depends_on_id; a genuinely legacy (pre-split) table never had
--     fk_wisp_dep_wisp_target/fk_wisp_dep_issue_target to begin with (their
--     target columns did not exist yet), so there is nothing for 0005 to
--     detect and restore.
--
-- The net effect: any database that takes the delegate path converges
-- structurally (columns, surrogate id, primary key, unique keys) but
-- silently ends up permanently missing two foreign keys and the one-target
-- CHECK constraint. Migration 0047, ignored/0003, and ignored/0005 are all
-- shipped and frozen (scripts/check-migration-hygiene.sh Check C forbids
-- editing a migration file that already exists on main), and a database
-- already affected has its schema_migrations cursor sitting at latest --
-- fixing only the forward-path files could never reach it, since none of
-- them are pending on that database again. A new, idempotent migration is
-- the only way to heal databases already in this state, matching the
-- 0053/0057 repair-migration precedent from the migration-chain-hardening
-- branch (#4878).
--
-- Each constraint is guarded independently by its own INFORMATION_SCHEMA
-- checks (constraint absent, and its required table/columns present) so
-- this safely no-ops on every population: a fresh-recreate-path database
-- (constraints already present from creation) or a database that already
-- carries them (idempotent replay) sees no-ops on all three; a
-- delegate-path database sees exactly the missing ones added; and a
-- database whose wisp_dependencies table (or a required column) is for any
-- other reason absent by the time this migration runs is left untouched
-- rather than assumed into a shape it may not have.
--
-- Adding a constraint over data that accumulated during the window it was
-- missing is exactly the failure class ignored/0011 (#4534) documents:
-- foreign keys re-added under FOREIGN_KEY_CHECKS = 0 accept whatever
-- orphaned rows are already there, and "Dolt then fails constraint
-- validation on subsequent writes, so one legacy orphan bricks every bd
-- create on an otherwise healthy database." The delegate path's
-- unconstrained window can leave two more classes of row that would abort a
-- later PREPARE'd ADD CONSTRAINT the same way, so this migration cleans up
-- both, immediately before the constraint that would otherwise reject them,
-- mirroring ignored/0011's guarded LEFT JOIN idiom:
--
--   1. FK orphans (before the two ADD CONSTRAINT ... FOREIGN KEY below): a
--      depends_on_wisp_id/depends_on_issue_id pointing at a row that no
--      longer exists (deleted while no CASCADE was in force). DELETE the
--      whole row -- exactly what ON DELETE CASCADE would have done had the
--      FK been in force when the target went away -- rather than null just
--      the dangling column, matching how a real CASCADE never leaves a
--      partial row behind.
--   2. CHECK-invalid rows (before ADD CONSTRAINT ck_wisp_dep_one_target): a
--      row with zero targets set is semantically meaningless (there is
--      nothing here to be blocked on) and is deleted outright. A row with
--      more than one target set is normalized to exactly one by applying
--      the SAME precedence the delegate's own backfill
--      (wispDependenciesSplitTargetBackfillSQL) already trusts when a
--      single legacy id resolves ambiguously -- confirmed by that function's
--      statement order (the external-prefix UPDATE runs first and is
--      excluded from the wisp UPDATE's guard; the wisp UPDATE runs next and
--      is excluded from the issue UPDATE's guard) and by its sibling test
--      TestWispDependenciesSplitTargetBackfillPrefersWispOverIssueThroughDoltCLI,
--      which seeds one id that resolves as both a wisp and an issue and
--      asserts the wisp reading wins. That gives external > wisp > issue;
--      normalizing here nulls the lower-precedence column(s) rather than
--      picking one arbitrarily or deleting the row (unlike a zero-target
--      row, a multi-target row already names a real, resolvable target --
--      just more than one -- so keeping the highest-precedence one preserves
--      real edge data instead of discarding it).
--
-- Both cleanup steps are scoped to exactly the rows the corresponding
-- constraint would otherwise reject, guarded by the same @needs_fk_*/
-- @needs_ck_one_target flags the ADD CONSTRAINT statements use: a database
-- that already has (or never needed) a constraint skips its cleanup too, so
-- a converged database never pays this scan, and a second pass after the
-- constraints are added is a no-op (no violating rows are left to find).

SET FOREIGN_KEY_CHECKS = 0;

SET @has_wisp_dependencies = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'wisp_dependencies'
);
SET @has_wisps = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'wisps'
);
SET @has_issues = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'issues'
);
SET @has_col_issue_target = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'wisp_dependencies'
      AND COLUMN_NAME = 'depends_on_issue_id'
);
SET @has_col_wisp_target = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'wisp_dependencies'
      AND COLUMN_NAME = 'depends_on_wisp_id'
);
SET @has_col_external_target = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'wisp_dependencies'
      AND COLUMN_NAME = 'depends_on_external'
);
SET @has_fk_wisp_target = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'wisp_dependencies'
      AND CONSTRAINT_NAME = 'fk_wisp_dep_wisp_target'
);
SET @has_fk_issue_target = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'wisp_dependencies'
      AND CONSTRAINT_NAME = 'fk_wisp_dep_issue_target'
);
SET @has_ck_one_target = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'wisp_dependencies'
      AND CONSTRAINT_NAME = 'ck_wisp_dep_one_target'
);

SET @needs_fk_wisp_target = IF(
    @has_wisp_dependencies > 0 AND @has_wisps > 0
    AND @has_col_wisp_target > 0 AND @has_fk_wisp_target = 0,
    1, 0);
SET @needs_fk_issue_target = IF(
    @has_wisp_dependencies > 0 AND @has_issues > 0
    AND @has_col_issue_target > 0 AND @has_fk_issue_target = 0,
    1, 0);
SET @needs_ck_one_target = IF(
    @has_wisp_dependencies > 0
    AND @has_col_issue_target > 0 AND @has_col_wisp_target > 0 AND @has_col_external_target > 0
    AND @has_ck_one_target = 0,
    1, 0);

-- --- Cleanup 1: FK orphans (#4534-class, see ignored/0011) ------------------

SET @sql = IF(@needs_fk_wisp_target = 1,
    'DELETE wd FROM wisp_dependencies wd LEFT JOIN wisps w ON w.id = wd.depends_on_wisp_id WHERE wd.depends_on_wisp_id IS NOT NULL AND w.id IS NULL',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_fk_issue_target = 1,
    'DELETE wd FROM wisp_dependencies wd LEFT JOIN issues i ON i.id = wd.depends_on_issue_id WHERE wd.depends_on_issue_id IS NOT NULL AND i.id IS NULL',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- --- Cleanup 2: CHECK-invalid rows (zero-target delete, multi-target -------
-- --- normalize to external > wisp > issue precedence) ----------------------

SET @sql = IF(@needs_ck_one_target = 1,
    'DELETE FROM wisp_dependencies WHERE depends_on_issue_id IS NULL AND depends_on_wisp_id IS NULL AND depends_on_external IS NULL',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_ck_one_target = 1,
    'UPDATE wisp_dependencies SET depends_on_wisp_id = NULL, depends_on_issue_id = NULL WHERE depends_on_external IS NOT NULL AND (depends_on_wisp_id IS NOT NULL OR depends_on_issue_id IS NOT NULL)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_ck_one_target = 1,
    'UPDATE wisp_dependencies SET depends_on_issue_id = NULL WHERE depends_on_external IS NULL AND depends_on_wisp_id IS NOT NULL AND depends_on_issue_id IS NOT NULL',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- --- Add the constraints -----------------------------------------------------

SET @sql = IF(@needs_fk_wisp_target = 1,
    'ALTER TABLE wisp_dependencies ADD CONSTRAINT fk_wisp_dep_wisp_target FOREIGN KEY (depends_on_wisp_id) REFERENCES wisps(id) ON DELETE CASCADE ON UPDATE CASCADE',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_fk_issue_target = 1,
    'ALTER TABLE wisp_dependencies ADD CONSTRAINT fk_wisp_dep_issue_target FOREIGN KEY (depends_on_issue_id) REFERENCES issues(id) ON DELETE CASCADE ON UPDATE CASCADE',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_ck_one_target = 1,
    'ALTER TABLE wisp_dependencies ADD CONSTRAINT ck_wisp_dep_one_target CHECK ((depends_on_issue_id IS NOT NULL) + (depends_on_wisp_id IS NOT NULL) + (depends_on_external IS NOT NULL) = 1)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET FOREIGN_KEY_CHECKS = 1;

-- ===== internal/storage/schema/migrations/0062_events_dolt_ignore.up.sql =====
-- Move the events audit table off the versioned plane (bd-red8u, Protocol
-- v0.1 C2.2: no per-write history cost for unversioned records).
--
-- events is the dominant history churner: every issue op appends audit rows,
-- so at fleet tempo the table is touched by ~80% of dolt commits and is the
-- primary driver of unbounded reachable-history growth (bd-7vb13
-- measurements). Like leases (0055) and repo_mtimes (0028), the rows keep
-- full SQL durability in the working set; what changes is that they stop
-- minting versioned history. Unlike those precedents, events is an
-- already-committed SYNCED table, and dolt_ignore only exempts tables that
-- have never been committed -- a drop+recreate netting out in one working set
-- leaves the table tracked-at-HEAD and permanently dirty. The drop must
-- therefore be committed on its own BEFORE the recreate, which makes this the
-- first self-committing table-plane migration (0040/0041 are the
-- self-commit precedent; --skip-empty keeps the replay idempotent).
--
-- Replication note (deliberate, per the 2026-07-30 mitigation-first ruling):
-- dolt_ignored tables do not replicate. Events are single-writer audit rows
-- with low cross-machine value; the C2.3 newest-wins replication leg
-- (bd-1quyq) re-adds unversioned sync later. Comments stay versioned until
-- that leg exists. The pre-flip events history remains in remotes until the
-- next squash window; only NEW growth stops.
--
-- Fresh clones never run this migration (their schema_migrations cursor
-- arrives at-latest); they materialize the table via ignored migration 0019.
-- Every step is guarded so a re-run from any intermediate state converges
-- (verified: full-replay and mid-crash states all land in the final shape).

-- Phase 0: Heal. A replay that crashed after the drop finds no events table;
-- recreate it empty so the copy below cannot fail. No-op on the normal path.
CREATE TABLE IF NOT EXISTS events (
    issue_id VARCHAR(255) NOT NULL,
    event_type VARCHAR(32) NOT NULL,
    actor VARCHAR(255) NOT NULL,
    old_value LONGTEXT,
    new_value LONGTEXT,
    comment TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    id CHAR(36) NOT NULL,
    PRIMARY KEY (id),
    INDEX idx_events_created_at (created_at),
    INDEX idx_events_issue (issue_id),
    CONSTRAINT fk_events_issue FOREIGN KEY (issue_id) REFERENCES issues (id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Phase 1: Preserve rows in a temp table. IF NOT EXISTS + INSERT IGNORE keep
-- a copy made by an interrupted earlier run intact (id is the PK, so the
-- union of the old copy and the current rows converges).
CREATE TABLE IF NOT EXISTS __temp__events_flip (
    issue_id VARCHAR(255) NOT NULL,
    event_type VARCHAR(32) NOT NULL,
    actor VARCHAR(255) NOT NULL,
    old_value LONGTEXT,
    new_value LONGTEXT,
    comment TEXT,
    created_at DATETIME NOT NULL,
    id CHAR(36) NOT NULL,
    PRIMARY KEY (id)
);
INSERT IGNORE INTO __temp__events_flip (issue_id, event_type, actor, old_value, new_value, comment, created_at, id)
    SELECT issue_id, event_type, actor, old_value, new_value, comment, created_at, id FROM events;

-- Phase 2: Drop the tracked table and commit the drop out of HEAD. The
-- DOLT_ADD is conditional on dolt_status actually showing a pending events
-- change: on first run the drop of the tracked table is pending; on a replay
-- the drop of the recreated (never-committed) table leaves no status row, and
-- an unconditional add of a table that exists nowhere would error. The add
-- uses '-f' because plain DOLT_ADD of a dolt_ignore'd table is a silent no-op:
-- on the normal path 'events' is not in dolt_ignore yet (Phase 3 adds it), but
-- a database that already carries the pattern while events is still tracked at
-- HEAD (branch-per-test databases materialize exactly that state; so would any
-- out-of-band-seeded pattern) needs the force or the drop never commits and
-- the recreate nets out to a permanently-dirty tracked table. The commit
-- is a bare statement so the drain path picks it up; --skip-empty makes the
-- replay a no-op instead of "nothing to commit" (the 0040/0041 lesson).
--
-- The bare COMMIT before the dolt_status read is load-bearing on the
-- sql-server path: migrations run there on a transaction-pinned connection,
-- and dolt_status reflects the WORKING SET, which an open SQL transaction has
-- not updated yet -- without it the probe reads 0, the DOLT_ADD is skipped,
-- and the drop+recreate nets out to a permanently-dirty tracked table.
-- Mid-body transaction commits are already this pass's semantics: CALL
-- DOLT_COMMIT (here and in 0040/0041) implicitly commits the session
-- transaction too, and every statement in this file is replay-safe from any
-- intermediate state. On autocommit paths (embedded engine, dolt CLI) the
-- bare COMMIT is a no-op.
DROP TABLE events;
COMMIT;
SET @flip_pending = (SELECT COUNT(*) FROM dolt_status WHERE table_name = 'events');
SET @sql = IF(@flip_pending > 0, 'CALL DOLT_ADD(''-f'', ''events'')', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
CALL DOLT_COMMIT('--skip-empty', '-m', 'schema: drop versioned events table for ignored-plane flip (bd-red8u)');

-- Phase 3: Register the ignore pattern (committed with the pass, so clones
-- inherit it) and recreate events in the working set, now dolt-ignored.
-- MigrateUp's cursor-gated doltIgnorePatterns seeding re-asserts the pattern
-- for databases materialized out-of-band.
REPLACE INTO dolt_ignore VALUES ('events', true);
CREATE TABLE IF NOT EXISTS events (
    issue_id VARCHAR(255) NOT NULL,
    event_type VARCHAR(32) NOT NULL,
    actor VARCHAR(255) NOT NULL,
    old_value LONGTEXT,
    new_value LONGTEXT,
    comment TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    id CHAR(36) NOT NULL,
    PRIMARY KEY (id),
    INDEX idx_events_created_at (created_at),
    INDEX idx_events_issue (issue_id),
    CONSTRAINT fk_events_issue FOREIGN KEY (issue_id) REFERENCES issues (id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Phase 4: Restore rows and clean up. __temp__events_flip was never
-- committed, so dropping it leaves no tracked changes.
INSERT IGNORE INTO events (issue_id, event_type, actor, old_value, new_value, comment, created_at, id)
    SELECT issue_id, event_type, actor, old_value, new_value, comment, created_at, id FROM __temp__events_flip;
DROP TABLE IF EXISTS __temp__events_flip;

-- ===== internal/storage/schema/migrations/0063_create_provenance_events.up.sql =====
-- provenance_events: a log binding an issue to a structured external artifact
-- (a git SHA, a PR, a work-id, a transcript, a branch). Append-only at the event
-- level — there is no UPDATE or DELETE operation on individual events. An event's
-- lifecycle is bound to its issue: it is removed only if the issue itself is
-- deleted (ON DELETE CASCADE), identical to the `events` audit table (0005).
--
-- This is a separate table from `events` on purpose. `events` is the hot
-- field-mutation audit trail (old_value/new_value pairs); provenance_events is
-- a typed binding to an opaque external reference produced by any runtime
-- (git hook, orchestrator, CI). bd never interprets `actor` or `ref` — they are
-- opaque identifiers — so the table stays a primitive usable without any
-- specific orchestrator. Only `kind` and `ref_kind` are structurally validated.
--
-- occurred_at (event-time) is separate from created_at (ingest-time): a producer
-- may record a fact after it happened (a git hook firing on a past commit).
--
-- `ref` is VARCHAR(255) rather than TEXT so it is directly indexable in
-- dolt/MySQL; a 40-char SHA or a PR URL fits comfortably. Refs longer than 255
-- chars are not supported by this column and should not be recorded here.
CREATE TABLE IF NOT EXISTS provenance_events (
    id CHAR(36) NOT NULL PRIMARY KEY,
    issue_id VARCHAR(255) NOT NULL,
    kind VARCHAR(32) NOT NULL,
    actor VARCHAR(255),
    ref VARCHAR(255),
    ref_kind VARCHAR(32),
    payload TEXT,
    source VARCHAR(64) NOT NULL,
    occurred_at DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_provenance_events_issue_occurred (issue_id, occurred_at),
    INDEX idx_provenance_events_ref (ref),
    INDEX idx_provenance_events_kind (kind),
    CONSTRAINT fk_provenance_events_issue FOREIGN KEY (issue_id) REFERENCES issues(id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- ===== internal/storage/schema/migrations/ignored/0001_create_local_state_tables.up.sql =====
DROP TABLE IF EXISTS __temp__wisps;
CREATE TABLE __temp__wisps (
    id VARCHAR(255) PRIMARY KEY,
    content_hash VARCHAR(64),
    title VARCHAR(500) NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    design TEXT NOT NULL DEFAULT '',
    acceptance_criteria TEXT NOT NULL DEFAULT '',
    notes TEXT NOT NULL DEFAULT '',
    status VARCHAR(32) NOT NULL DEFAULT 'open',
    priority INT NOT NULL DEFAULT 2,
    issue_type VARCHAR(32) NOT NULL DEFAULT 'task',
    assignee VARCHAR(255),
    estimated_minutes INT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255) DEFAULT '',
    owner VARCHAR(255) DEFAULT '',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    closed_at DATETIME,
    closed_by_session VARCHAR(255) DEFAULT '',
    external_ref VARCHAR(255),
    spec_id VARCHAR(1024),
    compaction_level INT DEFAULT 0,
    compacted_at DATETIME,
    compacted_at_commit VARCHAR(64),
    original_size INT,
    sender VARCHAR(255) DEFAULT '',
    ephemeral TINYINT(1) DEFAULT 0,
    wisp_type VARCHAR(32) DEFAULT '',
    pinned TINYINT(1) DEFAULT 0,
    is_template TINYINT(1) DEFAULT 0,
    mol_type VARCHAR(32) DEFAULT '',
    work_type VARCHAR(32) DEFAULT 'mutex',
    source_system VARCHAR(255) DEFAULT '',
    metadata JSON DEFAULT (JSON_OBJECT()),
    source_repo VARCHAR(512) DEFAULT '',
    close_reason TEXT DEFAULT '',
    event_kind VARCHAR(32) DEFAULT '',
    actor VARCHAR(255) DEFAULT '',
    target VARCHAR(255) DEFAULT '',
    payload TEXT DEFAULT '',
    await_type VARCHAR(32) DEFAULT '',
    await_id VARCHAR(255) DEFAULT '',
    timeout_ns BIGINT DEFAULT 0,
    waiters TEXT DEFAULT '',
    hook_bead VARCHAR(255) DEFAULT '',
    role_bead VARCHAR(255) DEFAULT '',
    agent_state VARCHAR(32) DEFAULT '',
    last_activity DATETIME,
    role_type VARCHAR(32) DEFAULT '',
    rig VARCHAR(255) DEFAULT '',
    due_at DATETIME,
    defer_until DATETIME,
    no_history TINYINT(1) DEFAULT 0,
    started_at DATETIME,
    INDEX idx_wisps_status (status),
    INDEX idx_wisps_priority (priority),
    INDEX idx_wisps_issue_type (issue_type),
    INDEX idx_wisps_assignee (assignee),
    INDEX idx_wisps_created_at (created_at),
    INDEX idx_wisps_spec_id (spec_id),
    INDEX idx_wisps_external_ref (external_ref)
);

DROP TABLE IF EXISTS __temp__wisp_labels;
CREATE TABLE __temp__wisp_labels (
    issue_id VARCHAR(255) NOT NULL,
    label VARCHAR(255) NOT NULL,
    PRIMARY KEY (issue_id, label),
    INDEX idx_wisp_labels_label (label)
);

DROP TABLE IF EXISTS __temp__wisp_dependencies;
CREATE TABLE __temp__wisp_dependencies (
    issue_id VARCHAR(255) NOT NULL,
    depends_on_id VARCHAR(255) NOT NULL,
    type VARCHAR(32) NOT NULL DEFAULT 'blocks',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255) DEFAULT '',
    metadata JSON DEFAULT (JSON_OBJECT()),
    thread_id VARCHAR(255) DEFAULT '',
    PRIMARY KEY (issue_id, depends_on_id),
    INDEX idx_wisp_dep_depends (depends_on_id),
    INDEX idx_wisp_dep_type (type),
    INDEX idx_wisp_dep_type_depends (type, depends_on_id)
);

DROP TABLE IF EXISTS __temp__wisp_events;
CREATE TABLE __temp__wisp_events (
    id CHAR(36) NOT NULL PRIMARY KEY DEFAULT (UUID()),
    issue_id VARCHAR(255) NOT NULL,
    event_type VARCHAR(32) NOT NULL,
    actor VARCHAR(255) DEFAULT '',
    old_value TEXT DEFAULT '',
    new_value TEXT DEFAULT '',
    comment TEXT DEFAULT '',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_wisp_events_issue (issue_id),
    INDEX idx_wisp_events_created_at (created_at)
);

DROP TABLE IF EXISTS __temp__wisp_comments;
CREATE TABLE __temp__wisp_comments (
    id CHAR(36) NOT NULL PRIMARY KEY DEFAULT (UUID()),
    issue_id VARCHAR(255) NOT NULL,
    author VARCHAR(255) DEFAULT '',
    text TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_wisp_comments_issue (issue_id)
);

DROP TABLE IF EXISTS __temp__repo_mtimes;
CREATE TABLE __temp__repo_mtimes (
    repo_path VARCHAR(512) PRIMARY KEY,
    jsonl_path VARCHAR(512) NOT NULL,
    mtime_ns BIGINT NOT NULL,
    last_checked DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_repo_mtimes_checked (last_checked)
);

DROP TABLE IF EXISTS __temp__local_metadata;
CREATE TABLE __temp__local_metadata (
    `key` VARCHAR(255) PRIMARY KEY,
    value TEXT NOT NULL DEFAULT ''
);
SET @exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'wisps');
SET @sql = IF(@exists = 0, 'RENAME TABLE __temp__wisps TO wisps', 'DROP TABLE __temp__wisps');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'wisp_labels');
SET @sql = IF(@exists = 0, 'RENAME TABLE __temp__wisp_labels TO wisp_labels', 'DROP TABLE __temp__wisp_labels');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'wisp_dependencies');
SET @sql = IF(@exists = 0, 'RENAME TABLE __temp__wisp_dependencies TO wisp_dependencies', 'DROP TABLE __temp__wisp_dependencies');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'wisp_events');
SET @sql = IF(@exists = 0, 'RENAME TABLE __temp__wisp_events TO wisp_events', 'DROP TABLE __temp__wisp_events');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'wisp_comments');
SET @sql = IF(@exists = 0, 'RENAME TABLE __temp__wisp_comments TO wisp_comments', 'DROP TABLE __temp__wisp_comments');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'repo_mtimes');
SET @sql = IF(@exists = 0, 'RENAME TABLE __temp__repo_mtimes TO repo_mtimes', 'DROP TABLE __temp__repo_mtimes');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'local_metadata');
SET @sql = IF(@exists = 0, 'RENAME TABLE __temp__local_metadata TO local_metadata', 'DROP TABLE __temp__local_metadata');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ===== internal/storage/schema/migrations/ignored/0003_split_wisp_dependencies_target.up.sql =====
SET FOREIGN_KEY_CHECKS = 0;

SET @needs_migrate = (
    SELECT IF(COUNT(*) = 0, 1, 0)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'wisp_dependencies'
      AND COLUMN_NAME = 'depends_on_wisp_id'
);

SET @sql = IF(@needs_migrate = 1,
    'ALTER TABLE wisp_dependencies ADD COLUMN depends_on_issue_id VARCHAR(255) NULL',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'ALTER TABLE wisp_dependencies ADD COLUMN depends_on_wisp_id VARCHAR(255) NULL',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'ALTER TABLE wisp_dependencies ADD COLUMN depends_on_external VARCHAR(255) NULL',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'UPDATE wisp_dependencies SET depends_on_external = depends_on_id WHERE depends_on_id LIKE ''external:%''',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'UPDATE wisp_dependencies wd JOIN wisps w ON w.id = wd.depends_on_id SET wd.depends_on_wisp_id = wd.depends_on_id WHERE wd.depends_on_external IS NULL',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'UPDATE wisp_dependencies wd JOIN issues i ON i.id = wd.depends_on_id SET wd.depends_on_issue_id = wd.depends_on_id WHERE wd.depends_on_external IS NULL AND wd.depends_on_wisp_id IS NULL',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'UPDATE wisp_dependencies SET depends_on_external = depends_on_id WHERE depends_on_external IS NULL AND depends_on_wisp_id IS NULL AND depends_on_issue_id IS NULL',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'ALTER TABLE wisp_dependencies DROP INDEX idx_wisp_dep_depends',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'ALTER TABLE wisp_dependencies DROP INDEX idx_wisp_dep_type_depends',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'ALTER TABLE wisp_dependencies DROP PRIMARY KEY',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'ALTER TABLE wisp_dependencies DROP COLUMN depends_on_id',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'ALTER TABLE wisp_dependencies ADD INDEX idx_wisp_dep_wisp_target (depends_on_wisp_id)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'ALTER TABLE wisp_dependencies ADD INDEX idx_wisp_dep_issue_target (depends_on_issue_id)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'ALTER TABLE wisp_dependencies ADD INDEX idx_wisp_dep_external_target (depends_on_external)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'ALTER TABLE wisp_dependencies ADD CONSTRAINT fk_wisp_dep_wisp_target FOREIGN KEY (depends_on_wisp_id) REFERENCES wisps(id) ON DELETE CASCADE ON UPDATE CASCADE',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'ALTER TABLE wisp_dependencies ADD CONSTRAINT fk_wisp_dep_issue_target FOREIGN KEY (depends_on_issue_id) REFERENCES issues(id) ON DELETE CASCADE ON UPDATE CASCADE',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'ALTER TABLE wisp_dependencies ADD CONSTRAINT ck_wisp_dep_one_target CHECK ((depends_on_issue_id IS NOT NULL) + (depends_on_wisp_id IS NOT NULL) + (depends_on_external IS NOT NULL) = 1)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'ALTER TABLE wisp_dependencies ADD COLUMN depends_on_id VARCHAR(255) AS (COALESCE(depends_on_issue_id, depends_on_wisp_id, depends_on_external)) STORED',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'ALTER TABLE wisp_dependencies ADD PRIMARY KEY (issue_id, depends_on_id)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'ALTER TABLE wisp_dependencies ADD INDEX idx_wisp_dep_type_target (type, depends_on_id)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_migrate = 1,
    'ALTER TABLE wisp_dependencies ADD CONSTRAINT fk_wisp_dep_issue FOREIGN KEY (issue_id) REFERENCES wisps(id) ON DELETE CASCADE ON UPDATE CASCADE',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET FOREIGN_KEY_CHECKS = 1;

-- ===== internal/storage/schema/migrations/ignored/0005_drop_wisp_dependencies_generated_column.up.sql =====
SET FOREIGN_KEY_CHECKS = 0;

SET @needs_drop = (
    SELECT IF(COUNT(*) > 0, 1, 0)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'wisp_dependencies'
      AND COLUMN_NAME = 'depends_on_id'
);

SET @has_idx_type_target = (
    SELECT IF(COUNT(*) > 0, 1, 0)
    FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'wisp_dependencies'
      AND INDEX_NAME = 'idx_wisp_dep_type_target'
);

SET @sql = IF(@needs_drop = 1 AND @has_idx_type_target = 1,
    'ALTER TABLE wisp_dependencies DROP INDEX idx_wisp_dep_type_target',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_fk_issue = (
    SELECT IF(COUNT(*) > 0, 1, 0)
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'wisp_dependencies'
      AND CONSTRAINT_NAME = 'fk_wisp_dep_issue'
);
SET @sql = IF(@needs_drop = 1 AND @has_fk_issue = 1,
    'ALTER TABLE wisp_dependencies DROP FOREIGN KEY fk_wisp_dep_issue',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_fk_wisp_target = (
    SELECT IF(COUNT(*) > 0, 1, 0)
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'wisp_dependencies'
      AND CONSTRAINT_NAME = 'fk_wisp_dep_wisp_target'
);
SET @sql = IF(@needs_drop = 1 AND @has_fk_wisp_target = 1,
    'ALTER TABLE wisp_dependencies DROP FOREIGN KEY fk_wisp_dep_wisp_target',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_fk_issue_target = (
    SELECT IF(COUNT(*) > 0, 1, 0)
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'wisp_dependencies'
      AND CONSTRAINT_NAME = 'fk_wisp_dep_issue_target'
);
SET @sql = IF(@needs_drop = 1 AND @has_fk_issue_target = 1,
    'ALTER TABLE wisp_dependencies DROP FOREIGN KEY fk_wisp_dep_issue_target',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_drop = 1,
    'ALTER TABLE wisp_dependencies DROP PRIMARY KEY',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_drop = 1,
    'ALTER TABLE wisp_dependencies DROP COLUMN depends_on_id',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_drop = 1,
    'ALTER TABLE wisp_dependencies ADD COLUMN id CHAR(36) NOT NULL DEFAULT (UUID()) PRIMARY KEY FIRST',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_drop = 1,
    'ALTER TABLE wisp_dependencies ADD UNIQUE KEY uk_wisp_dep_issue_target (issue_id, depends_on_issue_id)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_drop = 1,
    'ALTER TABLE wisp_dependencies ADD UNIQUE KEY uk_wisp_dep_wisp_target (issue_id, depends_on_wisp_id)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_drop = 1,
    'ALTER TABLE wisp_dependencies ADD UNIQUE KEY uk_wisp_dep_external_target (issue_id, depends_on_external)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_drop = 1,
    'ALTER TABLE wisp_dependencies ADD INDEX idx_wisp_dep_type_issue (type, depends_on_issue_id)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_drop = 1,
    'ALTER TABLE wisp_dependencies ADD INDEX idx_wisp_dep_type_wisp (type, depends_on_wisp_id)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_drop = 1,
    'ALTER TABLE wisp_dependencies ADD INDEX idx_wisp_dep_type_external (type, depends_on_external)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_drop = 1 AND @has_fk_issue = 1,
    'ALTER TABLE wisp_dependencies ADD CONSTRAINT fk_wisp_dep_issue FOREIGN KEY (issue_id) REFERENCES wisps(id) ON DELETE CASCADE ON UPDATE CASCADE',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_drop = 1 AND @has_fk_wisp_target = 1,
    'ALTER TABLE wisp_dependencies ADD CONSTRAINT fk_wisp_dep_wisp_target FOREIGN KEY (depends_on_wisp_id) REFERENCES wisps(id) ON DELETE CASCADE ON UPDATE CASCADE',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@needs_drop = 1 AND @has_fk_issue_target = 1,
    'ALTER TABLE wisp_dependencies ADD CONSTRAINT fk_wisp_dep_issue_target FOREIGN KEY (depends_on_issue_id) REFERENCES issues(id) ON DELETE CASCADE ON UPDATE CASCADE',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET FOREIGN_KEY_CHECKS = 1;

-- ===== internal/storage/schema/migrations/ignored/0012_create_leases.up.sql =====
-- Materialize the ephemeral leases table (bd-lrgn1) on clones that never ran
-- main migration 0055. The leases table is dolt_ignored, so it lives only in
-- the working set and is never part of committed history: a fresh clone
-- arrives with the schema_migrations cursor at-latest (0055 already recorded)
-- but WITHOUT the table, exactly like the wisp/local-state tables from
-- ignored/0001. Same __temp__ + conditional RENAME pattern: create only when
-- absent, never touch an existing table.
--
-- One row per live claim granted through this node; see
-- issueops.UpsertLeaseInTx for the lease-row invariant.
DROP TABLE IF EXISTS __temp__leases;
CREATE TABLE __temp__leases (
    issue_id VARCHAR(255) PRIMARY KEY,
    holder VARCHAR(255) NOT NULL,
    granted_at DATETIME NOT NULL,
    lease_expires_at DATETIME NOT NULL,
    heartbeat_at DATETIME NOT NULL,
    INDEX idx_leases_expires (lease_expires_at)
);
SET @exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'leases');
SET @sql = IF(@exists = 0, 'RENAME TABLE __temp__leases TO leases', 'DROP TABLE __temp__leases');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ===== internal/storage/schema/migrations/ignored/0013_add_wisp_row_lock.up.sql =====
-- Ignored migration 0013: ensure wisps.row_lock exists on every clone
-- (bd-rotq2).
--
-- Synced migration 0054 added row_lock to wisps — but wisps is dolt-ignored
-- (migration 0019), so its schema is clone-local, and a workspace that
-- bootstraps or re-clones from a remote whose schema_migrations cursor is
-- already >= 0054 adopts the cursor without ever executing 0054. Its wisps
-- table (materialized by ignored/0001, which predates row_lock) then
-- permanently lacks the column, and every wisp INSERT from a post-0054 binary
-- soft-fails with Error 1054 (observed in prod on claude-code-vm, wy-pt82l).
--
-- Carrying the column on the ignored track fixes both fronts: fresh
-- bootstraps get it right after ignored/0001 runs, and already-affected
-- workspaces self-heal on their next store open. The guard makes this a
-- no-op on in-place-upgraded workspaces where synced 0054 already added the
-- column, and on workspaces with no local wisps table yet.
--
-- Deliberately NOT healed: 0054's other two wisps columns
-- (lease_expires_at, heartbeat_at). 0055 moved leases to their own table
-- and dropped those columns from issues/wisps — wisps are never leased, and
-- nothing post-cutover reads or writes them on wisps — so bootstrapped
-- workspaces that never had them are already in the correct final shape.
-- row_lock is the only 0054 wisps column that survives 0055.
SET @needs_add = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'wisps') > 0
    AND
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'wisps'
          AND COLUMN_NAME = 'row_lock') = 0,
    1, 0
);
SET @sql = IF(@needs_add = 1,
    'ALTER TABLE wisps ADD COLUMN row_lock BIGINT NOT NULL DEFAULT 0',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ===== internal/storage/schema/migrations/ignored/0016_add_lease_granted_node.up.sql =====
-- Ignored migration 0016: record the granting replica on every lease
-- (wy-jpd3.7).
--
-- A lease is only meaningful on the replica that granted it. Every other
-- replica's view of the holder's liveness is stale by up to one sync
-- interval, so a reaper running there can revert a unit that is very much
-- alive on the machine that granted its lease. granted_node names that
-- machine (config.NodeID()) so reclaim can refuse a positively-foreign lease
-- instead of relying on the operator to partition every reaper by hand.
--
-- Lives on the IGNORED track because leases does: the table is dolt_ignored
-- (never replicated, clone-local), materialized by ignored/0012 on fresh
-- clones and by synced 0055 on in-place upgrades. Same shape as
-- ignored/0013: guarded so it is a no-op on a workspace that already carries
-- the column and on one with no leases table yet.
--
-- Empty string is the "provenance unknown" value, and DEFAULT '' is what
-- pre-existing lease rows adopt. Reclaim treats unknown as local (fail-open)
-- so this upgrade can never strand a stale lease the reaper could previously
-- recover; a heartbeat re-stamps an unknown row with the local node.
SET @needs_add = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'leases') > 0
    AND
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'leases'
          AND COLUMN_NAME = 'granted_node') = 0,
    1, 0
);
SET @sql = IF(@needs_add = 1,
    'ALTER TABLE leases ADD COLUMN granted_node VARCHAR(255) NOT NULL DEFAULT ''''',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ===== internal/storage/schema/migrations/ignored/0017_add_wisps_defer_until_index.up.sql =====
-- Index wisps.defer_until so the ready-work deferred-parents probe
-- (getChildrenOfDeferredParentsInTx: defer_until IS NOT NULL AND
-- defer_until > UTC_TIMESTAMP() LIMIT 1) is an index range scan instead of a
-- full scan over fat wisp rows. Migration 0052 added the equivalent
-- idx_issues_defer_until on issues; wisps was left unindexed, and the probe
-- runs on every ready-work call that excludes deferred items (it is skipped
-- when IncludeDeferred is set). Guarded so it is idempotent and tolerant
-- of an absent wisps table (matches 0006_add_wisp_is_blocked).
SET @needs_index = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'wisps') > 0
    AND
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'wisps'
          AND INDEX_NAME = 'idx_wisps_defer_until') = 0,
    1, 0
);
SET @sql = IF(@needs_index = 1,
    'CREATE INDEX idx_wisps_defer_until ON wisps(defer_until)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ===== internal/storage/schema/migrations/ignored/0019_create_events.up.sql =====
-- Materialize the events audit table (bd-red8u) on clones that never ran
-- main migration 0062. events is dolt_ignored since 0062, so it lives only in
-- the working set and is never part of committed history: a fresh clone
-- arrives with the schema_migrations cursor at-latest (0062 already recorded)
-- but WITHOUT the table, exactly like leases (ignored/0012) and the
-- wisp/local-state tables (ignored/0001).
--
-- NOT the usual __temp__ + RENAME dance: events carries the named constraint
-- fk_events_issue, and constraint names are database-unique -- creating a
-- temp twin while events exists errors with "duplicate foreign key constraint
-- name" (verified on dolt 2.2.2). A PREPAREd conditional CREATE gives the
-- same create-only-when-absent contract. CREATE TABLE IF NOT EXISTS alone
-- would also work (a same-name FK short-circuits on the existing table), but
-- the explicit guard keeps the never-touch-an-existing-table intent readable.
--
-- Shape must stay identical to 0062's recreate (the post-0037 converged
-- column order, id last) -- events/wisp_events twin parity is pinned by
-- internal/storage/dolt/schema_parity_test.go.
SET @exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'events');
SET @sql = IF(@exists = 0, 'CREATE TABLE events (
    issue_id VARCHAR(255) NOT NULL,
    event_type VARCHAR(32) NOT NULL,
    actor VARCHAR(255) NOT NULL,
    old_value LONGTEXT,
    new_value LONGTEXT,
    comment TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    id CHAR(36) NOT NULL,
    PRIMARY KEY (id),
    INDEX idx_events_created_at (created_at),
    INDEX idx_events_issue (issue_id),
    CONSTRAINT fk_events_issue FOREIGN KEY (issue_id) REFERENCES issues (id) ON DELETE CASCADE ON UPDATE CASCADE
)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ===== internal/storage/schema/migrations/ignored/0022_create_events_journal.up.sql =====
-- Materialize the clone-local events journal tables (bd-opisf) on clones that
-- never ran main migration 0064. A fresh clone arrives with the
-- schema_migrations cursor at-latest (0064 already recorded) but WITHOUT the
-- tables, exactly like the leases (ignored/0012) and events (ignored/0019)
-- precedents: dolt_ignored tables live only in the working set, and a working
-- set is not what a clone receives.
--
-- bd_events_journal and bd_events_seq are dolt_ignored (seeded by MigrateUp's
-- doltIgnorePatterns before this migration runs): operational, never versioned
-- or replicated, so the seq stays monotonic with no merge conflict. seq is NOT
-- AUTO_INCREMENT — it is drawn from the single-row bd_events_seq counter inside
-- the mutation's own transaction so concurrent allocators conflict and the
-- surviving seqs are gapless and commit-ordered (see main migration 0064 and
-- issueops.nextEventSeq).
--
-- Shape must stay identical to 0064's CREATE; the two doors are diffed by
-- internal/storage/embeddeddolt/migrate_ignored_plane_shape_test.go. Same
-- __temp__ + conditional RENAME pattern for both tables: create only when
-- absent, never touch an existing table. See issueops.RecordEventInTx for the
-- writer.
--
-- The payload columns are LONGTEXT rather than TEXT: a journal row commits in
-- the same transaction as the mutation it records, so an oversized comment or
-- edge payload overflowing a 64KB TEXT column would fail the journal INSERT and
-- roll back the user's write. idx_bd_events_journal_ts serves the retain-days
-- floor's `MIN(seq) WHERE ts >= ?` resolution, which automatic retention runs
-- unattended on every pass. See 0064 for the full reasoning on both, and for
-- the two deliberate divergences from the enterprise 0016/0017 shape.
DROP TABLE IF EXISTS __temp__bd_events_journal;
CREATE TABLE __temp__bd_events_journal (
    seq BIGINT NOT NULL PRIMARY KEY,
    ts DATETIME NOT NULL,
    op VARCHAR(32) NOT NULL,
    issue_id VARCHAR(255) NOT NULL,
    issue_json LONGTEXT,
    dep_json LONGTEXT,
    comment_json LONGTEXT,
    INDEX idx_bd_events_journal_issue (issue_id),
    INDEX idx_bd_events_journal_ts (ts)
);
SET @exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'bd_events_journal');
SET @sql = IF(@exists = 0, 'RENAME TABLE __temp__bd_events_journal TO bd_events_journal', 'DROP TABLE __temp__bd_events_journal');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

DROP TABLE IF EXISTS __temp__bd_events_seq;
CREATE TABLE __temp__bd_events_seq (
    id INT NOT NULL PRIMARY KEY,
    next_seq BIGINT NOT NULL
);
SET @seq_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'bd_events_seq');
SET @seq_sql = IF(@seq_exists = 0, 'RENAME TABLE __temp__bd_events_seq TO bd_events_seq', 'DROP TABLE __temp__bd_events_seq');
PREPARE stmt FROM @seq_sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
-- Seed (idempotent), then raise to the journal high-water mark. See main
-- migration 0064 for why this is VALUES + GREATEST rather than INSERT ... SELECT.
INSERT IGNORE INTO bd_events_seq (id, next_seq) VALUES (0, 0);
UPDATE bd_events_seq
    SET next_seq = GREATEST(next_seq, COALESCE((SELECT MAX(seq) FROM bd_events_journal), 0))
    WHERE id = 0;

-- ===== internal/storage/schema/migrations/ignored/0023_repair_events_journal_shape.up.sql =====
-- Repair the events-journal shape on workspaces provisioned from the fork
-- lineage that created those tables under a different ignored slot (bd-t9ovd).
--
-- A fork branch (bd-enterprise PR #32, feat/native-postgres-addon) shipped its
-- own ignored/0017_create_events_journal -- the slot upstream had already
-- assigned to 0017_add_wisps_defer_until_index. A workspace provisioned from
-- that lineage and later opened by an upstream binary converges SILENTLY
-- WRONG: its ignored cursor already reads past 17, so upstream's 0017..0022
-- are treated as applied without ever having run, and
--
--   (a) idx_wisps_defer_until is permanently missing, so the ready-work
--       deferred-parents probe full-scans wisps on every call (0017's whole
--       reason for existing);
--   (b) ignored/0022's guarded create finds bd_events_journal already present
--       and correctly leaves it alone -- so the fork's TEXT dep_json and
--       comment_json survive (TEXT caps at 65535 bytes: an oversized comment
--       fails the journal INSERT and therefore ROLLS BACK THE USER'S MUTATION,
--       since the journal row commits in that mutation's own transaction), and
--       idx_bd_events_journal_ts is absent, so the retain-days floor's
--       `MIN(seq) WHERE ts >= ?` full-scans on every unattended prune pass.
--
-- Nothing already in the tree detects any of this. The cursor-reality
-- sentinels (schema.go's cursorContradictedBySchema) test table EXISTENCE
-- only, and the content_hash skew comparison structurally cannot reach it:
-- ignored_schema_migrations is itself dolt_ignored, so two clones never see
-- each other's rows.
--
-- This is insurance, not the repair of a known population -- such a workspace
-- is believed rare and may well not exist. The point is to turn an
-- undetectable divergence into a no-op question: every step below probes for
-- its own drift independently and does nothing when it is absent, so a healthy
-- workspace arriving through either door (fresh init, fresh clone) runs the
-- probes and no DDL at all. Independent guards also make the file replayable
-- from any intermediate state, which crash-replay of an interrupted pass
-- requires.
--
-- Nothing is dropped or renamed (the ignored plane's no-DROP invariant), and
-- neither bd_events_seq nor a single journal row is read or written: the
-- counter value is the one piece of state a shape repair must never perturb.

-- The two payload columns, probed separately. ignored/0021's LONGTEXT widening
-- is the model, with DATA_TYPE in place of its COLUMN_TYPE: these columns carry
-- no length or attributes, so the bare type name is the whole comparison. An
-- absent table yields an empty result set, the variable is NULL, and `NULL = 1`
-- routes IF to its no-op branch -- which is why "the table exists" stays
-- implicit here. The index steps below cannot borrow that trick (a STATISTICS
-- count of 0 reads the same for "no index" and "no table") and spell the TABLES
-- probe out, as ignored/0017 does. The definitions mirror 0022's CREATE
-- exactly: nullable, no default.
SET @dep_json_is_text = (
    SELECT IF(DATA_TYPE = 'text', 1, 0)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'bd_events_journal'
      AND COLUMN_NAME = 'dep_json'
);
SET @sql = IF(@dep_json_is_text = 1,
    'ALTER TABLE bd_events_journal MODIFY COLUMN dep_json LONGTEXT',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @comment_json_is_text = (
    SELECT IF(DATA_TYPE = 'text', 1, 0)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'bd_events_journal'
      AND COLUMN_NAME = 'comment_json'
);
SET @sql = IF(@comment_json_is_text = 1,
    'ALTER TABLE bd_events_journal MODIFY COLUMN comment_json LONGTEXT',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- The retention index. 0022 and main 0064 declare it inline in their CREATE,
-- so only a journal table built elsewhere can be missing it.
SET @needs_journal_ts_index = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'bd_events_journal') > 0
    AND
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'bd_events_journal'
          AND INDEX_NAME = 'idx_bd_events_journal_ts') = 0,
    1, 0
);
SET @sql = IF(@needs_journal_ts_index = 1,
    'CREATE INDEX idx_bd_events_journal_ts ON bd_events_journal(ts)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Casualty (a): the index ignored/0017 would have created had the fork not
-- consumed its slot. Guard and index definition are 0017's, verbatim, so a
-- workspace repaired here and one that ran 0017 normally are indistinguishable.
SET @needs_index = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'wisps') > 0
    AND
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'wisps'
          AND INDEX_NAME = 'idx_wisps_defer_until') = 0,
    1, 0
);
SET @sql = IF(@needs_index = 1,
    'CREATE INDEX idx_wisps_defer_until ON wisps(defer_until)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
