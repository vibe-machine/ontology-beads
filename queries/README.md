# Questions

The questions Beads is meant to answer, and the query that answers each one. Installing the package stores them in the database as `StoredQuestion` and `StoredQuery` records.

1. What is recorded about this bead: its title, description, design, acceptance criteria, notes, type, status and priority? — [`queries/what-is-recorded-about-bead-one-3.tql`](what-is-recorded-about-bead-one-3.tql)
2. Who owns this bead, who holds it now, when was it created, started and closed, and why was it closed? — [`queries/who-owns-and-holds-bead-one-3-its-key-times-and-close-reason.tql`](who-owns-and-holds-bead-one-3-its-key-times-and-close-reason.tql)
3. Which beads are ready to start: open, nothing open in front of them, most urgent first? — [`queries/which-beads-are-ready-to-start-most-urgent-first.tql`](which-beads-are-ready-to-start-most-urgent-first.tql)
4. Which beads are blocked, and by which open beads? — [`queries/which-beads-are-blocked-and-by-which-open-beads.tql`](which-beads-are-blocked-and-by-which-open-beads.tql)
5. What does finishing this bead unblock? — [`queries/what-finishing-bead-one-13-unblocks.tql`](what-finishing-bead-one-13-unblocks.tql)
6. Which beads wait on a person's approval, and which approvals are still open? — [`queries/which-beads-wait-on-a-person-s-approval-and-which-approvals.tql`](which-beads-wait-on-a-person-s-approval-and-which-approvals.tql)
7. Which beads are being worked on right now, and who or which agent holds each one? — [`queries/which-beads-are-being-worked-on-now-and-who-holds-each.tql`](which-beads-are-being-worked-on-now-and-who-holds-each.tql)
8. Which beads are marked in progress but have gone quiet for a number of days? — [`queries/which-in-progress-beads-have-gone-quiet-for-30-days.tql`](which-in-progress-beads-have-gone-quiet-for-30-days.tql)
9. What is under this epic, at every level, and how much of it is closed? — [`queries/what-is-under-epic-one-1-at-every-level-and-its-status.tql`](what-is-under-epic-one-1-at-every-level-and-its-status.tql)
10. Which epic and which feature does this bead belong to? — [`queries/which-epic-and-feature-bead-one-5-belongs-to.tql`](which-epic-and-feature-bead-one-5-belongs-to.tql)
11. Which component does this bead belong to? — [`queries/which-component-bead-one-5-belongs-to.tql`](which-component-bead-one-5-belongs-to.tql)
12. Which beads break our tree rules: a task or bug directly under an epic, a feature under a feature, or an epic still open though every child is closed? — [`queries/which-beads-break-our-tree-rules.tql`](which-beads-break-our-tree-rules.tql)
13. Which beads carry a given label, or any one of several labels? — [`queries/which-beads-carry-the-label-ux-or-backend.tql`](which-beads-carry-the-label-ux-or-backend.tql)
14. Which open bugs are at priority 0 or 1? — [`queries/which-open-bugs-are-at-priority-0-or-1.tql`](which-open-bugs-are-at-priority-0-or-1.tql)
15. How many beads are in each status, and of each type? — no query yet
16. Which beads were created, or closed, in a given period? — no query yet
17. Which beads were discovered while working on this one, which beads are related to it, and which bead replaces it? — no query yet
18. What happened to this bead and when, and who did it: created, claimed, status changed, labelled, closed, reopened? — no query yet
19. What comments are on this bead, and by whom? — no query yet
20. Which beads belong to a wave, which wave, and what state is the wave in? — no query yet
