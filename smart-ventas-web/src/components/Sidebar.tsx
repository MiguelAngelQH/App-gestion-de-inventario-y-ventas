'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useState } from 'react';
import { LayoutDashboard, Package, DollarSign, ArrowDownToLine, Users, Building2, BarChart3, Settings, LogOut, Sun, Moon, ChevronLeft, ChevronRight } from 'lucide-react';
import { useTheme } from '@/lib/ThemeProvider';

const navItems = [
  { href: '/', label: 'Dashboard', icon: LayoutDashboard },
  { href: '/productos', label: 'Productos', icon: Package },
  { href: '/ventas', label: 'Ventas', icon: DollarSign },
  { href: '/compras', label: 'Compras', icon: ArrowDownToLine },
  { href: '/clientes', label: 'Clientes', icon: Users },
  { href: '/proveedores', label: 'Proveedores', icon: Building2 },
  { href: '/reportes', label: 'Reportes', icon: BarChart3 },
  { href: '/configuracion', label: 'Configuración', icon: Settings },
];

export default function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();
  const [loggingOut, setLoggingOut] = useState(false);
  const [collapsed, setCollapsed] = useState(false);
  const { theme, toggle } = useTheme();

  const handleLogout = async () => {
    setLoggingOut(true);
    try {
      await fetch('/api/auth/logout', { method: 'POST' });
      router.push('/login');
    } catch {
      setLoggingOut(false);
    }
  };

  if (pathname === '/login') return null;

  return (
    <aside className={`relative flex flex-col h-screen sticky top-0 transition-all duration-300 flex-shrink-0 ${collapsed ? 'w-20' : 'w-64'}`}>
      <div className="absolute inset-0 border-r border-[var(--border)] bg-[var(--bg-secondary)] rounded-r-2xl shadow-sm" />
      <div className="relative flex flex-col h-full z-10">
        <div className="p-5 border-b border-[var(--border)] flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center flex-shrink-0 shadow-md">
            <span className="text-white font-bold text-lg">S</span>
          </div>
          {!collapsed && (
            <div className="overflow-hidden">
              <h1 className="text-lg font-bold text-[var(--text-primary)]">SmartVentas</h1>
              <p className="text-[10px] text-[var(--text-muted)] tracking-wider uppercase">Panel de Administracion</p>
            </div>
          )}
        </div>

        <nav className="flex-1 p-3 space-y-1 overflow-hidden">
          {navItems.map((item) => {
            const active = pathname === item.href;
            const Icon = item.icon;
            return (
              <Link
                key={item.href}
                href={item.href}
                className={`flex items-center gap-3 px-4 py-2.5 rounded-xl text-sm transition-all duration-200 group ${
                  active
                    ? 'bg-blue-50 text-blue-700 dark:bg-blue-500/10 dark:text-blue-400 font-medium'
                    : 'text-[var(--text-secondary)] hover:bg-[var(--bg-tertiary)] hover:text-[var(--text-primary)]'
                }`}
              >
                <Icon size={20} className={`flex-shrink-0 ${active ? 'text-blue-600 dark:text-blue-400' : ''}`} />
                {!collapsed && <span>{item.label}</span>}
              </Link>
            );
          })}
        </nav>

        <div className="p-3 border-t border-[var(--border)] space-y-1">
          <button
            onClick={toggle}
            className="flex items-center gap-3 px-4 py-2.5 rounded-xl text-sm w-full text-[var(--text-secondary)] hover:bg-[var(--bg-tertiary)] hover:text-[var(--text-primary)] transition-all group"
          >
            {theme === 'dark' ? <Sun size={20} className="flex-shrink-0" /> : <Moon size={20} className="flex-shrink-0" />}
            {!collapsed && <span>{theme === 'dark' ? 'Modo claro' : 'Modo oscuro'}</span>}
          </button>

          <button
            onClick={handleLogout}
            disabled={loggingOut}
            className="flex items-center gap-3 px-4 py-2.5 rounded-xl text-sm w-full text-[var(--text-secondary)] hover:bg-red-50 hover:text-red-600 dark:hover:bg-red-500/10 dark:hover:text-red-400 transition-all disabled:opacity-50 group"
          >
            <LogOut size={20} className="flex-shrink-0" />
            {!collapsed && <span>{loggingOut ? 'Cerrando sesion...' : 'Cerrar sesion'}</span>}
          </button>

          {!collapsed && (
            <div className="px-4 py-2 text-xs text-[var(--text-muted)]">SmartVentas v1.2.0</div>
          )}

          <button
            onClick={() => setCollapsed(!collapsed)}
            className="flex items-center justify-center px-4 py-2 rounded-xl text-sm w-full text-[var(--text-muted)] hover:bg-[var(--bg-tertiary)] transition-all"
          >
            {collapsed ? <ChevronRight size={16} /> : <ChevronLeft size={16} />}
          </button>
        </div>
      </div>
    </aside>
  );
}
