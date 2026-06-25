# Select Native

The native HTML select control, styled to match.

## Specs

| Part | Description |
| --- | --- |
| Label | Optional label tied to the select via for/id. |
| Control | Native HTML select styled with the .select class. |
| Options | Native option elements, optionally led by a prompt. |

| Property | Value |
| --- | --- |
| Height | 2.25rem / 36px (h-9) |
| Padding | 0.75rem inline |
| Radius | var(--radius-md) |
| Border | 1px var(--input) |
| Shadow | var(--shadow-xs) |

Tokens used: `input`, `foreground`, `ring`, `muted-foreground`, `destructive`

## Accessibility

| Keys | Action |
| --- | --- |
| Enter / Space | Open the option list |
| Up / Down | Move between options |
| Type-ahead | Jump to the option starting with the typed characters |
| Esc | Close the list |

Role / ARIA: Native select (implicit role combobox / listbox), fully accessible by default. Bound to a FormField for id/name/value/errors.

Focus: Border switches to var(--ring) with a ring shadow on focus.

Screen reader: Native semantics are announced automatically (role, expanded state, selected option). Pair with a visible label.

Touch target: OS-native picker on touch devices guarantees an adequate hit area.

Reduced motion: Native control; no theme animation.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
Picker("Role", selection: $role) {
    ForEach(roles, id: \.self) { Text($0).tag($0) }
}
```

Maps directly to Picker, which renders as the platform-native control (wheel, menu, or list depending on context).

## Default

HEEx:

```heex
<.native_select
  field={@form[:role]}
  label="Role"
  prompt="Select a role"
  options={["Admin", "Member", "Viewer"]}
/>
```

```html
<label class="block w-full max-w-sm space-y-1.5">
  <span class="text-sm font-medium">Role</span>
  <select class="select w-full">
    <option disabled selected>Select a role</option>
    <option>Admin</option>
    <option>Member</option>
    <option>Viewer</option>
  </select>
</label>
```
