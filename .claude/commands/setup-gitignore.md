# Setup Gitignore

Apply the appropriate .gitignore template to a project.

## Usage

```
/setup-gitignore [path] [template]
```

## Templates Available

| Template | Tech Stack |
|----------|------------|
| `python-fastapi` | Python/FastAPI backend with venv |
| `node-nuxt` | Nuxt.js/Vue frontend |
| `node-react` | React/Next.js frontend |
| `r-analysis` | R data analysis projects |

## Workflow

1. **Identify the project path** - Which repo needs gitignore?
2. **Detect tech stack** - Look for pyproject.toml, package.json, nuxt.config.ts, etc.
3. **Apply template** - Copy from `templates/gitignore/` to project root
4. **Verify** - Run `git status` to confirm build artifacts are now ignored

## Auto-Detection Logic

```
If pyproject.toml or requirements.txt exists → python-fastapi
If nuxt.config.ts exists → node-nuxt
If next.config.js or vite.config.ts exists → node-react
If *.Rproj or *.R files exist → r-analysis
```

## Example

```bash
# User: /setup-gitignore private-dev/new-project

# Claude detects package.json with nuxt, applies node-nuxt template
cp templates/gitignore/node-nuxt.gitignore private-dev/new-project/.gitignore

# Verify
cd private-dev/new-project && git status
```

## After Setup

If the repo already has tracked build artifacts:
```bash
# Remove from tracking (keeps files locally)
git rm -r --cached .nuxt node_modules dist
git add .gitignore
git commit -m "Add .gitignore, stop tracking build artifacts"
```
