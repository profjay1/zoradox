# Deploy runbook — zoradox.com

The site is static files served by Caddy on a DigitalOcean droplet.
The Caddy vhost (caching headers, www redirect, 404 page) is **not** in this repo:
it lives in the portfolio-hub repo's Ansible role, the single source of truth for
`/etc/caddy`. Deploys here only copy files with rsync.

## Before the first deploy

- The portfolio-hub playbook must have run first. That run creates `/var/www/zoradox`
  and the Caddy vhost. Until then, there is nowhere to deploy to.
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
  to use another user).
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
# Font: long cache (30 days)
curl -sI https://zoradox.com/assets/fonts/inter-var.woff2 | grep -i '^cache-control'
#   expect: cache-control: ... max-age=2592000

# CSS and the homepage: always revalidated (no build step, so no hashed filenames)
curl -sI https://zoradox.com/css/styles.css | grep -i '^cache-control'
curl -sI https://zoradox.com/ | grep -i '^cache-control'
#   expect: cache-control: no-cache

# www redirects permanently to the apex domain
curl -sI https://www.zoradox.com/ | grep -iE '^(HTTP|location)'
#   expect: HTTP/2 301 (or 308), location: https://zoradox.com/

# Missing path: 404 status and the custom page
curl -s -o /dev/null -w '%{http_code}\n' https://zoradox.com/does-not-exist
curl -s https://zoradox.com/does-not-exist | grep -o '<title>.*</title>'
#   expect: 404, then <title>Page not found — ZORADOX</title>
```

If a header is wrong, fix it in portfolio-hub's Ansible role, not here.

## Caddy logs

Reading the journal needs `sudo`, which asks for a password, so use an interactive
session (`-t` gives ssh a terminal for the password prompt):

```bash
ssh -t deploy@"$DEPLOY_HOST" 'sudo journalctl -u caddy -n 100 --no-pager'   # last 100 lines
ssh -t deploy@"$DEPLOY_HOST" 'sudo journalctl -u caddy -f'                  # follow live
```
