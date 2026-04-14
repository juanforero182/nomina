import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fileInput", "submitButton", "buttonText", "buttonIcon", "buttonSpinner"]

  connect() {
    this.originalText = this.buttonTextTarget.textContent
  }

  fileChanged() {
    const hasFile = this.fileInputTarget.files.length > 0
    this.submitButtonTarget.disabled = !hasFile
  }

  submit() {
    if (this.submitButtonTarget.disabled) return

    this.submitButtonTarget.disabled = true
    this.buttonIconTarget.style.display = "none"
    this.buttonSpinnerTarget.style.display = ""
    this.buttonTextTarget.textContent = "Importando..."

    setTimeout(() => this.resetButton(), 15000)
  }

  resetButton() {
    this.submitButtonTarget.disabled = false
    this.buttonIconTarget.style.display = ""
    this.buttonSpinnerTarget.style.display = "none"
    this.buttonTextTarget.textContent = this.originalText
  }
}
