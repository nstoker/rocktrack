import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["radio"];

  static values = {};

  connect() {}

  select(event) {
    // Remove .active class from all radio labels
    this.radioTargets.forEach((radio) => {
      radio.classList.remove("active");
    });

    // Add .active class to the selected radio's label
    event.target.closest("label").classList.add("active");
  }
}
