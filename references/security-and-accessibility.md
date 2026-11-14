# Security, privacy and accessibility for Flutter

## Security based on real surfaces

- **Tokens and secrets:** do not put server secrets in `--dart-define`, assets, `pubspec.yaml` or the Flutter client as if they were confidential; a binary or web client can expose them. Keep secure credentials on the backend.
- **Authorization:** UI validations do not replace server-side validation/permissions. Do not accept resource IDs as proof of permission.
- **Storage:** choose a mechanism appropriate to the platform and sensitivity; do not persist sensitive tokens in plain web storage without assessing the risks.
- **Network:** check HTTP status/timeouts/errors, parse the JSON shape and limit data in logs. Do not disable TLS or accept certificates without validation.
- **Links and navigation:** validate URLs/deep links before executing actions and respect route auth/session.
- **Logs:** do not log passwords, tokens, personal data or sensitive bodies; do not surface raw technical errors to users.
- **Dependencies:** verify maintenance, license, compatibility, need and permissions before adding a package.

## Accessibility and usability

See https://docs.flutter.dev/ui/accessibility.

- Text readable at OS/browser scale, appropriate contrast and adaptation to long content.
- Semantics/labels/hints for icon-only controls and non-obvious interactions.
- Visible focus and correct tab order; escape/back/close reachable by keyboard on Web/desktop.
- Adequate touch targets for mobile apps, without sacrificing density on desktop if another accessible interaction exists.
- Do not use color alone to represent state (traffic lights), especially in warnings/errors. Add semantic text/icon.
- Avoid blocking with overlays/modals that cannot be closed or that do not restore focus.
- Test screen reader/semantics when it is a critical part of the flow and the platform allows it.

## Review rails

Security and accessibility alerts with demonstrated impact take priority over naming tweaks or style preferences. Do not suggest package/authentication changes blindly: inspect the real platform, backend and contracts.
