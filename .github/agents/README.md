# Copilot Agents for Sundee-Fundee

This folder contains helper definitions and documentation for AI agents that
assist with development of the workout app.  The names match the high-level
domains defined in project planning.

Each agent is typically registered via the GitHub Copilot CLI (`gh copilot
agent create`); the YAML files below serve as templates that can be copied to
workflows or passed to the CLI when creating the agent.

## Available agents

- `db-migration` – schema changes and migration tests
- `program-data` – add/edit json programs and related tests
- `calculations` – business logic helpers and unit tests
- `context` – work with React context providers and integration tests
- `ui-component` – create/modify React components and RTL tests
- `recommendation` – plateau/PR recommendation rules
- `sync-supabase` – cloud sync layer and e2e tests

To register an agent, run a command similar to:

```sh
gh copilot agent create db-migration \
  --description "Help update database schema and migration tests" \
  --script "# your script or commands here"
```

Replace the `--script` value with the sequence of steps you'd like the agent to
perform.  Adjust the names and descriptions as needed for your workflow.

Each domain also has a Markdown file in this directory describing the
typical responsibilities and reminders for working in that area.
