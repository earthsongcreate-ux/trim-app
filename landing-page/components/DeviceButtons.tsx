import React from "react";
import { Apple, PlayCircle } from "lucide-react";

export default function DeviceButtons() {
  return (
    <div className="flex flex-col sm:flex-row items-center gap-4">
      <a
        href="https://apps.apple.com/"
        target="_blank"
        rel="noopener noreferrer"
        className="flex items-center justify-center gap-3 h-16 px-8 bg-white/5 border-2 border-white/20 rounded-2xl font-bold hover:bg-white/10 hover:border-white/30 transition-all duration-300 min-w-[200px] group"
      >
        <Apple className="w-7 h-7 fill-white text-white group-hover:scale-110 transition-transform" />
        <div className="text-left">
          <p className="text-[10px] uppercase tracking-[0.1em] leading-none text-gray-400 mb-1">Download on the</p>
          <p className="text-lg leading-tight text-white font-semibold">App Store</p>
        </div>
      </a>
      <a
        href="https://play.google.com/store"
        target="_blank"
        rel="noopener noreferrer"
        className="flex items-center justify-center gap-3 h-16 px-8 bg-white/5 border-2 border-white/20 rounded-2xl font-bold hover:bg-white/10 hover:border-white/30 transition-all duration-300 min-w-[200px] group"
      >
        <PlayCircle className="w-7 h-7 text-white fill-white/10 group-hover:scale-110 transition-transform" />
        <div className="text-left">
          <p className="text-[10px] uppercase tracking-[0.1em] leading-none text-gray-400 mb-1">Get it on</p>
          <p className="text-lg leading-tight text-white font-semibold">Google Play</p>
        </div>
      </a>
    </div>
  );
}
