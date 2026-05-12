import Link from "next/link";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import { Mail, Clock, HelpCircle } from "lucide-react";

const faqs = [
  {
    q: "How do I cancel my subscription?",
    a: "You can manage or cancel your subscription anytime through your Apple App Store account settings.",
  },
  {
    q: "How do I delete my account?",
    a: "Open Trim → Settings → Delete Account.",
  },
  {
    q: "Is my financial data secure?",
    a: "We use industry-standard security practices and trusted providers to protect your information.",
  },
  {
    q: "I found a bug. What should I do?",
    a: "Email support@trimapp.co with details, device type, and screenshots if possible.",
  },
  {
    q: "Do you offer refunds?",
    a: "All subscription billing is handled through Apple and subject to their refund policies.",
  },
];

export default function SupportPage() {
  return (
    <main>
      <Navbar />

      <section className="pt-28 md:pt-32 pb-16 md:pb-24 px-6 md:px-12">
        <div className="max-w-5xl mx-auto">
          <div className="glass-card p-8 md:p-12">
            <div className="inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/5 px-4 py-2 text-sm text-gray-300">
              <HelpCircle className="w-4 h-4 text-trim-green" />
              Support
            </div>

            <h1 className="mt-6 text-3xl md:text-5xl font-bold tracking-tight">
              Need Help? We’ve Got You.
            </h1>
            <p className="mt-4 text-gray-400 text-base md:text-lg max-w-2xl leading-relaxed">
              Questions, billing help, technical issues, or feedback — we’re here to help.
            </p>

            <div className="mt-8 flex flex-col sm:flex-row gap-3">
              <Link
                href="#faq"
                className="px-6 py-3 rounded-xl bg-trim-green text-background text-sm font-bold neon-glow text-center"
              >
                Browse FAQs
              </Link>
              <a
                href="mailto:support@trimapp.co"
                className="px-6 py-3 rounded-xl border border-white/10 bg-white/5 text-sm font-bold text-white text-center hover:bg-white/10 transition-colors"
              >
                Email Support
              </a>
            </div>
          </div>

          <div className="mt-10 md:mt-14 grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="glass-card p-7 md:p-8">
              <div className="flex items-center gap-3">
                <div className="w-11 h-11 rounded-xl bg-trim-green/10 flex items-center justify-center">
                  <Mail className="w-5 h-5 text-trim-green" />
                </div>
                <h2 className="text-lg md:text-xl font-bold">Contact Email</h2>
              </div>
              <p className="mt-4 text-gray-400">Support email</p>
              <a
                href="mailto:support@trimapp.co"
                className="mt-2 text-xl font-bold text-white select-all hover:underline inline-block"
              >
                support@trimapp.co
              </a>
            </div>

            <div className="glass-card p-7 md:p-8">
              <div className="flex items-center gap-3">
                <div className="w-11 h-11 rounded-xl bg-trim-green/10 flex items-center justify-center">
                  <Clock className="w-5 h-5 text-trim-green" />
                </div>
                <h2 className="text-lg md:text-xl font-bold">Response Time</h2>
              </div>
              <p className="mt-4 text-gray-400">We aim to respond within</p>
              <p className="mt-2 text-xl font-bold text-white">24–48 business hours</p>
            </div>
          </div>

          <div id="faq" className="scroll-mt-28 mt-10 md:mt-14 glass-card p-7 md:p-10">
            <h2 className="text-xl md:text-2xl font-bold mb-6">Frequently Asked Questions</h2>

            <div className="divide-y divide-white/10 rounded-2xl border border-white/10 overflow-hidden">
              {faqs.map((item) => (
                <details key={item.q} className="group bg-white/0 open:bg-white/5 transition-colors">
                  <summary className="cursor-pointer list-none px-5 py-5 md:px-7 md:py-6 flex items-center justify-between gap-6">
                    <span className="font-semibold text-white">{item.q}</span>
                    <span className="text-gray-400 group-open:rotate-180 transition-transform">⌄</span>
                  </summary>
                  <div className="px-5 pb-6 md:px-7">
                    <p className="text-gray-400 leading-relaxed">{item.a}</p>
                  </div>
                </details>
              ))}
            </div>

            <div className="mt-8 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 rounded-2xl border border-white/10 bg-white/5 px-6 py-5">
              <p className="text-gray-300">
                Still stuck? Send us a note at <span className="font-semibold text-white select-all">support@trimapp.co</span>.
              </p>
              <a
                href="mailto:support@trimapp.co"
                className="px-5 py-2.5 rounded-xl bg-trim-green text-background text-sm font-bold neon-glow"
              >
                Email Support
              </a>
            </div>
          </div>
        </div>
      </section>

      <Footer />
    </main>
  );
}
