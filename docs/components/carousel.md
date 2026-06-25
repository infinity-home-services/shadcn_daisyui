# Carousel

A slideshow of items with previous/next controls.

> Requires a JS hook: initialize with `initShadcnDaisyui()` (dead views) or the corresponding `Shadcn*` LiveView hook from `shadcn-daisyui.js`.

## Specs

| Part | Description |
| --- | --- |
| Viewport | A horizontally scroll-snapping track (role=group, aria-roledescription=carousel). |
| Slides | Each child snaps to the viewport width. |
| Prev / Next | Buttons that scroll one viewport-width left/right with smooth behavior. |

| Property | Value |
| --- | --- |
| Slide step | carousel.clientWidth per click |
| Scroll | smooth behavior, CSS scroll-snap |
| Controls | btn-circle ghost arrows |

Tokens used: `background`, `foreground`, `border-color`, `muted`, `accent`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Reach the Prev and Next buttons |
| Enter / Space | Activate Prev/Next to scroll one slide (native buttons) |
| Arrow / Page keys | Scroll the focused viewport horizontally (native scroll-container behavior) |

Role / ARIA: The track is role=group with aria-roledescription=carousel and an aria-label; the arrow buttons get aria-label Next/Previous slide if unset.

Focus: Prev/Next are native buttons; the scroll viewport itself is keyboard-scrollable when focused.

Screen reader: Announced as a carousel group; arrows are labelled Next slide / Previous slide.

Touch target: Swipe to advance on touch; the circular arrow buttons are comfortably tappable.

Reduced motion: Scrolls use behavior:smooth - honor prefers-reduced-motion by treating the jump as instant for sensitive users.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
TabView {
    ForEach(slides) { slide in SlideView(slide) }
}
.tabViewStyle(.page(indexDisplayMode: .automatic))
```

A paged TabView gives native swipe + page dots; explicit prev/next arrows are not idiomatic on iOS, so they are usually dropped on touch.

## Default

HEEx:

```heex
<.carousel id="gallery">
  <:slide><div class="flex aspect-video w-full items-center justify-center bg-muted text-3xl font-semibold">1</div></:slide>
  <:slide><div class="flex aspect-video w-full items-center justify-center bg-muted text-3xl font-semibold">2</div></:slide>
  <:slide><div class="flex aspect-video w-full items-center justify-center bg-muted text-3xl font-semibold">3</div></:slide>
</.carousel>
```

```html
<div class="relative w-full max-w-sm px-4">
  <div data-carousel class="carousel w-full rounded-lg">
    <div class="carousel-item w-full">
      <div class="flex aspect-video w-full items-center justify-center rounded-lg border border-base-300 bg-muted text-3xl font-semibold">1</div>
    </div>
    <div class="carousel-item w-full">
      <div class="flex aspect-video w-full items-center justify-center rounded-lg border border-base-300 bg-muted text-3xl font-semibold">2</div>
    </div>
    <div class="carousel-item w-full">
      <div class="flex aspect-video w-full items-center justify-center rounded-lg border border-base-300 bg-muted text-3xl font-semibold">3</div>
    </div>
    <div class="carousel-item w-full">
      <div class="flex aspect-video w-full items-center justify-center rounded-lg border border-base-300 bg-muted text-3xl font-semibold">4</div>
    </div>
    <div class="carousel-item w-full">
      <div class="flex aspect-video w-full items-center justify-center rounded-lg border border-base-300 bg-muted text-3xl font-semibold">5</div>
    </div>
  </div>
  <button type="button" data-carousel-prev class="btn btn-outline btn-circle btn-sm absolute left-0 top-1/2 -translate-y-1/2">
    <span class="hero-chevron-left size-4" aria-hidden="true"></span>
  </button>
  <button type="button" data-carousel-next class="btn btn-outline btn-circle btn-sm absolute right-0 top-1/2 -translate-y-1/2">
    <span class="hero-chevron-right size-4" aria-hidden="true"></span>
  </button>
</div>
```
