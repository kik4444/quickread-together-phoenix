/** @type {HTMLTextAreaElement} */
const textarea = document.querySelector("#textarea");

/** @type {HTMLParagraphElement} */
const display = document.querySelector("#display");

window.addEventListener("phx:new_text", e => {
    textarea.value = e.detail.new_text;
});

window.addEventListener("phx:playing", e => {
    console.log(e.detail.playing);
});
