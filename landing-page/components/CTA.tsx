"use client";

import React from "react";
import { motion } from "framer-motion";
import DeviceButtons from "./DeviceButtons";

export default function CTA() {
  return (
    <section id="download" className="py-24 px-6 md:px-12">
      <div className="max-w-6xl mx-auto glass-card bg-trim-green/10 p-12 md:p-20 text-center relative overflow-hidden">
        <div className="absolute -top-24 -left-24 w-64 h-64 bg-trim-green/20 rounded-full blur-[100px]" />
        <div className="absolute -bottom-24 -right-24 w-64 h-64 bg-trim-green/20 rounded-full blur-[100px]" />
        
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
        >
          <h2 className="text-4xl md:text-6xl font-bold mb-8">Start saving in under 60 seconds.</h2>
          <p className="text-xl text-gray-300 mb-12 max-w-2xl mx-auto leading-relaxed">
            Join thousands of users who have reclaimed their subscriptions and optimized their bills.
          </p>

          <div className="flex justify-center">
            <DeviceButtons />
          </div>
        </motion.div>
      </div>
    </section>
  );
}
