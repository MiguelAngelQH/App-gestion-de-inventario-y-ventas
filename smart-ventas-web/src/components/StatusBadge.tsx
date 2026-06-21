interface Props {
  estado: string;
}

const config: Record<string, { bg: string; dot: string; label: string }> = {
  completada: { bg: 'bg-green-50 text-green-700 dark:bg-green-500/10 dark:text-green-400 border-green-200 dark:border-green-500/20', dot: 'bg-green-500', label: 'Completada' },
  recibida: { bg: 'bg-blue-50 text-blue-700 dark:bg-blue-500/10 dark:text-blue-400 border-blue-200 dark:border-blue-500/20', dot: 'bg-blue-500', label: 'Recibida' },
  pendiente: { bg: 'bg-yellow-50 text-yellow-700 dark:bg-yellow-500/10 dark:text-yellow-400 border-yellow-200 dark:border-yellow-500/20', dot: 'bg-yellow-500', label: 'Pendiente' },
  cancelada: { bg: 'bg-red-50 text-red-700 dark:bg-red-500/10 dark:text-red-400 border-red-200 dark:border-red-500/20', dot: 'bg-red-500', label: 'Cancelada' },
  pagado: { bg: 'bg-green-50 text-green-700 dark:bg-green-500/10 dark:text-green-400 border-green-200 dark:border-green-500/20', dot: 'bg-green-500', label: 'Pagado' },
  vencido: { bg: 'bg-red-50 text-red-700 dark:bg-red-500/10 dark:text-red-400 border-red-200 dark:border-red-500/20', dot: 'bg-red-500', label: 'Vencido' },
};

export default function StatusBadge({ estado }: Props) {
  const c = config[estado] || {
    bg: 'bg-gray-50 text-gray-700 dark:bg-white/5 dark:text-gray-400 border-gray-200 dark:border-white/10',
    dot: 'bg-gray-400',
    label: estado,
  };

  return (
    <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-xs font-medium border ${c.bg}`}>
      <span className={`w-1.5 h-1.5 rounded-full ${c.dot}`} />
      {c.label}
    </span>
  );
}
