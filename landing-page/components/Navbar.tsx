"use client";

import React from "react";
import Link from "next/link";
import { Zap } from "lucide-react";

export default function Navbar() {
  return (
    <nav className="fixed top-0 left-0 right-0 z-50 flex items-center justify-between px-6 py-4 md:px-12 glass border-none bg-background/50 backdrop-blur-md">
      <Link href="/" className="flex items-center gap-3">
        <img 
          src="/images/logo.png" 
          alt="Trim Logo" 
          className="h-8 w-auto object-contain"
        />
      </Link>
      
      <div className="hidden md:flex items-center gap-8 text-sm font-medium text-gray-400">
        <Link href="/#features" className="hover:text-white transition-colors">Features</Link>
        <Link href="/#how-it-works" className="hover:text-white transition-colors">How it works</Link>
        <Link href="/support" className="hover:text-white transition-colors">Support</Link>
      </div>

      <Link href="#download" className="px-5 py-2.5 rounded-full bg-trim-green text-background text-sm font-bold neon-glow">
        Download App
      </Link>
    </nav>
  );
}
