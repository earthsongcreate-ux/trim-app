"use client";

import React, { useEffect, useState } from "react";
import { Apple, PlayCircle } from "lucide-react";

export default function DeviceButtons() {
  const [device, setDevice] = useState<"ios" | "android" | "desktop">("desktop");

  useEffect(() => {
    const ua = navigator.userAgent.toLowerCase();
    if (ua.indexOf("iphone") > -1 || ua.indexOf("ipad") > -1) {
      setDevice("ios");
    } else if (ua.indexOf("android") > -1) {
      setDevice("android");
    }
  }, []);

  return (
    <div className="flex flex-col sm:flex-row items-center gap-4">
      {(device === "ios" || device === "desktop") && (
        <button className="flex items-center justify-center gap-3 h-16 px-8 bg-white/5 border-2 border-white/20 rounded-2xl font-bold hover:bg-white/10 hover:border-white/30 transition-all duration-300 min-w-[200px] group">
          <Apple className="w-7 h-7 fill-white text-white group-hover:scale-110 transition-transform" />
          <div className="text-left">
            <p className="text-[10px] uppercase tracking-[0.1em] leading-none text-gray-400 mb-1">Download on the</p>
            <p className="text-lg leading-tight text-white font-semibold">App Store</p>
          </div>
        </button>
      )}
      {(device === "android" || device === "desktop") && (
        <button className="flex items-center justify-center gap-3 h-16 px-8 bg-white/5 border-2 border-white/20 rounded-2xl font-bold hover:bg-white/10 hover:border-white/30 transition-all duration-300 min-w-[200px] group">
          <PlayCircle className="w-7 h-7 text-white fill-white/10 group-hover:scale-110 transition-transform" />
          <div className="text-left">
            <p className="text-[10px] uppercase tracking-[0.1em] leading-none text-gray-400 mb-1">Get it on</p>
            <p className="text-lg leading-tight text-white font-semibold">Google Play</p>
          </div>
        </button>
      )}
    </div>
  );
}
