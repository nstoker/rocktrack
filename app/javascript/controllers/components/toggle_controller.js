import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["toggleable"];

  static values = {
    singleActive: Boolean, // If true, and if using toggleId, then only one toggleable element can be active at a time.  If false, multiple toggleable elements can be active at once.
  };

  connect() {}

  toggle(event) {
    const toggleable_elements = this.toggleableTargets;
    const toggle_id = event.target.dataset.toggleId; // Use for toggling multiple different elements (like an "A", "B", "C").  Omit to toggle all toggleable elements.

    if (this.singleActiveValue && toggle_id) {
      const matchingElements = toggleable_elements.filter(
        (element) => element.dataset.toggleId === toggle_id
      );

      const areMatchingElementsHidden = matchingElements.every((element) =>
        element.classList.contains("hidden")
      );

      if (areMatchingElementsHidden) {
        toggleable_elements.forEach((element) => {
          element.classList.toggle(
            "hidden",
            element.dataset.toggleId !== toggle_id
          );
        });
      } else {
        matchingElements.forEach((element) => {
          element.classList.toggle("hidden");
        });
      }
    } else {
      toggleable_elements.forEach((element) => {
        if (!toggle_id || element.dataset.toggleId === toggle_id) {
          element.classList.toggle("hidden");
        }
      });
    }
  }
}
