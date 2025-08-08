# Changelog

## [Unreleased]

- Improve precision of cleanups to support concurrent checklist execution
- Allow embedding and execution of abitrary scripts in checklists
- - See the documentation for `cl run ...`
- Export `$CL_EXECUTION_LABEL` into the editor environment and substitute
- instances in the execution document
- Filter attachments out of execution list
- Add 'resume' subcommand to resume existing executions
- Move attached artifacts under execution slug directory
