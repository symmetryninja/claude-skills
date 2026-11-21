# claude-skills

A public collection of selected Claude Code skills, published as a plugin marketplace.
Each top-level folder is one plugin holding one skill.

## Rules

- **This repo is public.** Nothing private goes in: no keys, tokens or credentials, no
  personal email addresses, hostnames, IPs, local paths or machine names, and nothing
  from private projects. Scan before every commit (`just scan`).
- **Selected skills only.** A skill comes here only when its owner chooses to publish it.
  Skills tied to private projects stay out.
- **Commits** use the GitHub no-reply author address (set in this repo's git config).
- **Images** have their metadata stripped before committing (`just strip-images`).
- **Adding a skill:** create `<skill-name>/` with `.claude-plugin/plugin.json`,
  `skills/<skill-name>/SKILL.md` and a `README.md`. Add an entry to
  `.claude-plugin/marketplace.json` and a line to the top-level README, then run `just check`.
- **History:** add a plain-language entry to `HISTORY.md` after each meaningful change.
