# RickAndMorty

SwiftUI / MVVM აპი iPhone-ისა და iPad-ისთვის, Rick and Morty API-ით და მესამე მხარის runtime libraries-ის გარეშე. Minimum deployment target: iOS 17.6.

## გაშვება

გახსენი `RickAndMorty.xcodeproj`, აირჩიე shared `RickAndMorty` scheme და გაუშვი `⌘R`-ით. `⌘U` უშვებს Swift Testing Unit Tests-სა და XCTest UI Tests-ს. UI Tests ცალკე `RickAndMortyUITests` target-შია; Swift Testing გამოიყენება Unit Tests-ისთვის.

## ფუნქციონალი

- Character List, images, server search და status/gender/species filters.
- Infinite pagination, duplicate ID-ების გამოტოვება და Retry.
- Character Details, expandable episodes და ყველა სხვა მონაწილის ჰორიზონტალური სია; მიმდინარე პერსონაჟი გამორიცხულია.
- მონაწილეზე გადასვლა და უკან დაბრუნებისას უკვე ჩატვირთული სიის შენარჩუნება.
- Pull-to-refresh; განახლებისას არსებული მონაცემები რჩება, შეცდომა ცალკე ჩანს.
- Light/Dark Mode, Dynamic Type, semantic colors და accessibility labels/hints.
- English/Georgian localization აპის Settings ეკრანიდან: სიის ზედა მარცხენა gear ღილაკი → ენა → App language → სისტემის მიხედვით / English / ქართული. არჩევანი მაშინვე მოქმედებს და UserDefaults-ში ინახება. პერსონაჟების, ადგილებისა და ეპიზოდების საკუთარი სახელები API-ის ენაზე რჩება. ცნობილი status/gender და Human/Alien მნიშვნელობები ითარგმნება. Species-ის თავისუფალი საძიებო ტექსტი API-ის შესაბამისად English უნდა იყოს.
- აპის შიგნით მხოლოდ Light/Dark არჩევა: Settings → ბექგრაუნდი → Light ან Dark. რეჟიმი მოქმედებს სიაზე, Details-ზე, Filters-სა და Settings-ზე და ინახება ენისგან დამოუკიდებლად. პირველი გაშვების default არის Light. ფერების პალიტრა და appearance-ის Follow system არჩევანი არ არის.
- iPhone/iPad Portrait/Landscape. `UIRequiresFullScreen = NO` საშუალებას აძლევს iPadOS-ს აპი multitasking window-ში გახსნას; კონკრეტული window layout-ის მხარდაჭერა დამოკიდებულია iPadOS-სა და მოწყობილობაზე.

## Offline caching — bonus

`DiskResponseCache` ინახავს წარმატებულ პასუხებს `Library/Caches/RickAndMortyResponses`-ში, atomic writes-ით. Cache disposable-ია: iOS-მა შეიძლება წაშალოს. შენახვის მაქსიმუმია 100 MiB, ვადა — 7 დღე; ზედმეტი/ძველი ჩანაწერები იშლება. Cache-ის წაკითხვის ან ჩაწერის შეცდომა ონლაინ გამოყენებას არ აფერხებს.

API იყენებს network-first პოლიტიკას: კავშირის დაკარგვის, timeout-ის ან შესაბამისი transport error-ისას ბრუნდება იმავე URL-ის ვალიდური შენახული პასუხი. HTTP error, decoding error და cancellation cache-ით არ ინიღბება. სურათები იყენებს cache-first პოლიტიკას. პირველად უნახავი გვერდი, search ან episode offline ხელმისაწვდომი ვერ იქნება; წინასწარი სრული ჩამოტვირთვა არ ხდება. შენახული პასუხი შეიძლება მოძველებული იყოს. ეს cache არ არის მუდმივი database ან Favorites storage.

## არქიტექტურა და კოდის კითხვის რიგი

