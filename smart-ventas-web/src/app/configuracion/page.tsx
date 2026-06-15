'use client';

import { motion } from 'framer-motion';
import Link from 'next/link';
import { Settings, DollarSign, ChevronRight } from 'lucide-react';

const containerVariants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { staggerChildren: 0.06, delayChildren: 0.1 } },
};

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.4 } },
};

export default function ConfiguracionPage() {
  return (
    <motion.div variants={containerVariants} initial="hidden" animate="visible" className="space-y-5">
      <motion.div variants={itemVariants}>
        <h1 className="text-2xl font-bold text-[var(--text-primary)]">Configuración</h1>
        <p className="text-sm text-[var(--text-secondary)] mt-1">Administra las preferencias del sistema</p>
      </motion.div>

      <motion.div variants={itemVariants} className="space-y-3">
        <Link
          href="/configuracion/precios"
          className="card p-4 flex items-center gap-4 hover:shadow-md transition-shadow group"
        >
          <div className="w-12 h-12 rounded-xl bg-green-50 dark:bg-green-500/10 flex items-center justify-center flex-shrink-0">
            <DollarSign size={24} className="text-green-600 dark:text-green-400" />
          </div>
          <div className="flex-1 min-w-0">
            <h3 className="font-semibold text-[var(--text-primary)]">Configuración de Precios</h3>
            <p className="text-sm text-[var(--text-secondary)]">Edita precios y costos de todas las presentaciones</p>
          </div>
          <ChevronRight size={20} className="text-[var(--text-muted)] group-hover:text-[var(--text-primary)] transition-colors flex-shrink-0" />
        </Link>
      </motion.div>
    </motion.div>
  );
}
