window.addEventListener("phx:new_text", e => {
    /** @type {HTMLTextAreaElement} */
    const textarea = document.querySelector("#textarea");
    textarea.value = e.detail.new_text;
});
