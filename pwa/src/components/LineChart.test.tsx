import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { LineChart } from './LineChart';

describe('LineChart', () => {
  it('renders minimum data point message when < 2 points', () => {
    render(<LineChart data={[{ date: 'Jan 1', value: 100 }]} />);
    expect(screen.getByText(/at least 2 data points/i)).toBeInTheDocument();
  });

  it('renders SVG with 2+ data points', () => {
    const data = [
      { date: 'Jan 1', value: 100 },
      { date: 'Jan 8', value: 120 },
      { date: 'Jan 15', value: 115 },
    ];
    const { container } = render(<LineChart data={data} />);
    expect(container.querySelector('svg')).toBeInTheDocument();
    expect(container.querySelectorAll('circle').length).toBe(3);
  });

  it('shows x-axis labels from first and last data points', () => {
    const data = [
      { date: 'Mar 1', value: 50 },
      { date: 'Mar 15', value: 75 },
    ];
    render(<LineChart data={data} />);
    expect(screen.getByText('Mar 1')).toBeInTheDocument();
    expect(screen.getByText('Mar 15')).toBeInTheDocument();
  });

  it('uses custom formatValue for y-axis', () => {
    const data = [
      { date: 'A', value: 100 },
      { date: 'B', value: 200 },
    ];
    render(<LineChart data={data} formatValue={(v) => `${v}lbs`} />);
    expect(screen.getByText('200lbs')).toBeInTheDocument();
  });

  it('shows positive trend indicator for upward data', () => {
    const data = [
      { date: 'A', value: 100 },
      { date: 'B', value: 150 },
    ];
    render(<LineChart data={data} />);
    expect(screen.getByText('+50')).toBeInTheDocument();
  });
});