1. `App/RickAndMortyApp.swift` — Composition Root: ქმნის Repository-სა და APIClient-ს და გადასცემს ეკრანებს. აქ ხდება image loader-ის injection-იც.
2. `Features/Characters/CharacterListView.swift` — View მხოლოდ UI-ს ხატავს და მოქმედებებს ViewModel-ს გადასცემს. Navigation route არის მსუბუქი `Int` ID.
3. `CharacterListViewModel.swift` — screen state, search debounce, cancellation, request generation, pagination და refresh. `.task` იყენებს `loadIfNeeded()`-ს; უკან დაბრუნება უკვე ჩატვირთულ გვერდებს არ შლის.
4. `Data/CharactersRepository.swift` — API resources, query filters, filtered 404-ის ცარიელ სიად გარდაქმნა. Participants ჯგუფებად იტვირთება, სრული რაოდენობისა და თავდაპირველი რიგის შენარჩუნებით.
5. `Core/Network/URLRequestBuilder.swift` — URL, HTTPS/host validation, headers და timeout.
6. `Core/Network/APIClient.swift` — HTTP status და JSON decoding; `HTTPTransport.swift` — transport და cache policy; persistence დამალულია `ResponseCache` protocol-ის უკან.
7. `Details/CharacterDetailsViewModel.swift` — details/episodes და თითო episode-ის participants state. წარმატებით მიღებული მონაწილეები ViewModel-ის სიცოცხლის განმავლობაში თავიდან არ იტვირთება.
8. `Components/CharacterAvatar.swift` — injectable image loader, task cancellation, loading და fallback; networking logic View-ში არ არის.
9. `Features/Settings` — `AppSettings` ფლობს ენასა და Light/Dark რეჟიმს; `SettingsStore` persistence protocol-ია, `UserDefaultsSettingsStore` მისი რეალიზაცია. Settings-ის ორი სექცია ცალკე `LanguageSettingsView` და `BackgroundSettingsView` ეკრანებს ხსნის. View preferences-ის შენახვას პირდაპირ არ აკეთებს. Composition Root settings-სა და არჩეულ Locale-ს environment-ში გადასცემს. NavigationStack ენის ცვლილებაზე არ იქმნება თავიდან. Settings-ის ქვეეკრანები navigation title-ს არჩეული bundle-იდან პირდაპირ მიღებული ტექსტით აახლებენ; მის სანახავად გვერდიდან გასვლა საჭირო არ არის.
10. `Core/Localization` და `Localizable.xcstrings` — observable remote ტექსტები, validated cache და არჩეული bundle-ის fallback. `ErrorMessage` მნიშვნელობა ინახება ViewModel-ში; მისი ტექსტი View-ის Locale-ით ითარგმნება, ამიტომ უკვე ხილული error-იც ახალ ენაზე გადადის. იგივე Locale გამოიყენება status/gender მნიშვნელობებსა და თარიღებში. საკუთარი სახელები არ ითარგმნება.

Release build ყოველთვის რეალურ Repository-ს იყენებს. მხოლოდ Debug-ში `--ui-testing` არგუმენტი რთავს `PreviewRepository`-სა და local PNG loader-ს. UI Tests არ საჭიროებს API-ს ან ინტერნეტს. `--reset-settings` მხოლოდ UI Tests-ის ცალკე UserDefaults suite-ს ასუფთავებს და ჩვეულებრივი მომხმარებლის არჩევანს არ ეხება. `--dark-mode` მხოლოდ Debug UI შემოწმებისთვისაა; ჩვეულებრივ აპი სისტემის theme-ს მიჰყვება.

## Remote localization — Firebase REST

Project `rickandmorty-11c08` uses Realtime Database in `europe-west1`, with no Firebase SDK. Existing String Catalog translations remain the fallback. Settings sheets show a drag indicator across the Settings, language and background screens.

