'use client';

import { useEffect, useState } from 'react';
import { motion, useScroll, useTransform } from 'framer-motion';
import { Package, DollarSign, ArrowDownToLine, BarChart3, TrendingUp, Users, Building2, Bell, Sun, Scan, Smartphone, Shield, ExternalLink, Download, ChevronRight } from 'lucide-react';

const features = [
  { icon: Package, title: 'Inventario Inteligente', desc: 'Gestiona tu stock con escaneo de codigo de barras, control de minimos y alertas automaticas.' },
  { icon: DollarSign, title: 'Registro de Ventas', desc: 'Crea ventas al instante, selecciona productos, calcula totales y elige metodo de pago.' },
  { icon: ArrowDownToLine, title: 'Control de Compras', desc: 'Registra compras, actualiza costos automaticamente y mantén el historial de abastecimiento.' },
  { icon: Users, title: 'Cuentas por Cobrar', desc: 'Lleva el control de deudas de clientes, registra pagos parciales y vencecimientos.' },
  { icon: Building2, title: 'Cuentas por Pagar', desc: 'Administra saldos con proveedores, programa pagos y evita moras.' },
  { icon: BarChart3, title: 'Reportes y Metricas', desc: 'Graficos interactivos, top productos, ventas por categoria y análisis de ganancias.' },
  { icon: TrendingUp, title: 'Dashboard en Tiempo Real', desc: 'Ventas del dia, semana, ganancias totales y alertas de stock bajo en un vistazo.' },
  { icon: Sun, title: 'Modo Oscuro', desc: 'Interfaz adaptable con tema claro/oscuro para mayor comodidad visual.' },
  { icon: Bell, title: 'Notificaciones Push', desc: 'Recibe alertas cuando el stock esta bajo o los pagos se acercan a su vencimiento.' },
  { icon: Scan, title: 'Escaneo de Codigos', desc: 'Agrega productos rapidamente escaneando codigos de barras con tu camara.' },
  { icon: Shield, title: 'Seguro y Multi-usuario', desc: 'Cada usuario ve solo sus datos. Autenticacion segura con Firebase.' },
  { icon: Smartphone, title: 'App Movil + Web', desc: 'Gestiona desde tu telefono con la app Flutter o desde tu PC con el panel web.' },
];

const screens = [
  { name: 'Dashboard', color: 'from-emerald-500 to-teal-600', icon: TrendingUp, desc: 'Metricas en tiempo real' },
  { name: 'Inventario', color: 'from-blue-500 to-indigo-600', icon: Package, desc: 'Control de productos' },
  { name: 'Ventas', color: 'from-amber-500 to-orange-600', icon: DollarSign, desc: 'Registro de ventas' },
  { name: 'Reportes', color: 'from-purple-500 to-violet-600', icon: BarChart3, desc: 'Analisis y graficos' },
];

