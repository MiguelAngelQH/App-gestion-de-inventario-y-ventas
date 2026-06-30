'use client';

import { motion } from 'framer-motion';
import { Settings } from 'lucide-react';

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

      <motion.div variants={itemVariants} className="card p-8 text-center">
        <div className="w-16 h-16 rounded-2xl bg-blue-50 dark:bg-blue-500/10 flex items-center justify-center mx-auto mb-4">
          <Settings size={32} className="text-blue-600 dark:text-blue-400" />
        </div>
        <p className="text-[var(--text-secondary)] text-sm">
          La configuración de precios ahora se gestiona directamente desde la sección <strong>Productos</strong>.
        </p>
      </motion.div>
    </motion.div>
  );
}
