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
    <div className="flex flex-col sm:flex-row gap-4">
      {(device === "ios" || device === "desktop") && (
        <button className="flex items-center justify-center gap-2 px-8 py-4 bg-white text-background rounded-2xl font-bold hover:scale-105 transition-transform">
          <Apple className="w-6 h-6 fill-current" />
          <div className="text-left">
            <p className="text-[10px] uppercase leading-none opacity-70">Download on the</p>
            <p className="text-lg leading-tight">App Store</p>
          </div>
        </button>
      )}
      {(device === "android" || device === "desktop") && (
        <button className={`flex items-center justify-center gap-2 px-8 py-4 rounded-2xl font-bold transition-all ${device === 'android' ? 'bg-white text-background' : 'bg-background border border-white/10 hover:bg-white/5'}`}>
          <PlayCircle className="w-6 h-6" />
          <div className="text-left">
            <p className="text-[10px] uppercase leading-none opacity-70">Get it on</p>
            <p className="text-lg leading-tight">Google Play</p>
          </div>
        </button>
      )}
    </div>
  );
}
