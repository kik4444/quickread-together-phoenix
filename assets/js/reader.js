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

// Initial state
let playing = false;
let currentIndex = 0;
const chunkSize = 1;
const wordsPerMinute = 300;
let chunks = split(Textarea.value, chunkSize);

// TODO return new_text handling on Textarea

//@ts-expect-error
window.addEventListener("phx:playing_toggle", e => playing = e.detail.playing);

let Hooks = {};

Hooks.Display = {
    mounted() {
        this.displayChunk();

        //@ts-expect-error
        this.handleEvent("reader_reset", _ => {
            playing = false;
            currentIndex = 0;
        });

        // NOTE handler must be an arrow function due to "this" problem with setTimeout
        setTimeout(() => this.tick(), wordsPerMinute);
    },

    displayChunk() {
        //@ts-expect-error
        this.el.innerText = chunks[currentIndex].chunk;
    },

    tick() {
        if (playing) {
            if (currentIndex < chunks.length - 1) {
                ++currentIndex;
                this.displayChunk();
            } else {
                this.end();
            }
        }

        setTimeout(() => this.tick(), wordsPerMinute);
    },

    end() {
        // TODO send event to server
        // set playing to false server-side
        // set currentIndex to 0, but for everyone?
        //@ts-expect-error
        this.pushEvent("reader_ended");
    },
};

export default Hooks;
