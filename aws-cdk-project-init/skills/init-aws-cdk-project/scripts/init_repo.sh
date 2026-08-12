#!/usr/bin/env bash
set -euo pipefail

repo="zipon/Traceability#v1.0.4"

# Copy template into CURRENT directory (must be empty unless you add --force)
npx --yes degit "$repo" .

PROJECT_DIR_NAME="$(basename "$PWD")"

# ---- Convert folder name -> kebab-case for TS filenames (CDK convention) ----
# CoolStuff -> cool-stuff
# cool_stuff -> cool-stuff
# cool stuff -> cool-stuff
KEBAB_NAME="$(
  printf '%s' "$PROJECT_DIR_NAME" \
  | sed -E 's/[_[:space:]]+/-/g' \
  | sed -E 's/([a-z0-9])([A-Z])/\1-\2/g' \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9-]+/-/g' \
  | sed -E 's/^-+|-+$//g' \
  | sed -E 's/-+/-/g'
)"

# kebab -> PascalCase for class name: cool-stuff -> CoolStuff
PASCAL_NAME="$(
  printf '%s' "$KEBAB_NAME" \
  | awk -F'-' '{ for (i=1; i<=NF; i++) { $i=toupper(substr($i,1,1)) substr($i,2) } }1' \
  | tr -d ' '
)"
STACK_CLASS="${PASCAL_NAME}Stack"

export PROJECT_DIR_NAME KEBAB_NAME PASCAL_NAME STACK_CLASS

echo "Project folder: $PROJECT_DIR_NAME"
echo "File base:      $KEBAB_NAME"
echo "Stack class:    $STACK_CLASS"

# ---- Rename template files to project-specific CDK-style names ----
if [[ ! -f "bin/traceability.ts" ]]; then
  echo "ERROR: expected bin/traceability.ts (template changed?)"
  exit 1
fi
if [[ ! -f "lib/traceability-stack.ts" ]]; then
  echo "ERROR: expected lib/traceability-stack.ts (template changed?)"
  exit 1
fi

mv "bin/traceability.ts" "bin/${KEBAB_NAME}.ts"
mv "lib/traceability-stack.ts" "lib/${KEBAB_NAME}-stack.ts"
if [[ -f "test/traceability.test.ts" ]]; then
  mv "test/traceability.test.ts" "test/${KEBAB_NAME}.test.ts"
fi

# (Optional) Remove the extra demo stack so the result matches cdk init (single stack)
rm -f "lib/PinkFluffyUnicornsDancingOnRainbows-stack.ts" || true

# ---- Patch generated project robustly using Node ----
node - <<'NODE'
const fs = require("fs");
const path = require("path");

const projectDirName = process.env.PROJECT_DIR_NAME;
const kebab = process.env.KEBAB_NAME;
const pascal = process.env.PASCAL_NAME;
const stackClass = process.env.STACK_CLASS;

const binPath = `bin/${kebab}.ts`;
const libPath = `lib/${kebab}-stack.ts`;
const testPath = `test/${kebab}.test.ts`;

const skipDirs = new Set([".git", "node_modules", "cdk.out"]);

function walk(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  const files = [];

  for (const entry of entries) {
    if (skipDirs.has(entry.name)) {
      continue;
    }

    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...walk(fullPath));
    } else if (entry.isFile()) {
      files.push(fullPath);
    }
  }

  return files;
}

function walkPaths(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  const paths = [];

  for (const entry of entries) {
    if (skipDirs.has(entry.name)) {
      continue;
    }

    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      paths.push(...walkPaths(fullPath));
    }
    paths.push(fullPath);
  }

  return paths;
}

function isProbablyText(buffer) {
  return !buffer.includes(0);
}

function patchPathSegment(value) {
  return value
    .replace(/\bTraceabilityStack\b/g, stackClass)
    .replace(/\bTraceability\b/g, pascal)
    .replace(/traceability-stack/g, `${kebab}-stack`)
    .replace(/traceability\.test/g, `${kebab}.test`)
    .replace(/\btraceability\b/g, kebab);
}

function patchText(value) {
  return value
    .replace(/\bTraceabilityStack\b/g, stackClass)
    .replace(/\bTraceability\b/g, pascal)
    .replace(/traceability-stack/g, `${kebab}-stack`)
    .replace(/traceability\.test/g, `${kebab}.test`)
    .replace(/traceability\.ts\b/g, `${kebab}.ts`)
    .replace(/traceability\.js\b/g, `${kebab}.js`)
    .replace(/\btraceability\b/g, kebab);
}

