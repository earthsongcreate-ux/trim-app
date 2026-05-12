"use client";

import React from "react";
import Link from "next/link";
import { ChevronRight } from "lucide-react";
import { motion } from "framer-motion";
import DeviceButtons from "./DeviceButtons";

export default function Hero() {
  return (
    <section className="relative pt-32 pb-20 md:pt-48 md:pb-32 px-6 md:px-12 overflow-hidden">
      {/* Background glow effects */}
      <div className="absolute top-1/4 -left-20 w-96 h-96 bg-trim-green/10 rounded-full blur-[120px]" />
      <div className="absolute bottom-1/4 -right-20 w-96 h-96 bg-blue-500/10 rounded-full blur-[120px]" />

      <div className="max-w-7xl mx-auto grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
        >
          <h1 className="text-5xl md:text-7xl font-bold leading-tight mb-6 text-gradient">
            Stop wasting money on subscriptions.
          </h1>
          <p className="text-xl text-gray-400 mb-10 max-w-lg leading-relaxed">
            Trim finds, tracks, and cancels what you don’t need. Reclaim your financial freedom in seconds.
          </p>
          
          <DeviceButtons />

          <a
            href="#how-it-works"
            className="inline-flex items-center gap-2 mt-10 text-trim-green font-medium group hover:text-white transition-all duration-300"
          >
            <span className="group-hover:drop-shadow-[0_0_12px_rgba(110,196,153,0.25)] transition-all">
              See how it works
            </span>
            <ChevronRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
          </a>
        </motion.div>

        <motion.div 
          initial={{ opacity: 0, scale: 0.9, rotateY: -10 }}
          animate={{ opacity: 1, scale: 1, rotateY: 0 }}
          transition={{ duration: 1, ease: "easeOut" }}
          className="relative flex justify-center lg:justify-end"
        >
          <motion.div 
            animate={{ y: [0, -15, 0] }}
            transition={{ 
              duration: 6, 
              repeat: Infinity, 
              ease: "easeInOut" 
            }}
            className="relative w-full max-w-[500px]"
          >
             {/* Ambient soft glow behind phone */}
            <div className="absolute inset-0 bg-trim-green/20 blur-[100px] rounded-full" />
            <div className="relative z-10 glass-card p-2 md:p-4 rotate-3 hover:rotate-0 transition-all duration-500 hover:shadow-[0_0_50px_rgba(110,196,153,0.2)]">
              <img
                src="/images/hero-mockup.png"
                alt="Trim App Dashboard"
                width={500}
                height={1000}
                className="rounded-xl shadow-2xl"
                loading="eager"
                fetchPriority="high"
              />
            </div>
          </motion.div>
        </motion.div>
      </div>
    </section>
  );
}
