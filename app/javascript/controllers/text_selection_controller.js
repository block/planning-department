import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "popover", "form", "anchorInput", "anchorPreview", "anchorQuote"]
  static values = { planId: String }

  connect() {
    this.selectedText = null
    this.contentTarget.addEventListener("mouseup", this.handleMouseUp.bind(this))
    document.addEventListener("mousedown", this.handleDocumentMouseDown.bind(this))
    this.highlightAnchors()
  }

  disconnect() {
    this.contentTarget.removeEventListener("mouseup", this.handleMouseUp.bind(this))
    document.removeEventListener("mousedown", this.handleDocumentMouseDown.bind(this))
  }

  handleMouseUp(event) {
    // Small delay to let the selection finalize
    setTimeout(() => this.checkSelection(event), 10)
  }

  handleDocumentMouseDown(event) {
    // Hide popover if clicking outside it
    if (this.hasPopoverTarget && !this.popoverTarget.contains(event.target)) {
      this.popoverTarget.style.display = "none"
    }
  }

  checkSelection(event) {
    const selection = window.getSelection()
    const text = selection.toString().trim()

    if (text.length < 3) {
      this.popoverTarget.style.display = "none"
      return
    }

    // Make sure selection is within the content area
    if (!selection.rangeCount) return
    const range = selection.getRangeAt(0)
    if (!this.contentTarget.contains(range.commonAncestorContainer)) {
      return
    }

    this.selectedText = text

    // Position popover near the selection
    const rect = range.getBoundingClientRect()
    const contentRect = this.contentTarget.getBoundingClientRect()

    this.popoverTarget.style.display = "block"
    this.popoverTarget.style.top = `${rect.bottom - contentRect.top + 8}px`
    this.popoverTarget.style.left = `${rect.left - contentRect.left}px`
  }

  openCommentForm(event) {
    event.preventDefault()
    if (!this.selectedText) return

    // Set the anchor text
    this.anchorInputTarget.value = this.selectedText
    this.anchorQuoteTarget.textContent = this.selectedText.length > 120
      ? this.selectedText.substring(0, 120) + "…"
      : this.selectedText
    this.anchorPreviewTarget.style.display = "block"

    // Show form, hide popover
    this.formTarget.style.display = "block"
    this.popoverTarget.style.display = "none"

    // Clear browser selection
    window.getSelection().removeAllRanges()

    // Focus textarea
    const textarea = this.formTarget.querySelector("textarea")
    if (textarea) {
      textarea.focus()
      textarea.scrollIntoView({ behavior: "smooth", block: "center" })
    }
  }

  cancelComment(event) {
    event.preventDefault()
    this.formTarget.style.display = "none"
    this.anchorInputTarget.value = ""
    this.anchorPreviewTarget.style.display = "none"
    this.selectedText = null
  }

  scrollToAnchor(event) {
    const anchor = event.currentTarget.dataset.anchor
    if (!anchor) return

    // Remove existing highlights first
    this.contentTarget.querySelectorAll(".anchor-highlight--active").forEach(el => {
      el.classList.remove("anchor-highlight--active")
    })

    // Find and highlight the anchor text
    const highlighted = this.findAndHighlight(anchor, "anchor-highlight--active")
    if (highlighted) {
      highlighted.scrollIntoView({ behavior: "smooth", block: "center" })
    }
  }

  highlightAnchors() {
    // Find all threads with anchor text and highlight them
    const threads = this.element.querySelectorAll("[data-anchor-text]")
    threads.forEach(thread => {
      const anchor = thread.dataset.anchorText
      if (anchor && anchor.length > 0) {
        this.findAndHighlight(anchor, "anchor-highlight")
      }
    })
  }

  findAndHighlight(text, className) {
    if (!text || text.length === 0) return null

    const walker = document.createTreeWalker(
      this.contentTarget,
      NodeFilter.SHOW_TEXT,
      null,
      false
    )

    // Collect all text nodes and their positions
    const textNodes = []
    let fullText = ""
    let node
    while (node = walker.nextNode()) {
      textNodes.push({ node, start: fullText.length })
      fullText += node.textContent
    }

    // Find the text in the concatenated content
    const index = fullText.indexOf(text)
    if (index === -1) return null

    // Find which text nodes contain the match
    const matchEnd = index + text.length
    let firstHighlighted = null

    for (let i = 0; i < textNodes.length; i++) {
      const tn = textNodes[i]
      const nodeEnd = tn.start + tn.node.textContent.length

      // Skip nodes before the match
      if (nodeEnd <= index) continue
      // Stop after the match
      if (tn.start >= matchEnd) break

      const localStart = Math.max(0, index - tn.start)
      const localEnd = Math.min(tn.node.textContent.length, matchEnd - tn.start)

      // Split the text node and wrap the matching part
      const range = document.createRange()
      range.setStart(tn.node, localStart)
      range.setEnd(tn.node, localEnd)

      const mark = document.createElement("mark")
      mark.className = className
      range.surroundContents(mark)

      if (!firstHighlighted) firstHighlighted = mark
    }

    return firstHighlighted
  }
}
