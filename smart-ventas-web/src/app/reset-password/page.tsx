'use client';

import { useState, useEffect, Suspense } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { motion } from 'framer-motion';
import { Lock, ShieldCheck, AlertTriangle } from 'lucide-react';
import GradientOrbs from '@/components/GradientOrbs';

const API_KEY = process.env.NEXT_PUBLIC_FIREBASE_API_KEY || 'AIzaSyCuPyDwJtELgZ25NydWGdndDpNVZCf2B6I';

function ResetForm() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  const oobCode = searchParams.get('oobCode');

  useEffect(() => {
    if (!oobCode) {
      setError('Enlace inválido o expirado. Solicita un nuevo restablecimiento.');
    }
  }, [oobCode]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (password.length < 6) {
      setError('La contraseña debe tener al menos 6 caracteres');
      return;
    }

    if (password !== confirm) {
      setError('Las contraseñas no coinciden');
      return;
    }

    setLoading(true);

    try {
      const res = await fetch(
        `https://identitytoolkit.googleapis.com/v1/accounts:resetPassword?key=${API_KEY}`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ oobCode, newPassword: password }),
        }
      );

      const data = await res.json();

      if (!res.ok) {
        const code = data.error?.message;
        if (code === 'EXPIRED_OOB_CODE') {
          setError('El enlace ha expirado. Solicita uno nuevo.');
        } else if (code === 'INVALID_OOB_CODE') {
          setError('El enlace no es válido. Solicita uno nuevo.');
        } else {
          setError('Error al restablecer la contraseña. Intenta de nuevo.');
        }
        return;
      }

      setSuccess(true);
      setTimeout(() => router.push('/login'), 3000);
    } catch {
      setError('Error de conexión. Intenta de nuevo.');
    } finally {
      setLoading(false);
    }
  };

  if (success) {
    return (
      <motion.div
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: 1, scale: 1 }}
        className="bg-white rounded-2xl shadow-xl shadow-teal-600/5 border border-teal-100/50 p-8 md:p-10 text-center"
      >
        <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-teal-500 to-blue-600 flex items-center justify-center mx-auto mb-6 shadow-lg shadow-teal-600/20">
          <ShieldCheck size={32} className="text-white" />
        </div>
        <h2 className="text-2xl font-bold text-gray-900 mb-2">Contraseña actualizada</h2>
        <p className="text-gray-500 mb-6">Tu contraseña se ha restablecido correctamente.</p>
        <p className="text-sm text-gray-400">Redirigiendo al inicio de sesión...</p>
      </motion.div>
    );
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5 }}
      className="bg-white rounded-2xl shadow-xl shadow-teal-600/5 border border-teal-100/50 p-8 md:p-10"
    >
      <div className="text-center mb-8">
        <img src="/smartventas-logo-horizontal.svg" alt="SmartVentas" className="h-16 mx-auto mb-6" />
        <h1 className="text-2xl font-bold text-gray-900">Restablecer contraseña</h1>
        <p className="text-gray-500 mt-2 text-sm">Ingresa tu nueva contraseña</p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-5">
        {error && (
          <motion.div
            initial={{ opacity: 0, x: -10 }}
            animate={{ opacity: 1, x: 0 }}
            className="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-xl text-sm flex items-center gap-2"
          >
            <AlertTriangle size={16} />
            {error}
          </motion.div>
        )}

        <div>
          <label className="block text-sm font-medium text-gray-600 mb-2">Nueva contraseña</label>
          <div className="relative">
            <Lock size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400" />
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full pl-10 pr-4 py-3 bg-white border border-gray-200 rounded-xl text-gray-900 placeholder-gray-400 focus:border-teal-500 focus:ring-2 focus:ring-teal-500/10 transition-all"
              placeholder="Mínimo 6 caracteres"
              required
              minLength={6}
            />
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-600 mb-2">Confirmar contraseña</label>
          <div className="relative">
            <Lock size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400" />
            <input
              type="password"
              value={confirm}
              onChange={(e) => setConfirm(e.target.value)}
              className="w-full pl-10 pr-4 py-3 bg-white border border-gray-200 rounded-xl text-gray-900 placeholder-gray-400 focus:border-teal-500 focus:ring-2 focus:ring-teal-500/10 transition-all"
              placeholder="Repite la contraseña"
              required
            />
          </div>
        </div>

        <button
          type="submit"
          disabled={loading || !oobCode}
          className="w-full py-3 bg-gradient-to-r from-teal-600 to-blue-700 hover:from-teal-700 hover:to-blue-800 text-white font-medium rounded-xl transition-all shadow-lg shadow-teal-600/20 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
        >
          {loading ? (
            <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
          ) : (
            <>
              <ShieldCheck size={18} />
              Restablecer contraseña
            </>
          )}
        </button>
      </form>
    </motion.div>
  );
}

export default function ResetPasswordPage() {
  return (
    <div className="min-h-screen w-full flex items-center justify-center bg-gradient-to-br from-teal-50 via-white to-blue-50 relative overflow-hidden">
      <GradientOrbs />
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top_right,rgba(0,137,123,0.08),transparent_50%)] pointer-events-none" />
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_bottom_left,rgba(21,101,192,0.06),transparent_50%)] pointer-events-none" />

      <div className="relative w-full max-w-md mx-4 z-10">
        <Suspense fallback={
          <div className="bg-white rounded-2xl p-8 text-center">
            <div className="w-8 h-8 border-2 border-teal-600/30 border-t-teal-600 rounded-full animate-spin mx-auto" />
          </div>
        }>
          <ResetForm />
        </Suspense>
      </div>
    </div>
  );
}
