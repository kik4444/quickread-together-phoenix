/** @type {HTMLTextAreaElement} */
const textarea = document.querySelector("#textarea");

/** @type {HTMLInputElement} */
const wpmInput = document.querySelector("#words_per_minute");

/** @type {HTMLInputElement} */
const chunkSizeInput = document.querySelector("#chunk_size");

window.addEventListener("phx:new_text", e => textarea.value = e.detail.new_text);

window.addEventListener("phx:select_range", e => {
    // We must focus the textarea otherwise the highlight is not visible.
    textarea.focus();
    textarea.setSelectionRange(e.detail.start_offset, e.detail.stop_offset);
});

window.addEventListener("phx:selection_blur", _ => textarea.blur());

window.addEventListener("phx:wpm_changed", e => wpmInput.value = e.detail.wpm);

window.addEventListener("phx:chunk_size_changed", e => chunkSizeInput.value = e.detail.chunk_size);
