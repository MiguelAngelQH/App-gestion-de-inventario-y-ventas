interface Props {
  estado: string;
}

const colors: Record<string, string> = {
  completada: 'bg-green-100 text-green-700',
  recibida: 'bg-blue-100 text-blue-700',
  pendiente: 'bg-yellow-100 text-yellow-700',
  cancelada: 'bg-red-100 text-red-700',
  pagado: 'bg-green-100 text-green-700',
  vencido: 'bg-red-100 text-red-700',
};

export default function StatusBadge({ estado }: Props) {
  const cls = colors[estado] || 'bg-slate-100 text-slate-700';
  return (
    <span className={`inline-block px-2.5 py-0.5 rounded-full text-xs font-medium ${cls}`}>
      {estado}
    </span>
  );
}
