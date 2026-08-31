<div align="center">

<img src="ios/Assets.xcassets/AppIcon.appiconset/miranda.png" width="112" alt="Miranda app icon">

# Miranda

### Remember less. Focus more.

**A calm, single-priority app for busy minds.**

Miranda keeps the one thing that matters in front of you, without turning your life into another system to manage.

</div>

## One priority, always visible

Traditional task managers are good at holding everything. For an already busy mind, seeing everything can be the problem.

Miranda takes a different approach: capture what is on your mind, choose what matters now, and keep that priority where you will naturally see it. Finish it, then move to the next. No projects to maintain, tags to curate, or inbox to clear.

It is designed for people with ADHD, people experiencing decision fatigue, and anyone who wants a lighter alternative to a full productivity system.

## How it works

1. **Capture the thought.** Add a note by typing or using on-device voice input.
2. **Choose what matters.** Promote and reorder priorities while keeping everything else safely in Recent notes.
3. **Keep it in sight.** See the current priority from home screen and lock screen widgets.
4. **Finish and move on.** Mark it complete and let the next priority take its place.

## Built to reduce friction

- **Focused by design** — only the priorities that matter now take center stage.
- **Fast capture** — type or dictate a thought before it disappears.
- **Home and lock screen widgets** — glance at your priority without hunting through an app.
- **Recent notes** — keep the rest out of your head without losing it.
- **Siri and Shortcuts** — capture, hear, set, and complete priorities hands-free.
- **Useful note actions** — edit notes, open detected links, and add plans to Calendar.
- **A personal fit** — light and dark appearance, adaptive backgrounds, and alternate app icons.
- **No setup tax** — no account, subscription, ads, projects, folders, or tags.

## Privacy you can understand

Your notes stay on your device and in the private App Group container used by Miranda's widget. Note content is never sent to a server, and Miranda has no account or sign-in.

Voice capture requires Apple's on-device speech recognition. If on-device recognition is unavailable, Miranda disables dictation instead of sending your audio to the cloud. The app contains no advertising SDKs, does not track you across apps or websites, and does not sell your data.

Read the complete [privacy policy](PRIVACY.md).

## Designed with accessibility in mind

Miranda supports Voice Control, Dynamic Type at accessibility sizes, Dark Interface, sufficient contrast, differentiation without color alone, and Reduced Motion. Its current VoiceOver limitations are documented openly rather than hidden behind a broad claim.

See the detailed [accessibility statement](ACCESSIBILITY.md), including supported common tasks and known limitations.

## Made for iPhone

Miranda is a native SwiftUI app with a WidgetKit extension. It supports English, Spanish (Spain and Mexico), French, German, Dutch, Portuguese (Portugal), and Catalan.

The app is free to use, with no subscription or paywall.

---

## For developers

Miranda is built in public as a native Apple-platform project. The core experience works entirely from local storage; the app and widget share priority data through an App Group.

| Area | Technology |
|---|---|
| App | Swift, SwiftUI |
| Widgets | WidgetKit |
| Voice capture | Speech framework, on-device recognition required |
| Siri actions | App Intents and App Shortcuts |
| Storage | UserDefaults and App Group shared storage |
| Tests | XCTest and XCUITest |

### Repository map

| Path | Purpose |
|---|---|
| `ios/` | Main iOS app |
| `OneMustWidget/` | Home and lock screen widget extension |
| `iosTests/` | Unit tests |
| `iosUITests/` | UI and accessibility checks |
| `PRIVACY.md` | Public privacy policy |
| `ACCESSIBILITY.md` | Accessibility support and known limitations |

## Search terms

Miranda is a minimal productivity app, ADHD focus aid, daily intention planner, priority task manager, simple to-do list, brain-dump notebook, voice capture tool, and home screen widget for iPhone.

## Feedback

Questions, ideas, and accessibility reports are welcome at [hello@miranda.app](mailto:hello@miranda.app). Bug reports can also be opened through [GitHub Issues](https://github.com/pabloserrago/miranda/issues).

<div align="center">

**Your brain was not designed to remember everything. It was designed to focus on what matters.**

</div>
