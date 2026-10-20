import type { Metadata } from 'next';
import './globals.css';
import { Sidebar } from '@/components/Sidebar';

export const metadata: Metadata = {
  title: 'لوحة تحكم متجر السبح الفاخرة',
  description: 'إدارة المنتجات، الأقسام، الطلبات، والتحويلات البنكية',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ar" dir="rtl">
      <body className="antialiased min-h-screen bg-slate-50 flex">
        <Sidebar />
        <div className="flex-1 mr-64 flex flex-col min-h-screen">
          <main className="flex-1 pb-16">
            {children}
          </main>
        </div>
      </body>
    </html>
  );
}
