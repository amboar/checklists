# cl: Track and execute checklists

## Background

Often, execution of a task falls somewhere in a space of multiple axes: Some
tasks are performed once, never to be repeated, while others are repeated often;
some tasks are ill-defined and require a bunch of experimentation, while other
tasks are well understood and fairly rigid; finally, some tasks might have many
moving or unreliable parts while others have few or are reliable. Tasks that
fall into the former case of these axes tend not to be captured. Tasks that fall
into the latter category of these axes tend to be completely automated.

However, I've found there's ample ground in the middle: Tasks that are executed
semi-regularly, often irregularly enough to forget the details, while also
being ill-defined enough or have enough unreliable, moving parts that they are
difficult to script with confidence.

`cl` is a tool born from watching too much
[Air Crash Investigations][air-crash-investigations] - the use of checklists
by the aviation industry should equally apply to my life niche of writing and
maintaining software.

[air-crash-investigations]: https://www.imdb.com/title/tt0386950/

`cl` aims to provide confidence when executing tasks that rhyme in time but
suffer from variations on each execution. It combats the fragility of irregular,
detailed, and/or unreliable processes by discarding the rigidity of scripting
a task: It's sole job is to maintain markdown documents in a `git` repository.
`cl` doesn't put any requirements on the content of the documents, but it does
divide the documents it tracks into two categories:

1. Checklists
2. Executions

A "checklist" is something you might expect to execute multiple times, while
an "execution" is a specific instance of applying a checklist. `cl` tracks both
so you have a record of your executions, and allows you to promote an execution
to a checklist for later re-use.

The expectation is that checklists will evolve over time as exciting new failure
modes of the problem are understood or eliminated, with the executions tracking
the process and their discovery. As a bonus you get something approximating a
journal with a bit more structure than date-ordered entries alone.

The markdown documents are most useful if they are written using the task list
feature of [Github-Flavored Markdown][gfm-task-list]. Required commands and
notes can each be captured in (nested) list elements. Execution then becomes
a matter of checking off each item as the task proceeds, hopefully leading to
reliability of the outcome through completeness of the checklist.

[gfm-task-list]: https://github.github.com/gfm/#task-list-items-extension-

## Implementation Design Philosophy

The implementation tries not to be overly-prescriptive in the tools you must be
familiar with. Primarily, `cl` is a wrapper around `$EDITOR` and `git`, and is
implemented as a POSIX-compliant shell script.

## Installation

Run `make install` to symlink the script at `~/.local/bin/cl`

The script uses the git repository that contains it to track creation and
execution of checklists. Updating is a matter of merging changes from upstream.

## Usage

```
./scripts/cl.sh: Checklist maintenance and execution

Subcommands:

        add NAME
                Edit and track a new checklist named NAME

        backup TARGET
                Push the tracked checklists and executions to the remote git repository TARGET

        edit NAME
                Edit an existing checklist identified by NAME

        help
                Show help text

        list <checklists | executions>
                List checklists or executions

        promote EXECUTION CHECKLIST
                Lift the execution identified by EXECUTION to a checklist named CHECKLIST for reuse

        show <execution | checklist> NAME
                Output a checklist or execution identified by NAME

        rename CURRENT NEW
                Rename a checklist identified by CURRENT to NEW

        run EXECUTION [CHECKLIST ...]
                Execute a task, guided by zero or more checklists
```