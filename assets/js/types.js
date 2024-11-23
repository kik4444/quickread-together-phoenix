// Converted from https://github.com/DefinitelyTyped/DefinitelyTyped/blob/master/types/phoenix_live_view/index.d.ts

/**
* @template [T = HTMLElement] The type of the HTML element inside the hook, defaults to HTMLElement.
* @template [H = object] The payload type in handleEvent, defaults to object.
* @template [PE = object] The payload type in pushEvent, defaults to object.
* @template [PT = object] The payload type in pushEventTo, defaults to object.
* @typedef {Object} ViewHook
* @property {function(this: T & ViewHookInternal<T, H, PE, PT>):void} [mounted] Called when the element is mounted.
* @property {function(this: T & ViewHookInternal<T, H, PE, PT>):void} [beforeUpdate] Called before the element updates.
* @property {function(this: T & ViewHookInternal<T, H, PE, PT>):void} [updated] Called when the element updates.
* @property {function(this: T & ViewHookInternal<T, H, PE, PT>):void} [beforeDestroy] Called before the element is destroyed.
* @property {function(this: T & ViewHookInternal<T, H, PE, PT>):void} [destroyed] Called when the element is destroyed.
* @property {function(this: T & ViewHookInternal<T, H, PE, PT>):void} [disconnected] Called when the element is disconnected.
* @property {function(this: T & ViewHookInternal<T, H, PE, PT>):void} [reconnected] Called when the element is reconnected.
*/

/**
* @template [T = HTMLElement] The type of the HTML element, defaults to HTMLElement.
* @template [H = object] The payload type in handleEvent, defaults to object.
* @template [PE = object] The payload type in pushEvent, defaults to object.
* @template [PT = object] The payload type in pushEventTo, defaults to object.
* @typedef {Object} ViewHookInternal
* @property {T} el The HTML element.
* @property {string} viewName The name of the view.
* @property {(event: string, payload: PE, onReply?: (reply: any, ref: number) => any) => void} pushEvent Pushes an event.
* @property {(selectorOrTarget: any, event: string, payload: PT, onReply?: (reply: any, ref: number) => any) => void} pushEventTo Pushes an event to a selector or target.
* @property {(event: string, callback: (payload: H) => void) => void} handleEvent Handles an event.
* @property {() => void} [mounted] Called when the element is mounted.
* @property {() => void} [beforeUpdate] Called before the element updates.
* @property {() => void} [updated] Called when the element updates.
* @property {() => void} [beforeDestroy] Called before the element is destroyed.
* @property {() => void} [destroyed] Called when the element is destroyed.
* @property {() => void} [disconnected] Called when the element is disconnected.
* @property {() => void} [reconnected] Called when the element is reconnected.
*/

// Required for JSDoc to allow importing types from this file
export default null;
