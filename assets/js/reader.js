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
let pendingStop = false; // Used to prevent sending stop events repeatedly until the server responds
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
            } else {
                if (!pendingStop) {
                    pendingStop = true;
                    this.end();
                }
            }
        }

        this.displayChunk();

        setTimeout(() => this.tick(), wordsPerMinute);
    },

    end() {
        //@ts-expect-error
        this.pushEvent("reader_ended", {}, () => {
            playing = false;
            currentIndex = 0;
            pendingStop = false;
        });
    },
};

export default Hooks;
