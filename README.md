# claude-skills

Selected [Claude Code](https://code.claude.com) skills for makers: 3D printing, CAD and
workshop techniques. Each one is a separate plugin, so install only the ones you want.

## Skills

| Skill | What it's for |
|---|---|
| [strengthening-prints-with-internal-holes](strengthening-prints-with-internal-holes/) | Make FDM prints much stronger in joints, forks and bosses without raising infill, using hidden internal holes that force the slicer to add extra perimeters. Includes paste-ready OpenSCAD and an STL checker. |

## Install

Inside Claude Code:

```
/plugin marketplace add symmetryninja/claude-skills
/plugin install strengthening-prints-with-internal-holes@symmetryninja
```

Or from a shell:

```bash
claude plugin marketplace add symmetryninja/claude-skills
claude plugin install strengthening-prints-with-internal-holes@symmetryninja
```

Claude then uses the skill on its own whenever a task matches. You can also call it directly
with `/strengthening-prints-with-internal-holes:strengthening-prints-with-internal-holes`.

The skills follow the open [Agent Skills](https://agentskills.io) format, so the `skills/`
folders also work in other agents that support it. Copy a skill's folder into that agent's
skills directory.

## License

MIT. See [LICENSE](LICENSE).
