import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
export default class extends Controller {
  static targets = ["dialog", "backdrop"]

  connect() {
  }

  open(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }
    if (this.hasDialogTarget) {
      this.dialogTarget.classList.remove("hidden")
    }
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.remove("hidden")
    }
    // Prevent body scroll
    document.body.style.overflow = "hidden"
  }

  close(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }
    if (this.hasDialogTarget) {
      this.dialogTarget.classList.add("hidden")
    }
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.add("hidden")
    }
    // Restore body scroll
    document.body.style.overflow = ""

    // If element should be removed (original behavior)
    if (!this.hasDialogTarget && !this.hasBackdropTarget) {
      this.element.remove()
    }
  }

  closeOnBackdrop(event) {
    if (event.target === event.currentTarget) {
      this.close(event)
    }
  }
}
