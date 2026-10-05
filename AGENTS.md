# Agent guidelines

Instructions for AI coding agents working in this repository. See `README.md` for what the
project is, its settings, and how to use the image.

## Development

How to check your own work here. Check each change with these commands before you call it done,
fix what fails, and report what you ran and what it returned. CI only builds the image, so these
are the only checks of what the image does.

- Set up: Docker with BuildKit (`docker-buildx`), and `shellcheck`. Build the image from the
  working tree with `docker build --ulimit nofile=1024:1024 -t jeffersonlab/keycloak:dev .`
  (about 20 seconds). Without the ulimit, `dnf` in the builder stage spins at full CPU for more
  than ten minutes on Docker 29; CI doesn't need it.
- On every change to a script, run `shellcheck -S warning` on the files you changed and add no
  new warnings. The existing SC2034 and SC1090 warnings are expected: setup scripts set variables
  for, and source, `kc-lib.sh`.
- On every change, rebuild the image and run it alone, with its built-in database, on a free port
  (about a minute):

  ```bash
  docker run -d --rm --name keycloak-check -p 8082:8080 \
    -e KC_FRONTEND_URL=http://localhost:8082/auth -e KC_BACKEND_URL=http://localhost:8080/auth \
    -e KC_HTTP_RELATIVE_PATH=/auth -e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
    -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin -e KC_CLIENT_NAME=test -e KC_RESOURCE=test \
    -e 'KC_REDIRECT_URIS=["https://localhost:8443/test/*"]' jeffersonlab/keycloak:dev
  timeout 240 bash -c 'until [ "$(docker inspect -f "{{.State.Health.Status}}" keycloak-check)" = healthy ]; do sleep 3; done'
  ```

  The container turns healthy once the setup scripts have run, even if one of them failed, so
  also read `docker logs keycloak-check` for errors, and check what you changed with `kcadm.sh`:
  `docker exec keycloak-check /opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080/auth --realm master --user admin --password admin`,
  then, for example, `docker exec keycloak-check /opt/keycloak/bin/kcadm.sh get-roles -r test-realm --uusername jdoe`
  (`test-user` and `test-admin`). The test client does not allow password grants, so token
  requests for the test users fail by design. `docker stop keycloak-check` removes it.
- Before opening a pull request that touches Oracle, LDAP, or the compose files, also run the
  full stack: Oracle XE, 389 Directory Server, and Keycloak built from the working tree.
  `docker build --ulimit nofile=1024:1024 -t keycloak-keycloak .` (compose can't pass the ulimit),
  then `docker compose -f build.yaml up -d --wait`, and `docker compose -f build.yaml down` when
  done. It uses ports 8081, 9990, 1521, 5500, 3389, and 3636 and the fixed container names
  `keycloak`, `oracle`, and `dirsrv`, so only one copy runs in a VM: check `ss -ltnp` and
  `docker ps` first. Other projects run their own Keycloak on 8081; never stop it, ask instead.
- Test data: the default setup creates `test-realm`, the client from `KC_CLIENT_NAME` with the
  secret in `scripts/defaults/00_config.env`, and four users (`jadams`, `jsmith`, `tbrown`,
  `jdoe`) with the password `password`. Containers have no volumes, so each new container starts
  fresh and runs setup again; recreate it to reset.
- Outside systems: databases (the `oracle` container stands in), LDAP directories (`dirsrv`), and
  the Kerberos, SPNEGO, SAML, and OIDC identity provider setups in `scripts/`, which have no
  stand-in here. Never point the image at JLab's real directories, KDCs, identity providers,
  databases, or Keycloak servers.
- `scripts/kc-lib.sh` is the image's client-tools interface: users' own setup scripts call its
  functions and set its variables. Keep them compatible, or say in the pull request that the
  change breaks them.
- New settings are environment variables, documented in the README's Configure table. The setup
  marker's location is set in both `container-entrypoint.sh` and `container-healthcheck.sh`; keep
  them in sync.
- Never commit secrets. The passwords and client secret in this repository are for local testing
  only.

## Commit identity

Commits written by an agent must say so. Before committing, check that the repository-local
identity (never `--global`) is that of the GitHub App bot you push with, so GitHub links the
commits to it and squash commits show the same name. Never commit under a person's name or
email. Name the agent and model in a trailer: keep the one your tool adds (such as
`Co-Authored-By`), or else add `Assisted-by: <agent>:<model>`.

## Commits

- Imperative summary line, then a body explaining what changed and why.
- Squash merges use the commit messages: write the first one for `main`.
- Commit and push only when asked.

## Branches and pull requests

- Start each task on a new branch from an up-to-date `main`; target `main`. Work only in your
  own clone or worktree.
- Label every pull request `source::ai`, and make the person who reviews it both reviewer and
  assignee (ask for their username if you don't know it).
- You cannot add items to the JeffersonLab organization's project: when you report back, list
  the pull requests and issues you opened, so the person can add them to the period's project.
- Never change `VERSION` unless asked: a change to it on `main` releases the project (tag, GitHub
  release, and Docker image on Docker Hub). When asked, open a pull request that changes only
  `VERSION`, with the commit message `Bump version from X.Y.Z to X.Y.Z`, and write any upgrade
  steps in its description for the maintainer to add to the release.
- A person reviews and merges, and merged branches are deleted; never merge, approve, or enable
  auto-merge yourself.
- Before pushing to a pull request's branch, check that it is still open: commits pushed after it
  merged never reach `main`, so put them in a new pull request.
- To build on a pull request still in review, branch from its branch and target that branch,
  saying so in the description. Once the first merges, check that yours now targets `main`, and
  retarget it if not.
- Describe what changed, any deployment steps, and the checks you ran, including what you could
  not run. Add a short Decisions part: what the person questioned or changed during the session,
  which alternatives were dropped and why, and any second opinion that changed something.
- After pushing, wait for the pull request's checks to finish before reporting it ready (`ci`,
  which builds the image). Read failed jobs' logs and fix the cause; never skip or weaken a check
  to pass it. Report how they ended, and say if one failed for a reason outside your change.
- Name the issue a change is for in the commit body: `Fixes #<issue>`, or `Part of #<issue>` if
  some of it stays open. Work you were asked to do needs no issue.
- For something outside your task (another project, code another agent is working on, or a
  change that needs a decision), don't fix it in passing: offer to open an issue, labeled
  `source::ai` and assigned to the person you work with, with what you found, the evidence, and a
  suggested fix.
- When asked to plan work for other agents: check claims before filing, list draft issues before
  filing them, make each one self-contained with "Done when" and what not to do, say which can
  start now and which are blocked or share files, and ask before filing anything
  security-sensitive.
- When asked to address a review, reply in each thread with what you changed, and push new
  commits rather than rewriting ones already reviewed; the reviewer resolves the threads.
- When the person corrects you on something any agent here should know, propose adding it to
  this file, or better a check that catches it. Keep one developer's preferences out of it.
- When asked to review a pull request, ask whether to comment or commit; default to comments. To
  commit, add one commit per recommendation on top of the author's (never rewrite theirs), then
  post one comment listing each commit and what you tested, and that the author must pull. Never
  approve, merge, or resolve threads.
