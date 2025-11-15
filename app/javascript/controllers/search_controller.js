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
  }

  input() {
    this._syncUrl();
    this._submit();
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

  _debounce(fn, wait) {
    let t;
    return (...args) => {
      clearTimeout(t);
      t = setTimeout(() => fn.apply(this, args), wait);
    };
  }
}
