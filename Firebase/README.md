# Firebase Realtime Database localization

Firebase project: `rickandmorty-11c08`, Spark plan, Realtime Database in `europe-west1`. This dedicated database contains only RickAndMorty localization data.

Read endpoint: `https://rickandmorty-11c08-default-rtdb.europe-west1.firebasedatabase.app/localization/v1.json`.

The app uses URLSession and the documented Realtime Database REST API, without Firebase SDK dependencies. Bundled String Catalog translations remain available as fallback.

- `localization.seed.json`: initial complete English/Georgian dictionary exported from the bundled catalog. Already imported once. Do not re-import at root to edit one value: that would overwrite Console changes, including current text edits.
- `database.rules.json`: public reads are allowed only under `/localization/v1`. All client writes and other reads are denied. Authorized Firebase Console administrators can manage text values through their project permissions.
- `localization.keys.json`: stable remote ID → bundled source key mapping. Change translation values, not these IDs. IDs use underscores because Realtime Database keys cannot contain periods and certain other characters.

The actual endpoint is configured in `FirebaseLocalizationConfiguration.swift`. No admin credentials or Firebase SDK are included in the app.

`schemaVersion` describes the payload format. `revision` increases when publishing a changed translation set. `languages.en.strings` and `languages.ka.strings` contain the text values. The server-error message uses `{code}`; keep that token in both languages. Client validation rejects unsupported schema versions, empty text and incompatible placeholders, and retain the last valid cached dictionary when fetching fails.

Implemented behavior: load bundled/cached text without waiting for networking; refresh translations at app startup/foreground; use a per-key bundled fallback for missing remote entries. A normal REST request is not a real-time subscription. Editing Firebase changes what the next successful refresh receives; it does not push updates into every open app instantly.

Do not enable client write access or put private information in this public translation subtree. Do not use broad test-mode rules. Remote content changes existing text; new functionality still requires an app build.

## Editing an existing value

Open Data → localization → v1 → languages → ka (or en) → strings. Edit the value beside an existing key; keep its key unchanged. Values are visible after the app's next successful startup/foreground refresh. Merely closing and reopening a Settings page does not perform another fetch. This is REST, not a push listener.

The current app accepts text edits with the same `revision`; increasing it is useful for tracking grouped publishes. Older revisions never replace newer cached ones. For a rollback, publish the old content under a higher revision. `revision` is metadata, not an automatic backup. Export a snapshot before bulk changes.

## Adding a new key

1. In both `languages/en/strings` and `languages/ka/strings`, use Add child to create the same stable ID, such as `episode_details_title`, with each language's text. This example is not an implemented feature.
2. Add `case episodeDetailsTitle = "episode_details_title"` to `LocalizationKey` and map its `bundleKey` to `Episode details`.
3. Add the bundled English and Georgian `Episode details` translations in `Localizable.xcstrings`, with extraction state manual.
4. Use `LocalizedText(.episodeDetailsTitle)` in the new View. Keep `localization.keys.json` and the seed reference in sync when adding keys; do not overwrite live Console edits with the seed.

An app that does not know the new key cannot display a newly added screen without a build. Once the screen/key ships, changing its remote text needs no rebuild. Unknown remote IDs are ignored by old app versions, and missing IDs fall back to the bundled catalog. Unsupported system languages use English remote values and bundled fallback.

## Architecture and verification

`FirebaseLocalizationProvider` performs GET through `HTTPTransport`; `RemoteLocalization.validated()` checks schema, known string values and placeholders; `LocalizationStore` activates a complete validated document, coalesces overlapping refreshes and preserves the last good data; `DiskLocalizationCache` saves atomic JSON in Library/Caches. `LocalizedText` observes that store and Locale. Navigation titles and accessibility labels also use the same store. Names supplied by the character API remain untranslated.

Responses above 256 KiB are rejected before JSON decoding; known text values are limited to 4096 UTF-8 bytes, and request timeout is 10 seconds. HTTP failures and invalid data keep the last valid document. Cache files may be removed by iOS; bundled fallback is always retained. The API/image cache is separate from localization cache.

The catalog uses manual entries because lookup is through stable keys; automatic Xcode string-symbol generation is disabled since `LocalizationKey` already provides typed identifiers. This also avoids generated-symbol collisions for bundled keys such as `Type`.

Unit tests use protocol doubles, not the live service. UI tests have isolated bundled/remote fixtures. Production endpoint checks confirmed `200` on `/localization/v1.json` and `401` on the database root. The Console write rules deny client writes at all paths.
