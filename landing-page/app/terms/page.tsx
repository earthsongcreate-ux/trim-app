import Footer from "@/components/Footer";
import type { Metadata } from "next";
import Link from "next/link";
import { ShieldCheck, Lock, BadgeCheck, Cpu } from "lucide-react";

export const metadata: Metadata = {
  title: "Trim Terms of Use | Subscription Terms",
  description: "Review the Terms of Use for Trim by Veloran Labs.",
};

export default function Terms() {
  return (
    <>
      <header className="fixed top-0 left-0 right-0 z-50 px-6 md:px-12 py-4 glass border-none bg-background/60 backdrop-blur-md">
        <div className="max-w-5xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Link
              href="/"
              className="px-3 py-2 rounded-full border border-white/10 bg-white/5 text-sm font-semibold text-gray-200 hover:bg-white/10 transition-colors"
            >
              Home
            </Link>
            <Link href="/" className="flex items-center gap-3">
              <img
                src="/images/logo.png"
                alt="Trim Logo"
                className="h-7 w-auto object-contain"
              />
            </Link>
          </div>

          <div className="flex items-center gap-3">
            <Link
              href="/support"
              className="px-4 py-2 rounded-full bg-trim-green text-background text-sm font-bold neon-glow"
            >
              Support
            </Link>
          </div>
        </div>
      </header>

      <main className="pt-28 md:pt-32 pb-24 px-6 md:px-12">
        <div className="max-w-5xl mx-auto">
          <section className="glass-card p-8 md:p-12">
            <h1 className="text-4xl md:text-6xl font-bold tracking-tight">Terms of Use</h1>
            <p className="mt-4 text-gray-400 text-base md:text-lg">Effective Date: May 2026</p>

            <div className="mt-8 grid grid-cols-2 md:grid-cols-4 gap-3">
              {[
                { label: "Bank-Level Security", icon: <ShieldCheck className="w-4 h-4 text-trim-green" /> },
                { label: "Private by Design", icon: <Lock className="w-4 h-4 text-trim-green" /> },
                { label: "Cancel Anytime", icon: <BadgeCheck className="w-4 h-4 text-trim-green" /> },
                { label: "Trusted Technology Partners", icon: <Cpu className="w-4 h-4 text-trim-green" /> },
              ].map((b) => (
                <div
                  key={b.label}
                  className="flex items-center gap-2 rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-gray-200"
                >
                  {b.icon}
                  <span className="leading-tight">{b.label}</span>
                </div>
              ))}
            </div>
          </section>

          <section className="mt-10 md:mt-14 glass-card p-8 md:p-12 space-y-10 text-gray-300 leading-relaxed">
            <section>
              <h2 className="text-2xl md:text-3xl font-bold text-white mb-3">1. Acceptance</h2>
              <p>
                By using Trim, you agree to these Terms of Use and any additional rules or policies we provide. If you do
                not agree, do not use Trim.
              </p>
            </section>

            <section>
              <h2 className="text-2xl md:text-3xl font-bold text-white mb-3">2. Eligibility</h2>
              <p>You must be at least 18 years old to use Trim.</p>
            </section>

            <section>
              <h2 className="text-2xl md:text-3xl font-bold text-white mb-3">3. Account Responsibility</h2>
              <p>
                You are responsible for keeping your account credentials secure and for all activity that happens under
                your account.
              </p>
            </section>

            <section>
              <h2 className="text-2xl md:text-3xl font-bold text-white mb-3">4. Services Provided</h2>
              <p>Trim helps users:</p>
              <ul className="list-disc pl-6 space-y-1 text-gray-300">
                <li>Monitor subscriptions</li>
                <li>Analyze spending</li>
                <li>Discover savings opportunities</li>
                <li>Receive insights</li>
              </ul>
              <p className="mt-4">Trim is not:</p>
              <ul className="list-disc pl-6 space-y-1 text-gray-300">
                <li>A bank</li>
                <li>A financial advisor</li>
                <li>A credit provider</li>
                <li>A tax advisor</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl md:text-3xl font-bold text-white mb-3">5. Financial Connections</h2>
              <p>
                Trim may integrate with third-party providers (such as Plaid) to help you connect financial accounts.
                Availability may vary by region, bank, platform, and product stage.
              </p>
            </section>

            <section>
              <h2 className="text-2xl md:text-3xl font-bold text-white mb-3">6. Subscription Billing</h2>
              <p>Plans:</p>
              <ul className="list-disc pl-6 space-y-1 text-gray-300">
                <li>$12.99 monthly</li>
                <li>$99 yearly</li>
              </ul>
              <p className="mt-4">
                Subscriptions auto-renew unless cancelled. Billing is managed by Apple App Store or the applicable
                platform. Refunds are subject to platform rules.
              </p>
            </section>

            <section>
              <h2 className="text-2xl md:text-3xl font-bold text-white mb-3">7. Cancellation</h2>
              <p>You may cancel anytime through your device subscription settings.</p>
            </section>

            <section>
              <h2 className="text-2xl md:text-3xl font-bold text-white mb-3">8. Acceptable Use</h2>
              <p>You may not:</p>
              <ul className="list-disc pl-6 space-y-1 text-gray-300">
                <li>Abuse the platform</li>
                <li>Reverse engineer or attempt to extract source code</li>
                <li>Commit fraud</li>
                <li>Upload malicious code</li>
                <li>Misuse data or access systems without authorization</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl md:text-3xl font-bold text-white mb-3">9. Intellectual Property</h2>
              <p>
                Trim branding, software, design, and content are owned by Veloran Labs and its licensors. You may not
                copy, modify, distribute, or create derivative works except as allowed by law or with our written
                permission.
              </p>
            </section>

            <section>
              <h2 className="text-2xl md:text-3xl font-bold text-white mb-3">10. No Guarantees</h2>
              <p>
                Savings opportunities are estimates only. We do not guarantee results, outcomes, or specific savings
                amounts.
              </p>
            </section>

            <section>
              <h2 className="text-2xl md:text-3xl font-bold text-white mb-3">11. Limitation of Liability</h2>
              <p>
                To the maximum extent allowed by law, Veloran Labs is not liable for indirect damages, lost profits,
                data loss, financial decisions, service interruptions, or other losses related to your use of Trim.
              </p>
            </section>

            <section>
              <h2 className="text-2xl md:text-3xl font-bold text-white mb-3">12. Suspension / Termination</h2>
              <p>We may suspend or terminate accounts involved in abuse, fraud, or violations of these terms.</p>
            </section>

            <section>
              <h2 className="text-2xl md:text-3xl font-bold text-white mb-3">13. Changes to Service</h2>
              <p>
                We may modify or discontinue features, pricing, or offerings at any time. We may also update these terms
                and will revise the effective date when we do.
              </p>
            </section>

            <section>
              <h2 className="text-2xl md:text-3xl font-bold text-white mb-3">14. Governing Law</h2>
              <p>
                These terms are governed by applicable laws based on your jurisdiction and Veloran Labs’ operating
                jurisdiction.
              </p>
            </section>

            <section>
              <h2 className="text-2xl md:text-3xl font-bold text-white mb-3">15. Contact</h2>
              <div className="rounded-2xl border border-white/10 bg-white/5 p-6 text-gray-300">
                <p className="font-semibold text-white">Veloran Labs</p>
                <p className="mt-1">
                  <span className="select-all">support@trimapp.co</span>
                </p>
                <p className="mt-1">
                  <span className="select-all">trimapp.co</span>
                </p>
              </div>
            </section>
          </section>
        </div>
      </main>
      <Footer />
    </>
  );
}
