# br0kensmi1e.github.io

Personal writing, served via GitHub Pages at <https://br0kensmi1e.github.io/>.
No framework, package installation, analytics, external fonts, or build step.
Each post is a standalone styled `index.html` in its own subfolder.

## Structure

```
index.html          # landing page listing all posts
<post-slug>/
  index.html        # the published page
  index.md          # optional markdown source draft
  assets/           # style.css, favicon.svg, images
  artifacts/        # optional supplementary materials
```

## Adding a new post

1. `mkdir <post-slug>` and add `index.html` + `assets/`
2. Add an `<li>` entry to the post list in the root `index.html`
3. Commit and push — Pages deploys automatically

## Preview locally

```bash
open index.html
```
