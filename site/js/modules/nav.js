// Mobile menu: a disclosure button that shows/hides the header nav.
// Keep this query in sync with the header breakpoint in styles.css.
const desktop = window.matchMedia("(width >= 60em)");

export function initNav() {
  const header = document.querySelector(".header");
  const toggle = header?.querySelector(".header__toggle");
  const nav = header?.querySelector(".header__nav");
  if (!toggle || !nav) return;

  const isOpen = () => toggle.getAttribute("aria-expanded") === "true";

  const setOpen = (open) => {
    toggle.setAttribute("aria-expanded", String(open));
    header.classList.toggle("header--open", open);
  };

  toggle.addEventListener("click", () => setOpen(!isOpen()));

  // Close after choosing a link, so the page scrolls to the section.
  nav.addEventListener("click", (event) => {
    if (event.target.closest("a")) setOpen(false);
  });

  // Escape closes and returns focus to the button.
  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && isOpen()) {
      setOpen(false);
      toggle.focus();
    }
  });

  // Close when clicking or tabbing anywhere outside the header.
  document.addEventListener("click", (event) => {
    if (isOpen() && !header.contains(event.target)) setOpen(false);
  });
  document.addEventListener("focusin", (event) => {
    if (isOpen() && !header.contains(event.target)) setOpen(false);
  });

  // Reset when the viewport grows past the mobile layout.
  desktop.addEventListener("change", (event) => {
    if (event.matches) setOpen(false);
  });
}
