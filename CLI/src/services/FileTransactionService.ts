import fs from "fs-extra";
import path from "node:path";
import { randomUUID } from "node:crypto";
import { z } from "zod";
import { projectConfigSchema, type ProjectConfig } from "../types/config.schema.js";
import { CONFIG_FILE_NAME } from "../utils/constants.js";
import { ErrorCode, SwiftCNError } from "../utils/errors.js";

export interface InitFileRequest {
  sourcePath: string;
  destinationPath: string;
}

export interface InitTransactionInput {
  cwd: string;
  files: InitFileRequest[];
  config: ProjectConfig;
  force?: boolean;
}

export interface InitTransactionResult {
  added: string[];
  replaced: string[];
  skipped: string[];
}

export interface FileTransactionService {
  recover(cwd: string): Promise<void>;
  apply(input: InitTransactionInput): Promise<InitTransactionResult>;
}

const TRANSACTION_DIRECTORY = ".swiftcn-transaction";
const BOOTSTRAP_PREFIX = `${TRANSACTION_DIRECTORY}-bootstrap-`;
const bootstrapPattern = /^\.swiftcn-transaction-bootstrap-([1-9]\d*)-([\da-f]{8}-[\da-f]{4}-4[\da-f]{3}-[89ab][\da-f]{3}-[\da-f]{12})$/;
const journalSchema = z.object({
  version: z.literal(1),
  ownerPid: z.number().int().min(0).max(2147483647),
  state: z.enum(["staging", "applying", "committed"]),
  entries: z.array(z.object({
    destinationPath: z.string(),
    stagedPath: z.string(),
    backupPath: z.string().optional(),
    action: z.enum(["create", "replace", "skip"]),
    state: z.enum(["planned", "backup-created", "applied"]),
  }).strict()),
}).strict();
type TransactionJournal = z.infer<typeof journalSchema>;
type JournalEntry = TransactionJournal["entries"][number];

// Also excludes overlapping operations by different service instances in this process.
const activeProjects = new Set<string>();

export class FileTransactionServiceImpl implements FileTransactionService {
  async recover(cwd: string): Promise<void> {
    const root = await fs.realpath(cwd);
    await this.exclusive(root, () => this.recoverJournal(root));
  }

