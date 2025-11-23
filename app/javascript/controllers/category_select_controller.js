import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="category-select"
export default class extends Controller {
  static targets = ["select"];

  connect() {
    this._handleSubmitEnd = this._handleSubmitEnd.bind(this);
    this.element.addEventListener("turbo:submit-end", this._handleSubmitEnd);
  }

  disconnect() {
    this.element.removeEventListener("turbo:submit-end", this._handleSubmitEnd);
    this._setBusy(false);
  }

  submit() {
    if (typeof this.element.requestSubmit === "function") {
      this.element.requestSubmit();
    } else {
      this.element.submit();
    }
    this._setBusy(true);
  }

  _handleSubmitEnd() {
    this._setBusy(false);
  }

  _setBusy(state) {
    if (!this.hasSelectTarget) return;

    this.selectTargets.forEach((element) => {
      element.disabled = state;
      if (state) {
        element.setAttribute("aria-busy", "true");
      } else {
        element.removeAttribute("aria-busy");
      }
    });
  }
}
