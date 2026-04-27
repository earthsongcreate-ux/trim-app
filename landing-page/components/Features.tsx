"use client";

import React from "react";
import { Search, Scissors, LayoutDashboard, HeartPulse } from "lucide-react";
import { motion } from "framer-motion";

const features = [
  {
    icon: <Search className="w-8 h-8 text-trim-green" />,
    title: "Subscription Detection",
    description: "Our AI scans your accounts to find every recurring charge, even hidden ones."
  },
  {
    icon: <Scissors className="w-8 h-8 text-trim-green" />,
    title: "Bill Negotiation",
    description: "Don't overpay. We negotiate your bills to get you the lowest possible rate automatically."
  },
  {
    icon: <LayoutDashboard className="w-8 h-8 text-trim-green" />,
    title: "Savings Dashboard",
    description: "Track every dollar saved and see your financial health improve in real-time."
  },
  {
    icon: <HeartPulse className="w-8 h-8 text-trim-green" />,
    title: "Financial Health Score",
    description: "Get a personalized score based on your spending habits and savings potential."
  }
];

export default function Features() {
  return (
    <section id="features" className="py-24 px-6 md:px-12 bg-background">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-16">
          <h2 className="text-3xl md:text-5xl font-bold mb-4">Smart tools for smart saving.</h2>
          <p className="text-gray-400 max-w-2xl mx-auto text-lg">
            Powerful features designed to put money back in your pocket without you lifting a finger.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
          {features.map((feature, idx) => (
            <motion.div 
              key={idx}
              whileHover={{ y: -10 }}
              className="glass-card p-8 group hover:bg-white/[0.07] transition-all duration-300"
            >
              <div className="mb-6 w-14 h-14 rounded-2xl bg-trim-green/10 flex items-center justify-center group-hover:scale-110 transition-transform">
                {feature.icon}
              </div>
              <h3 className="text-xl font-bold mb-3">{feature.title}</h3>
              <p className="text-gray-400 leading-relaxed text-sm">
                {feature.description}
              </p>
              <div className="mt-6 w-full h-1 bg-white/5 rounded-full overflow-hidden">
                <div className="h-full bg-trim-green w-0 group-hover:w-full transition-all duration-700 delay-100" />
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}