  async apply(input: InitTransactionInput): Promise<InitTransactionResult> {
    const root = await fs.realpath(input.cwd);
    return this.exclusive(root, async () => {
      await this.recoverJournal(root);
      const config = projectConfigSchema.parse(input.config);
      const configPath = path.join(root, CONFIG_FILE_NAME);
      const files = input.files.map((file) => ({
        ...file,
        destinationPath: path.resolve(root, path.relative(path.resolve(input.cwd), path.resolve(input.cwd, file.destinationPath))),
      }));
      this.validateDestinations(root, files.map((file) => file.destinationPath), false);
      this.validateDestinations(root, [...files.map((file) => file.destinationPath), configPath], true);
      for (const file of files) {
        await this.validateFilePath(root, file.destinationPath);
        const source = await fs.lstat(file.sourcePath);
        if (!source.isFile()) throw new SwiftCNError(`Source must be a regular file: ${file.sourcePath}`, ErrorCode.INVALID_INPUT);
      }
      await this.validateFilePath(root, configPath);
      const directory = this.directory(root);
      const entries: JournalEntry[] = [];
      for (const [index, file] of [...files, { sourcePath: "", destinationPath: configPath }].entries()) {
        const exists = await fs.pathExists(file.destinationPath);
        const action = exists ? (input.force || file.destinationPath === configPath ? "replace" : "skip") : "create";
        entries.push({
          destinationPath: file.destinationPath,
          stagedPath: path.join(directory, "stage", String(index)),
          ...(action === "replace" ? { backupPath: path.join(directory, "backup", String(index)) } : {}),
          action,
          state: "planned",
        });
      }
      const journal: TransactionJournal = { version: 1, ownerPid: process.pid, state: "staging", entries };
      const bootstrap = path.join(root, `${BOOTSTRAP_PREFIX}${process.pid}-${randomUUID()}`);
      // Publish a fully seeded, nonempty directory atomically. A crash before
      // publication leaves only a bootstrap with its immutable owner in its name.
      // rename cannot replace another owner's nonempty transaction directory.
      try {
        await fs.mkdir(bootstrap);
        await this.writeAtomic(path.join(bootstrap, "journal.json"), journal);
        await fs.rename(bootstrap, directory);
      } catch (error) {
        await fs.remove(bootstrap).catch(() => {});
        if (this.hasCode(error, "EEXIST") || this.hasCode(error, "ENOTEMPTY")) throw this.running();
        throw this.failed(error);
      }
      try {
        await fs.ensureDir(path.join(directory, "stage"));
        await fs.ensureDir(path.join(directory, "backup"));
        for (const [index, file] of files.entries()) {
          if (entries[index].action !== "skip") await fs.copy(file.sourcePath, entries[index].stagedPath, { dereference: false });
        }
        await this.writeAtomic(entries[entries.length - 1].stagedPath, config);
        for (const entry of entries) {
          if (entry.action !== "skip") await this.validateFilePath(root, entry.stagedPath);
        }
        journal.state = "applying";
        await this.writeJournal(root, journal);
        for (const entry of entries) {
          if (entry.action === "skip") continue;
          await this.validateFilePath(root, entry.destinationPath);
          await this.validateFilePath(root, entry.stagedPath);
          if (entry.backupPath) {
            // Preserve the old config at its final path until the atomic replacement.
            if (entry.destinationPath === configPath) {
              const temporary = `${entry.backupPath}.${randomUUID()}.tmp`;
              await fs.copy(entry.destinationPath, temporary, { overwrite: false, errorOnExist: true });
              await fs.rename(temporary, entry.backupPath);
            }
            else await fs.move(entry.destinationPath, entry.backupPath, { overwrite: false });
            entry.state = "backup-created";
            await this.writeJournal(root, journal);
          }
          await fs.ensureDir(path.dirname(entry.destinationPath));
          if (entry.destinationPath === configPath) await fs.rename(entry.stagedPath, entry.destinationPath);
          else await fs.move(entry.stagedPath, entry.destinationPath, { overwrite: false });
          entry.state = "applied";
          await this.writeJournal(root, journal);
        }
        journal.state = "committed";
        await this.writeJournal(root, journal);
      } catch (error) {
        if (journal.state === "committed") journal.state = "applying";
        try {
          if (journal.state !== "staging") {
            await this.rollback(root, entries);
            journal.state = "staging";
            await this.writeJournal(root, journal);
          }
          await this.cleanup(root);
        } catch (rollbackError) {
          // A failed rollback is still recoverable in this process after the fault is fixed.
          journal.ownerPid = 0;
          await this.releaseOwner(root, journal);
          throw this.failed(error, rollbackError);
        }
        throw this.failed(error);
      }
      // Once committed, cleanup failures must never undo successfully installed files.
      try {
        await this.cleanup(root);
      } catch (error) {
        journal.ownerPid = 0;
        await this.releaseOwner(root, journal);
        throw this.failed(error);
      }
      return {
        added: entries.filter((entry) => entry.destinationPath !== configPath && entry.action === "create").map((entry) => path.resolve(input.cwd, path.relative(root, entry.destinationPath))),
        replaced: entries.filter((entry) => entry.destinationPath !== configPath && entry.action === "replace").map((entry) => path.resolve(input.cwd, path.relative(root, entry.destinationPath))),
        skipped: entries.filter((entry) => entry.action === "skip").map((entry) => path.resolve(input.cwd, path.relative(root, entry.destinationPath))),
      };
    });
  }

  private async exclusive<T>(root: string, operation: () => Promise<T>): Promise<T> {
    if (activeProjects.has(root)) throw this.running();
    activeProjects.add(root);
    try { return await operation(); } finally { activeProjects.delete(root); }
  }

  private directory(root: string): string {
    return path.join(root, TRANSACTION_DIRECTORY);
  }

