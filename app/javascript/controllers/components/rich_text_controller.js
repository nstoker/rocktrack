import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [""];

  focus(event) {
    var compact_container = event.target.closest(".rich-text-container");
    if (compact_container) {
      compact_container.classList.add("focused");
    }
  }

  unfocus(event) {
    var compact_container = event.target.closest(".rich-text-container");
    if (compact_container) {
      compact_container.classList.remove("focused");
    }
  }
}
