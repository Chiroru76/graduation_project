import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="repeat-rule"
export default class extends Controller {
  static targets = ["checkbox", "output"]

  connect() {
    this.updateOutput();
  }

  toggle() {
    this.updateOutput()
  }

  updateOutput() {
    const selected = this.checkboxTargets
      .filter((cb) => cb.checked)
      .map((cb) => cb.value);

    this.outputTarget.textContent =
      selected.length > 0 ? `選択中: ${selected.join(", ")}` : "未選択";
  }

}
