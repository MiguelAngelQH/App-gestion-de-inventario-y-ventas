import type { Metadata } from "next";
import "./globals.css";
import Sidebar from "@/components/Sidebar";
import { ThemeProvider } from "@/lib/ThemeProvider";
import GradientOrbs from "@/components/GradientOrbs";
import { ToastProvider } from "@/components/Toast";

export const metadata: Metadata = {
  title: "SmartVentas - Gestion inteligente para tu negocio",
  description: "App movil y panel web para gestionar inventario, ventas, compras, cuentas por cobrar/pagar y reportes. Todo sincronizado en la nube.",
  icons: {
    icon: '/smartventas-favicon.svg',
    apple: '/smartventas-favicon.svg',
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="es" className="h-full">
      <body className="h-full flex">
        <ThemeProvider>
          <ToastProvider>
            <GradientOrbs />
            <Sidebar />
            <main className="flex-1 overflow-auto p-6 lg:p-8 relative z-10">
              {children}
            </main>
          </ToastProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}
