import pc from "picocolors";

const VERSION = "1.0.0";

// Box-drawing characters
const S_BAR = "│";
const S_BAR_END = "└";
const S_BAR_H = "─";
const S_CORNER_TOP_LEFT = "┌";
const S_STEP_ACTIVE = "◇";
const S_STEP_ERROR = "✖";
const S_CONNECT_LEFT = "├";

export const ui = {
  /** Print header with version */
  header: () => {
    console.log(`${pc.gray(S_CORNER_TOP_LEFT)}  ${pc.bold("swiftcn")} ${pc.dim(`v${VERSION}`)}`);
    console.log(pc.gray(S_BAR));
  },

  /** Print a step/action message */
  step: (message: string) => {
    console.log(`${pc.cyan(S_STEP_ACTIVE)}  ${message}`);
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

  /** Print a file in tree structure */
  fileTree: (path: string, isLast: boolean = false) => {
    const prefix = isLast ? S_BAR_END : S_CONNECT_LEFT;
    console.log(`${pc.gray(prefix)}  ${path}`);
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
  },

  /** Print empty line */
  break: () => {
    console.log(pc.gray(S_BAR));
  },

  /** Print numbered step */
  numberedStep: (num: number, title: string, command: string) => {
    console.log(`${pc.gray(S_BAR)}  ${pc.bold(num.toString())}. ${title}`);
    console.log(`${pc.gray(S_BAR)}     ${pc.cyan(command)}`);
  },
};
