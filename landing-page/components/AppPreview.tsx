"use client";

import React from "react";
import Image from "next/image";
import { motion } from "framer-motion";

const screens = [
  { title: "Dashboard", img: "/images/preview-1.png" },
  { title: "Insights", img: "/images/preview-2.png" },
  { title: "Savings", img: "/images/hero-mockup.png" },
];

export default function AppPreview() {
  return (
    <section className="py-24 bg-background overflow-hidden">
      <div className="max-w-7xl mx-auto px-6 md:px-12 mb-12">
        <h2 className="text-3xl md:text-5xl font-bold">Experience the future of finance.</h2>
      </div>

      <div className="flex overflow-x-auto pb-12 gap-8 px-6 md:px-12 no-scrollbar">
        {screens.map((screen, idx) => (
          <motion.div 
            key={idx}
            initial={{ opacity: 0, x: 50 }}
            whileInView={{ opacity: 1, x: 0 }}
            transition={{ delay: idx * 0.2 }}
            className="flex-none w-[280px] md:w-[350px]"
          >
            <div className="glass-card p-3 md:p-5 mb-4 group overflow-hidden">
              <Image 
                src={screen.img} 
                alt={screen.title} 
                width={350} 
                height={700}
                className="rounded-xl group-hover:scale-105 transition-transform duration-500"
              />
            </div>
            <h3 className="text-xl font-bold px-2">{screen.title}</h3>
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
