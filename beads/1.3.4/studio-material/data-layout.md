# Beads 1.3.4 data layout

Read on 2026-11-19 from a live beads 1.3.4 database (Dolt, MySQL protocol). Source: github.com/gastownhall/beads, tag v1.3.4, commit 7ef2fd05eb0cd3bdbde051f93cfc14ccf270cdde.

Each bead is one row of `issues`. Links between beads are rows of `dependencies` (the parent of a bead is a `parent-child` link). Labels, comments and the change history are their own tables. Tables whose name starts with `wisp_` hold short-lived beads with the same columns.

## Tables

```
TABLE_NAME                | TABLE_TYPE
--------------------------+-----------
bd_events_journal         | BASE TABLE
bd_events_seq             | BASE TABLE
blocked_issues            | VIEW      
child_counters            | BASE TABLE
comments                  | BASE TABLE
compaction_snapshots      | BASE TABLE
config                    | BASE TABLE
custom_statuses           | BASE TABLE
custom_types              | BASE TABLE
dependencies              | BASE TABLE
events                    | BASE TABLE
federation_peers          | BASE TABLE
ignored_schema_migrations | BASE TABLE
interactions              | BASE TABLE
issues                    | BASE TABLE
issue_counter             | BASE TABLE
issue_snapshots           | BASE TABLE
labels                    | BASE TABLE
leases                    | BASE TABLE
local_metadata            | BASE TABLE
metadata                  | BASE TABLE
provenance_events         | BASE TABLE
ready_issues              | VIEW      
repo_mtimes               | BASE TABLE
routes                    | BASE TABLE
schema_migrations         | BASE TABLE
wisps                     | BASE TABLE
wisp_child_counters       | BASE TABLE
wisp_comments             | BASE TABLE
wisp_dependencies         | BASE TABLE
wisp_events               | BASE TABLE
wisp_labels               | BASE TABLE
(32 rows)
```

## issues

```
COLUMN_NAME         | COLUMN_TYPE   | IS_NULLABLE | COLUMN_KEY
--------------------+---------------+-------------+-----------
id                  | varchar(255)  | NO          | PRI       
content_hash        | varchar(64)   | YES         |           
title               | varchar(500)  | NO          |           
description         | longtext      | NO          |           
design              | longtext      | NO          |           
acceptance_criteria | longtext      | NO          |           
notes               | longtext      | NO          |           
status              | varchar(32)   | NO          | MUL       
priority            | int           | NO          | MUL       
issue_type          | varchar(32)   | NO          | MUL       
assignee            | varchar(255)  | YES         | MUL       
estimated_minutes   | int           | YES         |           
created_at          | datetime      | NO          | MUL       
created_by          | varchar(255)  | YES         |           
owner               | varchar(255)  | YES         |           
updated_at          | datetime      | NO          | MUL       
closed_at           | datetime      | YES         |           
closed_by_session   | varchar(255)  | YES         |           
external_ref        | varchar(255)  | YES         | MUL       
spec_id             | varchar(1024) | YES         | MUL       
compaction_level    | int           | YES         |           
compacted_at        | datetime      | YES         |           
compacted_at_commit | varchar(64)   | YES         |           
original_size       | int           | YES         |           
sender              | varchar(255)  | YES         |           
ephemeral           | tinyint(1)    | YES         |           
wisp_type           | varchar(32)   | YES         |           
pinned              | tinyint(1)    | YES         |           
is_template         | tinyint(1)    | YES         |           
mol_type            | varchar(32)   | YES         |           
work_type           | varchar(32)   | YES         |           
source_system       | varchar(255)  | YES         |           
metadata            | json          | YES         |           
source_repo         | varchar(512)  | YES         |           
close_reason        | longtext      | YES         |           
event_kind          | varchar(32)   | YES         |           
actor               | varchar(255)  | YES         |           
target              | varchar(255)  | YES         |           
payload             | text          | YES         |           
await_type          | varchar(32)   | YES         |           
await_id            | varchar(255)  | YES         |           
timeout_ns          | bigint        | YES         |           
waiters             | text          | YES         |           
hook_bead           | varchar(255)  | YES         |           
role_bead           | varchar(255)  | YES         |           
agent_state         | varchar(32)   | YES         |           
last_activity       | datetime      | YES         |           
role_type           | varchar(32)   | YES         |           
rig                 | varchar(255)  | YES         |           
due_at              | datetime      | YES         |           
defer_until         | datetime      | YES         | MUL       
no_history          | tinyint(1)    | YES         |           
started_at          | datetime      | YES         |           
is_blocked          | tinyint(1)    | NO          | MUL       
deleted_at          | datetime      | YES         |           
row_lock            | bigint        | NO          |           
storage_class       | varchar(16)   | YES         |           
(57 rows)
```

## dependencies

```
COLUMN_NAME         | COLUMN_TYPE  | IS_NULLABLE | COLUMN_KEY
--------------------+--------------+-------------+-----------
id                  | char(36)     | NO          | PRI       
issue_id            | varchar(255) | NO          | MUL       
type                | varchar(32)  | NO          | MUL       
created_at          | datetime     | NO          |           
created_by          | varchar(255) | NO          |           
metadata            | json         | YES         |           
thread_id           | varchar(255) | YES         | MUL       
depends_on_issue_id | varchar(255) | YES         | MUL       
depends_on_wisp_id  | varchar(255) | YES         | MUL       
depends_on_external | varchar(255) | YES         | MUL       
(10 rows)
```

