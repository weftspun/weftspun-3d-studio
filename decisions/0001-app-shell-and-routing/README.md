# RFD 0001: App shell and routing

**State:** abandoned
**Feature:** app shell

## Problem

The app ships one viewport and many tools. Tools need separate
routes. The shell must keep one scene session.

## Decision

Use React Router with three routes.

- `/` is the main app.
- `/studio` is the Studio pipeline page.
- `/xr` is the IWSDK lab.

The main app mounts SceneManager, TaskManager, and the avatar
panels. The Studio page and the XR lab load lazily.

The shell inits the native face bridge and the remote log client.
Init errors do not block the viewport.

## References

- Routes: `src/main.jsx`
- Main app: `src/App.jsx`
- Studio page: `src/pages/StudioPage.jsx`
- XR lab: `src/pages/IwsdkImmersive.jsx`

## Related

RFD 0002 defines the Studio pipeline. RFD 0010 defines the XR lab.
