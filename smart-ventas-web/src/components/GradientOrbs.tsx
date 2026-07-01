'use client';

import { useEffect, useRef } from 'react';

interface Orb {
  x: number;
  y: number;
  vx: number;
  vy: number;
  radius: number;
  color: string;
}

export default function GradientOrbs() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const mouseRef = useRef({ x: -1000, y: -1000 });
  const orbsRef = useRef<Orb[]>([]);
  const animRef = useRef<number>(0);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const resize = () => {
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
    };
    resize();
    window.addEventListener('resize', resize);

    orbsRef.current = [
      { x: 0.2, y: 0.3, vx: 0.003, vy: 0.002, radius: 320, color: 'rgba(0,137,123,' },
      { x: 0.7, y: 0.2, vx: -0.002, vy: 0.003, radius: 280, color: 'rgba(21,101,192,' },
      { x: 0.5, y: 0.7, vx: 0.002, vy: -0.002, radius: 350, color: 'rgba(255,143,0,' },
      { x: 0.85, y: 0.6, vx: -0.003, vy: -0.001, radius: 250, color: 'rgba(0,137,123,' },
    ];

    const onMouse = (e: MouseEvent) => {
      mouseRef.current = { x: e.clientX / canvas.width, y: e.clientY / canvas.height };
    };
    const onLeave = () => {
      mouseRef.current = { x: -1000, y: -1000 };
    };
    window.addEventListener('mousemove', onMouse);
    window.addEventListener('mouseleave', onLeave);

    const animate = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      const w = canvas.width;
      const h = canvas.height;
      const mouse = mouseRef.current;

      if (mouse.x > 0) {
        orbsRef.current[0].x += (mouse.x * 0.5 + 0.15 - orbsRef.current[0].x) * 0.003;
        orbsRef.current[0].y += (mouse.y * 0.4 + 0.2 - orbsRef.current[0].y) * 0.003;
      }

      orbsRef.current.forEach((orb) => {
        orb.x += orb.vx;
        orb.y += orb.vy;

        if (orb.x < -0.1 || orb.x > 1.1) orb.vx *= -1;
        if (orb.y < -0.1 || orb.y > 1.1) orb.vy *= -1;

        const cx = (orb.x + (mouse.x > 0 ? (mouse.x - 0.5) * 0.08 : 0)) * w;
        const cy = orb.y * h;
        const r = Math.min(w, h) * 0.35;

        const grad = ctx.createRadialGradient(cx, cy, 0, cx, cy, r);
        grad.addColorStop(0, orb.color + '0.35)');
        grad.addColorStop(0.5, orb.color + '0.15)');
        grad.addColorStop(1, orb.color + '0)');
        ctx.fillStyle = grad;
        ctx.fillRect(0, 0, w, h);
      });

      animRef.current = requestAnimationFrame(animate);
    };
    animate();

    return () => {
      cancelAnimationFrame(animRef.current);
      window.removeEventListener('resize', resize);
      window.removeEventListener('mousemove', onMouse);
      window.removeEventListener('mouseleave', onLeave);
    };
  }, []);

  return (
    <canvas
      ref={canvasRef}
      className="fixed inset-0 pointer-events-none"
      style={{ zIndex: 0 }}
    />
  );
}
