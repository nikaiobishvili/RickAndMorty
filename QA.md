# QA — 2026-11-25

## განხორციელებული scope

Required scope: Character List, server search/filter, infinite pagination, Character Details, expandable episodes, ყველა სხვა მონაწილის ჰორიზონტალური სია, participant-to-details navigation, Unit Tests და Light/Dark Mode.

Bonus implementation: disk API/image cache, English/Georgian localization აპის Settings-იდან შენახული არჩევანით, Portrait/Landscape და iPad multitasking-ის დასაშვები configuration. Favorites არ დამატებულა.

## ავტომატური შემოწმებები

- Swift Testing: 29 Unit Test. Double-ები რეალურ ქსელს არ იყენებს; persistence ტესტებს დამოუკიდებელი temporary directories აქვს და ასუფთავებს მათ.
- XCTest: 6 UI Test, Debug fixture repository-ითა და local PNG-ით. მოწმდება navigation/back, ყველა სხვა მონაწილიდან ბოლო მონაწილემდე მიღწევა, Georgian/Dark/Landscape/დიდი Dynamic Type და accessibility audit. Details-ის საინფორმაციო რიგები accessibility ზომებზე ვერტიკალურ layout-ზე გადადის.
- iPhone 18 Pro და iPad Pro 11-inch (M5), iOS 27.2 Simulator.
- Debug tests და Release build მოწმდება ცალ-ცალკე. Release-ში test fixtures გამორიცხულია.
- `git diff --check` მოწმდება საბოლოო ცვლილებებზე.

პირველმა accessibility audit-მა Character List-ის secondary ტექსტში contrast issue იპოვა. ტექსტი ახლა semantic primary color-ს იყენებს. Details-ის label/value რიგებიც primary ტექსტსა და adaptive layout-ს იყენებს. პრობლემური audit არ გამორთულა და issue არ დამალულა.

საბოლოო Settings/Light-Dark შემოწმებები:

- iPad: 29/29 Unit Test; 6/6 UI Test, სრული suite წარმატებულია.
- iPhone: ენისა და მხოლოდ Light/Dark-ის ორივე targeted UI Test წარმატებულია, ორივე გვერდის accessibility audit-ით. ძირითადი ოთხი UI flow და Unit suite ამავე სამუშაო ეტაპზე ცალკე შემოწმდა.
- Release: `BUILD SUCCEEDED`; `git diff --check`: სუფთა.
- iPad final report: `/tmp/RickAndMorty-completion/Logs/Test/Test-RickAndMorty-2026.11.25_11-20-12-+0400.xcresult`.
- iPhone preferences report: `/tmp/RickAndMorty-completion/Logs/Test/Test-RickAndMorty-2026.11.25_11-18-12-+0400.xcresult`.
- Screenshots-ით დადასტურებულია ქართულზე გადასვლისთანავე შეცვლილი ენის გვერდის სათაური და Background-ში მხოლოდ Light/Dark არჩევანი.

## გასამიჯნი manual QA

ქვემოთ ჩამოთვლილი შემოწმებები automated tests-ით დასრულებულად არ ითვლება:

1. VoiceOver-ის რეალური მოსმენა: row-ის სახელი/status/species ერთად იკითხება; decorative image გამოტოვებულია; episode-ის Expanded/Collapsed მდგომარეობა გამოითქმის; participant-ს აქვს სახელი და navigation hint. Automated accessibility audit ამას სრულად არ ცვლის.
2. რეალურ iPad-ზე მეორე აპთან multitasking, window resize და gestures. `UIRequiresFullScreen = NO`, ყველა iPad orientation და მოქნილი scroll layout კონფიგურირებულია; ორი აპის ერთდროული native window interaction ცალკე manual შემოწმებაა.
3. რეალურ მოწყობილობაზე მეხსიერება/ენერგია და minimum supported iOS 17.6-ზე smoke test. ამ გარემოში ტესტები iOS 27.2 Simulator-ზე შესრულდა.
4. ონლაინ/ოფლაინ ხელით სცენარი: ონლაინ გახსენი სია, კონკრეტული details/episode, დახურე აპი, გამორთე კავშირი და ხელახლა გახსენი ნანახი რესურსები. პირველად უნახავი რესურსისთვის მოსალოდნელია error/Retry. Cache fallback და დისკზე შენახვა Unit Tests-ით შემოწმებულია; მოწყობილობის airplane-mode სცენარი ცალკე manual QA-ა.

## In-app language და App Icon

Settings სიის ზედა მარცხენა gear ღილაკიდან იხსნება. მას ორი სექცია აქვს — Language და Background — ცალკე ქვეეკრანებით. Language-ში არჩევანია Follow system / English / ქართული. Background-ში მხოლოდ Light/Dark არის. Theme და ენა დამოუკიდებლად ინახება და relaunch-ზე აღდგება. დამატებითი ფერების პალიტრა და appearance-ის system არჩევანი ამოღებულია; legacy ფერის ველი იგნორირდება, პირველი გაშვების default არის Light. `AppSettings` არის shared @Observable state; `SettingsStore` abstraction-ის უკან UserDefaults ინახავს არჩევანს. `AppRootView` აკვირდება Locale-ს ისე, რომ არსებული navigation/data state არ იშლება. Settings sheet იღებს იმავე Locale-ს პირდაპირ, რათა ღია sheet-შიც მაშინვე შეიცვალოს ენა.

UI regression test-მა თავდაპირველად ღია sheet-ის თარგმნის პრობლემა გამოავლინა; root observation და sheet locale scope გასწორდა. iPhone-ზე target UI test-ით შემოწმდა English → ქართული → relaunch → English → Follow system. Dynamic status/error მნიშვნელობები explicit არჩეულ localization bundle-ს იყენებს. Error მნიშვნელობად ინახება და rendering-ისას ითარგმნება. ახალი ოთხი Unit Test ამოწმებს preference persistence/fallback-სა და explicit-language rendering-ს, ასევე theme-ის დამოუკიდებელ შენახვასა და legacy ფერების იგნორირებას.

App Icon არის 1024×1024 opaque PNG, `AppIcon.appiconset`-ში. `sips`-ით დადასტურებულია ზომა და alpha channel-ის არყოფნა; compiled Info.plist შეიცავს `CFBundleIcons/CFBundlePrimaryIcon/CFBundleIconName = AppIcon`. Asset generation prompt და method README-შია.

Settings-ის ტექსტს აქვს explicit `Color.primary`. Done ღილაკები ამოღებულია მთავარი Settings-იდან და ორივე ქვეეკრანიდან; არჩევანი ავტომატურად ინახება. უკან დაბრუნება ხდება native Back-ით, sheet-ის დახურვა — ჩამოსრიალებით. Language და Background ქვეეკრანებს სრული audit აქვთ; audit issues არ იფილტრება და არ იმალება.

## Cache-ის საზღვრები

Cache მაქსიმუმ 100 MiB-ია და ჩანაწერი 7 დღე მოქმედებს. ინახება მხოლოდ წარმატებული GET პასუხები. API network-first-ია, images cache-first. HTTP/decoding errors და cancellation არ იფარება cached success-ით. iOS-ს შეუძლია `Library/Caches` გაასუფთაოს; მუდმივი offline archive-ის გარანტია არ არსებობს.

## Git

არსებული სამუშაო checkpoint: `37ed75e` — `Add character browsing, filters, details, and episode navigation`, author `Nika Iobishvili`. ამ checkpoint-ის შემდეგი implementation ცვლილებები review-სთვის working tree-შია. Push არ შესრულებულა.
