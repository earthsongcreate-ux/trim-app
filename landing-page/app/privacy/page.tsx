import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";

export default function Privacy() {
  return (
    <>
      <Navbar />
      <main className="pt-40 pb-24 px-6 md:px-12 max-w-4xl mx-auto">
        <h1 className="text-4xl md:text-6xl font-bold mb-8">Privacy Policy</h1>
        <p className="text-gray-400 mb-8">Last Updated: April 2024</p>
        
        <div className="prose prose-invert prose-lg max-w-none space-y-12 text-gray-300">
          <section>
            <h2 className="text-2xl font-bold text-white mb-4">1. Data Collection</h2>
            <p>
              Trim takes your privacy seriously. We collect information you provide directly to us, such as your name, email, and financial account information connected via Plaid.
            </p>
          </section>
          
          <section>
            <h2 className="text-2xl font-bold text-white mb-4">2. Financial Data Handling</h2>
            <p>
              We use Plaid to securely connect to your financial institutions. Trim never stores your banking login credentials. We only receive read-only access to transaction data to identify subscriptions and potential savings.
            </p>
          </section>

          <section>
            <h2 className="text-2xl font-bold text-white mb-4">3. Data Usage</h2>
            <p>
              Your data is used solely to provide and improve our services, specifically to detect recurring charges and offer bill negotiation features. We do not sell your personal data to third parties.
            </p>
          </section>
        </div>
      </main>
      <Footer />
    </>
  );
}
