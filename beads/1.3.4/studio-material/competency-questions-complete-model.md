# Competency questions for a complete beads model

Drafted on 2026-11-20 for the owner's review. Not yet approved.

The first 23 questions (`competency-questions.md`, `competency-questions-additions.md`) were chosen by one test: does a screen or rule of ours use the fact today? That test left out facts beads records about every bead, such as who created it. The owner's ruling on 2026-11-20 changes the test: the model in Knowledge is our own copy of the beads information model, so it holds everything beads 1.3.4 records about work, and leaves a fact out only for a stated reason.

The questions below continue the numbering. Each names where beads records the fact (from `internal/types/types.go` at tag v1.3.4 and the tables of a live 1.3.4 database) and how much of it the workspace database holds today (2,837 beads, 3,940 links, 12,614 history entries, counted 2026-11-20).

## Who did it

24. Who created this bead, and which beads did a given person or agent create?
    - Beads: `created_by` on every bead; set from `bd create --actor`, else `$BEADS_ACTOR`, git user name, `$USER`.
    - Evidence: filled on 2,803 beads. Values today: "Robert (Kenpo) Evans" 2,109, "kenpo" 665, "vibemachine" 29. From today the companion files beads as "companion".
    - Our use: finding every bead an agent filed; Plan's inspector shows "Filed by".

25. Which session closed this bead?
    - Beads: `closed_by_session`, the Claude Code session that closed it.
    - Evidence: 0 beads today. Kept because it is the only fact tying a closed bead to the session that did the work.

26. Who added this link between two beads, and when?
    - Beads: every link has `created_by` and `created_at`.
    - Evidence: all 3,940 links.

## More kinds of links

27. Which beads does this bead track, validate, or loosely relate to?
    - Beads: link kinds `tracks`, `validates`, `relates-to`.
    - Evidence: 30, 1 and 1 links. The sync skips all three today because the model has no place for them.

28. Which bead is a duplicate of which, and which bead was caused by, or delegated from, which?
    - Beads: link kinds `duplicates`, `caused-by`, `delegated-from`.
    - Evidence: 0 links today; the workflow rules we follow name `caused-by` as a root-cause link.

29. Which beads run only if another fails, and which wait for all (or any) of another bead's children?
    - Beads: link kinds `conditional-blocks` and `waits-for`; a `waits-for` link carries the gate ("all-children" or "any-children") and optionally which bead spawns the children.
    - Evidence: 0 links today. Both change what is ready, so questions 3 to 5 are wrong without them the day one is used.

30. Which person or agent approved, authored, or was assigned this bead as a link, and until which bead's closing is this one active?
    - Beads: link kinds `approved-by`, `authored-by`, `assigned-to`, `attests`, `until`.
    - Evidence: 0 links today.

31. Which message replies to which, and which messages form one conversation?
    - Beads: link kind `replies-to` with a thread id on the link.
    - Evidence: 0 links today.

32. What extra data does a link carry, and does it point outside this repository?
    - Beads: `metadata` on a link; a link's target can be a bead, or an external reference (`depends_on_external`).
    - Evidence: 0 of each today.

## Gates

33. What exactly is this gate waiting for, for how long at most, and who is told when it clears?
    - Beads: `await_type` (gh:run, gh:pr, timer, human, mail), `await_id` (run id, pull request number), `timeout`, `waiters`.
    - Evidence: 34 gates carry a type (the model keeps the type only); 0 carry an id.

## Planning facts

34. Which specification does this bead belong to, and which beads implement a given specification?
    - Beads: `spec_id`.
    - Evidence: 47 beads.

35. How long is this bead estimated to take, when is it due, and until when is it put off?
    - Beads: `estimated_minutes`, `due_at`, `defer_until` (a deferred bead is hidden from ready work until that time).
    - Evidence: 0 beads today. `defer_until` changes what is ready.

36. Which beads may only one worker take, and which are open to several?
    - Beads: `work_type` ("mutex" or "open_competition").
    - Evidence: 134 beads say "mutex"; the rest are empty, which beads reads as mutex.

37. Which beads are pinned, and which are templates?
    - Beads: `pinned` (a standing context note, not work) and `is_template`.
    - Evidence: 0 of each today.

## Outside systems

38. Which outside item does this bead stand for, and which system brought it in?
    - Beads: `external_ref` (such as "gh-9" or "jira-ABC") and `source_system`.
    - Evidence: 1 bead with a reference, 0 with a source system.

39. What free-form data does this bead carry beyond the dispatch facts?
    - Beads: `metadata`, any well-formed JSON.
    - Evidence: 46 beads. Question 23 already lifts the dispatch keys out as named facts; this keeps the whole value so nothing is lost.

## Deleted and compacted beads

40. Which beads were deleted, and when?
    - Beads: a deleted bead stays in the database with `deleted_at`.
    - Evidence: 289 beads. The sync removes them from Knowledge today, so Knowledge cannot say a bead ever existed.

41. Which beads had their text shortened to save space, when, at which commit, and from what size?
    - Beads: `compaction_level`, `compacted_at`, `compacted_at_commit`, `original_size`.
    - Evidence: 0 beads today.

## What agents did

42. What did an agent or tool do on this bead: which model, which prompt and response, which tool, did it fail?
    - Beads: the `interactions` table: kind, actor, model, prompt, response, error, tool name, exit code, parent interaction, label, reason.
    - Evidence: 0 rows today.

43. What happened to the work on this bead: cut, claimed, suspended, resumed, handed off, committed, landed, used?
    - Beads: the `provenance_events` table: one of those eight kinds, actor, a reference and its kind (such as a commit), payload, source, when it occurred.
    - Evidence: 0 rows today.

44. On which machine was this bead's lease granted?
    - Beads: `granted_node` on a lease.
    - Evidence: 15 leases today.

## The repository's own settings

45. Which statuses and types does this repository add to the built-in ones, and which category does each custom status fall in?
    - Beads: tables `custom_statuses` (name, category) and `custom_types`. Built in: 7 statuses (open, in_progress, blocked, deferred, closed, pinned, hooked) and 12 types (bug, feature, task, epic, chore, decision, message, molecule, gate, spike, story, milestone).
    - Evidence: the sync already logs statuses and types it has no place for.

46. Which id prefixes does this repository route to which folder?
    - Beads: table `routes` (prefix, path).
    - Evidence: the workspace database holds beads under three prefixes (question 21).

## Proposed to leave out, with the reason

- `content_hash`, `row_lock`, `is_blocked`: internal. The first two detect change; the third is beads' stored answer to "is it blocked", which the model answers from the links.
- `federation_peers`: holds passwords.
- Counters, snapshots, migration and journal tables: how beads stores and replays, not facts about work.
- Short-lived beads ("wisps": heartbeats, pings, patrol reports) and the fields only they use (`wisp_type`, `ephemeral`, `no_history`, `storage_class`): beads itself does not sync them between machines; 0 rows today.
- Agent-swarm fields from Gastown (`mol_type`, bonded molecules, formula source, `sender`, event beads' `event_kind`/`actor`/`target`/`payload`, and the database columns `hook_bead`, `role_bead`, `agent_state`, `role_type`, `rig` that the 1.3.4 type no longer names): 0 beads use them and Gastown is being removed. Decision for the owner: leave out, or give them a place for completeness.
- `source_repo` on a bead: question 21 is answered by where the bead was read from; all 5 values name the workspace itself.
