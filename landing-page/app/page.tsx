import Navbar from "@/components/Navbar";
import Hero from "@/components/Hero";
import Features from "@/components/Features";
import SavingsImpact from "@/components/SavingsImpact";
import AppPreview from "@/components/AppPreview";
import CTA from "@/components/CTA";
import Footer from "@/components/Footer";

export default function Home() {
  return (
    <main>
      <Navbar />
      <Hero />
      <div id="how-it-works">
        {/* Simple 3-step guide can be integrated here or as its own component */}
        <section className="py-24 px-6 md:px-12 bg-trim-dark/50">
          <div className="max-w-7xl mx-auto">
            <h2 className="text-center text-3xl md:text-5xl font-bold mb-16">How it works</h2>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-12">
              {[
                { step: "01", title: "Connect your accounts", desc: "Securely link your bank using Plaid encryption." },
                { step: "02", title: "Trim detects waste", desc: "Our AI identifies unwanted subscriptions and high bills." },
                { step: "03", title: "You save instantly", desc: "Cancel with one tap or let us negotiate for you." }
              ].map((item, i) => (
                <div key={i} className="relative p-8 glass-card">
                  <span className="absolute -top-6 -left-6 text-6xl font-black text-white/5">{item.step}</span>
                  <h3 className="text-2xl font-bold mb-4">{item.title}</h3>
                  <p className="text-gray-400">{item.desc}</p>
                </div>
              ))}
            </div>
          </div>
        </section>
      </div>
      <Features />
      <SavingsImpact />
      <AppPreview />
      <CTA />
      <Footer />
    </main>
  );
}
