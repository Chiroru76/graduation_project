import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list"]

  toggle(event) {
    const el = this.listTarget
    const expanded = this.element.getAttribute("aria-expanded") === "true"
    this.element.setAttribute("aria-expanded", String(!expanded))
    el.classList.toggle("hidden")
  }
}