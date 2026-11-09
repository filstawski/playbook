# Verifying motion

The user catches every jump, so "the transition exists" is not proof. These
are the checks to run before reporting motion work, and the tools that make
them reliable.

1. **Watch every transition the change touches before reporting.** That
   means view switches, filters, segment changes, moves, open/close, page
   changes, hovers and presses, not only static states. Check two widths for
   apps (1440 and 1180). For sites, also check 320, 390, 768 and 1024 px and
   a landscape phone. Crop to the section **and what is below it**: a list
   fading in correctly while the sections below jumped in one frame was
   missed until the crop included them ("how could you have made this
   mistake without noticing").
2. **Use a production build on its own port, never the user's dev server.**
   Dev compiles freeze animations mid-flight, and the user's server is
   theirs. Still read the dev server's console after an update: hydration
   mismatches are only reported in development, and a lost
   `backdrop-filter` doesn't error.
3. **Film, then probe.** Screenshot bursts miss fades shorter than about
   300 ms, and slowed playback slows only CSS and WAAPI, not Motion's
   JavaScript-driven heights and layout.
   - Use CDP `Page.startScreencast` to capture every painted frame at real
     speed.
   - For ground truth, run a per-`requestAnimationFrame` probe of computed
     opacity, transform and position, element counts and `getAnimations()`.
   - For CSS motion, `Animation.setPlaybackRate(0.1)` on a real hover,
     press or release.
   - For motion shorter than the capture cadence, pause and seek:
     `getAnimations({ subtree: true })`, `pause()`, `currentTime = t`.

   Report numbers: the largest step between frames, when content and
   container settle, how many copies were alive at once, and overshoot
   peaks. Run more than once: a first run after a server start once showed
   a 27 px "jump" that never recurred.
4. **Turn reduced motion off in look and motion specs.** If the suite
   defaults to `reducedMotion: "reduce"` (see the CI guidelines), add
   `test.use({ reducedMotion: "no-preference" })`. Otherwise collapses jump,
   icons stand still, and the frames prove nothing. An agent once filmed
   with reduced motion on and took the missing glides for a bug. Verify the
   reduced-motion path separately.
5. **Check iOS Safari and Android.** The user tests the installed app on an
   iPhone and an Android phone.
   - Scope iOS-only fixes with `@supports (-webkit-touch-callout: none)`,
     and check Android too.
   - Touch has no hover: a press must play what hover plays, and nothing
     may stay "rolled" after a tap (`@media (hover: hover)`).
   - The phone keyboard shrinks the window; nothing may push the app bar
     out of view.
6. **Send frames or clips with the report.** Include slowed frames, a short
   clip or a contact sheet. The user has the last word on feel. Keep a
   dev-only lab page for playing variants side by side.
7. **Don't run look specs at the same time as the e2e suite** when both
   write the same auth storage file (cookies ignore ports): the e2e run gets
   signed out halfway and fails broadly. Give look specs their own
   `storageState`.
8. **Guard motion that must not regress in CI:**
   - An overlay opened twice must have a running `scale`/`translate` CSS
     transition, polled every 50 ms.
   - A busy button must transition `filter`/`opacity`.
   - An icon plays once on hover and focus, and not at all with reduced
     motion.
   - The CSS spring twins match the TypeScript tokens.

   Hold a busy state long enough to look at by delaying POSTs 1.5 s in a
   test route handler.
9. **For view transitions, log `transition.ready` rejections (skips) before
   suspecting the CSS.** Record `::view-transition-*` animations through
   `document.getAnimations()`, and read the pseudo-element's computed
   `translate` to confirm the direction.
10. **Measure performance after motion work:**
    - the LCP element (it should only rise);
    - CLS below 0.01 (header parts that move with a persistent
      `will-change: transform` don't count as shifts);
    - long tasks, and JavaScript executed before load.
11. **Render exported motion videos (logo animations) frame by frame** at
    exact 1/60 s steps instead of screen-recording live. A live capture
    froze for 0.17–0.33 s, and the user saw "a slight lag".
12. **Gestures: test the math, then flick for real.** Unit-test projection,
    rubber-banding and the snap choice ([P19](patterns.md#p19-drag-swipe-and-snap-sheets-drawers-carousels)).
    Then flick with timed pointer moves while probing the panel per frame:
    - it doesn't move before the slop, and doesn't jump when crossing it;
    - after release it keeps going the way the pointer went, with no stop
      before the spring takes over;
    - a touch while it settles catches it where it is;
    - it ends exactly on a snap point.

    Then try it on the iPhone and the Android phone: a missing
    `touch-action` only shows there, as a scroll that steals the drag.

## Probe and capture snippets

Playwright with a CDP session:

```ts
import { expect, test, type Locator, type Page } from "@playwright/test";

test.use({ reducedMotion: "no-preference" });

/** CSS transitions running on an element right now. */
const transitions = (el: Locator) =>
  el.evaluate((node) =>
    node.getAnimations({ subtree: true }).flatMap((a) => (a instanceof CSSTransition ? [a.transitionProperty] : [])),
  );

test("the dialog lands every time it opens", async ({ page }) => {
  await page.goto("/somewhere");
  for (let i = 0; i < 2; i++) {
    await page.getByRole("button", { name: "Open" }).click();
    await expect.poll(() => transitions(page.getByRole("dialog")), { intervals: [50] }).toContain("scale");
    await page.getByRole("button", { name: "Cancel" }).click();
    await expect(page.getByRole("dialog")).toBeHidden();
  }
});

/** Per-frame probe: start it, act, then read the frames where something changed. */
async function probe(page: Page, selector: string, ms = 1500) {
  await page.evaluate(([sel, duration]) => {
    const frames: unknown[] = [];
    (window as unknown as { frames_: unknown[] }).frames_ = frames;
    const until = performance.now() + Number(duration);
    const tick = () => {
      const els = [...document.querySelectorAll(String(sel))];
      frames.push({
        t: Math.round(performance.now()),
        n: els.length, // copies alive at once
        boxes: els.map((el) => {
          const r = el.getBoundingClientRect();
          const cs = getComputedStyle(el);
          return { top: Math.round(r.top), h: Math.round(r.height), o: cs.opacity, tf: cs.transform };
        }),
      });
      if (performance.now() < until) requestAnimationFrame(tick);
    };
    requestAnimationFrame(tick);
  }, [selector, ms] as const);
}

/** Slow CSS/WAAPI to a tenth and capture every painted frame. */
async function film(page: Page) {
  const cdp = await page.context().newCDPSession(page);
  await cdp.send("Animation.enable");
  await cdp.send("Animation.setPlaybackRate", { playbackRate: 0.1 });
  const frames: string[] = [];
  cdp.on("Page.screencastFrame", async ({ data, sessionId }) => {
    frames.push(data); // base64 PNG; lay out as a contact sheet afterwards
    await cdp.send("Page.screencastFrameAck", { sessionId });
  });
  await cdp.send("Page.startScreencast", { format: "png", everyNthFrame: 1 });
  return async () => {
    await cdp.send("Page.stopScreencast");
    return frames;
  };
}

/** A flick: `distance` px along y in `ms`, released while still moving. Run `probe` first. */
async function flick(page: Page, from: { x: number; y: number }, distance: number, ms = 120, steps = 8) {
  await page.mouse.move(from.x, from.y);
  await page.mouse.down();
  for (let i = 1; i <= steps; i++) {
    await page.mouse.move(from.x, from.y + (distance * i) / steps);
    await page.waitForTimeout(ms / steps); // real time between moves, so the velocity is real
  }
  await page.mouse.up();
}
```
