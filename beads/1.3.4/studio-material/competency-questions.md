# Competency questions for the beads model

Derived on 2026-11-19 from two things: what beads 1.3.4 itself answers through its commands, and what this workspace actually asks of beads (the Plan screen's data layer, our written rules, and the fields, labels and links in use in the workspace database of 2,424 live beads).

Each question names where it comes from. A question is here only when beads answers it today and we use the answer.

## One bead

1. What is recorded about this bead: its title, description, design, acceptance criteria, notes, type, status and priority?
   - Beads: `bd show`. It is the command our guidance names most.
   - Our use: description is filled on 2,303 of 2,424 beads, acceptance criteria on 1,876, design on 1,584, notes on 1,011. Plan shows description and design in a panel under the bead list.
2. Who owns this bead, who holds it now, when was it created, started and closed, and why was it closed?
   - Beads: `bd show`, `bd close --reason`.
   - Our use: owner is filled on 2,370 beads, the holder on 452, a start time on 1,073, a close reason on 1,221 of 1,345 closed beads.

## What to work on

3. Which beads are ready to start: open, nothing open in front of them, most urgent first?
   - Beads: `bd ready`. It leaves out beads that are in progress, blocked or deferred.
   - Our use: Plan asks for ready beads; the first rule of our bead workflow is to pick work from this list.
4. Which beads are blocked, and by which open beads?
   - Beads: `bd blocked`.
   - Our use: 1,002 "blocks" links; Plan asks for a bead's blockers and counts blocked beads.
5. What does finishing this bead unblock?
   - Beads: `bd dep tree`, `bd graph`.
   - Our use: Plan asks which beads a bead is blocking.
6. Which beads wait on a person's approval, and which approvals are still open?
   - Beads: `bd gate list`. A gate is a bead that blocks its waiters until it closes.
   - Our use: 28 gates, every one a human approval, 6 still open. Our rules say an approval is a gate, never a plain task.
7. Which beads are being worked on right now, and who or which agent holds each one?
   - Beads: status "in progress", the claim (`bd update --claim`), and the lease that `bd heartbeat` keeps alive.
   - Our use: 225 beads in progress, 31 leases, and the label `tvm:agent=active` that our dispatch puts on a bead an agent is running. A new "Working Now" screen will show exactly this.
8. Which beads are marked in progress but have gone quiet for a number of days?
   - Beads: `bd stale`, `bd reclaim`.
   - Our use: our rule is that "in progress" means being worked now. 30 beads are in progress with no change for 30 days.

## Structure

9. What is under this epic, at every level, and how much of it is closed?
   - Beads: `bd children`, `bd epic status`.
   - Our use: 2,221 parent links, up to seven levels deep. Plan is a tree of exactly this.
10. Which epic and which feature does this bead belong to?
    - Beads: `bd show` gives the parent.
    - Our use: Plan asks for a bead's parents.
11. Which component does this bead belong to?
    - Beads: labels.
    - Our use: each epic carries one label `tvm:component:<name>` and its whole subtree belongs to that component. 16 components. Plan shows, sorts and searches by it.
12. Which beads break our tree rules: a task or bug directly under an epic, a feature under a feature, or an epic still open though every child is closed?
    - Beads: `bd epic close-eligible` finds epics whose children are all closed.
    - Our use: the rule is epic, then feature, then task. 449 tasks and bugs sit directly under an epic today.

## Finding and counting

13. Which beads carry a given label, or any one of several labels?
    - Beads: `bd list --label`, `--label-any`.
    - Our use: 241 different plain labels, used 2,828 times; Plan filters by label.
14. Which open bugs are at priority 0 or 1?
    - Beads: `bd list` by type, status and priority (0 is most urgent).
    - Our use: 501 bugs, 79 of them open at priority 0 or 1.
15. How many beads are in each status, and of each type?
    - Beads: `bd status`, `bd count`.
    - Our use: Plan's data layer asks for the count per status. Today: 1,345 closed, 538 deferred, 315 open, 225 in progress, 1 blocked.
16. Which beads were created, or closed, in a given period?
    - Beads: `bd list --created-after`, `--closed-after`.
    - Our use: not in our rules or in Plan today; kept because any report of finished work needs it.

## Other links between beads

17. Which beads were discovered while working on this one, which beads are related to it, and which bead replaces it?
    - Beads: link types "discovered-from", "related", "supersedes".
    - Our use: 48 discovered-from links, 55 related, 7 supersedes. Our rule is to file a bead for anything found along the way.

## History

18. What happened to this bead and when, and who did it: created, claimed, status changed, labelled, closed, reopened?
    - Beads: `bd history`; every change is one entry.
    - Our use: 11,831 entries. The most common are label added, updated, created, status changed, closed and claimed.
19. What comments are on this bead, and by whom?
    - Beads: `bd comments`.
    - Our use: Plan reads a bead's comments. Only 27 exist, so this is the least used question here.

## Dispatch

20. Which beads belong to a wave, which wave, and what state is the wave in?
    - Beads: a custom bead type, and labels that hold a state.
    - Our use: a wave is a batch of beads dispatched to agents together. The wave is a bead of type "wave" carrying `tvm:wave=<state>`; each member carries `tvm:wave-of=<wave id>`. Plan has a Wave view.

## Noticed and left out

- Deferred-until dates, due dates and time estimates: beads has them; none is filled on any bead here. "Deferred" is used as a status only.
- Pinned beads and templates: never used here.
- Molecules, formulas, wisps and swarms: beads' work templates and short-lived beads; no rows here.
- Memories (`bd remember`): 40 here, but they are settings, not beads.
- External trackers (Jira, Linear, GitHub, Notion): one bead has an external reference.
- The free-form metadata on a bead: set on 30 beads; the ones looked at hold the process id of a dispatched agent.
- Work type (one worker or open competition) and specification ids: set on about 130 and 47 beads; nothing we ask depends on them.
- Which bead database a bead lives in: each repository has its own database and id prefix (`one-`, `exile-`). It matters once Plan reads from the model; until then the prefix of the id says it.
- Compaction, federation, sync and duplicate detection: how beads stores and moves data, not what a bead is.
