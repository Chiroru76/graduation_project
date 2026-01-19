import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { duration: Number };

  connect() {
    // フェードイン効果
    this.element.style.opacity = "0";
    requestAnimationFrame(() => {
      this.element.style.opacity = "1";
    });

    // 指定時間後に自動で消す（デフォルト 4秒）
    const ms = this.hasDurationValue ? this.durationValue : 4000;
    this.timeout = setTimeout(() => this.dismiss(), ms);
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout);
    }
  }

  dismiss() {
    // フェードアウト
    this.element.style.opacity = "0";

    // 300ms 後に DOM から削除
    setTimeout(() => {
      if (this.element && this.element.parentNode) {
        this.element.parentNode.removeChild(this.element);
      }
    }, 300);
  }
}
