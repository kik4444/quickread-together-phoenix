import split from "./splitter";

/** Because apparently JSDoc has no other way to assert non-null. See https://github.com/microsoft/TypeScript/issues/23405
 * @template T
 * @param {T} value
 * @returns {NonNullable<T>} `value` unchanged
 */
function $(value) {
    return /** @type {NonNullable<T>} */ (value);
}

/** @type {HTMLTextAreaElement} */
const Textarea = $(document.querySelector("#textarea"));

/** @type {HTMLParagraphElement} */
const Display = $(document.querySelector("#display"));

// Initial state
let playing = false;
let currentIndex = 0;
const chunkSize = 1;
const wordsPerMinute = 300;

let chunks = split(Textarea.value, chunkSize);

const displayChunk = () => Display.innerText = chunks[currentIndex].chunk;

function stop() {
    // TODO send event to server
    // set playing to false server-side
    // set currentIndex to 0, but for everyone?
}

function tick() {
    if (playing) {
        if (currentIndex < chunks.length - 1) {
            ++currentIndex;
            displayChunk();
        } else {
            stop();
        }
    }

    setTimeout(tick, wordsPerMinute);
}

setTimeout(tick, wordsPerMinute);

Display.addEventListener("display_mounted", _ => displayChunk());

//@ts-expect-error
window.addEventListener("phx:playing", e => playing = e.detail.playing);
