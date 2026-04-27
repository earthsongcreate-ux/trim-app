"use client";

import React, { useEffect, useState, useRef } from "react";
import { motion, useInView, useSpring, useTransform } from "framer-motion";

function Counter({ value }: { value: number }) {
  const [displayValue, setDisplayValue] = useState(0);
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true });
  
  const springValue = useSpring(0, { stiffness: 50, damping: 30 });
  
  useEffect(() => {
    if (isInView) {
      springValue.set(value);
    }
  }, [isInView, value, springValue]);

  useEffect(() => {
    return springValue.on("change", (latest) => {
      setDisplayValue(Math.floor(latest));
    });
  }, [springValue]);

  return <span ref={ref}>${displayValue.toLocaleString()}</span>;
}

export default function SavingsImpact() {
  return (
    <section className="py-24 px-6 md:px-12 bg-trim-dark relative overflow-hidden">
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-trim-green/5 rounded-full blur-[150px] -z-10" />
      
      <div className="max-w-4xl mx-auto text-center">
        <h3 className="text-gray-400 font-medium uppercase tracking-widest mb-4">Total Impact</h3>
        <div className="text-7xl md:text-9xl font-bold mb-6 text-gradient flex items-center justify-center gap-2">
          <Counter value={482} />
        </div>
        <p className="text-2xl md:text-3xl font-light text-white/80 mb-12">
          Average saved per user this year.
        </p>
        
        <div className="relative w-48 h-48 mx-auto mb-12">
          <svg className="w-full h-full" viewBox="0 0 100 100">
            <circle 
              cx="50" cy="50" r="45" 
              fill="none" stroke="currentColor" strokeWidth="2" 
              className="text-white/5"
            />
            <motion.circle 
              cx="50" cy="50" r="45" 
              fill="none" stroke="currentColor" strokeWidth="4" 
              strokeDasharray="283"
              initial={{ strokeDashoffset: 283 }}
              whileInView={{ strokeDashoffset: 283 - (283 * 0.68) }}
              transition={{ duration: 2, ease: "easeOut" }}
              className="text-trim-green drop-shadow-[0_0_8px_rgba(74,222,128,0.5)]"
              strokeLinecap="round"
            />
          </svg>
          <div className="absolute inset-0 flex items-center justify-center flex-col">
            <span className="text-4xl font-bold">68%</span>
            <span className="text-[10px] text-gray-400 uppercase">Growth</span>
          </div>
        </div>

        <p className="text-gray-500 italic">"Real users. Real savings. Join 50,000+ others today."</p>
      </div>
    </section>
  );
}
