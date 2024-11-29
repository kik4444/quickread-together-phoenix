/** @type {HTMLTextAreaElement} */
const textarea = document.querySelector("#textarea");

window.addEventListener("phx:select_range", e => {
    // We must focus the textarea otherwise the highlight is not visible.
    textarea.focus();
    textarea.setSelectionRange(e.detail.start_offset, e.detail.stop_offset);
});

window.addEventListener("phx:selection_blur", _ => textarea.blur());
