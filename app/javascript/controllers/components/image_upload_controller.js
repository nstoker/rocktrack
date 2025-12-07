import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["output", "input", "savedImage", "hiddenButton"];

  updateImage() {
    var input = this.inputTarget;
    var output = this.outputTarget;

    if (input.files && input.files[0]) {
      var reader = new FileReader();

      reader.onload = function () {
        output.src = reader.result;
      };

      reader.readAsDataURL(input.files[0]);
    }

    if (this.hasHiddenButtonTarget) {
      this.hiddenButtonTarget.classList.remove("hidden");
    }
  }

  revealImagePreview() {
    this.outputTarget.classList.remove("hidden");

    if (this.hasSavedImageTarget) {
      this.savedImageTarget.classList.add("hidden");
    }
  }
}
