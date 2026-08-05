import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// Pi sets the terminal title with OSC 0: ESC ] 0 ; <title> BEL.
// Install this before interactive mode finishes binding extensions, so its first
// title update (and all later session-name updates) is discarded.
const INSTALLED = Symbol.for("pi.no-window-title.installed");
const OSC_TITLE = /\x1b]0;[^\x07\x1b]*(?:\x07|\x1b\\)/g;

type MarkedStdout = typeof process.stdout & { [INSTALLED]?: boolean };

export default function (_pi: ExtensionAPI) {
  const stdout = process.stdout as MarkedStdout;
  if (stdout[INSTALLED]) return;

  const write = stdout.write.bind(stdout);
  stdout.write = ((chunk: string | Uint8Array, ...args: unknown[]) => {
    // Pi's terminal implementation writes the entire OSC sequence as a string.
    // Leave non-string output untouched to avoid changing normal TUI rendering.
    if (typeof chunk === "string") chunk = chunk.replace(OSC_TITLE, "");
    return (write as (...writeArgs: unknown[]) => boolean)(chunk, ...args);
  }) as typeof stdout.write;
  stdout[INSTALLED] = true;
}
