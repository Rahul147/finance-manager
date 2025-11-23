import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "link" ]

  connect() {
    this.boundUpdate = this.update.bind(this)
    document.addEventListener("turbo:load", this.boundUpdate)
    this.update()
  }

  disconnect() {
    document.removeEventListener("turbo:load", this.boundUpdate)
  }

  update() {
    const currentPath = window.location.pathname

    this.linkTargets.forEach((link) => {
      const navPath = link.dataset.navPath
      const isActive = this.matchesPath(currentPath, navPath)

      link.classList.toggle("nav-link--active", isActive)
      if (isActive) {
        link.setAttribute("aria-current", "page")
      } else {
        link.removeAttribute("aria-current")
      }
    })
  }

  matchesPath(currentPath, navPath) {
    if (!navPath) return false
    if (navPath === "/") return currentPath === "/"
    return currentPath === navPath || currentPath.startsWith(`${navPath}/`)
  }
}

