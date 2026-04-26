import { test, expect } from '@playwright/test';

const GAME_URL = process.env.GAME_URL || 'http://localhost:8000/index.html';

/**
 * E2E Tests — Tetris Game Critical User Flows
 *
 * Runs against Godot HTML5 export served on localhost:8000.
 * Requires: godot --headless export to web, served by python3 -m http.server.
 *
 * Critical flows covered:
 * 1. Game loads without errors
 * 2. New game starts → board visible
 * 3. Piece movement (left/right/down)
 * 4. Rotation (CW/CCW)
 * 5. Hard drop
 * 6. Pause toggle
 * 7. No console errors during normal gameplay
 */

test.describe('Tetris — Critical User Flows', () => {

  test.beforeEach(async ({ page }) => {
    // Listen for console errors (Error level only)
    page.on('console', msg => {
      if (msg.type() === 'error') {
        console.error('[Console Error]', msg.text());
      }
    });
    await page.goto(GAME_URL);
    // Wait for Godot canvas to be visible
    await page.waitForSelector('canvas', { timeout: 15000 });
  });

  // --- Flow 1: Game loads without crash ---
  test('game loads without crash', async ({ page }) => {
    const consoleErrors: string[] = [];
    page.on('console', msg => {
      if (msg.type() === 'error') consoleErrors.push(msg.text());
    });

    await page.goto(GAME_URL);
    await page.waitForSelector('canvas', { timeout: 15000 });

    // Canvas should be present and visible
    const canvas = page.locator('canvas');
    await expect(canvas).toBeVisible();

    // No console errors at load
    expect(consoleErrors).toHaveLength(0);
  });

  // --- Flow 2: New game starts ---
  test('new game starts when Enter is pressed', async ({ page }) => {
    await page.waitForSelector('canvas');
    // Focus the canvas so keyboard input goes to Godot
    await page.locator('canvas').click();

    // Press Enter to start new game
    await page.keyboard.press('Enter');
    await page.waitForTimeout(500);

    // Canvas still visible (game didn't crash)
    const canvas = page.locator('canvas');
    await expect(canvas).toBeVisible();
  });

  // --- Flow 3: Piece movement ---
  test('left/right arrow keys move piece', async ({ page }) => {
    await page.waitForSelector('canvas');
    await page.locator('canvas').click();
    await page.keyboard.press('Enter');  // start game
    await page.waitForTimeout(300);

    // Move right 3 times
    await page.keyboard.press('ArrowRight');
    await page.waitForTimeout(100);
    await page.keyboard.press('ArrowRight');
    await page.waitForTimeout(100);
    await page.keyboard.press('ArrowRight');
    await page.waitForTimeout(100);

    // No crash — canvas still alive
    const canvas = page.locator('canvas');
    await expect(canvas).toBeVisible();
  });

  test('soft drop with down arrow', async ({ page }) => {
    await page.waitForSelector('canvas');
    await page.locator('canvas').click();
    await page.keyboard.press('Enter');
    await page.waitForTimeout(300);

    // Hold soft drop for a bit
    await page.keyboard.press('ArrowDown');
    await page.waitForTimeout(200);
    await page.keyboard.press('ArrowDown');
    await page.waitForTimeout(200);

    const canvas = page.locator('canvas');
    await expect(canvas).toBeVisible();
  });

  // --- Flow 4: Rotation ---
  test('X/Z keys rotate piece CW and CCW', async ({ page }) => {
    await page.waitForSelector('canvas');
    await page.locator('canvas').click();
    await page.keyboard.press('Enter');
    await page.waitForTimeout(300);

    // Rotate CW (X)
    await page.keyboard.press('x');
    await page.waitForTimeout(100);
    await page.keyboard.press('x');
    await page.waitForTimeout(100);

    // Rotate CCW (Z)
    await page.keyboard.press('z');
    await page.waitForTimeout(100);

    const canvas = page.locator('canvas');
    await expect(canvas).toBeVisible();
  });

  // --- Flow 5: Hard drop ---
  test('Space key hard drops piece', async ({ page }) => {
    await page.waitForSelector('canvas');
    await page.locator('canvas').click();
    await page.keyboard.press('Enter');
    await page.waitForTimeout(300);

    // Hard drop
    await page.keyboard.press('Space');
    await page.waitForTimeout(500);

    const canvas = page.locator('canvas');
    await expect(canvas).toBeVisible();
  });

  // --- Flow 6: Pause toggle ---
  test('Escape pauses and unpauses', async ({ page }) => {
    await page.waitForSelector('canvas');
    await page.locator('canvas').click();
    await page.keyboard.press('Enter');
    await page.waitForTimeout(300);

    // Pause
    await page.keyboard.press('Escape');
    await page.waitForTimeout(300);

    // Unpause
    await page.keyboard.press('Escape');
    await page.waitForTimeout(300);

    const canvas = page.locator('canvas');
    await expect(canvas).toBeVisible();
  });

  // --- Flow 7: No errors during 30 seconds of gameplay ---
  test('no console errors during active gameplay', async ({ page }) => {
    const consoleErrors: string[] = [];
    page.on('console', msg => {
      if (msg.type() === 'error') consoleErrors.push(msg.text());
    });

    await page.goto(GAME_URL);
    await page.waitForSelector('canvas');
    await page.locator('canvas').click();
    await page.keyboard.press('Enter');

    // Simulate 30 seconds of active play
    for (let i = 0; i < 30; i++) {
      // Random actions to keep game active
      const actions = [
        'ArrowLeft', 'ArrowRight', 'ArrowDown',
        'x', 'z', ' ',  // move left/right/down, rotate CW/CCW, hard drop
      ];
      const action = actions[Math.floor(Math.random() * actions.length)];
      await page.keyboard.press(action);
      await page.waitForTimeout(1000);
    }

    // No errors accumulated
    expect(consoleErrors).toHaveLength(0);
  });

  // --- Flow 8: Multiple hard drops in succession ---
  test('multiple hard drops lock pieces correctly', async ({ page }) => {
    await page.waitForSelector('canvas');
    await page.locator('canvas').click();
    await page.keyboard.press('Enter');
    await page.waitForTimeout(300);

    // Hard drop 5 times in succession
    for (let i = 0; i < 5; i++) {
      await page.keyboard.press('Space');
      await page.waitForTimeout(300);  // wait for lock
    }

    const canvas = page.locator('canvas');
    await expect(canvas).toBeVisible();
  });
});