  private async recoverJournal(root: string): Promise<void> {
    // Bootstrap contents have never been published or applied to destinations.
    for (const name of await fs.readdir(root)) {
      const match = bootstrapPattern.exec(name);
      if (!match) continue;
      const pid = Number(match[1]);
      if (!Number.isSafeInteger(pid) || pid > 2147483647) throw this.failed(new Error("Invalid bootstrap owner"));
      const bootstrap = path.join(root, name);
      const bootstrapStat = await this.stat(bootstrap);
      if (!bootstrapStat) continue;
      if (!bootstrapStat.isDirectory() || bootstrapStat.isSymbolicLink()) throw new SwiftCNError(`Unsafe bootstrap: ${bootstrap}`, ErrorCode.PATH_TRAVERSAL);
      if (this.isAlive(pid)) throw this.running();
      try { await fs.remove(bootstrap); } catch (error) { throw this.failed(error); }
    }
    const directory = this.directory(root);
    const stat = await this.stat(directory);
    if (!stat) return;
    if (!stat.isDirectory() || stat.isSymbolicLink()) throw new SwiftCNError(`Unsafe transaction directory: ${directory}`, ErrorCode.PATH_TRAVERSAL);
    if ((await fs.readdir(directory)).length === 0) {
      // Publication is always nonempty. Only journal-last cleanup leaves this
      // state, and rmdir cannot remove a concurrently published nonempty owner.
      try { await fs.rmdir(directory); } catch (error) {
        if (!this.hasCode(error, "ENOENT")) throw this.failed(error);
      }
      return;
    }
    const journalPath = path.join(directory, "journal.json");
    await this.validateFilePath(root, journalPath);
    let journal: TransactionJournal;
    try {
      journal = journalSchema.parse(await fs.readJson(journalPath));
      this.validateDestinations(root, journal.entries.map((entry) => entry.destinationPath), true);
      const reserved = new Set<string>();
      for (const entry of journal.entries) {
        if (path.dirname(entry.stagedPath) !== path.join(directory, "stage") || reserved.has(entry.stagedPath)) throw new Error("Invalid or duplicate staged path");
        reserved.add(entry.stagedPath);
        if ((entry.action === "replace") !== Boolean(entry.backupPath)) throw new Error("Invalid backup action");
        if (entry.backupPath && (path.dirname(entry.backupPath) !== path.join(directory, "backup") || reserved.has(entry.backupPath))) throw new Error("Invalid or duplicate backup path");
        if (entry.backupPath) reserved.add(entry.backupPath);
        if (entry.action !== "replace" && entry.state === "backup-created") throw new Error("Invalid mutation state");
        await this.validateFilePath(root, entry.destinationPath);
        await this.validateFilePath(root, entry.stagedPath);
        if (entry.backupPath) await this.validateFilePath(root, entry.backupPath);
      }
      const configIndex = journal.entries.findIndex((entry) => entry.destinationPath === path.join(root, CONFIG_FILE_NAME));
      if (configIndex >= 0 && (configIndex !== journal.entries.length - 1 || journal.entries[configIndex].action === "skip")) throw new Error("Config must be the final mutation");
    } catch (error) {
      if (error instanceof SwiftCNError) throw error;
      throw this.failed(error);
    }
    if (this.isAlive(journal.ownerPid)) throw this.running();
    const claim = await this.claimRecovery(directory);
    let ownsJournal = false;
    try {
      // Another recovery can finish and a new init can claim the same pathname
      // between our initial read and the atomic ownership claim.
      const claimedDirectory = await fs.lstat(directory);
      const claimedJournal = journalSchema.parse(await fs.readJson(journalPath));
      if (claimedDirectory.ino !== stat.ino || claimedDirectory.dev !== stat.dev || JSON.stringify(claimedJournal) !== JSON.stringify(journal)) throw this.running();
      // Cleanup removes recovery claims before the journal. Keep a live owner
      // in the journal until its unlink, so a second recovery cannot enter.
      ownsJournal = true;
      journal.ownerPid = process.pid;
      await this.writeJournal(root, journal);
      if (journal.state === "applying") {
        await this.rollback(root, journal.entries);
        journal.state = "staging";
        await this.writeJournal(root, journal);
      }
      await this.cleanup(root);
    } catch (error) {
      if (ownsJournal) {
        journal.ownerPid = 0;
        await this.releaseOwner(root, journal);
      }
      await fs.unlink(claim).catch(() => {});
      if (error instanceof SwiftCNError && error.code === ErrorCode.INIT_ALREADY_RUNNING) throw error;
      throw this.failed(error);
    }
  }

  private async claimRecovery(directory: string): Promise<string> {
    // Each dead recovery owner gets a new slot. Never unlink a stale claim:
    // that would allow two processes to race while replacing each other's lock.
    for (let slot = 0; ; slot++) {
      const claim = path.join(directory, `recovery-owner-${slot}`);
      try {
        await fs.symlink(String(process.pid), claim);
        return claim;
      } catch (error) {
        if (!this.hasCode(error, "EEXIST")) throw this.failed(error);
        const owner = await fs.readlink(claim);
        if (!/^\d+$/.test(owner) || !Number.isSafeInteger(Number(owner)) || Number(owner) > 2147483647) throw this.failed(new Error("Invalid recovery owner"));
        if (this.isAlive(Number(owner))) throw this.running();
      }
    }
  }

  private async rollback(root: string, entries: JournalEntry[]): Promise<void> {
    for (const entry of [...entries].reverse()) {
      if (entry.action === "skip") continue;
      await this.validateFilePath(root, entry.destinationPath);
      await this.validateFilePath(root, entry.stagedPath);
      if (entry.backupPath) {
        await this.validateFilePath(root, entry.backupPath);
        if (await fs.pathExists(entry.backupPath)) {
          await fs.ensureDir(path.dirname(entry.destinationPath));
          await fs.rename(entry.backupPath, entry.destinationPath);
        }
      } else if (!await fs.pathExists(entry.stagedPath) && await fs.pathExists(entry.destinationPath)) {
        // Move it back to staging instead of deleting. This records completion on
        // disk even if recovery itself dies before another journal update.
        await fs.ensureDir(path.dirname(entry.stagedPath));
        await fs.rename(entry.destinationPath, entry.stagedPath);
      }
    }
  }

