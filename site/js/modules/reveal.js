// Scroll reveal: fades [data-reveal] elements in as they enter the viewport.
// Content stays visible if JS fails, the browser lacks IntersectionObserver,
// or the user prefers reduced motion.
const STAGGER_LIMIT = 5;

export function initReveal() {
  const elements = [...document.querySelectorAll("[data-reveal]")];
  if (!elements.length) return;

  const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  if (reducedMotion || !("IntersectionObserver" in window)) return;

  // Stagger siblings: each card waits a little longer than the one before.
  for (const el of elements) {
    const siblings = [...el.parentElement.children].filter((c) => c.hasAttribute("data-reveal"));
    const index = siblings.indexOf(el);
    if (index > 0) el.style.setProperty("--reveal-index", Math.min(index, STAGGER_LIMIT));
  }

  // Anything already on screen stays visible, so it doesn't flash out and back in.
  for (const el of elements) {
    if (el.getBoundingClientRect().top < window.innerHeight) el.classList.add("is-visible");
  }

  const observer = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (!entry.isIntersecting) continue;
        entry.target.classList.add("is-visible");
        observer.unobserve(entry.target);
      }
    },
    { rootMargin: "0px 0px -10% 0px" }
  );

  for (const el of elements) {
    if (!el.classList.contains("is-visible")) observer.observe(el);
  }

  document.documentElement.classList.add("reveal-ready");
}
