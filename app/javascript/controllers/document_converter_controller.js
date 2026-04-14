import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sourceFormat", "targetFormat", "fileSection", "fileInput", "submitButton", "buttonText", "buttonIcon", "buttonSpinner"]
  static values = { convertLabel: String, convertingLabel: String }

  connect() {
    this.originalText = this.buttonTextTarget.textContent
    this.updateState()
  }

  selectChanged() {
    if (this.hasFileInputTarget) {
      this.fileInputTarget.value = ""
    }
    this.updateState()
  }

  fileChanged() {
    this.updateState()
  }

  submit() {
    if (this.submitButtonTarget.disabled) return

    // Show loading state
    this.submitButtonTarget.disabled = true
    this.buttonIconTarget.style.display = "none"
    this.buttonSpinnerTarget.style.display = ""
    this.buttonTextTarget.textContent = "Convirtiendo..."

    // Reset after timeout (file download doesn't trigger page navigation)
    setTimeout(() => this.resetButton(), 10000)
  }

  resetButton() {
    this.submitButtonTarget.disabled = false
    this.buttonIconTarget.style.display = ""
    this.buttonSpinnerTarget.style.display = "none"
    this.buttonTextTarget.textContent = this.originalText
  }

  updateState() {
    const sourceSelected = this.sourceFormatTarget.value !== ""
    const targetSelected = this.targetFormatTarget.value !== ""
    const bothSelected = sourceSelected && targetSelected

    if (bothSelected) {
      this.fileSectionTarget.classList.remove("hidden")
    } else {
      this.fileSectionTarget.classList.add("hidden")
    }

    if (this.hasFileInputTarget) {
      const hasFile = this.fileInputTarget.files.length > 0
      this.submitButtonTarget.disabled = !hasFile
    }
  }
}
