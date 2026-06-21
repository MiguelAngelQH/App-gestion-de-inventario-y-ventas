'use client';

import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
} from 'recharts';

interface Props {
  data: { fecha: string; total: number }[];
}

const CustomTooltip = ({ active, payload, label }: any) => {
  if (active && payload && payload.length) {
    return (
      <div className="bg-white dark:bg-[#0a0428] rounded-xl px-4 py-3 shadow-lg border border-gray-100 dark:border-white/10">
        <p className="text-xs text-gray-500 dark:text-white/50 mb-1">{label}</p>
        <p className="text-sm font-semibold text-gray-900 dark:text-white">S/ {Number(payload[0].value).toFixed(2)}</p>
      </div>
    );
  }
  return null;
};

export default function SalesChart({ data }: Props) {
  const chartData = data.map((d: any) => ({
    ...d,
    fecha: new Date(d.fecha).toLocaleDateString('es-PE', { weekday: 'short', day: 'numeric' }),
  }));

  return (
    <div className="card p-5">
      <h3 className="text-sm font-semibold text-[var(--text-primary)] mb-4">Ventas Ultimos 7 Dias</h3>
      <ResponsiveContainer width="100%" height={280}>
        <BarChart data={chartData}>
          <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
          <XAxis dataKey="fecha" tick={{ fontSize: 11, fill: 'var(--text-muted)' }} axisLine={{ stroke: 'var(--border)' }} />
          <YAxis tick={{ fontSize: 11, fill: 'var(--text-muted)' }} axisLine={{ stroke: 'var(--border)' }} />
          <Tooltip content={<CustomTooltip />} />
          <Bar dataKey="total" radius={[6, 6, 0, 0]} maxBarSize={40} fill="url(#barGradient)" />
          <defs>
            <linearGradient id="barGradient" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="#2563eb" stopOpacity={0.8} />
              <stop offset="100%" stopColor="#6366f1" stopOpacity={0.3} />
            </linearGradient>
          </defs>
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}
