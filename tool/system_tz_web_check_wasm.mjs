// Runs a dart2wasm build of tool/system_tz_web_check.dart in node:
//
//   dart compile wasm tool/system_tz_web_check.dart -o check.wasm
//   node tool/system_tz_web_check_wasm.mjs check.wasm
//
// (dart compile wasm writes check.mjs, the JS loader, next to check.wasm.)
import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const wasmPath = resolve(process.argv[2] ?? 'check.wasm');
const loader = await import(
  pathToFileURL(wasmPath.replace(/\.wasm$/, '.mjs')).href
);
const app = await loader.compile(await readFile(wasmPath));
const instance = await app.instantiate({});
instance.invokeMain();
