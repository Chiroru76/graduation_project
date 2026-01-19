import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { duration: Number }; // ミリ秒

  connect() {
    // 自動で消す（duration が未設定なら 5秒）
    const ms = this.hasDurationValue ? this.durationValue : 5000;
    this.timeout = setTimeout(() => this.dismiss(), ms);
  }


  close(event) {
    event.preventDefault();
    this.dismiss();
  }

  dismiss() {
    // フェードアウトしてから DOM 削除
    this.element.classList.add("opacity-0");
    setTimeout(() => this.remove(), 300);
  }

  remove() {
    if (this.element && this.element.parentNode) {
      this.element.parentNode.removeChild(this.element);
    }
  }
}