`LocalizationKey` contains stable server IDs and bundled-key mappings. Views use `LocalizedText(.settings)` or `localization.string(.settings, locale: locale)` for titles/labels. `CharacterDisplayText` and `ErrorMessage` use the same resolver. Personal character/episode names remain API content.

`AppRootView` triggers `LocalizationStore.refresh()` on app startup/foreground. A validated cached dictionary is activated before fetching. A successful GET activates and caches the new complete dictionary; missing keys use bundled translations in the selected language. Downloads, schema and placeholders are validated before cache replacement. Concurrent refreshes share one request. This is not a real-time listener: changing Console text does not push an update to an app that remains in the foreground. For a copy change, go Home and reopen the app, or relaunch; opening another Settings page alone is insufficient.

Once this integration is installed, existing remote copy changes require no new build. Adding a new screen or code key requires a build once. New key setup, JSON schema, endpoint and rules are documented in `Firebase/README.md`. The initial seed is a reference, not a file to re-import over subsequent Console edits.

## Unit Tests — რას ამოწმებს თითოეული

ტესტის ძირითადი ფორმაა Arrange (საწყისი მდგომარეობა) → Act (მოქმედება) → Assert (`#expect`). Doubles რეალურ HTTP-ს არ აგზავნის. `#require` წყვეტს ტესტს, თუ შემდგომი შემოწმების აუცილებელი მონაცემი არ არსებობს.

