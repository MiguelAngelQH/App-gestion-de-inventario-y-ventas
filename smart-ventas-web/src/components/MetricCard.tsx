import { type LucideIcon } from 'lucide-react';

interface Props {
  titulo: string;
  valor: string;
  icono: LucideIcon;
  color?: string;
}

export default function MetricCard({ titulo, valor, icono: Icon, color = 'from-teal-600 to-blue-800' }: Props) {
  return (
    <div className="card p-5 relative overflow-hidden group">
      <div className="flex items-start justify-between mb-2">
        <p className="card-header">{titulo}</p>
        <div className={`w-10 h-10 rounded-xl bg-gradient-to-br ${color} flex items-center justify-center shadow-md flex-shrink-0 ml-3`}>
          <Icon size={18} className="text-white" />
        </div>
      </div>
      <p className="text-2xl font-bold text-[var(--text-primary)] tracking-tight">{valor}</p>
    </div>
  );
}
