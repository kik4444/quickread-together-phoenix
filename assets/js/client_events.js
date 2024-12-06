/** @type {HTMLTextAreaElement} */
const textarea = document.querySelector("#textarea");

/** @type {HTMLInputElement} */
const wpmInput = document.querySelector("#words_per_minute");

/** @type {HTMLInputElement} */
const chunkSizeInput = document.querySelector("#chunk_size");

/** @type {HTMLInputElement} */
const indexInput = document.querySelector("#index");

// Phoenix does not change the values in input elements if the user is focused on them,
// so we must change them ourselves via an event.
window.addEventListener("phx:new_text", e => textarea.value = e.detail.new_text);

// We must focus the textarea otherwise the selection range is not visible.
window.addEventListener("phx:selection_focus", _ => textarea.focus());

window.addEventListener("phx:select_range", e => textarea.setSelectionRange(e.detail.start_offset, e.detail.stop_offset));

window.addEventListener("phx:selection_blur", _ => textarea.blur());

window.addEventListener("phx:wpm_changed", e => wpmInput.value = e.detail.wpm);

window.addEventListener("phx:chunk_size_changed", e => chunkSizeInput.value = e.detail.chunk_size);

window.addEventListener("phx:index_changed", e => indexInput.value = e.detail.index);
