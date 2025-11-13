export const MANAGEMENT_COMMANDS = [
  'list',
  'ls',
  'add',
  'remove',
  'rm',
  'current',
  'use',
  'help',
  '-h',
  '--help',
] as const;

export type ManagementCommand = (typeof MANAGEMENT_COMMANDS)[number];
