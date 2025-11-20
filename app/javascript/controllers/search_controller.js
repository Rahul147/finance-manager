import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="search"
export default class extends Controller {
  static values = { delay: { type: Number, default: 300 } };
  static targets = ["input"];

  connect() {
    this._submit = this._debounce(
      () => this.element.requestSubmit(),
      this.delayValue
    );

    this._focusInputSoon();
  }

  input() {
    this._syncUrl();
    this._submit();
  }

  focusInput() {
    this._focusInputSoon();
  }

  _syncUrl() {
    try {
      const url = new URL(window.location);
      const q = this.hasInputTarget ? this.inputTarget.value : "";
      if (q && q.length > 0) {
        url.searchParams.set("q", q);
      } else {
        url.searchParams.delete("q");
      }
      window.history.replaceState({}, "", url);
    } catch (e) {
      // no-op
    }
  }

  // TODO: Clear the input?
  clear(event) {}

  _focusInputSoon() {
    if (!this.hasInputTarget) return;

    const schedule =
      globalThis.requestAnimationFrame ?? ((cb) => setTimeout(cb, 0));

    schedule(() => {
      if (!this.hasInputTarget) return;
      this.inputTarget.focus({ preventScroll: true });
      if (typeof this.inputTarget.select === "function") {
        this.inputTarget.select();
      }
    });
  }

  _debounce(fn, wait) {
    let t;
    return (...args) => {
      clearTimeout(t);
      t = setTimeout(() => fn.apply(this, args), wait);
    };
  }
}