| Test | ქცევა და მისი მნიშვნელობა |
| --- | --- |
| `searchAndFiltersUseTheSameRequest` | spaces იშლება; name/status/gender/species ერთ სწორად encoded request-შია; page info იკითხება. |
| `participantBatchesPreserveAllOtherCharactersInEpisodeOrder` | 21 სხვა მონაწილე ორ request-ში სრულად ბრუნდება, API-ის არეული რიგი სწორდება. |
| `paginationAppendsOnlyNewCharacters` | გვერდები ერთიანდება დუბლიკატების გარეშე; ბოლო გვერდის შემდეგ request აღარ იგზავნება. |
| `paginationFailureKeepsTheFirstPage` | მეორე გვერდის შეცდომა პირველ გვერდს არ შლის და Retry URL რჩება. |
| `successfulResponseIsAvailableOffline` | წარმატებული პასუხი ინახება და შემდეგ offline ბრუნდება. |
| `cachedImagesAvoidAnotherNetworkRequest` | cache-first განმეორებით transport-ს აღარ იძახებს. |
| `cancellationDoesNotReturnCachedData` | cancellation-ს cached success ვერ ფარავს. |
| `serverErrorDoesNotReturnCachedSuccess` | 503 cached 200-ით არ ჩანაცვლდება. |
| `malformedJSONProducesDecodingError` | გაუმართავი JSON შესაბამის შეცდომად ბრუნდება. |
| `offlineWithoutCachePropagatesError` | შენახული პასუხის გარეშე offline შეცდომა caller-მდე მიდის. |
| `diskCacheSurvivesRecreationAndExpires` | cache ახალი instance-იდან იკითხება და ვადის შემდეგ აღარ ბრუნდება; დრო injection-ით კონტროლდება. |
| `diskCacheHonorsSizeLimitAndCorruptionIsAMiss` | დაზიანებული ჩანაწერი არ იწვევს crash-ს, ზედმეტად დიდი პასუხი არ ინახება. |
| `builderRejectsUntrustedNextPageURLs` | არასანდო host/scheme/port/path იბლოკება. |
| `georgianCatalogContainsTranslatedLabels` | ქართული resources build-ში მოხვდა და ძირითადი labels ითარგმნება. |
| `oldSearchResponseCannotOverwriteNewResults` | ახალი ძებნის პასუხის შემდეგ მოსული ძველი პასუხი state-ს ვერ შეცვლის; რიგს continuations აკონტროლებს. |
| `cancelledRequestDoesNotPublishResults` | გაუქმებული request UI state-ში შედეგს ვერ აქვეყნებს. |
| `searchAndFiltersResetPagination` | ახალი query/filter ძველ გვერდებს ანაცვლებს და pagination თავიდან იწყება. |
| `refreshFailureKeepsVisibleCharacters` | refresh-ის შეცდომისას ძველი სია და ახალი error ცალ-ცალკე რჩება. |
| `detailsFailureCanBeRetriedAndLoadedParticipantsAreReused` | Details-ის Retry მუშაობს; გაშლილი episode-ის წარმატებული პასუხი მეორედ არ იტვირთება. |
| `participantsFailureRequiresExplicitRetry` | შეცდომის შემდეგ ახალი მცდელობა მხოლოდ Retry-ით იწყება. |
| `returningFromDetailsKeepsLoadedPages` | ეკრანის ხელახალი გამოჩენა უკვე ჩატვირთულ გვერდებს არ ცვლის. |
| `failedRefreshRetainsPaginationURL` | წარუმატებელი refresh pagination-ის გაგრძელების შესაძლებლობას ინარჩუნებს. |
| `failedNewSearchDoesNotOfferPreviousQueryPagination` | ახალი ძებნის შეცდომისას ძველი query-ის შემდეგი გვერდი აღარ შეთავაზდება. |
| `sessionTransportAcceptsHTTPAndRejectsNonHTTPResponses` | `URLProtocol` double-ით რეალური URLSession adapter მოწმდება HTTP-ს, non-HTTP-სა და 503-ზე; გარე კავშირი არ გამოიყენება. |
| `filtered404MeansNoMatchesButUnfiltered404RemainsAnError` | filtered 404 ნიშნავს ცარიელ შედეგს, endpoint-ის unfiltered 404 კი შეცდომად რჩება. |
| `selectionUpdatesLocaleAndIsRestoredByNewSettings` | არჩეული ენა ცვლის Locale-ს, ახალი Settings instance აღადგენს არჩევანს; იმავე ენის ხელახლა არჩევა ზედმეტ write-ს არ აკეთებს. |
| `userDefaultsPersistsSelectionAndUnknownValuesFallBackToSystem` | რეალური UserDefaults adapter ინახავს ენას; არასწორი შენახული კოდი system არჩევანზე ბრუნდება. ტესტს საკუთარი suite აქვს. |
| `dynamicValuesAndExistingErrorsUseTheSelectedLanguage` | status და უკვე შექმნილი error არჩეული ენით ითარგმნება, 503-ის კოდი რჩება, საკუთარი სახელი უცვლელია. |
| `themePersistsIndependentlyOfLanguageAndLegacyColorsAreDiscarded` | Light/Dark ახალი Settings instance-იდან აღდგება, language შენარჩუნებულია; legacy ფერის ველი იგნორირდება, დაზიანებული appearance record Light-ზე ბრუნდება. |
| `providerDecodesValidatedReadOnlyResponse` | Firebase JSON იკითხება და მოწმდება GET, Accept header და fresh-request policy. |
| `incompatibleSchemaEmptyValuesAndInvalidPlaceholdersAreRejected` | არასწორი schema, ცარიელი ტექსტი და `{code}`-ის დაზიანება არ მიიღება. |
| `unknownKeysAndLanguagesAllowForwardCompatibility` | მომავალი ვერსიის უცნობი keys/languages მიმდინარე აპს არ აფუჭებს. |
| `providerRejectsHTTPFailuresLargeResponsesAndUntrustedURLs` | HTTP error, ზომის ზღვარი და დაუშვებელი endpoint სწორ შეცდომად ბრუნდება. |
| `diskCacheSurvivesRecreationAndRejectsCorruption` | ვალიდური თარგმანი დისკიდან აღდგება, დაზიანებული ფაილი გამოტოვებულია. |
| `remoteOverridesFallbackUsesRequestedLanguageAndFormatsArguments` | remote ტექსტი არჩეულ ენაზე გამოიყენება, missing key bundled-ზე ბრუნდება, error-ის `{code}` იცვლება; unsupported locale English-ს იყენებს. |
| `offlineStartupUsesLastValidCache` | offline გაშვებისას ბოლო ვალიდური cache რჩება. |
| `invalidDownloadNeverReplacesGoodCacheAndOlderRevisionIsIgnored` | არასწორი ან ძველი პასუხი ახალ/ვალიდურ თარგმანებს ვერ გადაწერს. |
| `editedTextWithSameRevisionIsRefreshedAndOfflineDoesNotEraseIt` | Console copy edit იმავე revision-ითაც აისახება; შემდგომი offline error ტექსტს არ შლის. |

