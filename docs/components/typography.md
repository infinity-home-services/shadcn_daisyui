# Typography

Styles for headings, prose, lists, and inline code.

## Specs

| Part | Description |
| --- | --- |
| Headings | h1 text-3xl bold, h2 text-xl semibold (often border-b), tracking-tight. |
| Prose | leading-7 paragraphs, links via link-primary, muted secondary text. |
| Blocks | Blockquotes (border-l-2), lists (list-disc), inline code on var(--muted). |

| Property | Value |
| --- | --- |
| h1 | text-3xl (1.875rem) font-bold tracking-tight |
| h2 | text-xl (1.25rem) font-semibold, optional border-b 1px var(--border-color) pb-2 |
| Body | leading-7 prose, text-sm for UI copy |
| Inline code | var(--muted) bg, var(--radius-sm), px-1.5 py-0.5 font-mono text-sm |

Tokens used: `foreground`, `muted`, `muted-foreground`, `border-color`, `primary`

## Accessibility

Role / ARIA: Native semantic elements (h1/h2, p, blockquote, ul, code, a) supply structure and roles directly.

Focus: Only links are focusable; they take the standard ring-shadow outline.

Screen reader: Heading levels build the document outline; keep them sequential and meaningful.

Touch target: Inline links are below 44pt; rely on platform link affordances rather than enlarging text runs.

Reduced motion: Static text; no motion.

## Native (SwiftUI)

Parity: guidance only - no native component yet.

```swift
VStack(alignment: .leading, spacing: 16) {
  Text("The Joke Tax Chronicles").font(.largeTitle.bold())
  Text("Once upon a time...").foregroundStyle(.secondary)
  Text("The King's Plan").font(.title2.weight(.semibold))
}
```

A guidance topic rather than a component: map the type ramp to Text styles (.largeTitle, .title2, .body) and Dynamic Type.

## Default

```html
<article class="space-y-4">
  <h1 class="text-3xl font-bold tracking-tight">The Joke Tax Chronicles</h1>
  <p class="leading-7 text-muted-foreground">
    Once upon a time, in a far-off land, there was a very lazy king who spent all day on his throne.
  </p>
  <h2 class="border-b border-base-300 pb-2 text-xl font-semibold tracking-tight">The King's Plan</h2>
  <p class="leading-7">
    The king thought long and hard, and finally came up with
    <a class="link link-primary">a brilliant plan</a>: he would tax the jokes in the kingdom.
  </p>
  <blockquote class="border-l-2 border-base-300 pl-4 italic text-muted-foreground">
    "After all," he said, "everyone enjoys a good joke, so it's only fair that they should pay for the privilege."
  </blockquote>
  <ul class="list-disc space-y-1 pl-6 text-sm">
    <li>1st level of puns: 5 gold coins</li>
    <li>2nd level of jokes: 10 gold coins</li>
    <li>3rd level of one-liners: 20 gold coins</li>
  </ul>
  <p class="text-sm">
    Install with <code class="rounded bg-muted px-1.5 py-0.5 font-mono text-sm">npm i shadcn-daisyui</code>.
  </p>
</article>
```
