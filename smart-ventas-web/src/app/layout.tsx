import type { Metadata } from "next";
import "./globals.css";
import Sidebar from "@/components/Sidebar";
import { ThemeProvider } from "@/lib/ThemeProvider";
import ParticleBackground from "@/components/ParticleBackground";
import { ToastProvider } from "@/components/Toast";

export const metadata: Metadata = {
  title: "SmartVentas - Panel de Administracion",
  description: "Panel de administracion para SmartVentas",
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
            <ParticleBackground />
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