## labels

```
COLUMN_NAME | COLUMN_TYPE  | IS_NULLABLE | COLUMN_KEY
------------+--------------+-------------+-----------
issue_id    | varchar(255) | NO          | PRI       
label       | varchar(255) | NO          | PRI       
(2 rows)
```

## comments

```
COLUMN_NAME | COLUMN_TYPE  | IS_NULLABLE | COLUMN_KEY
------------+--------------+-------------+-----------
id          | char(36)     | NO          | PRI       
issue_id    | varchar(255) | NO          | MUL       
author      | varchar(255) | NO          |           
text        | longtext     | NO          |           
created_at  | datetime     | NO          | MUL       
(5 rows)
```

## events

```
COLUMN_NAME | COLUMN_TYPE  | IS_NULLABLE | COLUMN_KEY
------------+--------------+-------------+-----------
issue_id    | varchar(255) | NO          | MUL       
event_type  | varchar(32)  | NO          |           
actor       | varchar(255) | NO          |           
old_value   | longtext     | YES         |           
new_value   | longtext     | YES         |           
comment     | text         | YES         |           
created_at  | datetime     | NO          | MUL       
id          | char(36)     | NO          | PRI       
(8 rows)
```

## leases

```
COLUMN_NAME      | COLUMN_TYPE  | IS_NULLABLE | COLUMN_KEY
-----------------+--------------+-------------+-----------
issue_id         | varchar(255) | NO          | PRI       
holder           | varchar(255) | NO          |           
granted_at       | datetime     | NO          |           
lease_expires_at | datetime     | NO          | MUL       
heartbeat_at     | datetime     | NO          |           
granted_node     | varchar(255) | NO          |           
(6 rows)
```

## custom_types

```
COLUMN_NAME | COLUMN_TYPE | IS_NULLABLE | COLUMN_KEY
------------+-------------+-------------+-----------
name        | varchar(64) | NO          | PRI       
(1 rows)
```

## custom_statuses

```
COLUMN_NAME | COLUMN_TYPE | IS_NULLABLE | COLUMN_KEY
------------+-------------+-------------+-----------
name        | varchar(64) | NO          | PRI       
category    | varchar(32) | NO          |           
(2 rows)
```

## child_counters

```
COLUMN_NAME | COLUMN_TYPE  | IS_NULLABLE | COLUMN_KEY
------------+--------------+-------------+-----------
parent_id   | varchar(255) | NO          | PRI       
last_child  | int          | NO          |           
(2 rows)
```

## config

```
COLUMN_NAME | COLUMN_TYPE  | IS_NULLABLE | COLUMN_KEY
------------+--------------+-------------+-----------
key         | varchar(255) | NO          | PRI       
value       | text         | NO          |           
(2 rows)
```

## metadata

```
COLUMN_NAME | COLUMN_TYPE  | IS_NULLABLE | COLUMN_KEY
------------+--------------+-------------+-----------
key         | varchar(255) | NO          | PRI       
value       | text         | NO          |           
(2 rows)
```

## Values in use in one real database (about 2,700 beads)

Status:
```
status      | n   
------------+-----
closed      | 1576
deferred    | 596 
open        | 315 
in_progress | 225 
blocked     | 1   
(5 rows)
```
Bead type:
```
issue_type | n   
-----------+-----
task       | 1551
bug        | 581 
feature    | 406 
epic       | 96  
gate       | 28  
chore      | 19  
wave       | 18  
decision   | 10  
spike      | 4   
(9 rows)
```
Priority (0 is most urgent):
```
priority | n   
---------+-----
0        | 85  
1        | 1018
2        | 1368
3        | 226 
4        | 16  
(5 rows)
```
Link type:
```
type            | n   
----------------+-----
parent-child    | 2463
blocks          | 1106
related         | 59  
discovered-from | 48  
tracks          | 30  
supersedes      | 7   
relates-to      | 1   
validates       | 1   
(8 rows)
```
History entry type:
```
event_type         | n   
-------------------+-----
label_added        | 3448
updated            | 3226
created            | 2708
status_changed     | 1127
closed             | 736 
claimed            | 310 
dependency_added   | 225 
reopened           | 16  
renamed            | 11  
dependency_removed | 11  
label_removed      | 9   
commented          | 5   
(12 rows)
```
Custom bead types registered here:
```
name         
-------------
agent        
convoy       
decision     
gate         
merge-request
message      
molecule     
rig          
role         
slot         
wave         
(11 rows)
```

## Added on 2026-11-20 for the complete model

- `competency-questions-complete-model.md`: questions 24 to 46 and the leave-out list, approved by the owner on 2026-11-20.
- `tables-added-for-complete-model.sql`: the table definitions behind those questions, copied from Beads tag v1.3.4, `internal/storage/schema/migrations/`; each block names its file.
- `proposed-model-additions.tql`: the proposed schema additions. It loads on top of gist 5.1.0 and beads 0.1.2 in a throwaway TypeDB (checked 2026-11-20); it is a proposal for Studio, not the published schema.
