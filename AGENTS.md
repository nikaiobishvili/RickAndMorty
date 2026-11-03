# RickAndMorty Project Instructions

## Project goal

This is a learning-focused, production-style SwiftUI application using the Rick and Morty API.

The user is building the application personally from scratch. The primary goal is to understand every implementation decision, especially SwiftUI, MVVM, networking, navigation, concurrency, and unit testing.

## Communication

- Communicate in Georgian. Keep code, type, method, API, file names, and established technical terminology in English.
- Explain the reasoning before proposing code, with enough detail for learning.
- Give only one manageable implementation step at a time.

## Official assignment scope

- Build an iOS/iPadOS application using the Rick and Morty API and Swift, without third-party libraries.
- Show an infinite Character List with at least a name and image for every character, with search/filter functionality.
- Tapping a character opens its Character Details with detailed character information.
- Show the character's episodes as sections, each expandable using a button.
- Expanding an episode shows a horizontally scrollable list of images of all other characters participating in that episode. Exclude the character whose details are currently displayed; do not silently truncate the other participants.
- Tapping a participant image opens that participant's Character Details.
- Include Unit Tests, Light/Dark Mode, and production-quality behavior and code.
- Apple Human Interface Guidelines compliance is an official plus; GitHub publication is desirable and requires explicit approval.
- Official bonus scope: offline caching, localization, Portrait/Landscape, and iPad split screen (multitasking, not necessarily a split-column navigation UI).
- Orientation support remains an agreed project goal. Keep bonus completion separate from required-scope completion.
- Favorites are an optional extra requiring separate user approval, not part of the required implementation order.

## Development approach

- Work incrementally in small, understandable steps.
- Explain the purpose and behavior of code before proposing it.
- The user should normally type the implementation personally.
- Do not implement an entire feature unless the user explicitly asks.
- Do not edit files unless the user explicitly requests an edit.
- When reviewing code, diagnose and explain before changing it.
- Do not overengineer early stages.
- Build the visual UI with mock data before integrating the API.
- Preserve all existing user changes.
- Do not change Google Drive documents without explicit user approval.
- Build the project independently from scratch. Do not open or use RickAndMorty-iOS.zip.

## Project technical decisions

These choices refine the official assignment; it permits either UIKit or SwiftUI and does not prescribe MVVM, a deployment version, or a testing framework.

- Use Swift and SwiftUI.
- Use MVVM.
- Minimum deployment target is iOS 17.
- Support iPhone and iPad.
- Support Portrait and Landscape orientations.
- Plan iPad split screen support as an official bonus goal.
- Support Light and Dark Mode.
- Use NavigationStack for SwiftUI navigation.
- Use Observation with @Observable for view models.
- Isolate UI-facing view models with @MainActor.
- Do not use third-party libraries.
- Follow Apple Human Interface Guidelines.
- Use semantic colors, Dynamic Type, and accessibility labels.
- Never mention TBC anywhere in the project.

## Architecture responsibilities

- Views render UI and own only local presentation state.
- ViewModels own screen state and presentation logic.
- Networking and persistence must be abstracted behind protocols.
- Route values should be lightweight and Hashable.
- Avoid placing networking, persistence, or business logic directly in Views.
- Add abstractions only when the project actually needs them.
- Choose concrete filter fields, extra row fields, detail fields, and localization languages explicitly; do not present them as verbatim assignment requirements.

## Testing

- Use Swift Testing for unit tests.
- Explain every test because the user is learning unit testing from zero.
- Unit test ViewModels, decoding, networking behavior, pagination, search/filter logic, and persistence.
- Use protocol-based test doubles instead of real network requests.
- Run relevant tests after implementation changes when possible.

## Git workflow

- Keep changes small and commit-ready.
- Never commit, push, create branches, or open pull requests without explicit user approval.
- Before suggesting a commit, summarize exactly which files changed.
- Suggest a focused English commit message.
- Preserve unrelated working-tree changes.
- A clean main branch or a commit is not a prerequisite for every learning step. Preserve existing uncommitted work.
- Do not use destructive Git commands.

## Current development order

1. Configure the project and deployment targets.
2. Build the Character List visual UI with mock data.
3. Add Character API models and decoding tests.
4. Add testable networking and relevant tests.
5. Add the repository and Character List ViewModel, then connect the existing UI to real data.
6. Add pagination and its tests.
7. Connect the search/filter UI to real query logic, cancellation, pagination reset, and tests.
8. Build Character Details with mock data and lightweight Hashable navigation routes.
9. Connect Character Details to real data and test its state transitions.
10. Build expandable episode sections and the complete other-participant image list, then connect data and participant-to-details navigation with tests.
11. Verify all required assignment acceptance criteria.
12. Implement agreed bonus stages: offline caching, localization, and complete orientation/iPad split screen verification.
13. Finish documentation and final QA. Address accessibility and adaptive layout throughout UI development, not only at the end.
