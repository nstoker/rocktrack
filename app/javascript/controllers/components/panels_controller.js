import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["panel"];

  static values = {
    defaultPanelId: String,
    oneOpen: Boolean,
  };

  connect() {
    let panelToOpen = null;

    // First check if defaultPanelIdValue is set (takes precedence)
    if (this.hasDefaultPanelIdValue) {
      panelToOpen = this.element.querySelector(
        `.panel[data-panel-id='${this.defaultPanelIdValue}']`
      );
    }
    // If no default panel ID is set, check for active_panel URL parameter
    else {
      const urlParams = new URLSearchParams(window.location.search);
      const activePanel = urlParams.get('active_panel');

      if (activePanel) {
        panelToOpen = this.element.querySelector(
          `.panel[data-panel-id='${activePanel}']`
        );
      }
    }

    if (panelToOpen) {
      panelToOpen.classList.remove("panel-closed");
      panelToOpen.classList.add("panel-open");
    }
  }

  togglePanel(event) {
    var panel = event.target.closest(".panel");

    // Toggle the clicked panel open/closed
    if (panel.classList.contains("panel-open")) {
      panel.classList.remove("panel-open");
      panel.classList.add("panel-closed");

      // if the url has an active_panel parameter, remove it
      const urlParams = new URLSearchParams(window.location.search);
      urlParams.delete("active_panel");
      window.history.replaceState({}, "", window.location.pathname + "?" + urlParams.toString());

    } else {
      panel.classList.add("panel-open");
      panel.classList.remove("panel-closed");
    }

    // If only one panel can be opened, close the others if the clicked panel was opened
    if (this.oneOpenValue == true && panel.classList.contains("panel-open")) {
      this.panelTargets.forEach((target) => {
        if (target !== panel) {
          target.classList.remove("panel-open");
          target.classList.add("panel-closed");
        }
      });
    }
  }
}
