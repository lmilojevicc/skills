#!/usr/bin/env bun
// Checks every skills/<name>/SKILL.md. Runs under bun or node, no dependencies.
//   - frontmatter present, `name` equals the directory, `description` set
//   - name and description within the Agent Skills limits (64 / 1024 chars)
//   - `disable-model-invocation`, when set, is true or false (AGENTS.md)
//   - relative links resolve and stay inside the skill, so each skill installs
//     on its own as an independent package (AGENTS.md)
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { dirname, join, relative, resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..', 'skills');
const errors = [];
const fail = (skill, message) => errors.push(`${skill}: ${message}`);

function frontmatter(text) {
  const match = text.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n/);
  if (!match) return null;
  const fields = {};
  let key = null;
  for (const line of match[1].split(/\r?\n/)) {
    const top = line.match(/^([A-Za-z][\w-]*):\s*(.*)$/);
    if (top) {
      key = top[1];
      fields[key] = top[2].replace(/^(['"])(.*)\1$/, '$2');
    } else if (key && /^\s+\S/.test(line) && ['>-', '>', '|', '|-', ''].includes(fields[key].trim())) {
      fields[key] = `${fields[key].replace(/^[>|]-?$/, '')} ${line.trim()}`.trim();
    }
  }
  return fields;
}

function markdownFiles(dir) {
  return readdirSync(dir).flatMap((entry) => {
    const path = join(dir, entry);
    if (statSync(path).isDirectory()) return entry === 'node_modules' ? [] : markdownFiles(path);
    return path.endsWith('.md') ? [path] : [];
  });
}

for (const skill of readdirSync(root).filter((d) => statSync(join(root, d)).isDirectory()).sort()) {
  const dir = join(root, skill);
  const file = join(dir, 'SKILL.md');
  if (!existsSync(file)) {
    fail(skill, 'missing SKILL.md');
    continue;
  }
  const fields = frontmatter(readFileSync(file, 'utf8'));
  if (!fields) {
    fail(skill, 'SKILL.md has no YAML frontmatter');
    continue;
  }
  if (fields.name !== skill) fail(skill, `name "${fields.name ?? ''}" does not match its directory`);
  if (!/^[a-z0-9]+(-[a-z0-9]+)*$/.test(fields.name ?? '') || fields.name.length > 64)
    fail(skill, 'name must be lowercase words joined by hyphens, at most 64 characters');
  if (!fields.description) fail(skill, 'description is empty');
  else if (fields.description.length > 1024) fail(skill, `description is ${fields.description.length} characters (max 1024)`);
  if ('disable-model-invocation' in fields && !['true', 'false'].includes(fields['disable-model-invocation']))
    fail(skill, 'disable-model-invocation must be true or false');

  for (const md of markdownFiles(dir)) {
    const text = readFileSync(md, 'utf8').replace(/```[\s\S]*?```/g, '').replace(/`[^`\n]*`/g, '');
    for (const [, target] of text.matchAll(/\]\(([^)\s]+)(?:\s+"[^"]*")?\)/g)) {
      if (/^([a-z]+:|#|\/)/i.test(target)) continue;
      const path = resolve(dirname(md), decodeURIComponent(target.split('#')[0]));
      const where = relative(root, md);
      if (relative(dir, path).startsWith('..')) fail(skill, `${where} links outside the skill: ${target}`);
      else if (!existsSync(path)) fail(skill, `${where} has a broken link: ${target}`);
    }
  }
}

if (errors.length) {
  console.error(errors.join('\n'));
  process.exit(1);
}
console.log('All skills OK.');
