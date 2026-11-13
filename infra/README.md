# Deploy runbook — zoradox.com

The site is static files served by Caddy on a DigitalOcean droplet.
The Caddy vhost (caching headers, www redirect, 404 page) is **not** in this repo:
it lives in the portfolio-hub repo's Ansible role, the single source of truth for
`/etc/caddy`. Deploys here only copy files with rsync.

## Before deploying

- The server must be in your `~/.ssh/known_hosts` (connect once with `ssh` if not).
  Set `DEPLOY_HOST` to the same host string you use there (or an alias from
  `~/.ssh/config`). The server IP never goes in this repo.

## Deploy

Always dry run first, then deploy. Run from anywhere in the repo:

```bash
export DEPLOY_HOST=<host string from known_hosts>
infra/deploy.sh --dry-run    # lists what would change; changes nothing
infra/deploy.sh              # deploys
```

- Uploads `site/` to `deploy@$DEPLOY_HOST:/var/www/zoradox/` (set `DEPLOY_USER`
  to use another user). It prints only "deploying to zoradox.com", never the host.
- Skips dotfiles (`.git`, `.env`, `.DS_Store`, ...) except `.well-known/`, plus
  `node_modules/` and `*.md`.
- `--delete` removes files on the server that are no longer in `site/`. The script
  refuses to run if `site/index.html` is missing.
- It deploys your working tree, and warns if `site/` has uncommitted changes.
  Commit first, so every deploy can be rolled back.

## Rollback

Deploy the previous good commit or tag again:

```bash
git log --oneline -- site/          # find the last good commit
git checkout <commit-or-tag>        # detached HEAD is fine
infra/deploy.sh --dry-run
infra/deploy.sh
git switch main                     # back to your branch afterwards
```

Tip: tag each good deploy (`git tag deploy-2026-11-07 && git push --tags`) to make
this easier.

## Post-deploy checks

```bash
# Homepage: 200, cache-control: no-cache
curl -sI https://zoradox.com/ | grep -iE '^(HTTP|cache-control)'

# Font: cache-control: ... max-age=2592000
curl -sI https://zoradox.com/assets/fonts/inter-var.woff2 | grep -iE '^(HTTP|cache-control)'

# CSS and JS: cache-control: no-cache
curl -sI https://zoradox.com/css/styles.css | grep -iE '^(HTTP|cache-control)'
curl -sI https://zoradox.com/js/main.js | grep -iE '^(HTTP|cache-control)'

# www: 301, location: https://zoradox.com/
curl -sI https://www.zoradox.com | grep -iE '^(HTTP|location)'

# Missing path: 404 and the custom page (<title>Page not found — ZORADOX</title>)
curl -si https://zoradox.com/does-not-exist | grep -iE '^HTTP|<title>'
```

If a header is wrong, fix it in portfolio-hub's Ansible role, not here.

## Caddy logs

Reading the journal needs `sudo`, which asks for a password, so use an interactive
session. `-t` gives ssh a terminal for the password prompt; `-q` hides the
"Connection to ... closed" line, so the server address never appears:

```bash
ssh -tq deploy@"$DEPLOY_HOST" 'sudo journalctl -u caddy -n 100 --no-pager'   # last 100 lines
ssh -tq deploy@"$DEPLOY_HOST" 'sudo journalctl -u caddy -f'                  # follow live
```

<!--
CSP (not enabled yet; a note, not a header). When it's added, it goes in
portfolio-hub's Caddy vhost, not here:
- Start with Content-Security-Policy-Report-Only; enforce once reports are clean.
- script-src: hash for the one inline <head> script (index, thank-you, privacy):
  'sha256-WZRJfWvsnNCPcxzZwvyhovnZGqhZaC+8gPGPRbx6wTk='. Changing that script changes the hash.
- form-action and connect-src: https://api.web3forms.com (no-JS POST and fetch).
- No inline style attributes in site/, so style-src 'self' works.
Details: CLAUDE.md, "Later: Content Security Policy".
-->
