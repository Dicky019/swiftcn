import { afterAll, beforeAll, describe, expect, it } from "vitest";
import fs from "fs-extra";
import os from "node:os";
import path from "node:path";
import { execFile, fork, type ChildProcess } from "node:child_process";
import { once } from "node:events";
import { promisify } from "node:util";
import { FileTransactionServiceImpl } from "../../services/FileTransactionService.js";

const cli = path.resolve(import.meta.dirname, "../../..");
type Message = { type: "paused" | "done" | "error"; code?: string; message?: string };

describe("FileTransactionService cross-process recovery", () => {
  let compiled: string;

  beforeAll(async () => {
    // Compile current sources for ordinary Node processes, including Node 20.
    compiled = await fs.realpath(await fs.mkdtemp(path.join(os.tmpdir(), "swiftcn-process-build-")));
    await fs.copy(path.join(cli, "package.json"), path.join(compiled, "package.json"));
    await fs.symlink(path.join(cli, "node_modules"), path.join(compiled, "node_modules"));
    await promisify(execFile)(process.execPath, [
      path.join(cli, "node_modules/typescript/bin/tsc"), "--project", path.join(cli, "tsconfig.json"),
      "--outDir", path.join(compiled, "dist"),
    ]);
  });
  afterAll(async () => { if (compiled) await fs.remove(compiled); });

  it("excludes another recovery until cleanup finishes and leaves subsequent init recoverable", async () => {
    const root = await fs.realpath(await fs.mkdtemp(path.join(os.tmpdir(), "swiftcn-process-project-")));
    const cwd = path.join(root, "project");
    const transaction = path.join(cwd, ".swiftcn-transaction");
    const source = path.join(root, "source.swift");
    const owned = path.join(cwd, "Theme/Owned.swift");
    const children: ChildProcess[] = [];
    const spawn = (mode: "recover" | "apply") => {
      const child = fork(path.join(cli, "src/__tests__/fixtures/transaction-process.mjs"), [
        path.join(compiled, "dist/services/FileTransactionService.js"), mode, cwd, source,
      ], { stdio: ["ignore", "ignore", "inherit", "ipc"] });
      children.push(child);
      const queued: Message[] = [];
      const waiting: ((message: Message) => void)[] = [];
      child.on("message", (message: Message) => {
        if (waiting.length) waiting.shift()!(message); else queued.push(message);
      });
      return {
        child,
        next: () => queued.length ? Promise.resolve(queued.shift()!) : new Promise<Message>((resolve) => waiting.push(resolve)),
      };
    };
    try {
      await fs.outputJson(path.join(transaction, "journal.json"), {
        version: 1, ownerPid: 2147483647, state: "staging", entries: [],
      });
      await fs.outputFile(owned, "user original");
      await fs.writeFile(source, "replacement");
      const first = spawn("recover");
      expect(await first.next()).toEqual({ type: "paused" });
      const second = spawn("recover");
      expect(await second.next()).toMatchObject({ type: "error", code: "INIT_ALREADY_RUNNING" });
      first.child.send("continue");
      expect(await first.next()).toEqual({ type: "done" });

      const nextInit = spawn("apply");
      expect(await nextInit.next()).toEqual({ type: "paused" });
      expect(await fs.pathExists(path.join(transaction, "journal.json"))).toBe(true);
      const exit = once(nextInit.child, "exit");
      nextInit.child.kill("SIGKILL");
      await exit;
      await new FileTransactionServiceImpl().recover(cwd);
      expect(await fs.readFile(owned, "utf8")).toBe("user original");
      expect(await fs.pathExists(path.join(cwd, "swiftcn.json"))).toBe(false);
      expect(await fs.pathExists(transaction)).toBe(false);
    } finally {
      await Promise.all(children.map(async (child) => {
        if (child.exitCode !== null || child.signalCode !== null) return;
        const exit = once(child, "exit");
        child.kill("SIGKILL");
        await exit;
      }));
      await fs.remove(root);
    }
  });
});
