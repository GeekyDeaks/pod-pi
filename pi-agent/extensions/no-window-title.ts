import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const OSC_WINDOW_TITLE = /\x1b\][0-2];[^\x07\x1b]*(?:\x07|\x1b\\)/g;

/** Prevent Pi from changing the terminal window or tab title. */
export default function noWindowTitle(_pi: ExtensionAPI) {
  const write = process.stdout.write.bind(process.stdout);

  process.stdout.write = ((chunk: string | Uint8Array, ...args: unknown[]) => {
    if (typeof chunk === "string") {
      chunk = chunk.replace(OSC_WINDOW_TITLE, "");
    }
    return write(chunk, ...(args as []));
  }) as typeof process.stdout.write;
}
