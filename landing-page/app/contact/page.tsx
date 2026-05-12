import Link from "next/link";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import { Mail } from "lucide-react";

export default function ContactPage() {
  return (
    <main>
      <Navbar />

      <section className="pt-28 md:pt-32 pb-16 md:pb-24 px-6 md:px-12">
        <div className="max-w-4xl mx-auto">
          <div className="glass-card p-8 md:p-12 text-center">
            <div className="mx-auto w-16 h-16 rounded-2xl bg-trim-green/10 flex items-center justify-center mb-6">
              <Mail className="w-8 h-8 text-trim-green" />
            </div>
            <h1 className="text-3xl md:text-5xl font-bold tracking-tight">Contact</h1>
            <p className="mt-4 text-gray-400 text-base md:text-lg max-w-2xl mx-auto leading-relaxed">
              Email us and we’ll get back to you within 24–48 business hours.
            </p>

            <div className="mt-10 flex flex-col sm:flex-row items-center justify-center gap-3">
              <a
                href="mailto:support@trimapp.co"
                className="px-6 py-3 rounded-xl bg-trim-green text-background text-sm font-bold neon-glow text-center"
              >
                Email support@trimapp.co
              </a>
              <Link
                href="/"
                className="px-6 py-3 rounded-xl border border-white/10 bg-white/5 text-sm font-bold text-white text-center hover:bg-white/10 transition-colors"
              >
                Back to Home
              </Link>
            </div>
          </div>
        </div>
      </section>

      <Footer />
    </main>
  );
}
