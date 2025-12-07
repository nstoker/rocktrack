import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["hexInput", "colorPicker"];

  static values = {};

  connect() {}

  focus() {
    this.element.classList.add("focused");
  }

  blur() {
    this.element.classList.remove("focused");
  }

  updateColorPicker() {
    const hexInput = this.hexInputTarget;
    const colorPicker = this.colorPickerTarget;

    // Get the value and process it
    let value = hexInput.value.trim().toLowerCase();

    // Remove all characters except letters, numbers, and #
    value = value.replace(/[^a-z0-9#]/g, "");

    // Ensure it starts with a single #
    if (!value.startsWith("#")) {
      value = `#${value}`;
    }

    // Validate the color format
    const isValidHex = /^#([0-9a-f]{3}|[0-9a-f]{6})$/i.test(value);

    // Update the color picker value only if valid
    if (isValidHex) {
      colorPicker.value = value;
    }
  }

  updateHexInput() {
    const hexInput = this.hexInputTarget;
    const colorPicker = this.colorPickerTarget;

    hexInput.value = colorPicker.value;
  }
}
