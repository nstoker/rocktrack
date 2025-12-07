import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "input",
    "copyButton",
    "defaultIcon",
    "copiedIcon",
    "copyText",
    "richContent",
  ];
  static values = {
    prepend: String,
    success: String,
    string: String,
    append: String,
  };

  copy() {
    if (this.hasInputTarget) {
      var input_value = this.inputTarget.value;
    }

    var prepend_value = this.prependValue;
    var success_value = this.successValue;
    var string_value = this.stringValue;
    var append_value = this.appendValue;

    if (string_value) {
      var copy_text = string_value;
    } else {
      if (prepend_value && input_value && append_value) {
        var copy_text = prepend_value + input_value + append_value;
      } else if (prepend_value && input_value) {
        var copy_text = prepend_value + input_value;
      } else if (append_value && input_value) {
        var copy_text = input_value + append_value;
      } else {
        var copy_text = input_value;
      }
    }

    var input = document.createElement("input");
    input.setAttribute("value", copy_text);
    document.body.appendChild(input);
    input.select();
    var result = document.execCommand("copy");
    document.body.removeChild(input);

    this.copiedFeedback();
  }

  highlight(event) {
    event.target.closest("input").select();
  }

  copyRichContent() {
    var rich_content = this.richContentTarget.innerHTML;
    this.copyRichContentToClipboard(rich_content);

    var success_value = this.successValue;
    if (success_value) {
      this.copyButtonTarget.innerHTML = success_value;
    } else {
      this.copyButtonTarget.innerHTML = "Copied";
    }
  }

  copyRichContentToClipboard(str) {
    function listener(e) {
      e.clipboardData.setData("text/html", str);
      e.clipboardData.setData("text/plain", str);
      e.preventDefault();
    }
    document.addEventListener("copy", listener);
    document.execCommand("copy");
    document.removeEventListener("copy", listener);
  }

  copiedFeedback() {
    var copy_button = this.copyButtonTarget;
    if (this.hasDefaultIconTarget) {
      var default_icon = this.defaultIconTarget;
    }
    if (this.hasCopiedIconTarget) {
      var copied_icon = this.copiedIconTarget;
    }
    if (this.hasCopyTextTarget) {
      var copy_text = this.copyTextTarget;
    }

    // Store the original text
    if (copy_text) {
      var original_text = copy_text.innerHTML;
    } else {
      var original_text = copy_button.innerHTML;
    }

    // Set the success text
    if (this.hasSuccessValue) {
      var success_text = this.successValue;
    } else {
      var success_text = "Copied";
    }

    // Show the success text
    if (copy_text) {
      copy_text.innerHTML = success_text;
    } else {
      copy_button.innerHTML = success_text;
    }

    if (default_icon && copied_icon) {
      default_icon.classList.add("hidden");
      copied_icon.classList.remove("hidden");
    }

    // Reset after 2 seconds
    setTimeout(() => {
      if (copy_text) {
        copy_text.innerHTML = original_text;
      } else {
        copy_button.innerHTML = original_text;
      }

      if (default_icon && copied_icon) {
        default_icon.classList.remove("hidden");
        copied_icon.classList.add("hidden");
      }
    }, 2000);
  }
}
