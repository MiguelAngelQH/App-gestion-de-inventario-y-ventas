interface Props {
  titulo: string;
  valor: string;
  color: string;
  icono: string;
}

export default function MetricCard({ titulo, valor, color, icono }: Props) {
  return (
    <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-5">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm text-slate-500 font-medium">{titulo}</p>
          <p className={`text-2xl font-bold mt-1 ${color}`}>{valor}</p>
        </div>
        <span className="text-3xl">{icono}</span>
      </div>
    </div>
  );
}
