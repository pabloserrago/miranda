# Accessibility

**Miranda** is built by Pablo Serrano. This page describes how the app works
with iOS accessibility features, and where it currently falls short.

The feature names below match the **Accessibility Nutrition Labels** on
Miranda's App Store product page, so you can compare the two directly.

## What Miranda supports

| Accessibility feature | Miranda |
|---|---|
| VoiceOver | Not yet — see [Known limitations](#known-limitations) |
| Voice Control | Supported |
| Larger Text | Supported |
| Dark Interface | Supported |
| Differentiate Without Color Alone | Supported |
| Sufficient Contrast | Supported |
| Reduced Motion | Supported |
| Captions | Not applicable — no video or audio-only content |
| Audio Descriptions | Not applicable — no video content |

Apple's labels describe whether you can complete an app's **common tasks** using
a feature. For Miranda those tasks are: getting through first launch, seeing
your priorities, adding a note by typing or dictation, opening and editing a
note, reordering priorities, marking one complete, and changing settings.
Miranda has no account, no login, and nothing to purchase.

## Voice Control

*Navigate and interact with the app using your voice to tap, swipe, type, and
more.*

Every button in Miranda has a spoken name, including icon-only buttons like the
microphone, the plus button, and Settings. You can address any of them with
"Tap" followed by the name, or use "Show numbers".

Reordering your priorities normally uses a press-and-drag gesture. Because that
gesture cannot be spoken, each priority also offers **Move Up** and **Move Down**
as actions, so the list can be reordered entirely by voice. The Recent notes
panel, which normally opens by dragging, also has a button.

Turn it on in **Settings → Accessibility → Voice Control**.

## Larger Text

*Increases the text size in the app to 200% or more.*

Miranda uses Dynamic Type, so all in-app text scales with your setting up to the
largest accessibility size — beyond 300% of the default. Rows grow to fit rather
than cutting text off.

Turn it on in **Settings → Accessibility → Display & Text Size → Larger Text**.
The change applies immediately; you do not need to reopen Miranda.

The home screen and lock screen widgets are an exception. Widgets are given a
fixed size by iOS, so their text shrinks to fit rather than growing.

## Dark Interface

*Applies a dark color scheme to the screens, menus, and controls to reduce eye
strain.*

Miranda follows your system appearance. There is no in-app override, so setting
your device to Dark, Light, or Automatic controls the app.

Change it in **Settings → Display & Brightness**.

## Differentiate Without Color Alone

*Uses shapes or text, in addition to or instead of color, to distinguish key
information.*

Miranda does not use color as the only way to convey meaning. Swipe actions
carry both a symbol and a written label, the recording state says "Listening…",
and delete actions say "Delete".

The background picker in Settings is the one place where color itself is what
you are choosing. With Differentiate Without Color turned on, the selected
background is marked with a checkmark rather than only a colored border.

Turn it on in **Settings → Accessibility → Display & Text Size → Differentiate
Without Color**.

## Sufficient Contrast

*Increases or adjusts the contrast between text or iconography and background.*

Text and meaningful icons meet the commonly recommended minimums by default — at
least 4.5:1 for body text and 3:1 for icons — in both light and dark appearance.
You should not need to turn on Increase Contrast to read the app.

## Reduced Motion

*Modifies or reduces certain types of animation that may cause motion sickness
or discomfort.*

With Reduce Motion on, Miranda removes the animation from reordering, the
completion celebration, toasts, button presses, and the animated dictation
waveform. Content that appears or disappears cross-fades instead of sliding, so
you can still follow what changed.

Miranda's background is a still image. Nothing in the app moves on its own
without you doing something.

Turn it on in **Settings → Accessibility → Motion → Reduce Motion**.

There is also a separate **Completion animation** switch in Miranda's own
settings. Reduce Motion overrides it — the celebration stays off regardless of
how that switch is set.

## Dictation

Not one of Apple's labelled features, but worth stating: voice capture uses
Apple's on-device speech recognition. If on-device recognition is not available
for your language or device, dictation is turned off rather than sending audio
to a server. No audio is recorded or transmitted.

## Known limitations

These are the things we know are not right yet:

- **VoiceOver is not supported yet.** Much of the groundwork is in place, since
  buttons are named and no action depends on a gesture. But reading order,
  element traits, and spoken announcements have not been reviewed, so Miranda
  does not claim VoiceOver support. If you use VoiceOver, expect rough edges.
- **Reordering does not announce the result.** Using Move Up or Move Down
  changes the order, but the app does not speak the new position back to you.
- **Widget text does not scale** with Larger Text, because iOS gives widgets a
  fixed size. Everything the widget shows is also in the app, at full size.

## Reporting a problem

If something in Miranda does not work with the assistive technology you use, or
this page claims something that turns out not to be true, please email
[hello@miranda.app](mailto:hello@miranda.app). Accessibility bugs are treated as
bugs, not feature requests.

---

*Last updated: August 2026*