## UI Tests და QA

`CharacterFlowTests` ამოწმებს list → details → episode → participant → back გზას, ბოლო მონაწილემდე გადახვევას, ქართული labels-ის არსებობას Landscape/დიდი ტექსტით და Character List/Details-ის automated accessibility audit-ს. ცალკე UI Test ამოწმებს Settings-ში English → ქართული ცვლილებას, ქართული status-ის გამოჩენას, app relaunch-ის შემდეგ არჩევანის შენარჩუნებას, English-ზე დაბრუნებასა და Follow system-ს. Background UI Test ამოწმებს Dark-ის არჩევას, app relaunch-ის შემდეგ აღდგენას, Light-ზე გადასვლასა და System/color-palette controls-ის არყოფნას. Language და Background ქვეეკრანები accessibility audit-ითაც მოწმდება. Remote fixture UI Test ამოწმებს სათაურის, status-ისა და ქართული ენის footer-ის remote მნიშვნელობებს, მათ შორის `111`-იან regression მაგალითს. Screenshots ინახება `.xcresult` attachments-ში.

Automated audit VoiceOver-ის რეალური მოსმენისა და მოწყობილობაზე multitasking gestures-ის შემოწმებას არ ცვლის. Final QA-ის შედეგები და ასეთი შეზღუდვები მოცემულია `QA.md`-ში.

## სასწავლო პირველი ნაბიჯი

მიჰყევი მხოლოდ პირველი გვერდის გზას: App → View `.task` → ViewModel → Repository → RequestBuilder → APIClient → Transport → DTO → ViewModel state → View. თითო საზღვარზე დასვი breakpoint და ნახე შემავალი/გამომავალი მნიშვნელობა. შემდეგ იგივე გზა დამოუკიდებლად ახსენი: ვინ იცის URL, ვინ ფლობს state-ს და რატომ არ აკეთებს View HTTP request-ს.

## App Icon

`RickAndMorty/Assets.xcassets/AppIcon.appiconset/AppIcon.png` — 1024×1024 RGB PNG, alpha channel-ის გარეშე. Asset Catalog მას iPhone/iPad-ის შესაბამის ზომებად გარდაქმნის; გარე rounded mask არ არის ჩახატული. Dark/Tinted რეჟიმებისთვის გამოიყენება სისტემის დამუშავება.

შექმნილია built-in `image_gen`-ით, შემდეგ 1024×1024 ზომაზე მომზადდა asset-ისთვის. გამოყენებული prompt:

> Use case: logo-brand. Create a finished iOS app icon for a Rick and Morty character explorer. Single bold swirling luminous lime-green interdimensional portal, a thick clean spiral with a few organic portal ripples, centered on a solid very dark navy background, high contrast, restrained premium cartoon/vector-like painted finish, instantly recognizable at 40 pixels. Full square opaque 1024 by 1024 artwork extending edge to edge. Portal occupies central 70 percent with balanced margin. No lettering, no characters, no text, no watermark, no mockup, no rounded outer icon corners (iOS applies its own mask), no border, no tiny scattered details. Save the generated image for integrating into the app asset catalog.
