'use client';

import {
  PieChart, Pie, Cell, Tooltip, ResponsiveContainer, Legend,
} from 'recharts';

const COLORS = ['#2563eb', '#6366f1', '#16a34a', '#d97706', '#dc2626', '#ec4899', '#14b8a6', '#f97316', '#8b5cf6', '#84cc16'];

interface Props {
  data: { categoria: string; total: number }[];
}

const CustomTooltip = ({ active, payload }: any) => {
  if (active && payload && payload.length) {
    return (
      <div className="bg-white dark:bg-[#0a0428] rounded-xl px-4 py-3 shadow-lg border border-gray-100 dark:border-white/10">
        <p className="text-xs text-gray-500 dark:text-white/50 mb-1">{payload[0].name}</p>
        <p className="text-sm font-semibold text-gray-900 dark:text-white">S/ {Number(payload[0].value).toFixed(2)}</p>
      </div>
    );
  }
  return null;
};

const CustomLegend = ({ payload }: any) => (
  <div className="flex flex-wrap justify-center gap-x-4 gap-y-1 mt-2">
    {payload.map((entry: any, index: number) => (
      <div key={index} className="flex items-center gap-1.5">
        <div className="w-2 h-2 rounded-full flex-shrink-0" style={{ backgroundColor: entry.color }} />
        <span className="text-xs text-[var(--text-secondary)]">{entry.value}</span>
      </div>
    ))}
  </div>
);

export default function CategoryChart({ data }: Props) {
  return (
    <div className="card p-5">
      <h3 className="text-sm font-semibold text-[var(--text-primary)] mb-4">Ventas por Categoria</h3>
      <ResponsiveContainer width="100%" height={280}>
        <PieChart>
          <Pie
            data={data}
            dataKey="total"
            nameKey="categoria"
            cx="50%"
            cy="50%"
            outerRadius={90}
            innerRadius={50}
            paddingAngle={3}
          >
            {data.map((_, index) => (
              <Cell key={index} fill={COLORS[index % COLORS.length]} stroke="transparent" />
            ))}
          </Pie>
          <Tooltip content={<CustomTooltip />} />
          <Legend content={<CustomLegend />} />
        </PieChart>
      </ResponsiveContainer>
    </div>
  );
}
