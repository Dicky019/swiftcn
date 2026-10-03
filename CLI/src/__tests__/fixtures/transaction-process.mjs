// Real child-process fixture; pause filesystem boundaries without replacing results.
import fs from "fs-extra";
import path from "node:path";
import { pathToFileURL } from "node:url";

const [servicePath, mode, cwd, source] = process.argv.slice(2);
const { FileTransactionServiceImpl } = await import(pathToFileURL(servicePath).href);
const pause = async () => {
  const continued = new Promise((resolve) => process.once("message", resolve));
  process.send({ type: "paused" });
  await continued;
};

if (mode === "recover") {
  const unlink = fs.unlink.bind(fs);
  fs.unlink = async (file) => {
    if (String(file).endsWith("/journal.json")) await pause();
    return unlink(file);
  };
} else {
  const move = fs.move.bind(fs);
  fs.move = async (from, to, options) => {
    const result = await move(from, to, options);
    if (String(to).endsWith("/backup/0")) await pause();
    return result;
  };
}

try {
  const service = new FileTransactionServiceImpl();
  if (mode === "recover") await service.recover(cwd);
  else await service.apply({
    cwd, force: true,
    config: { componentsPath: "Components", themePath: "Theme" },
    files: [{ sourcePath: source, destinationPath: path.join(cwd, "Theme", "Owned.swift") }],
  });
  process.send({ type: "done" });
} catch (error) {
  process.send({ type: "error", code: error.code, message: error.message });
}
process.disconnect();
