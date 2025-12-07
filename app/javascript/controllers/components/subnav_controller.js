import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "activeItemChevron", "activeItemText"];

  static values = {}

  connect() {
    var active_item = this.element.querySelector(".active-subnav-item");
    if (active_item) {
      var link_text = active_item.querySelector(".subnav-link-text").innerHTML;
      var active_item_text = this.activeItemTextTarget;
      active_item_text.innerHTML = link_text;
    }
  }

  toggle() {
    var menu = this.menuTarget;
    var active_item_icon = this.activeItemChevronTarget;

    if (menu.classList.contains("hidden")) {
      menu.classList.remove("hidden");
      active_item_icon.classList.add("rotate-180");
    } else {
      menu.classList.add("hidden");
      active_item_icon.classList.remove("rotate-180");
    }
  }
}
