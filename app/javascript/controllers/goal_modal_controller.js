import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="goal-modal"
export default class extends Controller {
  static targets = ["backdrop", "panel", "value", "unit", "period", "summary"];

  open()  { this.backdropTarget.classList.remove("hidden"); this.panelTarget.focus(); }
  close() { this.backdropTarget.classList.add("hidden"); }

  // 値が変わったらサマリー表示を更新
  refresh() {
    const v = this.valueTarget.value;
    const u = this.unitTarget.selectedOptions[0]?.text || "";
    const p = this.periodTarget.selectedOptions[0]?.text || "";
    if (this.hasSummaryTarget) {
      this.summaryTarget.textContent = v && u && p ? `${v} ${u} / ${p}` : "未設定";
    }
  }

}
