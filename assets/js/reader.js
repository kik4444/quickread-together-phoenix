import split, { empty_chunk } from "./splitter";

// Initial state
let playing = false;
let currentIndex = 0;
const chunkSize = 1;
const wordsPerMinute = 300;

let chunks = empty_chunk();

//@ts-expect-error
window.addEventListener("phx:playing", e => playing = e.detail.playing);

let Hooks = {};

Hooks.TextArea = {
    //@ts-expect-error
    mounted() { chunks = split(/** @type {HTMLTextAreaElement}*/(this.el).value, chunkSize); }
};

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
                this.displayChunk();
            } else {
                this.stop();
            }
        }

        setTimeout(() => this.tick(), wordsPerMinute);
    },

    stop() {
        // TODO send event to server
        // set playing to false server-side
        // set currentIndex to 0, but for everyone?
    },
};

export default Hooks;
