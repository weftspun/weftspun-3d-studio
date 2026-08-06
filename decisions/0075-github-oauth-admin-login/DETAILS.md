# RFD 0075 details: registration steps and the login flow

## Why an OAuth App, not a GitHub App

GitHub gives two different mechanisms for this kind of thing.

An OAuth App logs a user in as themselves; the resulting token
carries that user's own permissions. A GitHub App installs on
specific repos with its own fine-grained permissions and short-lived
installation tokens, independent of any one user's account, the
right tool for an unattended deploy action, not for "prove this is
really you."

This RFD's problem is squarely the first case: a person needs to
prove who they are and that they belong to `weftspun`, before
admining or organizing uploads. An OAuth App is the correct,
narrower tool for that, nothing more.

## Registration, done by hand

GitHub gives no API to script this part; it needs a browser, signed
in as an owner of the `weftspun` org.

1. Visit `https://github.com/organizations/weftspun/settings/applications/new`.
2. **Application name:** `weftspun-studio`
3. **Homepage URL:** `https://weftspun-studio.fly.dev`
4. **Authorization callback URL:** `https://weftspun-studio.fly.dev/auth/github/callback`
5. Click **Register application**. GitHub shows the **Client ID**
   directly. Click **Generate a new client secret** for the
   **Client Secret**, shown once.
6. Both values become Fly secrets, `GITHUB_OAUTH_CLIENT_ID` and
   `GITHUB_OAUTH_CLIENT_SECRET`, never committed to the repo, the
   same pattern RFD 0073's `VGW_ACCESS_KEY`/`VGW_SECRET_KEY` already
   set with `flyctl secrets set`.

## The login flow, not yet built

Two routes, added to `lib/weftspun_studio/router.ex`:

**`GET /auth/github/login`** redirects to GitHub's own authorize
URL, `https://github.com/login/oauth/authorize`, with `client_id`,
the callback `redirect_uri`, and `scope=read:org`. That scope reads
org membership only; it does not grant repo access, matching RFD
0058's zero-trust habit of asking for no more than the task needs.

**`GET /auth/github/callback`** receives the `code` GitHub appends,
exchanges it for an access token at
`https://github.com/login/oauth/access_token`, then calls
`GET /orgs/weftspun/members/{username}` with that token. GitHub
answers `204` for a real member, `404` otherwise, per GitHub's own
documented contract for that endpoint. Only a `204` starts a
session; a `404` ends the flow with a plain, honest "not a weftspun
member" response, not a silent failure.

## The real DevOps steps, as run

1. `flyctl secrets set GITHUB_OAUTH_CLIENT_ID=... GITHUB_OAUTH_CLIENT_SECRET=...
   --app weftspun-studio`, values from the hand-done registration
   above, run by the user directly rather than pasted into any
   chat transcript.
2. A signed-cookie session needs its own signing key, separate from
   the OAuth secrets. Generated with `openssl rand -base64 48`, the
   same urandom-based pattern RFD 0073 already used for
   `VGW_ACCESS_KEY`/`VGW_SECRET_KEY`, and set as a fourth Fly
   secret, `SECRET_KEY_BASE`, with
   `flyctl secrets set SECRET_KEY_BASE=... --app weftspun-studio`.
3. Each `flyctl secrets set` restarts the running machine on its
   own, independent of the GitHub Actions deploy pipeline, so the
   secret exists before the code that reads it ever deploys.

## Session storage: a signed cookie

Decided: `Plug.Session`, `store: :cookie`, signed with
`SECRET_KEY_BASE` above. No new database table, no new ETS
process, nothing to garbage-collect. `Plug.Router` sets no
`secret_key_base` on its own, unlike a Phoenix endpoint, so a small
plug sets `conn.secret_key_base` from the Fly secret before
`Plug.Session` runs.

## What still needs deciding

Session lifetime, and whether the org-membership check runs once at
login or again on some cadence, since a person removed from
`weftspun` after logging in should not keep admin access
indefinitely on an old session. Which upload-admin routes actually
exist to gate: none do yet, this session's own scope stops at
proving the login and membership check work, demonstrated on one
small protected route, not at building the upload-admin feature
itself.
