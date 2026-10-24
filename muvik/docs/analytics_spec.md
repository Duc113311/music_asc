# Analytics spec (Muvik)

Same gateway design as smart_drink: every event goes through `Analytics`
(`lib/utils/analytics.dart`), which validates names, accepts string-only
parameters and drops events silently when Firebase is not up (Muvik works fully
offline). GA4 has no rename: changing an event name starts a new series, so settle
names here before shipping them.

## Rules

- Event name: 1-40 chars, a letter then letters/digits/underscore, no `firebase_`,
  `google_` or `ga_` prefix.
- Parameters are strings only. Bucket numbers into stable bands (see how smart_drink
  does it in its `Analytics` helpers) and never rename a band.
- No personal data: no song titles, artist names, file paths or e-mail addresses.
- New events get a named helper in `Analytics` so the list stays greppable, plus a row
  below.

## Events

| Event | Parameters | Sent from | Status |
|---|---|---|---|
| `screen_view` | `screen_name` = route (`/home`, `/player`, ...) | `RouteAnalytics.onRouting` (every named route; tabs inside the home shell are not routes) | live |

## Candidates (not implemented, decide before adding)

| Event | Why | Parameters (all strings) |
|---|---|---|
| `scan_completed` | Does the automatic library check find music? | `songs_bucket`, `source_type` (`mediastore`/`saf`), `result` (`success`/`partial`/`empty`) |
| `language_selected` | First-run language screen | `language`, `source` (`first_run`/`settings`) |
| `tab_view` | Which tab (Home, Library, Stats, Settings) is used | `tab` |
| `play_started` | Core usage | `source` (`library`/`playlist`/`stats`/`search`), no song data |
| `onboarding_step` | Funnel of the first-run flow | `step`, `action` |
| `permission_result` | Audio/notification permission funnel | `permission`, `result` |

## User properties

None yet. Candidate: `language` (the app locale), `library_size_bucket`.
