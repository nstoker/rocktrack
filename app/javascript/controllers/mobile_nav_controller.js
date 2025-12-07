import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["mobileNav"];

  toggle() {
    if (this.mobileNavTarget.classList.contains("hidden")) {
      this.mobileNavTarget.classList.remove("hidden");
    } else {
      this.mobileNavTarget.classList.add("hidden");
    }
  }
}
