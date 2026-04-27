"use client";

import React from "react";
import Link from "next/link";
import { Zap } from "lucide-react";

export default function Navbar() {
  return (
    <nav className="fixed top-0 left-0 right-0 z-50 flex items-center justify-between px-6 py-4 md:px-12 glass border-none bg-background/50 backdrop-blur-md">
      <Link href="/" className="flex items-center gap-2">
        <div className="w-8 h-8 bg-trim-green rounded-lg flex items-center justify-center shadow-[0_0_15px_rgba(74,222,128,0.5)]">
          <Zap className="text-background w-5 h-5 fill-current" />
        </div>
        <span className="text-xl font-bold tracking-tight">Trim</span>
      </Link>
      
      <div className="hidden md:flex items-center gap-8 text-sm font-medium text-gray-400">
        <Link href="#features" className="hover:text-white transition-colors">Features</Link>
        <Link href="#how-it-works" className="hover:text-white transition-colors">How it works</Link>
        <Link href="/contact" className="hover:text-white transition-colors">Support</Link>
      </div>

      <Link href="#download" className="px-5 py-2.5 rounded-full bg-trim-green text-background text-sm font-bold neon-glow">
        Download App
      </Link>
    </nav>
  );
}
