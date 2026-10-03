import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import fs from "fs-extra";
import path from "node:path";
import os from "node:os";
import { FileTransactionServiceImpl } from "../../services/FileTransactionService.js";
import { projectConfigSchema } from "../../types/config.schema.js";
import { ErrorCode } from "../../utils/errors.js";

describe("FileTransactionServiceImpl", () => {
  let root: string;
  let cwd: string;
  let source: string;
  let first: string;
  let second: string;
  let service: FileTransactionServiceImpl;
  const config = projectConfigSchema.parse({ componentsPath: "Components", themePath: "Theme" });
  const deadPid = 2147483647;
  const requests = () => [
    { sourcePath: source, destinationPath: first },
    { sourcePath: source, destinationPath: second },
  ];
  const transaction = () => path.join(cwd, ".swiftcn-transaction");
  const journalPath = () => path.join(transaction(), "journal.json");

  beforeEach(async () => {
    root = await fs.realpath(await fs.mkdtemp(path.join(os.tmpdir(), "swiftcn-init-")));
    cwd = path.join(root, "project");
    source = path.join(root, "source.swift");
    first = path.join(cwd, "Theme", "First.swift");
    second = path.join(cwd, "Theme", "Second.swift");
    await fs.ensureDir(cwd);
    await fs.writeFile(source, "new");
    service = new FileTransactionServiceImpl();
  });

  afterEach(async () => {
    vi.restoreAllMocks();
    await fs.remove(root);
  });

  // These fixtures model disk state at the process-termination boundary,
  // including moves that completed before their journal state was updated.
  async function interrupted(state: "planned" | "backup-created" | "applied" = "applied") {
    const stage = path.join(transaction(), "stage");
    const backup = path.join(transaction(), "backup");
    await fs.outputFile(path.join(backup, "0"), "original");
    await fs.outputFile(first, "new");
    await fs.outputFile(second, "new");
    await fs.ensureDir(stage);
    const entries = [
      { destinationPath: first, stagedPath: path.join(stage, "0"), backupPath: path.join(backup, "0"), action: "replace", state },
      { destinationPath: second, stagedPath: path.join(stage, "1"), action: "create", state: state === "backup-created" ? "planned" : state },
    ];
    await fs.writeJson(journalPath(), { version: 1, ownerPid: deadPid, state: "applying", entries });
    return entries;
  }

  it("adds files and reports only source destinations", async () => {
    const result = await service.apply({ cwd, files: requests(), config });
    expect(result).toEqual({ added: [first, second], replaced: [], skipped: [] });
    expect(await fs.readFile(first, "utf8")).toBe("new");
    expect(await fs.readJson(path.join(cwd, "swiftcn.json"))).toEqual(config);
    expect(await fs.pathExists(transaction())).toBe(false);
  });

  it("preserves the caller's project-root spelling in reported paths", async () => {
    const alias = path.join(root, "alias");
    await fs.symlink(cwd, alias);
    const destination = path.join(alias, "Theme", "First.swift");
    const result = await service.apply({ cwd: alias, files: [{ sourcePath: source, destinationPath: destination }], config });
    expect(result.added).toEqual([destination]);
    expect(await fs.readFile(first, "utf8")).toBe("new");
  });

  it("skips copy-owned files without force while updating existing config", async () => {
    await fs.outputFile(first, "owned");
    await fs.writeJson(path.join(cwd, "swiftcn.json"), { componentsPath: "Old" });
    const result = await service.apply({ cwd, files: requests(), config });
    expect(result).toEqual({ added: [second], replaced: [], skipped: [first] });
    expect(await fs.readFile(first, "utf8")).toBe("owned");
    expect(await fs.readJson(path.join(cwd, "swiftcn.json"))).toEqual(config);
  });

  it("backs up and replaces an existing source file with force", async () => {
    await fs.outputFile(first, "owned");
    const result = await service.apply({ cwd, files: requests(), config, force: true });
    expect(result.replaced).toEqual([first]);
    expect(await fs.readFile(first, "utf8")).toBe("new");
  });

  it("restores original files and config when a later installation fails", async () => {
    await fs.outputFile(first, "original");
    await fs.writeFile(path.join(cwd, "swiftcn.json"), "original config\n");
    const move = fs.move.bind(fs);
    vi.spyOn(fs, "move").mockImplementation(async (from, to, options) => {
      if (to === second) throw new Error("disk full");
      return move(from, to, options);
    });
    await expect(service.apply({ cwd, files: requests(), config, force: true })).rejects.toMatchObject({
      code: ErrorCode.INIT_TRANSACTION_FAILED, cause: expect.objectContaining({ message: "disk full" }),
    });
    expect(await fs.readFile(first, "utf8")).toBe("original");
    expect(await fs.pathExists(second)).toBe(false);
    expect(await fs.readFile(path.join(cwd, "swiftcn.json"), "utf8")).toBe("original config\n");
    expect(await fs.pathExists(transaction())).toBe(false);
  });

  it.each(["planned", "backup-created", "applied"] as const)("recovers completed moves with journal state %s", async (state) => {
    await interrupted(state);
    await service.recover(cwd);
    expect(await fs.readFile(first, "utf8")).toBe("original");
    expect(await fs.pathExists(second)).toBe(false);
    expect(await fs.pathExists(transaction())).toBe(false);
  });

  it("does not delete an unjournaled destination when its staged file still exists", async () => {
    const entries = await interrupted("planned");
    await fs.outputFile(entries[1].stagedPath, "new");
    await fs.outputFile(second, "user-owned");
    await service.recover(cwd);
    expect(await fs.readFile(second, "utf8")).toBe("user-owned");
  });

  it("rejects a live owner without changing its journal or files", async () => {
    await interrupted();
    const journal = await fs.readJson(journalPath());
    journal.ownerPid = process.pid;
    await fs.writeJson(journalPath(), journal);
    await expect(service.recover(cwd)).rejects.toMatchObject({ code: ErrorCode.INIT_ALREADY_RUNNING });
    expect(await fs.readFile(first, "utf8")).toBe("new");
    expect(await fs.readJson(journalPath())).toEqual(journal);
  });

  it("rejects concurrent applies rather than rolling back the other owner", async () => {
    const results = await Promise.allSettled([
      service.apply({ cwd, files: requests(), config }),
      new FileTransactionServiceImpl().apply({ cwd, files: requests(), config }),
    ]);
    expect(results.filter((result) => result.status === "fulfilled")).toHaveLength(1);
    expect(results.filter((result) => result.status === "rejected")[0]).toMatchObject({
      reason: { code: ErrorCode.INIT_ALREADY_RUNNING },
    });
    expect(await fs.readFile(first, "utf8")).toBe("new");
  });

  it.each(["outside", "reserved", "bootstrap", "config", "config ancestor", "duplicate", "missing source", "directory", "overlap"])("rejects %s requests before creating staging", async (kind) => {
    let files = requests();
    if (kind === "outside") files[0].destinationPath = path.join(root, "escaped.swift");
    if (kind === "reserved") files[0].destinationPath = path.join(transaction(), "evil.swift");
    if (kind === "bootstrap") files[0].destinationPath = path.join(cwd, ".swiftcn-transaction-bootstrap-owned", "evil.swift");
    if (kind === "config") files[0].destinationPath = path.join(cwd, "swiftcn.json");
    if (kind === "config ancestor") files[0].destinationPath = path.join(cwd, "swiftcn.json", "child.swift");
    if (kind === "duplicate") files[1].destinationPath = first;
    if (kind === "missing source") files[1].sourcePath = path.join(root, "missing");
    if (kind === "directory") await fs.ensureDir(first);
    if (kind === "overlap") files[1].destinationPath = path.join(first, "child");
    await expect(service.apply({ cwd, files, config })).rejects.toThrow();
    expect(await fs.pathExists(transaction())).toBe(false);
    expect(await fs.pathExists(path.join(cwd, "swiftcn.json"))).toBe(false);
  });

  it("rejects a symlink destination ancestor before creating staging", async () => {
    await fs.symlink(root, path.join(cwd, "Theme"));
    await expect(service.apply({ cwd, files: requests(), config })).rejects.toMatchObject({ code: ErrorCode.PATH_TRAVERSAL });
    expect(await fs.pathExists(transaction())).toBe(false);
    expect(await fs.pathExists(path.join(root, "First.swift"))).toBe(false);
  });

  it.each([
    ".SWIFTCN-TRANSACTION/Core/Theme.swift",
    ".SWIFTCN-TRANSACTION-BOOTSTRAP-owned/Theme.swift",
    "SWIFTCN.JSON",
    "SWIFTCN.JSON/Theme.swift",
  ])("rejects filesystem aliases of reserved path %s before staging", async (destination) => {
    await expect(service.apply({
      cwd, config,
      files: [{ sourcePath: source, destinationPath: path.join(cwd, destination) }],
    })).rejects.toMatchObject({ code: ErrorCode.INVALID_INPUT });
    expect(await fs.readdir(cwd)).toEqual([]);
  });

  it.each([
    ["Theme/First.swift", "theme/first.swift"],
    ["Theme/First.swift", "theme/FIRST.swift/Child.swift"],
    ["Theme/Caf\u00e9.swift", "Theme/Cafe\u0301.swift"],
  ])("rejects ambiguous destination aliases %s and %s before staging", async (left, right) => {
    await expect(service.apply({
      cwd, config,
      files: [left, right].map((destination) => ({ sourcePath: source, destinationPath: path.join(cwd, destination) })),
    })).rejects.toMatchObject({ code: ErrorCode.INVALID_INPUT });
    expect(await fs.readdir(cwd)).toEqual([]);
  });

  it.each(["destination", "stage", "backup", "duplicate", "owner", "version"])("rejects an invalid %s journal without mutating destinations", async (kind) => {
    await interrupted();
    const journal = await fs.readJson(journalPath());
    if (kind === "destination") journal.entries[0].destinationPath = path.join(root, "outside");
    if (kind === "stage") journal.entries[0].stagedPath = source;
    if (kind === "backup") journal.entries[0].backupPath = source;
    if (kind === "duplicate") journal.entries[1].destinationPath = first;
    if (kind === "owner") journal.ownerPid = -1;
    if (kind === "version") journal.version = 2;
    await fs.writeJson(journalPath(), journal);
    await expect(service.recover(cwd)).rejects.toThrow();
    expect(await fs.readFile(first, "utf8")).toBe("new");
    expect(await fs.readFile(source, "utf8")).toBe("new");
    expect(await fs.pathExists(journalPath())).toBe(true);
  });

  it("preserves a journal when rollback fails and permits a later recovery", async () => {
    await interrupted();
    const rename = fs.rename.bind(fs);
    vi.spyOn(fs, "rename").mockImplementation(async (from, to) => {
      if (to === first) throw new Error("restore blocked");
      return rename(from, to);
    });
    await expect(service.recover(cwd)).rejects.toMatchObject({ code: ErrorCode.INIT_TRANSACTION_FAILED });
    expect(await fs.pathExists(journalPath())).toBe(true);
    expect(await fs.readFile(path.join(transaction(), "backup", "0"), "utf8")).toBe("original");
    vi.restoreAllMocks();
    await service.recover(cwd);
    expect(await fs.readFile(first, "utf8")).toBe("original");
    expect(await fs.pathExists(second)).toBe(false);
  });

  it("keeps the previous config readable until the final atomic rename", async () => {
    const configPath = path.join(cwd, "swiftcn.json");
    await fs.writeFile(configPath, "old config");
    const rename = fs.rename.bind(fs);
    let observed = false;
    vi.spyOn(fs, "rename").mockImplementation(async (from, to) => {
      if (to === configPath) {
        observed = true;
        expect(await fs.readFile(configPath, "utf8")).toBe("old config");
        expect(await fs.readFile(first, "utf8")).toBe("new");
        expect(await fs.readFile(second, "utf8")).toBe("new");
      }
      return rename(from, to);
    });
    await service.apply({ cwd, files: requests(), config });
    expect(observed).toBe(true);
    expect(await fs.readJson(configPath)).toEqual(config);
  });

  it("rolls back all sources when the final config rename fails", async () => {
    await fs.outputFile(first, "original");
    const configPath = path.join(cwd, "swiftcn.json");
    await fs.writeFile(configPath, "old config");
    const rename = fs.rename.bind(fs);
    vi.spyOn(fs, "rename").mockImplementation(async (from, to) => {
      if (to === configPath && String(from).includes(`${path.sep}stage${path.sep}`)) throw new Error("config blocked");
      return rename(from, to);
    });
    await expect(service.apply({ cwd, files: requests(), config, force: true })).rejects.toMatchObject({ code: ErrorCode.INIT_TRANSACTION_FAILED });
    expect(await fs.readFile(first, "utf8")).toBe("original");
    expect(await fs.pathExists(second)).toBe(false);
    expect(await fs.readFile(configPath, "utf8")).toBe("old config");
  });

  it("does not restore a partial config backup when copying its backup fails", async () => {
    const configPath = path.join(cwd, "swiftcn.json");
    await fs.writeFile(configPath, "old config");
    const copy = fs.copy.bind(fs);
    vi.spyOn(fs, "copy").mockImplementation(async (from, to, options) => {
      if (from === configPath) {
        await fs.outputFile(to, "partial");
        throw new Error("backup disk full");
      }
      return copy(from, to, options);
    });
    await expect(service.apply({ cwd, files: requests(), config })).rejects.toThrow("backup disk full");
    expect(await fs.readFile(configPath, "utf8")).toBe("old config");
    expect(await fs.pathExists(first)).toBe(false);
  });

  it("recovers a failed rollback from apply while the process is still alive", async () => {
    await fs.outputFile(first, "original");
    const move = fs.move.bind(fs);
    const rename = fs.rename.bind(fs);
    vi.spyOn(fs, "move").mockImplementation(async (from, to, options) => {
      if (to === second) throw new Error("install blocked");
      return move(from, to, options);
    });
    vi.spyOn(fs, "rename").mockImplementation(async (from, to) => {
      if (String(from).includes(`${path.sep}backup${path.sep}`) && to === first) throw new Error("restore blocked");
      return rename(from, to);
    });
    await expect(service.apply({ cwd, files: requests(), config, force: true })).rejects.toThrow("rollback failed: restore blocked");
    expect(await fs.pathExists(journalPath())).toBe(true);
    vi.restoreAllMocks();
    await service.recover(cwd);
    expect(await fs.readFile(first, "utf8")).toBe("original");
    expect(await fs.pathExists(second)).toBe(false);
  });

  it("cleans a committed stale journal without reverting completed files", async () => {
    await interrupted();
    const journal = await fs.readJson(journalPath());
    journal.state = "committed";
    await fs.writeJson(journalPath(), journal);
    await service.recover(cwd);
    expect(await fs.readFile(first, "utf8")).toBe("new");
    expect(await fs.readFile(second, "utf8")).toBe("new");
    expect(await fs.pathExists(transaction())).toBe(false);
  });

  it("recovers again after a previous recovery process dies", async () => {
    await interrupted();
    await fs.symlink(String(deadPid), path.join(transaction(), "recovery-owner-0"));
    await service.recover(cwd);
    expect(await fs.readFile(first, "utf8")).toBe("original");
    expect(await fs.pathExists(second)).toBe(false);
  });

  it("refuses recovery while another recovery process owns the journal", async () => {
    await interrupted();
    await fs.symlink(String(process.pid), path.join(transaction(), "recovery-owner-0"));
    await expect(service.recover(cwd)).rejects.toMatchObject({ code: ErrorCode.INIT_ALREADY_RUNNING });
    expect(await fs.readFile(first, "utf8")).toBe("new");
  });

  it.each(["transaction", "stage", "backup", "destination", "journal"])("rejects a %s symlink during recovery", async (kind) => {
    await interrupted();
    const symlinkPath = kind === "transaction" ? transaction() : kind === "stage" || kind === "backup" ? path.join(transaction(), kind) : kind === "destination" ? first : journalPath();
    await fs.remove(symlinkPath);
    await fs.symlink(kind === "destination" || kind === "journal" ? source : root, symlinkPath);
    await expect(service.recover(cwd)).rejects.toMatchObject({ code: ErrorCode.PATH_TRAVERSAL });
    expect(await fs.readFile(source, "utf8")).toBe("new");
  });

  it("never recovers a new transaction that replaced the stale directory before ownership was claimed", async () => {
    await interrupted();
    const symlink = fs.symlink.bind(fs);
    vi.spyOn(fs, "symlink").mockImplementation(async (target, link, type) => {
      if (String(link).endsWith("recovery-owner-0")) {
        await fs.remove(transaction());
        await interrupted();
        const journal = await fs.readJson(journalPath());
        journal.ownerPid = process.pid;
        await fs.writeJson(journalPath(), journal);
        await fs.outputFile(first, "active owner's file");
      }
      return symlink(target, link, type);
    });
    await expect(service.recover(cwd)).rejects.toMatchObject({ code: ErrorCode.INIT_ALREADY_RUNNING });
    expect(await fs.readFile(first, "utf8")).toBe("active owner's file");
    expect(await fs.pathExists(journalPath())).toBe(true);
  });

  it("preserves the applying journal if recording the commit and rollback both fail", async () => {
    await fs.outputFile(first, "original");
    const rename = fs.rename.bind(fs);
    vi.spyOn(fs, "rename").mockImplementation(async (from, to) => {
      if (to === journalPath() && (await fs.readJson(String(from))).state === "committed") throw new Error("commit blocked");
      if (String(from).includes(`${path.sep}backup${path.sep}`) && to === first) throw new Error("restore blocked");
      return rename(from, to);
    });
    await expect(service.apply({ cwd, files: requests(), config, force: true })).rejects.toThrow("commit blocked");
    expect((await fs.readJson(journalPath())).state).toBe("applying");
    vi.restoreAllMocks();
    await service.recover(cwd);
    expect(await fs.readFile(first, "utf8")).toBe("original");
    expect(await fs.pathExists(second)).toBe(false);
    expect(await fs.pathExists(path.join(cwd, "swiftcn.json"))).toBe(false);
  });

  it("permits cleanup recovery after a committed transaction's cleanup fails", async () => {
    const remove = fs.remove.bind(fs);
    vi.spyOn(fs, "remove").mockImplementation(async (file) => {
      if (file === path.join(transaction(), "stage")) throw new Error("cleanup blocked");
      return remove(file);
    });
    await expect(service.apply({ cwd, files: requests(), config })).rejects.toThrow("cleanup blocked");
    expect(await fs.readFile(first, "utf8")).toBe("new");
    vi.restoreAllMocks();
    await service.recover(cwd);
    expect(await fs.readFile(first, "utf8")).toBe("new");
    expect(await fs.pathExists(transaction())).toBe(false);
  });

  it.each([false, true])("cleans a dead bootstrap owner before publication (journal=%s)", async (hasJournal) => {
    const bootstrap = path.join(cwd, `.swiftcn-transaction-bootstrap-${deadPid}-00000000-0000-4000-8000-000000000000`);
    await fs.ensureDir(bootstrap);
    if (hasJournal) await fs.writeJson(path.join(bootstrap, "journal.json"), { version: 1, ownerPid: deadPid, state: "staging", entries: [] });
    await fs.outputFile(first, "owned");
    await service.recover(cwd);
    expect(await fs.pathExists(bootstrap)).toBe(false);
    expect(await fs.readFile(first, "utf8")).toBe("owned");
  });

  it("refuses a live bootstrap owner even before its journal exists", async () => {
    const bootstrap = path.join(cwd, `.swiftcn-transaction-bootstrap-${process.pid}-00000000-0000-4000-8000-000000000000`);
    await fs.ensureDir(bootstrap);
    await expect(service.recover(cwd)).rejects.toMatchObject({ code: ErrorCode.INIT_ALREADY_RUNNING });
    expect(await fs.pathExists(bootstrap)).toBe(true);
  });

  it("publishes the transaction directory with its staging journal already present", async () => {
    const rename = fs.rename.bind(fs);
    let observed = false;
    vi.spyOn(fs, "rename").mockImplementation(async (from, to) => {
      if (to === transaction()) {
        observed = true;
        expect(await fs.readJson(path.join(String(from), "journal.json"))).toMatchObject({ ownerPid: process.pid, state: "staging" });
        expect(await fs.pathExists(first)).toBe(false);
      }
      return rename(from, to);
    });
    await service.apply({ cwd, files: requests(), config });
    expect(observed).toBe(true);
  });

  it("discards interrupted staging without changing existing destinations", async () => {
    await interrupted();
    const journal = await fs.readJson(journalPath());
    journal.state = "staging";
    journal.entries.forEach((entry: { state: string }) => { entry.state = "planned"; });
    await fs.remove(path.join(transaction(), "backup"));
    await fs.writeJson(journalPath(), journal);
    await service.recover(cwd);
    expect(await fs.readFile(first, "utf8")).toBe("new");
    expect(await fs.readFile(second, "utf8")).toBe("new");
    expect(await fs.pathExists(transaction())).toBe(false);
  });

  it("recovers an empty directory left after journal-last cleanup", async () => {
    await fs.ensureDir(transaction());
    await fs.outputFile(first, "owned");
    await service.recover(cwd);
    expect(await fs.pathExists(transaction())).toBe(false);
    expect(await fs.readFile(first, "utf8")).toBe("owned");
  });

  it("cleans files before deleting the journal", async () => {
    const unlink = fs.unlink.bind(fs);
    let observed = false;
    vi.spyOn(fs, "unlink").mockImplementation(async (file) => {
      if (file === journalPath()) {
        observed = true;
        expect(await fs.readdir(transaction())).toEqual(["journal.json"]);
      }
      return unlink(file);
    });
    await service.apply({ cwd, files: requests(), config });
    expect(observed).toBe(true);
  });

  it("releases failed apply ownership even when a move's journal update failed", async () => {
    await fs.outputFile(first, "original");
    const rename = fs.rename.bind(fs);
    let journalFailed = false;
    vi.spyOn(fs, "rename").mockImplementation(async (from, to) => {
      if (to === journalPath() && !journalFailed && (await fs.readJson(String(from))).entries.some((entry: { state: string }) => entry.state === "backup-created")) {
        journalFailed = true;
        throw new Error("journal blocked");
      }
      if (String(from).includes(`${path.sep}backup${path.sep}`) && to === first) throw new Error("restore blocked");
      return rename(from, to);
    });
    await expect(service.apply({ cwd, files: requests(), config, force: true })).rejects.toThrow("journal blocked");
    vi.restoreAllMocks();
    await service.recover(cwd);
    expect(await fs.readFile(first, "utf8")).toBe("original");
  });

  it("rejects a staged symlink before installing it", async () => {
    const copy = fs.copy.bind(fs);
    vi.spyOn(fs, "copy").mockImplementation(async (from, to, options) => {
      if (from === source) return fs.symlink(source, to);
      return copy(from, to, options);
    });
    await expect(service.apply({ cwd, files: requests(), config })).rejects.toThrow();
    expect(await fs.pathExists(first)).toBe(false);
    expect(await fs.pathExists(path.join(cwd, "swiftcn.json"))).toBe(false);
  });

  it("preserves symlink targets while removing an abandoned bootstrap", async () => {
    const bootstrap = path.join(cwd, `.swiftcn-transaction-bootstrap-${deadPid}-00000000-0000-4000-8000-000000000000`);
    await fs.ensureDir(bootstrap);
    await fs.symlink(root, path.join(bootstrap, "outside"));
    await service.recover(cwd);
    expect(await fs.pathExists(bootstrap)).toBe(false);
    expect(await fs.readFile(source, "utf8")).toBe("new");
  });
});
