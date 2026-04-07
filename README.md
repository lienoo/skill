# Skill Pack

This repository packages two reusable skills:

- `handoff`
- `resume-handoff`

They are stored under `skills/` and can be installed into a local skills directory with `bin/install-skills.sh`.

## Quick Install

```bash
git clone git@github.com:lienoo/skill.git
cd skill
bash bin/install-skills.sh
```

Default install target priority:

1. `~/.codex/skills` if it already exists
2. `~/.agents/skills` if `~/.codex/skills` does not exist and this directory exists
3. Create `~/.codex/skills` if neither exists

## Install To A Specific Directory

Use `--target` to install to an explicit existing directory:

```bash
bash bin/install-skills.sh --target ~/.agents/skills
```

If `--target` points to something that is not an existing directory, installation fails.

## Manual Install

Copy these directories to your target skills root:

- `skills/handoff`
- `skills/resume-handoff`

Example:

```bash
mkdir -p ~/.codex/skills
cp -R skills/handoff ~/.codex/skills/
cp -R skills/resume-handoff ~/.codex/skills/
```

## Update Flow

```bash
git pull
rm -rf ~/.codex/skills/handoff ~/.codex/skills/resume-handoff
bash bin/install-skills.sh
```

If you installed into `~/.agents/skills` or another custom directory, remove or move the old directories in that target before running the installer again.

## Conflict Behavior

If target skill directories already exist, installer exits non-zero and prints a message asking you to remove or move existing directories manually.