/** Rename any remaining template-named paths added by future template changes. */
for (const oldPath of walkPaths(".").sort((a, b) => b.length - a.length)) {
  const dirname = path.dirname(oldPath);
  const basename = path.basename(oldPath);
  const nextBasename = patchPathSegment(basename);
  if (nextBasename === basename) {
    continue;
  }

  const nextPath = path.join(dirname, nextBasename);
  if (fs.existsSync(nextPath)) {
    throw new Error(`Cannot rename ${oldPath} to ${nextPath}: destination already exists`);
  }

  fs.renameSync(oldPath, nextPath);
}

/** Patch all generated text files so the copied template consistently uses this project name. */
for (const file of walk(".")) {
  const buffer = fs.readFileSync(file);
  if (!isProbablyText(buffer)) {
    continue;
  }

  const current = buffer.toString("utf8");
  const next = patchText(current);
  if (next !== current) {
    fs.writeFileSync(file, next, "utf8");
  }
}

if (fs.existsSync("README.md")) {
  const readme = fs
    .readFileSync("README.md", "utf8")
    .replace(/PinkFluffyUnicornsDancingOnRainbows/g, `${pascal}LegacyStack`);
  fs.writeFileSync("README.md", readme, "utf8");
}

/** Patch bin file:
 * - remove PinkFluffy... import + instantiation (to mimic cdk init single stack)
 * - set stack id and stackName to folder name
 */
let bin = fs.readFileSync(binPath, "utf8");

// Normalize to multi-line (the repo's bin file is currently one-liner; this improves readability)
bin = bin.replace(/;\s*/g, ";\n").replace(/\n{2,}/g, "\n");

// Remove PinkFluffy import/usage if present.
bin = bin.replace(/^.*PinkFluffyUnicornsDancingOnRainbowsStack.*\n/gm, "");
bin = bin.replace(/^.*new\s+PinkFluffyUnicornsDancingOnRainbowsStack.*\n/gm, "");

// Ensure stack id matches folder name (and add stackName in props)
bin = bin.replace(
  /new\s+(\w+Stack)\s*\(\s*app\s*,\s*['"][^'"]+['"]\s*,\s*\{\s*\}\s*\)\s*;?/m,
  (m, cls) => `new ${cls}(app, '${projectDirName}', { stackName: '${projectDirName}' });`
);

// If it was created without props, add props
bin = bin.replace(
  /new\s+(\w+Stack)\s*\(\s*app\s*,\s*['"][^'"]+['"]\s*\)\s*;?/m,
  (m, cls) => `new ${cls}(app, '${projectDirName}', { stackName: '${projectDirName}' });`
);

fs.writeFileSync(binPath, bin.trim() + "\n", "utf8");

/** Patch cdk.json app entry to point to new bin filename. */
if (fs.existsSync("cdk.json")) {
  const cdk = JSON.parse(fs.readFileSync("cdk.json", "utf8"));
  if (typeof cdk.app === "string") {
    cdk.app = cdk.app.replace(/bin\/traceability\.ts\b/g, `bin/${kebab}.ts`);
  }
  fs.writeFileSync("cdk.json", JSON.stringify(cdk, null, 2) + "\n", "utf8");
}

/** Patch package.json name and executable mapping to kebab-case. */
if (fs.existsSync("package.json")) {
  const pkg = JSON.parse(fs.readFileSync("package.json", "utf8"));
  pkg.name = kebab;
  if (pkg.bin && typeof pkg.bin === "object" && !Array.isArray(pkg.bin)) {
    delete pkg.bin.traceability;
    pkg.bin[kebab] = `bin/${kebab}.js`;
  }
  fs.writeFileSync("package.json", JSON.stringify(pkg, null, 2) + "\n", "utf8");
}

console.log("Patched:");
console.log(" -", binPath);
console.log(" -", libPath);
if (fs.existsSync(testPath)) {
  console.log(" -", testPath);
}
console.log(" - cdk.json app -> bin/" + kebab + ".ts");
console.log(" - package.json name -> " + kebab);
console.log(" - package.json bin -> " + kebab + ": bin/" + kebab + ".js");
NODE

npm install

# ---- Fresh git repo like cdk init ----
if command -v git >/dev/null 2>&1; then
  git init -q
  git add .
  git commit -m "Initial project from ${repo} template" -q || true
fi

echo
echo "✅ Project initialized as:"
echo "   bin/${KEBAB_NAME}.ts"
echo "   lib/${KEBAB_NAME}-stack.ts"
echo "   test/${KEBAB_NAME}.test.ts"
echo "   class ${STACK_CLASS}"
echo "   stack id/stackName: ${PROJECT_DIR_NAME}"
echo
echo "Next:"
echo "  cdk synth"
