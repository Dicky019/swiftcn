import pc from "picocolors";

const VERSION = "1.0.0";

// RGB color helper for true color terminals
const rgb = (r: number, g: number, b: number) => (text: string) =>
  `\x1b[38;2;${r};${g};${b}m${text}\x1b[0m`;

// Gradient colors from #de5e44 to #ff9521
const gradientColors = [
  rgb(222, 94, 68),   // #de5e44
  rgb(229, 105, 61),  // #e5693d
  rgb(236, 116, 54),  // #ec7436
  rgb(243, 127, 47),  // #f37f2f
  rgb(250, 138, 40),  // #fa8a28
  rgb(255, 149, 33),  // #ff9521
];

// Accent color #fa8a28
const accent = rgb(250, 138, 40);

// ASCII Art Banner lines
const BANNER_LINES = [
  "███████╗██╗    ██╗██╗███████╗████████╗ ██████╗███╗   ██╗",
  "██╔════╝██║    ██║██║██╔════╝╚══██╔══╝██╔════╝████╗  ██║",
  "███████╗██║ █╗ ██║██║█████╗     ██║   ██║     ██╔██╗ ██║",
  "╚════██║██║███╗██║██║██╔══╝     ██║   ██║     ██║╚██╗██║",
  "███████║╚███╔███╔╝██║██║        ██║   ╚██████╗██║ ╚████║",
  "╚══════╝ ╚══╝╚══╝ ╚═╝╚═╝        ╚═╝    ╚═════╝╚═╝  ╚═══╝",
];

// Box-drawing characters
const S_BAR = "│";
const S_BAR_END = "└";
const S_BAR_H = "─";
const S_CORNER_TOP_LEFT = "┌";
const S_STEP_ACTIVE = "◇";
const S_STEP_ERROR = "✖";
const S_CONNECT_LEFT = "├";

/** Format text with bar prefix for each line */
const formatWithBar = (text: string): string => {
  return text
    .split("\n")
    .map((line) => `${pc.gray(S_BAR)}  ${line}`)
    .join("\n");
};

export const ui = {
  /** Print header with version */
  header: () => {
    console.log();
    BANNER_LINES.forEach((line, i) => {
      console.log(gradientColors[i](line));
    });
    console.log();
    console.log(`${pc.gray(S_CORNER_TOP_LEFT)}  ${pc.dim(`v${VERSION}`)}`);
  },

  /** Format multi-line text with bar prefix */
  formatWithBar,

  /** Print a step/action message */
  step: (message: string) => {
    console.log(`${pc.green(S_STEP_ACTIVE)}  ${message}`);
  },

  /** Print a line continuation */
  line: (message: string = "") => {
    console.log(`${pc.gray(S_BAR)}  ${message}`);
  },

  /** Print a file added */
  fileAdded: (path: string) => {
    console.log(`${pc.gray(S_BAR)}  ${pc.green("+")} ${path}`);
  },

  /** Print a file exists */
  fileExists: (path: string) => {
    console.log(`${pc.gray(S_BAR)}  ${pc.yellow("~")} ${path} ${pc.dim("(exists)")}`);
  },

  /** Print section header */
  section: (title: string) => {
    const line = S_BAR_H.repeat(45 - title.length);
    console.log(`${pc.gray(S_BAR)}  ${title} ${pc.gray(line)}`);
  },

  /** Print info text */
  info: (message: string) => {
    console.log(`${pc.gray(S_BAR)}  ${pc.dim(message)}`);
  },

  /** Print error */
  error: (message: string) => {
    console.log(`${pc.red(S_STEP_ERROR)}  ${message}`);
  },

  /** Print end of output */
  end: (message: string = "") => {
    console.log(`${pc.gray(S_BAR_END)}  ${message}`);
    console.log();
  },

  /** Print empty line */
  break: () => {
    console.log(pc.gray(S_BAR));
  },

  /** Print a command hint */
  command: (cmd: string, description?: string) => {
    if (description) {
      console.log(`${pc.gray(S_BAR)}  ${pc.gray("→")} ${accent(cmd)}  ${pc.dim(description)}`);
    } else {
      console.log(`${pc.gray(S_BAR)}  ${pc.gray("→")} ${accent(cmd)}`);
    }
  },

  /** Print success message with celebration */
  success: (message: string) => {
    console.log(`${pc.green("◆")}  ${pc.green(pc.bold(message))}`);
  },

  /** Print a hint/tip */
  hint: (message: string) => {
    console.log(`${pc.gray(S_BAR)}  ${pc.dim("›")} ${pc.dim(message)}`);
  },

  /** Print a labeled list (e.g., Variants: a · b · c) */
  labeledList: (label: string, items: string[]) => {
    const formatted = items.map((item) => accent(item)).join(` ${pc.dim("·")} `);
    console.log(`${pc.gray(S_BAR)}  ${pc.bold(label + ":")} ${formatted}`);
  },

  /** Apply accent color to text */
  accent: (text: string) => accent(text),
};
