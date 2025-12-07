import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["intervalButton", "plan", "toggleableContent"]
  static classes = ["activeInterval", "inactiveInterval"]
  static values = {
    defaultInterval: String,
  }

  connect() {
    this.toggleInterval(this.defaultIntervalValue)
  }

  clickIntervalToggle(event) {
    const intervalButton = event.target.closest(".toggle-interval")
    const interval = intervalButton.dataset.interval
    this.toggleInterval(interval)
  }

  toggleInterval(interval) {
    // Toggle the interval selection buttons
    this.intervalButtonTargets.forEach(button => {
      if (button.dataset.interval === interval) {
        button.classList.add(this.activeIntervalClass)
        button.classList.remove(this.inactiveIntervalClass)
      } else {
        button.classList.remove(this.activeIntervalClass)
        button.classList.add(this.inactiveIntervalClass)
      }
    })

    // Toggle the toggleable content in the plans
    this.toggleableContentTargets.forEach(content => {
      if (content.dataset.interval === interval) {
        content.classList.remove("hidden")
      } else {
        content.classList.add("hidden")
      }
    })
  }

  clickChangePlanButton(event) {
    const form = event.target.closest("form")
    const button = form.querySelector(".change-plan-button")
    const icon = button.querySelector(".change-plan-button-icon")
    const textContainer = button.querySelector(".change-plan-button-text")
    console.log('button', button)
    console.log('icon', icon)
    console.log('textContainer', textContainer)

    const processingText = form.dataset.processingText
    console.log('this.element', this.element)
    console.log('this.element.dataset', this.element.dataset)
    console.log('processingText', processingText)

    icon.classList.remove("hidden")
    textContainer.textContent = processingText
    button.classList.add("opacity-50")
    button.disabled = true
  }
}
