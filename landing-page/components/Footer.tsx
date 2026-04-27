"use client";

import React from "react";
import Link from "next/link";
import { Zap, Mail } from "lucide-react";

export default function Footer() {
  return (
    <footer className="bg-background pt-20 pb-10 px-6 md:px-12 border-t border-white/5">
      <div className="max-w-7xl mx-auto grid grid-cols-1 md:grid-cols-4 gap-12 mb-16">
        <div className="col-span-1 md:col-span-2">
          <Link href="/" className="flex items-center gap-2 mb-6">
            <div className="w-8 h-8 bg-trim-green rounded-lg flex items-center justify-center">
              <Zap className="text-background w-5 h-5 fill-current" />
            </div>
            <span className="text-xl font-bold">Trim</span>
          </Link>
          <p className="text-gray-400 max-w-sm mb-6">
            The world's first AI-powered subscription manager and automated savings engine.
          </p>
          <div className="flex items-center gap-2 text-trim-green">
            <Mail className="w-5 h-5" />
            <a href="mailto:support@trimapp.co" className="hover:underline">support@trimapp.co</a>
          </div>
        </div>

        <div>
          <h4 className="font-bold mb-6">Product</h4>
          <ul className="space-y-4 text-gray-400">
            <li><Link href="#features" className="hover:text-white transition-colors">Features</Link></li>
            <li><Link href="#how-it-works" className="hover:text-white transition-colors">How it works</Link></li>
            <li><Link href="/contact" className="hover:text-white transition-colors">Contact</Link></li>
          </ul>
        </div>

        <div>
          <h4 className="font-bold mb-6">Legal</h4>
          <ul className="space-y-4 text-gray-400">
            <li><Link href="/privacy" className="hover:text-white transition-colors">Privacy Policy</Link></li>
            <li><Link href="/terms" className="hover:text-white transition-colors">Terms of Service</Link></li>
          </ul>
        </div>
      </div>

      <div className="max-w-7xl mx-auto pt-10 border-t border-white/5 flex flex-col md:row items-center justify-between gap-6 text-sm text-gray-500">
        <p>© 2024 Trim Financial Inc. All rights reserved.</p>
        <div className="flex gap-8">
          <a href="#" className="hover:text-white transition-colors">Twitter</a>
          <a href="#" className="hover:text-white transition-colors">Instagram</a>
          <a href="#" className="hover:text-white transition-colors">LinkedIn</a>
        </div>
      </div>
    </footer>
  );
}