  private validateDestinations(root: string, destinations: string[], allowConfig: boolean): void {
    const seen = new Set<string>();
    // Reject ambiguous aliases on every filesystem, including case-sensitive
    // hosts, so a plan cannot collide when used on macOS's default filesystem.
    const identity = (value: string) => value.normalize("NFD").toLowerCase();
    for (const destination of destinations) {
      const relative = path.relative(root, destination);
      if (!path.isAbsolute(destination) || destination !== path.normalize(destination) || !relative || relative === ".." || relative.startsWith(`..${path.sep}`) || path.isAbsolute(relative)) {
        throw new SwiftCNError(`Destination escapes project: ${destination}`, ErrorCode.PATH_TRAVERSAL);
      }
      const relativeIdentity = identity(relative);
      const firstPart = relativeIdentity.split(path.sep)[0];
      if (firstPart === TRANSACTION_DIRECTORY || firstPart.startsWith(BOOTSTRAP_PREFIX) || (!allowConfig && relativeIdentity === CONFIG_FILE_NAME)) throw new SwiftCNError(`Reserved destination: ${destination}`, ErrorCode.INVALID_INPUT);
      if (seen.has(identity(destination))) throw new SwiftCNError(`Duplicate destination: ${destination}`, ErrorCode.INVALID_INPUT);
      seen.add(identity(destination));
    }
    for (const destination of destinations) {
      let ancestor = path.dirname(destination);
      while (ancestor !== root) {
        if (seen.has(identity(ancestor))) throw new SwiftCNError(`Overlapping destination: ${destination}`, ErrorCode.INVALID_INPUT);
        ancestor = path.dirname(ancestor);
      }
    }
  }

  private async validateFilePath(root: string, file: string): Promise<void> {
    let current = root;
    const parts = path.relative(root, file).split(path.sep);
    for (const [index, part] of parts.entries()) {
      current = path.join(current, part);
      const stat = await this.stat(current);
      if (!stat) continue;
      if (stat.isSymbolicLink()) throw new SwiftCNError(`Symlink path is not allowed: ${current}`, ErrorCode.PATH_TRAVERSAL);
      if (index === parts.length - 1 ? !stat.isFile() : !stat.isDirectory()) throw new SwiftCNError(`Expected ${index === parts.length - 1 ? "file" : "directory"}: ${current}`, ErrorCode.INVALID_INPUT);
    }
  }

  private async stat(file: string) {
    try { return await fs.lstat(file); } catch (error) {
      if (this.hasCode(error, "ENOENT")) return undefined;
      throw error;
    }
  }

  private async writeJournal(root: string, journal: TransactionJournal): Promise<void> {
    await this.writeAtomic(path.join(this.directory(root), "journal.json"), journal);
  }

  private async cleanup(root: string): Promise<void> {
    const directory = this.directory(root);
    for (const name of await fs.readdir(directory)) {
      if (name !== "journal.json") await fs.remove(path.join(directory, name));
    }
    await fs.unlink(path.join(directory, "journal.json"));
    await fs.rmdir(directory);
  }

  private async releaseOwner(root: string, journal: TransactionJournal): Promise<void> {
    try {
      const current = journalSchema.parse(await fs.readJson(path.join(this.directory(root), "journal.json")));
      const identities = (entries: JournalEntry[]) => entries.map(({ state: _state, ...entry }) => entry);
      if (current.ownerPid === process.pid && JSON.stringify(identities(current.entries)) === JSON.stringify(identities(journal.entries))) await this.writeJournal(root, journal);
    } catch { /* Preserve the last durable journal, or the safely empty cleanup directory. */ }
  }

  private async writeAtomic(file: string, value: unknown): Promise<void> {
    const temporary = `${file}.${randomUUID()}.tmp`;
    await fs.writeFile(temporary, JSON.stringify(value, null, 2) + "\n", { flag: "wx" });
    await fs.rename(temporary, file);
  }

  private isAlive(pid: number): boolean {
    if (pid === 0) return false;
    try { process.kill(pid, 0); return true; } catch (error) {
      return !this.hasCode(error, "ESRCH");
    }
  }

  private hasCode(error: unknown, code: string): boolean {
    return error instanceof Error && "code" in error && error.code === code;
  }

  private running(): SwiftCNError {
    return new SwiftCNError("Another init transaction is already running", ErrorCode.INIT_ALREADY_RUNNING);
  }

  private failed(error: unknown, rollbackError?: unknown): SwiftCNError {
    const message = error instanceof Error ? error.message : String(error);
    const rollbackMessage = rollbackError instanceof Error ? rollbackError.message : String(rollbackError);
    const failure = new SwiftCNError(`Init transaction failed: ${message}${rollbackError ? `; rollback failed: ${rollbackMessage}` : ""}`, ErrorCode.INIT_TRANSACTION_FAILED);
    failure.cause = error;
    return failure;
  }
}
