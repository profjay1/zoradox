// Contact form: shows clear inline validation messages, then sends with fetch.
// Without JS the form still works: native validation + a normal POST to Web3Forms.
const ENDPOINT = "https://api.web3forms.com/submit";
const MOCK_DELAY = 800;

// Local previews never send real submissions.
// ?mock=error tests the error state; ?live sends for real.
function getMockMode() {
  const params = new URLSearchParams(window.location.search);
  if (params.has("live")) return null;
  if (params.has("mock")) return params.get("mock") || "success";
  const isLocal = ["localhost", "127.0.0.1", ""].includes(window.location.hostname);
  return isLocal ? "success" : null;
}

// The only place that knows where leads go. Phase 2: point ENDPOINT at /api/contact.
export async function submitLead(data) {
  const mock = getMockMode();
  if (mock) {
    console.info("[contact-form] Mock submission, nothing sent:", data);
    await new Promise((resolve) => setTimeout(resolve, MOCK_DELAY));
    if (mock === "error") throw new Error("Mock error");
    return;
  }

  const response = await fetch(ENDPOINT, {
    method: "POST",
    headers: { "Content-Type": "application/json", Accept: "application/json" },
    body: JSON.stringify(data),
  });
  if (!response.ok) {
    const result = await response.json().catch(() => ({}));
    throw new Error(result.body?.message || result.message || `HTTP ${response.status}`);
  }
}

function messageFor(field) {
  const { validity, dataset } = field;
  if (validity.valueMissing) return dataset.errorRequired;
  if (validity.typeMismatch) return dataset.errorType;
  return field.validationMessage;
}

function validate(field) {
  const error = document.getElementById(`${field.id}-error`);
  const valid = field.validity.valid;
  if (valid) field.removeAttribute("aria-invalid");
  else field.setAttribute("aria-invalid", "true");
  if (error) error.textContent = valid ? "" : messageFor(field);
  return valid;
}

export function initContactForm() {
  const form = document.querySelector(".contact__form");
  if (!form) return;

  const fields = [...form.querySelectorAll("[required]")];
  const button = form.querySelector(".contact__submit");
  const status = form.querySelector(".contact__status");
  const idleLabel = button.textContent;
  let sending = false;

  // We show our own messages, so turn off the browser's bubbles.
  form.noValidate = true;

  const setStatus = (text, type) => {
    status.textContent = text;
    status.classList.toggle("contact__status--success", type === "success");
    status.classList.toggle("contact__status--error", type === "error");
  };

  const setSending = (value) => {
    sending = value;
    button.setAttribute("aria-disabled", String(value));
    button.textContent = value ? button.dataset.sending : idleLabel;
  };

  // Once a field shows an error, re-check it as the user fixes it.
  for (const field of fields) {
    field.addEventListener("input", () => {
      if (field.hasAttribute("aria-invalid")) validate(field);
    });
  }

  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    if (sending) return;

    const invalid = fields.filter((field) => !validate(field));
    if (invalid.length) {
      setStatus("");
      invalid[0].focus();
      return;
    }

    const data = Object.fromEntries(new FormData(form));
    delete data.redirect; // only used by the no-JS POST

    setStatus("");
    setSending(true);
    try {
      await submitLead(data);
      form.reset();
      setStatus(form.dataset.success, "success");
    } catch (error) {
      console.error("[contact-form]", error);
      setStatus(form.dataset.error, "error");
    } finally {
      setSending(false);
    }
  });
}
