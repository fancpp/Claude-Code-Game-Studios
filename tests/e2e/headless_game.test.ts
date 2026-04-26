/**
 * E2E Game Smoke Tests — Godot Headless
 *
 * These tests run the Godot game in headless mode and verify
 * that critical game systems function without crash or errors.
 *
 * This is the primary CI test when Godot web export templates are not available.
 * The full browser-based E2E tests (game.spec.ts) run when export templates exist.
 *
 * Tests run via: godot --headless --script tests/e2e/game_smoke.gd
 */

import { test, expect } from '@playwright/test';

const SMOKE_SCRIPT = 'res://tests/e2e/game_smoke.gd';

/**
 * E2E Smoke Tests using Godot headless game execution.
 *
 * These tests use Playwright to invoke Godot in headless mode
 * with a smoke test script that exercises the game loop.
 */
test.describe('Godot Headless Smoke Tests', () => {

  test('godot binary is available', async () => {
    const { exec } = require('child_process');
    const result = await new Promise<string>((resolve, reject) => {
      exec('which godot', (err: Error | null, stdout: string) => {
        if (err) reject(err);
        else resolve(stdout.trim());
      });
    });
    expect(result).toContain('godot');
  });

  test('game starts without errors in headless mode', async ({ page }) => {
    // Start godot headless with the smoke test script
    const { spawn } = require('child_process');
    const errors: string[] = [];

    const proc = spawn('godot', [
      '--headless',
      '--script',
      'res://tests/e2e/game_smoke.gd',
    ], {
      cwd: '/home/efan/work/claude_workspace/my-game',
    });

    let output = '';
    proc.stdout.on('data', (data: Buffer) => { output += data.toString(); });
    proc.stderr.on('data', (data: Buffer) => {
      const text = data.toString();
      if (text.includes('ERROR') || text.includes('FAILED')) {
        errors.push(text);
      }
    });

    const exitCode = await new Promise<number>((resolve) => {
      proc.on('close', (code: number) => resolve(code ?? 0));
      setTimeout(() => { proc.kill(); resolve(1); }, 30000);
    });

    console.log('Godot output:', output);
    expect(exitCode).toBe(0);
    expect(errors).toHaveLength(0);
  });

  test('game script has no syntax errors', async ({ page }) => {
    const { spawn } = require('child_process');
    const proc = spawn('godot', [
      '--headless',
      '--check-only',
      '--script',
      'res://tests/e2e/game_smoke.gd',
    ], {
      cwd: '/home/efan/work/claude_workspace/my-game',
    });

    const exitCode = await new Promise<number>((resolve) => {
      proc.on('close', (code: number) => resolve(code ?? 0));
      setTimeout(() => { proc.kill(); resolve(1); }, 10000);
    });

    expect(exitCode).toBe(0);
  });
});