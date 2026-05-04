"use client";

import React from "react";
import Image from "next/image";
import { motion } from "framer-motion";

const screens = [
  { title: "Dashboard", img: "/images/preview_1.png" },
  { title: "Insights", img: "/images/preview_2.png" },
  { title: "Savings", img: "/images/preview_3.png" },
];

export default function AppPreview() {
  return (
    <section className="py-24 bg-background overflow-hidden">
      <div className="max-w-7xl mx-auto px-6 md:px-12 mb-16 text-center">
        <motion.h2 
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-3xl md:text-5xl font-bold"
        >
          Experience the future of finance.
        </motion.h2>
      </div>

      <div className="max-w-7xl mx-auto px-6 md:px-12 flex flex-wrap justify-center items-center gap-8 md:gap-12">
        {screens.map((screen, idx) => (
          <motion.div 
            key={idx}
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: idx * 0.1, duration: 0.6 }}
            whileHover={{ y: -6 }}
            className="w-full sm:w-[300px] md:w-[340px]"
          >
            <div className="p-2 md:p-3 mb-6 group relative overflow-hidden transition-all duration-500 rounded-2xl bg-[rgba(255,255,255,0.03)] border border-[rgba(255,255,255,0.06)] backdrop-blur-md shadow-[0_10px_40px_rgba(0,0,0,0.4)] hover:shadow-[0_0_40px_rgba(110,196,153,0.15)] hover:border-trim-green/30">
              <div className="aspect-[9/18] relative overflow-hidden rounded-xl bg-transparent">
                <Image 
                  src={screen.img} 
                  alt={screen.title} 
                  fill
                  className="object-cover group-hover:scale-105 transition-transform duration-700 ease-out"
                />
              </div>
            </div>
            <h3 className="text-xl font-bold text-center text-gray-200 group-hover:text-white transition-colors">{screen.title}</h3>
          </motion.div>
        ))}
      </div>
      
      <style jsx>{`
        .no-scrollbar::-webkit-scrollbar {
          display: none;
        }
        .no-scrollbar {
          -ms-overflow-style: none;
          scrollbar-width: none;
        }
      `}</style>
    </section>
  );
}