export default function LandingPage() {
  const [scrolled, setScrolled] = useState(0);
  const { scrollYProgress } = useScroll();
  const opacity = useTransform(scrollYProgress, [0, 0.15], [1, 0]);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY);
    window.addEventListener('scroll', onScroll);
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  const scrollTo = (id: string) => {
    document.getElementById(id)?.scrollIntoView({ behavior: 'smooth' });
  };

  return (
    <div className="-m-6 lg:-m-8 min-h-screen bg-[var(--bg-primary)]">
      {/* Navbar */}
      <motion.nav
        initial={{ y: -20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ duration: 0.6 }}
        className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${scrolled > 50 ? 'bg-[var(--bg-secondary)]/80 backdrop-blur-xl border-b border-[var(--border)] shadow-sm' : 'bg-transparent'}`}
      >
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center shadow-md">
                <span className="text-white font-bold text-base">S</span>
              </div>
              <span className="text-lg font-bold text-[var(--text-primary)]">SmartVentas</span>
            </div>
            <div className="flex items-center gap-4">
              <button onClick={() => scrollTo('features')} className="text-sm text-[var(--text-secondary)] hover:text-[var(--text-primary)] transition-colors hidden sm:block">Funciones</button>
              <button onClick={() => scrollTo('screens')} className="text-sm text-[var(--text-secondary)] hover:text-[var(--text-primary)] transition-colors hidden sm:block">App</button>
              <button onClick={() => scrollTo('download')} className="text-sm text-[var(--text-secondary)] hover:text-[var(--text-primary)] transition-colors hidden sm:block">Descargar</button>
              <a
                href="/dashboard"
                className="flex items-center gap-1.5 px-4 py-2 rounded-xl text-sm font-medium bg-gradient-to-r from-blue-600 to-indigo-600 text-white hover:from-blue-700 hover:to-indigo-700 transition-all shadow-lg shadow-blue-500/20"
              >
                <ExternalLink size={15} />
                Panel Admin
              </a>
            </div>
          </div>
        </div>
      </motion.nav>

      {/* Hero */}
      <section className="relative min-h-screen flex items-center justify-center overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-br from-blue-600/10 via-transparent to-indigo-600/10" />
        <div className="absolute inset-0">
          <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-blue-500/20 rounded-full blur-[120px]" />
          <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-indigo-500/20 rounded-full blur-[120px]" />
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-gradient-to-br from-blue-400/5 to-indigo-400/5 rounded-full blur-[100px]" />
        </div>

        <div className="relative z-10 max-w-5xl mx-auto px-4 text-center">
          <motion.div
            initial={{ opacity: 0, y: 40 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.2 }}
          >
            <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-blue-500/10 border border-blue-500/20 text-blue-600 dark:text-blue-400 text-xs font-medium mb-6">
              <TrendingUp size={14} />
              Gestion inteligente para tu negocio
            </div>
          </motion.div>

          <motion.h1
            initial={{ opacity: 0, y: 40 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.4 }}
            className="text-5xl sm:text-6xl lg:text-7xl font-extrabold text-[var(--text-primary)] leading-tight mb-6"
          >
            Controla tu{' '}
            <span className="bg-gradient-to-r from-blue-500 via-indigo-500 to-purple-600 bg-clip-text text-transparent">
              negocio
            </span>
            {' '}desde cualquier lugar
          </motion.h1>

          <motion.p
            initial={{ opacity: 0, y: 40 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.6 }}
            className="text-lg sm:text-xl text-[var(--text-secondary)] max-w-2xl mx-auto mb-10 leading-relaxed"
          >
            Gestiona inventario, ventas, compras, cuentas por cobrar/pagar y genera reportes
            desde tu telefono o computadora. Todo sincronizado en la nube en tiempo real.
          </motion.p>

          <motion.div
            initial={{ opacity: 0, y: 40 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.8 }}
            className="flex flex-col sm:flex-row items-center justify-center gap-4"
          >
            <button onClick={() => scrollTo('download')} className="flex items-center gap-2 px-8 py-3.5 rounded-xl text-base font-semibold bg-gradient-to-r from-blue-600 to-indigo-600 text-white hover:from-blue-700 hover:to-indigo-700 transition-all shadow-xl shadow-blue-500/25 hover:shadow-blue-500/40">
              <Download size={20} />
              Descargar App
            </button>
            <a href="/dashboard" className="flex items-center gap-2 px-8 py-3.5 rounded-xl text-base font-semibold border border-[var(--border)] text-[var(--text-primary)] hover:bg-[var(--bg-tertiary)] transition-all">
              Panel de Administracion
              <ChevronRight size={18} />
            </a>
          </motion.div>
        </div>

        <motion.div style={{ opacity }} className="absolute bottom-8 left-1/2 -translate-x-1/2">
          <motion.div
            animate={{ y: [0, 8, 0] }}
            transition={{ duration: 2, repeat: Infinity }}
            className="flex flex-col items-center gap-2 text-[var(--text-muted)] cursor-pointer"
            onClick={() => scrollTo('features')}
          >
            <span className="text-xs">Descubre mas</span>
            <ChevronRight size={16} className="rotate-90" />
          </motion.div>
        </motion.div>
      </section>

      {/* Features */}
      <section id="features" className="py-24 relative">
        <div className="absolute inset-0 bg-gradient-to-b from-transparent via-blue-500/5 to-transparent" />
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="text-center mb-16"
          >
            <h2 className="text-3xl sm:text-4xl font-bold text-[var(--text-primary)] mb-4">
              Todo lo que necesitas para tu negocio
            </h2>
            <p className="text-lg text-[var(--text-secondary)] max-w-2xl mx-auto">
              Una solucion completa que combina app movil y panel web para gestionar cada aspecto de tu emprendimiento.
            </p>
          </motion.div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {features.map((feature, i) => {
              const Icon = feature.icon;
              return (
                <motion.div
                  key={feature.title}
                  initial={{ opacity: 0, y: 30 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.5, delay: i * 0.05 }}
                  whileHover={{ y: -4 }}
                  className="card p-6 hover:shadow-lg transition-all duration-300 group cursor-default"
                >
                  <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-blue-500/10 to-indigo-500/10 border border-blue-500/20 flex items-center justify-center mb-4 group-hover:scale-110 transition-transform duration-300">
                    <Icon size={24} className="text-blue-600 dark:text-blue-400" />
                  </div>
                  <h3 className="text-lg font-semibold text-[var(--text-primary)] mb-2">{feature.title}</h3>
                  <p className="text-sm text-[var(--text-secondary)] leading-relaxed">{feature.desc}</p>
                </motion.div>
              );
            })}
          </div>
        </div>
      </section>

      {/* App Screens Mockups */}
      <section id="screens" className="py-24 relative">
        <div className="absolute inset-0 bg-gradient-to-b from-transparent via-indigo-500/5 to-transparent" />
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="text-center mb-16"
          >
            <h2 className="text-3xl sm:text-4xl font-bold text-[var(--text-primary)] mb-4">
              App movil inteligente
            </h2>
            <p className="text-lg text-[var(--text-secondary)] max-w-2xl mx-auto">
              Interfaz moderna y facil de usar con Material Design 3, desarrollada en Flutter.
            </p>
          </motion.div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {screens.map((screen, i) => {
              const Icon = screen.icon;
              return (
                <motion.div
                  key={screen.name}
                  initial={{ opacity: 0, y: 30 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.5, delay: i * 0.1 }}
                  className="flex flex-col items-center"
                >
                  {/* Phone frame mockup */}
                  <div className="relative w-48 h-96 rounded-[2rem] border-4 border-[var(--border)] bg-[var(--bg-primary)] shadow-xl overflow-hidden mb-4">
                    {/* Notch */}
                    <div className="absolute top-0 left-1/2 -translate-x-1/2 w-24 h-5 bg-[var(--border)] rounded-b-xl z-10" />
                    {/* Screen content */}
                    <div className="h-full w-full pt-6 pb-4 px-3 flex flex-col">
                      {/* Status bar */}
                      <div className="flex justify-between text-[8px] text-[var(--text-muted)] mb-3 px-1">
                        <span>9:41</span>
                        <span className="flex gap-1">
                          <span className="w-3 h-2 rounded-sm border border-current" />
                          <span className="w-3.5 h-2 rounded-sm border border-current" />
                        </span>
                      </div>
                      {/* Mockup header */}
                      <div className={`h-12 rounded-xl bg-gradient-to-r ${screen.color} mb-3 flex items-center px-3`}>
                        <Icon size={14} className="text-white mr-2" />
                        <span className="text-xs font-semibold text-white">{screen.name}</span>
                      </div>
                      {/* Mockup content */}
                      <div className="flex-1 space-y-2">
                        {[...Array(5)].map((_, j) => (
                          <div key={j} className="flex items-center gap-2">
                            <div className={`w-2 h-2 rounded-full bg-gradient-to-r ${screen.color} opacity-60`} />
                            <div className="flex-1 h-3 rounded bg-[var(--bg-tertiary)]" />
                            <div className="w-8 h-3 rounded bg-[var(--bg-tertiary)]" />
                          </div>
                        ))}
                      </div>
                      {/* Mockup bottom bar */}
                      <div className="flex justify-center gap-4 pt-3 border-t border-[var(--border)]">
                        {[...Array(4)].map((_, j) => (
                          <div key={j} className="w-4 h-1 rounded-full bg-[var(--bg-tertiary)]" />
                        ))}
                      </div>
                    </div>
                  </div>
                  <p className="text-sm font-medium text-[var(--text-primary)]">{screen.name}</p>
                  <p className="text-xs text-[var(--text-muted)]">{screen.desc}</p>
                </motion.div>
              );
            })}
          </div>
        </div>
      </section>

      {/* Download Section */}
      <section id="download" className="py-24 relative">
        <div className="absolute inset-0 bg-gradient-to-b from-transparent via-emerald-500/5 to-transparent" />
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="card p-8 sm:p-12 text-center relative overflow-hidden"
          >
            <div className="absolute top-0 right-0 w-64 h-64 bg-gradient-to-br from-emerald-500/10 to-teal-500/10 rounded-full blur-[80px]" />
            <div className="absolute bottom-0 left-0 w-64 h-64 bg-gradient-to-br from-blue-500/10 to-indigo-500/10 rounded-full blur-[80px]" />

            <div className="relative z-10">
              <motion.div
                initial={{ scale: 0 }}
                whileInView={{ scale: 1 }}
                viewport={{ once: true }}
                transition={{ type: 'spring', stiffness: 200, delay: 0.2 }}
                className="w-16 h-16 rounded-2xl bg-gradient-to-br from-emerald-500 to-teal-600 flex items-center justify-center mx-auto mb-6 shadow-lg shadow-emerald-500/20"
              >
                <Smartphone size={32} className="text-white" />
              </motion.div>

              <h2 className="text-3xl sm:text-4xl font-bold text-[var(--text-primary)] mb-4">
                Descarga la App
              </h2>
              <p className="text-lg text-[var(--text-secondary)] max-w-xl mx-auto mb-8">
                Disponible para Android y proximamente para iOS. Lleva tu negocio en el bolsillo.
              </p>

              <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
                <motion.a
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                  href="#"
                  className="flex items-center gap-3 px-8 py-4 rounded-xl bg-[var(--text-primary)] text-[var(--bg-primary)] hover:opacity-90 transition-all font-semibold shadow-xl"
                >
                  <svg viewBox="0 0 24 24" fill="currentColor" className="w-6 h-6"><path d="M3 20.5V3.5c0-.67.34-1.26.87-1.63L14.69 12 .87 22.13C.34 21.76 0 21.17 0 20.5zM21.63 12.63c.24-.34.37-.76.37-1.13 0-.37-.13-.79-.37-1.13L17.25 7.5 14.69 12l2.56 4.5 4.38-3.87zM4.5 20.5l10.25-7.5L4.5 5.5v5.25L10 12l-5.5 1.25v5.25z"/></svg>
                  <div className="text-left">
                    <div className="text-xs opacity-80">Disponible en</div>
                    <div className="text-base font-bold">Google Play</div>
                  </div>
                </motion.a>

                <motion.a
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                  href="#"
                  className="flex items-center gap-3 px-8 py-4 rounded-xl border-2 border-[var(--border)] border-dashed text-[var(--text-muted)] hover:text-[var(--text-primary)] hover:border-[var(--text-muted)] transition-all cursor-not-allowed opacity-60"
                >
                  <svg viewBox="0 0 24 24" fill="currentColor" className="w-6 h-6"><path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z"/></svg>
                  <div className="text-left">
                    <div className="text-xs opacity-80">Proximamente</div>
                    <div className="text-base font-bold">App Store</div>
                  </div>
                </motion.a>
              </div>

              <div className="mt-10 pt-8 border-t border-[var(--border)]">
                <p className="text-sm text-[var(--text-secondary)] mb-4">¿Ya tienes cuenta?</p>
                <a
                  href="/dashboard"
                  className="inline-flex items-center gap-2 px-6 py-3 rounded-xl text-sm font-medium bg-gradient-to-r from-blue-600 to-indigo-600 text-white hover:from-blue-700 hover:to-indigo-700 transition-all shadow-lg shadow-blue-500/20"
                >
                  <ExternalLink size={16} />
                  Ir al Panel de Administracion
                </a>
              </div>
            </div>
          </motion.div>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-8 border-t border-[var(--border)]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex flex-col sm:flex-row items-center justify-between gap-4">
            <div className="flex items-center gap-2 text-sm text-[var(--text-muted)]">
              <div className="w-6 h-6 rounded-lg bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center">
                <span className="text-white font-bold text-xs">S</span>
              </div>
              SmartVentas v1.2.0
            </div>
            <div className="flex items-center gap-6 text-sm text-[var(--text-muted)]">
              <span>© 2026 SmartVentas</span>
              <span>Hecho con Flutter & Next.js</span>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}