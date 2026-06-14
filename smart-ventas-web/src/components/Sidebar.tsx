'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useState } from 'react';

const navItems = [
  { href: '/', label: 'Dashboard', icon: '📊' },
  { href: '/productos', label: 'Productos', icon: '📦' },
  { href: '/ventas', label: 'Ventas', icon: '💰' },
  { href: '/compras', label: 'Compras', icon: '📥' },
  { href: '/clientes', label: 'Clientes', icon: '👥' },
  { href: '/proveedores', label: 'Proveedores', icon: '🏢' },
  { href: '/reportes', label: 'Reportes', icon: '📈' },
];

export default function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();
  const [loggingOut, setLoggingOut] = useState(false);

  const handleLogout = async () => {
    setLoggingOut(true);
    try {
      await fetch('/api/auth/logout', { method: 'POST' });
      router.push('/login');
    } catch {
      setLoggingOut(false);
    }
  };

  return (
    <aside className="w-64 bg-slate-900 text-white flex flex-col h-screen sticky top-0">
      <div className="p-5 border-b border-slate-700">
        <h1 className="text-xl font-bold text-blue-400">SmartVentas</h1>
        <p className="text-xs text-slate-400 mt-1">Panel de Administración</p>
      </div>
      <nav className="flex-1 p-3 space-y-1">
        {navItems.map((item) => {
          const active = pathname === item.href;
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center gap-3 px-4 py-2.5 rounded-lg text-sm transition-colors ${
                active
                  ? 'bg-blue-600 text-white'
                  : 'text-slate-300 hover:bg-slate-800 hover:text-white'
              }`}
            >
              <span>{item.icon}</span>
              <span>{item.label}</span>
            </Link>
          );
        })}
      </nav>
      <div className="p-4 border-t border-slate-700">
        <button
          onClick={handleLogout}
          disabled={loggingOut}
          className="flex items-center gap-3 px-4 py-2.5 rounded-lg text-sm w-full text-slate-300 hover:bg-slate-800 hover:text-white transition-colors disabled:opacity-50"
        >
          <span>🚪</span>
          <span>{loggingOut ? 'Cerrando sesión...' : 'Cerrar sesión'}</span>
        </button>
        <div className="text-xs text-slate-500 mt-2">SmartVentas v1.1.0</div>
      </div>
    </aside>
  );
}
