import Footer from "@/components/Footer";
import type { Metadata } from "next";
import Link from "next/link";
import { ShieldCheck, Lock, BadgeCheck, Cpu } from "lucide-react";

export const metadata: Metadata = {
  title: "Trim Privacy Policy | Secure Money Management",
  description: "Learn how Trim by Veloran Labs collects, uses, and protects your data.",
};

export default function Privacy() {
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
            <h1 className="text-4xl md:text-6xl font-bold tracking-tight">Privacy Policy</h1>
            <p className="mt-4 text-gray-400 text-base md:text-lg">Last Updated: May 2026</p>

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
              <h2 className="text-2xl md:text-3xl font-bold text-white mb-3">1. Introduction</h2>
              <p>
                Trim (“Trim”, “we”, “us”) is built by Veloran Labs. We value your privacy and aim to handle your
                information with care, clarity, and strong security practices.
              </p>
              <p className="mt-3">
                This Privacy Policy explains what we collect, how we use it, and the choices you have.
              </p>
            </section>

            <section>
              <h2 className="text-2xl md:text-3xl font-bold text-white mb-3">2. Information We Collect</h2>

              <h3 className="text-lg md:text-xl font-semibold text-white mt-6 mb-2">Information You Provide</h3>
              <ul className="list-disc pl-6 space-y-1 text-gray-300">
                <li>Name</li>
                <li>Email</li>
                <li>Account login details</li>
                <li>Support messages</li>
              </ul>

              <h3 className="text-lg md:text-xl font-semibold text-white mt-6 mb-2">Financial Information</h3>
              <ul className="list-disc pl-6 space-y-1 text-gray-300">
                <li>Connected account data through Plaid or similar providers (sandbox today; real integration planned)</li>
                <li>Transaction history</li>
                <li>Recurring payments / subscriptions</li>
                <li>Read-only access where applicable</li>
              </ul>

              <h3 className="text-lg md:text-xl font-semibold text-white mt-6 mb-2">Automatic Information</h3>
              <ul className="list-disc pl-6 space-y-1 text-gray-300">
                <li>Device type</li>
                <li>App usage analytics</li>
                <li>Crash reports</li>
                <li>IP address and approximate location</li>
                <li>Cookies if you use our website (trimapp.co)</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl md:text-3xl font-bold text-white mb-3">3. How We Use Information</h2>
              <ul className="list-disc pl-6 space-y-1 text-gray-300">
                <li>Provide and improve Trim services</li>
                <li>Detect recurring subscriptions</li>
                <li>Identify savings opportunities</li>
                <li>Personalize insights</li>
                <li>Provide customer support</li>
                <li>Help prevent fraud and abuse</li>
                <li>Security monitoring and troubleshooting</li>
                <li>Billing and account management</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl md:text-3xl font-bold text-white mb-3">4. Financial Data Providers</h2>
              <p>
                Trim may use Plaid and similar providers to help you connect your financial accounts securely. Trim does
                not store your banking credentials directly. When available, we access account and transaction data
                through these providers using secure connections.
              </p>
            </section>

            <section>
              <h2 className="text-2xl md:text-3xl font-bold text-white mb-3">5. Payments</h2>
              <p>
                Subscriptions are initially billed through Apple App Store subscriptions, and later may be available on
                Android/Google Play. Pricing is currently $12.99 monthly or $99 yearly (subject to change). Your purchase
                and billing details are handled by the platform you use.
              </p>
            </section>

            <section>
              <h2 className="text-2xl md:text-3xl font-bold text-white mb-3">6. Sharing of Information</h2>
              <p className="font-semibold text-white">We do not sell your personal data.</p>
              <p className="mt-3">We may share information only with:</p>
              <ul className="list-disc pl-6 space-y-1 text-gray-300">
                <li>Service providers that help us operate the app and website</li>
                <li>Infrastructure vendors (for example, secure cloud hosting and authentication systems such as Firebase Authentication)</li>
                <li>Payment processors and platform providers (Apple / Google Play)</li>
                <li>Legal and compliance requests (when required by law)</li>
                <li>Business transfers (for example, if we are acquired)</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl md:text-3xl font-bold text-white mb-3">7. Data Retention</h2>
              <p>
                We keep information only as long as needed for operational, security, customer support, and legal
                reasons. We also retain data when necessary to resolve disputes or enforce our agreements.
              </p>
            </section>

            <section>
              <h2 className="text-2xl md:text-3xl font-bold text-white mb-3">8. Security</h2>
              <p>
                We use industry-standard safeguards and trusted providers to protect your information. However, no
                system can be guaranteed 100% secure, and we cannot promise absolute security.
              </p>
            </section>

            <section>
              <h2 className="text-2xl md:text-3xl font-bold text-white mb-3">9. Your Rights</h2>
              <p>You may request:</p>
              <ul className="list-disc pl-6 space-y-1 text-gray-300">
                <li>Access to your information</li>
                <li>Correction of inaccurate information</li>
                <li>Deletion of your information</li>
                <li>Account closure</li>
                <li>Marketing opt-out</li>
              </ul>
              <p className="mt-3">
                Account deletion is available inside the app and by emailing{" "}
                <span className="font-semibold text-white select-all">support@trimapp.co</span>.
              </p>
            </section>

            <section>
              <h2 className="text-2xl md:text-3xl font-bold text-white mb-3">10. International Users</h2>
              <p>
                Trim is used by people in the USA, Canada, Australia, Europe, and other regions. Your information may be
                processed in multiple countries depending on where our service providers operate.
              </p>
            </section>

            <section>
              <h2 className="text-2xl md:text-3xl font-bold text-white mb-3">11. Children</h2>
              <p>Trim is not intended for users under 18. If you are under 18, do not use Trim.</p>
            </section>

            <section>
              <h2 className="text-2xl md:text-3xl font-bold text-white mb-3">12. Changes</h2>
              <p>
                We may update this Privacy Policy from time to time. If we make changes, we will update the “Last
                Updated” date at the top of this page.
              </p>
            </section>

            <section>
              <h2 className="text-2xl md:text-3xl font-bold text-white mb-3">13. Contact</h2>
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
