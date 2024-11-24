/** @type {HTMLTextAreaElement} */
const textarea = document.querySelector("#textarea");

window.addEventListener("phx:new_text", e => {
    textarea.value = e.detail.new_text;
});
