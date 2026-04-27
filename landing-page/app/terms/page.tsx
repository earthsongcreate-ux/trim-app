import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";

export default function Terms() {
  return (
    <>
      <Navbar />
      <main className="pt-40 pb-24 px-6 md:px-12 max-w-4xl mx-auto">
        <h1 className="text-4xl md:text-6xl font-bold mb-8">Terms of Service</h1>
        <p className="text-gray-400 mb-8">Effective Date: April 2024</p>
        
        <div className="prose prose-invert prose-lg max-w-none space-y-12 text-gray-300">
          <section>
            <h2 className="text-2xl font-bold text-white mb-4">1. Acceptance of Terms</h2>
            <p>
              By accessing or using the Trim app, you agree to be bound by these Terms of Service and all applicable laws and regulations.
            </p>
          </section>
          
          <section>
            <h2 className="text-2xl font-bold text-white mb-4">2. Subscription Billing</h2>
            <p>
              Trim offers both free and premium tiers. Premium features are billed on a recurring monthly or annual basis. You can cancel your subscription at any time within the app settings.
            </p>
          </section>

          <section>
            <h2 className="text-2xl font-bold text-white mb-4">3. Limitation of Liability</h2>
            <p>
              Trim provides financial information for informational purposes. We are not a bank or financial advisor. Users are responsible for verifying all financial decisions.
            </p>
          </section>
        </div>
      </main>
      <Footer />
    </>
  );
}
