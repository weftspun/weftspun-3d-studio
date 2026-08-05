# RFD 0075: GitHub OAuth login, gated on weftspun org membership

**State:** prediscussion
**Scope:** `weftspun_studio`, the upload-admin routes

## Problem

Uploads need an admin, a real person, organized under a real
identity, not an open, anonymous route. The user asked for a way to
verify someone's GitHub identity and their `weftspun` org
membership, so only real org members can admin and organize
uploads.

## Decision

An OAuth App, not a GitHub App. The user needs to log in as
themselves and prove `weftspun` org membership. A GitHub App suits
an unattended deploy action instead, a different, separate need,
already distinguished from this one in the discussion that produced
this RFD.

Register the OAuth App by hand, GitHub gives no API for it, at
`github.com/organizations/weftspun/settings/applications/new`, name
`weftspun-studio`, homepage `https://weftspun-studio.fly.dev`,
callback `https://weftspun-studio.fly.dev/auth/github/callback`.
See `DETAILS.md` for the exact registration values, the login flow
`weftspun_studio` needs to add, and the org-membership check that
makes this a real gate, not only a login button.

## Related

RFD 0062 gives the Fly.io toplevel this login flow runs on. RFD 0058
names the zero-trust posture this session already applies
elsewhere, the same reasoning that makes an org-membership check
necessary here, not merely "logged in with GitHub."
