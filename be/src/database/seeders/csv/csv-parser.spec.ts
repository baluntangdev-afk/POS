import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';
import { parseCsvFile } from './csv-parser';

function writeTempCsv(content: string): string {
  const file = path.join(os.tmpdir(), `test-${Date.now()}-${Math.random()}.csv`);
  fs.writeFileSync(file, content, 'utf-8');
  return file;
}

describe('parseCsvFile', () => {
  it('parses headers and rows', () => {
    const file = writeTempCsv('A,B,C\n1,2,3\n4,5,6\n');
    const result = parseCsvFile(file);
    expect(result.headers).toEqual(['A', 'B', 'C']);
    expect(result.rows).toEqual([
      ['1', '2', '3'],
      ['4', '5', '6'],
    ]);
    fs.unlinkSync(file);
  });

  it('handles CRLF line endings', () => {
    const file = writeTempCsv('A,B\r\n1,2\r\n');
    const result = parseCsvFile(file);
    expect(result.headers).toEqual(['A', 'B']);
    expect(result.rows).toEqual([['1', '2']]);
    fs.unlinkSync(file);
  });

  it('handles quoted fields containing commas', () => {
    const file = writeTempCsv('A,B\n"hello, world",2\n');
    const result = parseCsvFile(file);
    expect(result.rows[0][0]).toBe('hello, world');
    fs.unlinkSync(file);
  });

  it('strips UTF-8 BOM', () => {
    const bom = Buffer.from([0xef, 0xbb, 0xbf]);
    const file = path.join(os.tmpdir(), `bom-${Date.now()}.csv`);
    fs.writeFileSync(file, Buffer.concat([bom, Buffer.from('A,B\n1,2\n')]));
    const result = parseCsvFile(file);
    expect(result.headers[0]).toBe('A');
    fs.unlinkSync(file);
  });

  it('skips blank trailing lines', () => {
    const file = writeTempCsv('A,B\n1,2\n\n');
    const result = parseCsvFile(file);
    expect(result.rows).toHaveLength(1);
    fs.unlinkSync(file);
  });

  it('trims whitespace from values', () => {
    const file = writeTempCsv('A , B \n 1 , 2 \n');
    const result = parseCsvFile(file);
    expect(result.headers).toEqual(['A', 'B']);
    expect(result.rows[0]).toEqual(['1', '2']);
    fs.unlinkSync(file);
  });

  it('throws if file does not exist', () => {
    expect(() => parseCsvFile('/no/such/file.csv')).toThrow();
  });
});
