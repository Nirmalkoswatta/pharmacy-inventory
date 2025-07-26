// Simple test to ensure Jest is working
describe('Basic Test Suite', () => {
  test('should pass basic test', () => {
    expect(1 + 1).toBe(2);
  });

  test('should verify Node.js environment', () => {
    expect(process.env.NODE_ENV).toBeDefined();
  });

  test('should test basic JavaScript functionality', () => {
    const testArray = [1, 2, 3];
    expect(testArray).toHaveLength(3);
    expect(testArray).toContain(2);
  });
});
