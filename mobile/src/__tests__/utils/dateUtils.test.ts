import {formatDate, formatDateTime} from '../../utils/dateUtils';

describe('dateUtils', () => {
  describe('formatDate', () => {
    it('should format date correctly', () => {
      const date = new Date('2024-01-15');
      const formatted = formatDate(date);
      expect(formatted).toBe('15.01.2024');
    });
  });

  describe('formatDateTime', () => {
    it('should format date and time correctly', () => {
      const date = new Date('2024-01-15T14:30:00');
      const formatted = formatDateTime(date);
      expect(formatted).toContain('15.01.2024');
      expect(formatted).toContain('14:30');
    });
  });
});
