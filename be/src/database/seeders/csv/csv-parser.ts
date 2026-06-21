import * as fs from 'fs';

export interface ParsedCsv {
  headers: string[];
  rows: string[][];
}

/**
 * Splits a single CSV line into trimmed fields, honouring double-quoted fields
 * (which may contain commas) and escaped quotes (`""`). Stores frequently export
 * descriptions containing commas, so naive `split(',')` would corrupt the data.
 */
function parseLine(line: string): string[] {
  const fields: string[] = [];
  let current = '';
  let inQuotes = false;

  for (let i = 0; i < line.length; i++) {
    const ch = line[i];
    if (ch === '"') {
      if (inQuotes && line[i + 1] === '"') {
        current += '"';
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (ch === ',' && !inQuotes) {
      fields.push(current.trim());
      current = '';
    } else {
      current += ch;
    }
  }
  fields.push(current.trim());
  return fields;
}

export function parseCsvFile(filePath: string): ParsedCsv {
  let content = fs.readFileSync(filePath, 'utf-8');

  // Strip UTF-8 BOM — common when stores export from Windows Excel.
  if (content.charCodeAt(0) === 0xfeff) {
    content = content.slice(1);
  }

  const lines = content.split(/\r?\n/).filter((l) => l.trim() !== '');

  if (lines.length === 0) {
    return { headers: [], rows: [] };
  }

  const headers = parseLine(lines[0]);
  const rows = lines.slice(1).map((l) => parseLine(l));

  return { headers, rows };
}
