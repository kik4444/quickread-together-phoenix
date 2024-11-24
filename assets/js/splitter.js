/**
 * Parsed text chunk without whitespace and
 * with recorded start and stop offsets
 * for highlighting those words in their source TextArea
 * @typedef {Object} TextChunk
 * @property {string} chunk
 * @property {number} startOffset
 * @property {number} stopOffset
 */

/**
 * @param {string} text
 * @param {number} chunkSize
 * @returns {TextChunk[]}
 */
export default function (text, chunkSize) {
    if (!text) {
        return [{
            chunk: "",
            startOffset: 0,
            stopOffset: 0
        }];
    }

    /** @type {TextChunk[]} */
    let delimitedText = [];

    const matches = text.matchAll(/\S+/g);

    for (const match of matches) {
        delimitedText.push({
            chunk: match[0],
            startOffset: match.index,
            stopOffset: match.index + match[0].length - 1,
        });
    }

    if (chunkSize > 1) {
        /** @type {TextChunk[]} */
        let newDelimitedText = [];

        for (let i = 0; i < delimitedText.length; i += chunkSize) {
            const sections = delimitedText.slice(i, i + chunkSize);

            const joinedText = sections
                .map(section => section.chunk)
                .reduce((prev, cur) => prev + " " + cur);

            newDelimitedText.push({
                chunk: joinedText,
                startOffset: sections[0].startOffset,
                stopOffset: sections[sections.length - 1].stopOffset
            });
        }

        console.log("got here");
        return newDelimitedText;
    }

    return delimitedText;
}
