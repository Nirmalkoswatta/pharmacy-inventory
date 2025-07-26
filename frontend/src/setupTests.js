// jest-dom adds custom jest matchers for asserting on DOM nodes.
// allows you to do things like:
// expect(element).toHaveTextContent(/react/i)
// learn more: https://github.com/testing-library/jest-dom
import '@testing-library/jest-dom';

// Mock AOS (Animate On Scroll) since it doesn't work in test environment
jest.mock('aos', () => ({
  init: jest.fn(),
  refresh: jest.fn(),
  refreshHard: jest.fn(),
}));

// Mock Lottie React
jest.mock('lottie-react', () => {
  return function LottieMock() {
    return <div data-testid="lottie-animation">Lottie Animation</div>;
  };
});

// Mock framer-motion
jest.mock('framer-motion', () => ({
  motion: {
    div: 'div',
    span: 'span',
    h1: 'h1',
    h2: 'h2',
    h3: 'h3',
    p: 'p',
    button: 'button',
  },
  AnimatePresence: ({ children }) => children,
}));

// Global test timeout
jest.setTimeout(10000);
