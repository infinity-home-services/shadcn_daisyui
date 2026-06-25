# Tabs

Layered sections of content shown one panel at a time.

## Usage guidance

Use when:

- Peer views of the same object (Details / Activity / Settings)
- 2-5 sections the user switches between without losing context

Don't use for:

- Primary app navigation - that's the dock/navbar/sidebar's job
- Sequential steps - use steps + explicit next/back actions

Sizing: Tab triggers are h-7 text-sm inside the boxed list; don't restyle.

Responsive: Tabs stay horizontal at all widths; if labels crowd on compact, shorten the labels - never wrap to two rows or scroll.

iOS: A segmented Picker (.pickerStyle(.segmented)) for 2-4 peers; never a nested TabView.

## Specs

| Part | Description |
| --- | --- |
| Tablist | Segmented box (tabs-box) on a muted background holding the triggers. |
| Tab trigger | Radio-driven label; the active one gets a white box and shadow. |
| Panel | tab-content region shown for the selected tab. |

| Property | Value |
| --- | --- |
| List padding | 3px (p-[3px]) |
| List radius | var(--radius-lg) |
| Trigger height | 1.75rem (28px) |
| Trigger radius | var(--radius-md) |
| Trigger font | 0.875rem / 500 |

Tokens used: `muted`, `muted-foreground`, `background`, `foreground`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Move focus to the tablist |
| Arrow keys | Move between tabs (native radio-group behavior) |
| Space | Activate the focused tab |

Role / ARIA: Outer element carries role=tablist; triggers are radio inputs labeled via aria-label. The active trigger reflects aria-selected / checked.

Focus: Focused tab shows a ring; the selected tab is the white box with a subtle shadow.

Screen reader: Each trigger is named by its aria-label; the radio grouping conveys selection and set size.

Touch target: Triggers are 28px tall - fine for pointer; enlarge for touch-primary layouts.

Reduced motion: Active-tab swap is instant; no slide animation.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
TabView {
    Text("Account").tabItem { Label("Account", systemImage: "person") }
    Text("Password").tabItem { Label("Password", systemImage: "lock") }
}
```

TabView covers the same intent but presents as a bottom tab bar (or sidebar) rather than an inline segmented control; .pickerStyle(.segmented) is closer visually.

## Default

HEEx:

```heex
<.tabs id="settings">
  <:tab label="Account" checked>Account settings…</:tab>
  <:tab label="Password">Password settings…</:tab>
  <:tab label="Notifications">Notification settings…</:tab>
</.tabs>
```

```html
<div role="tablist" class="tabs tabs-box w-fit">
  <input type="radio" name="demo_tabs" class="tab" aria-label="Account" checked />
  <input type="radio" name="demo_tabs" class="tab" aria-label="Password" />
  <input type="radio" name="demo_tabs" class="tab" aria-label="Notifications" />
</div>
```
