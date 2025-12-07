import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["reorderable"]
  static classes = ["dropIndicator"]

  connect() {
    this.setupDragAndDrop()
  }

  setupDragAndDrop() {
    // Make the container a drop area
    this.element.addEventListener("dragover", this.dragOver.bind(this))
    this.element.addEventListener("drop", this.drop.bind(this))

    // Setup draggable items
    this.reorderableTargets.forEach(item => {
      item.setAttribute("draggable", true)
      item.addEventListener("dragstart", this.dragStart.bind(this))
      item.addEventListener("dragend", this.dragEnd.bind(this))
      item.classList.add("cursor-move")
    })
  }

  dragStart(event) {
    const draggedElement = event.target.closest("[data-components--reorder-target=reorderable]")
    draggedElement.classList.add("dragged-element")
    draggedElement.classList.add("opacity-50")
  }

  dragEnd(event) {
    const draggedElement = event.target.closest("[data-components--reorder-target=reorderable]")
    draggedElement.classList.remove("dragged-element")
    draggedElement.classList.remove("opacity-50")
    this.element.querySelectorAll(".drop-indicator").forEach(indicator => {
      indicator.remove()
    })
  }

  getDropPosition(event) {
    const containerRect = this.element.getBoundingClientRect()
    const dropY = event.clientY - containerRect.top

    // Find the closest item to the drop position
    let closestItem = null
    let minDistance = Infinity

    this.reorderableTargets.forEach(item => {
      const rect = item.getBoundingClientRect()
      const itemCenter = rect.top + rect.height/2 - containerRect.top
      const distance = Math.abs(dropY - itemCenter)

      if (distance < minDistance) {
        minDistance = distance
        closestItem = item
      }
    })

    if (!closestItem) return { item: null, position: "before" }

    const itemRect = closestItem.getBoundingClientRect()
    const itemCenter = itemRect.top + itemRect.height/2 - containerRect.top
    return {
      item: closestItem,
      position: dropY < itemCenter ? "before" : "after"
    }
  }

  dragOver(event) {
    event.preventDefault()

    // Remove any existing drop indicators
    this.element.querySelectorAll(".drop-indicator").forEach(indicator => {
      indicator.remove()
    })

    const { item, position } = this.getDropPosition(event)
    if (!item) return

    const dropIndicator = document.createElement("div")
    dropIndicator.classList.add("drop-indicator") // hard-code our identifier class

    var classes = this.dropIndicatorClasses
    if (classes.length === 0) {
      // If no custom classes are set, use these default classes
      classes = ["h-[1px]", "border-t-4", "border-dashed", "border-gray-200", "dark:border-gray-800", "w-full"]
    }
    dropIndicator.classList.add(...classes) // add custom styling classes, set in the DOM

    if (position === "before") {
      item.parentNode.insertBefore(dropIndicator, item)
    } else {
      item.parentNode.insertBefore(dropIndicator, item.nextSibling)
    }
  }

  drop(event) {
    event.preventDefault()
    const draggedElement = document.querySelector(".dragged-element")
    const { item, position } = this.getDropPosition(event)

    if (!item || draggedElement === item) return

    if (position === "before") {
      item.parentNode.insertBefore(draggedElement, item)
    } else {
      item.parentNode.insertBefore(draggedElement, item.nextSibling)
    }

    // Clean up any remaining drop indicators
    this.element.querySelectorAll(".drop-indicator").forEach(indicator => {
      indicator.remove()
    })

    // Handle saving the new position by providing the following data attributes on each item:
    // - data-save-path: the path to send the patch request to save the new position
    // - data-starting-position: the starting position of each item
    if (draggedElement.dataset.savePath) {
      const savePath = draggedElement.dataset.savePath

      // Calculate new position based on the item we're dropping after
      let newPosition
      const draggedPosition = parseInt(draggedElement.dataset.startingPosition)
      const targetPosition = parseInt(item.dataset.startingPosition)

      if (position === "before") {
        // If dropping before an item, use its position
        newPosition = targetPosition
        // If moving down in the list, adjust the position
        if (draggedPosition > targetPosition) {
          newPosition = targetPosition
        }
      } else {
        // If dropping after an item, use its position + 1
        newPosition = targetPosition + 1
        // If moving up in the list, adjust the position
        if (draggedPosition < targetPosition) {
          newPosition = targetPosition
        }
      }

      // Ensure position is at least 1
      newPosition = Math.max(1, newPosition)

      const formData = new FormData()
      formData.append("position", newPosition)

      fetch(savePath, {
        method: "PATCH",
        body: formData,
        headers: {
          "X-Requested-With": "XMLHttpRequest",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
      })
    }
  }
}
