# Three more competency questions for the beads model

Derived on 2026-11-19, the same way as the first 20: from what beads 1.3.4 itself records, and from what this workspace asks of it. They are needed because the model is about to hold the beads of more than one repository, copied in automatically, and Plan is about to read from it.

The first 20 questions stay as they are. These continue the numbering.

## Repositories

21. Which bead repository does this bead live in, and which beads does a repository hold?
    - Beads: every repository has its own bead database; `bd` works on the repository you are standing in. The file `.beads/metadata.json` in the repository names the database.
    - Our use: Plan lists the repositories it knows (the ones registered in its settings, and the ones it finds in submodules) and shows each one's beads. A link to a bead inside the app names the repository first, then the bead.
    - Evidence: two repositories today. The workspace holds 2,444 live beads; Exile, a submodule, holds 1.
    - The id does not answer it. The workspace database alone holds beads under three id prefixes: `one-` (2,412), `gist-` (31) and `ontool-` (1).
    - What is known about a repository: its name (`OneWorkspace`, `Exile`), its folder on this machine, and the name of its bead database (`beads_one`, `exile`).

22. Up to which change has each repository's copy been brought, and when?
    - Beads: every write is recorded as one commit in the bead database, and the database can name its latest commit in one step. The workspace database has 10,331 commits; its latest is a 32-character id such as `c4idvo5o8t62icvs284tlpbgqh5ktu2m`.
    - Our use: planned, not in use yet (bead one-h9t3.9). A sync copies every repository's beads into this model. It compares the commit it last copied with the repository's latest commit to decide what to copy, and Plan shows the person when each repository was last brought up to date.
    - A commit id alone does not say everything: Plan's own edits change the bead database's contents without making a commit. The database can also give a fingerprint of its current contents, another 32-character id, which changes with every edit.
    - What is recorded: per repository, the id of the commit last copied, the fingerprint of the contents at that moment, and the time the copy finished.

## Dispatch

23. Where does the agent dispatched for this bead run: which terminal session, which work folder, which branch, and which process?
    - Beads: a bead carries free-form data, set with `bd update --metadata`.
    - Our use: when Supervise dispatches an agent for a bead it writes these facts on the bead and reads them back to find the agent again. Our code reads: `tmux_socket`, `tmux_session`, `worktree_path`, `base_branch`, `runtime_branch_commit`, `dispatch_slot_id`, `codex_home`, `agent_pid`.
    - Evidence: 30 beads carry such data. `base_branch` and `runtime_branch_commit` are on 21 beads; `tmux_socket`, `tmux_session`, `worktree_path`, `dispatch_slot_id` and `codex_home` on 18; `agent_pid` on 5.

## Noticed and left out

- Who created a bead. Beads prints it (`bd show`, "Created by"), and it is filled on 2,411 of 2,444 beads with three different values. No screen of ours shows it and no rule of ours uses it. The owner and the holder are already in the model.
- Other free-form keys on beads (`catalogue_moves_owned` on 6 beads, `workflow_transition` on 4, `wave_phase` on 3, and a few more): written by agents, read by none of our code.
- The source-repository field on a bead: filled on 5 beads, all with the workspace's own name. Question 21 is answered by where the bead was read from, not by this field.
- The address the repository is pushed to: not looked at; nothing we ask depends on it yet.
