'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { 
  LayoutDashboard, 
  ShoppingBag, 
  Layers, 
  Image as ImageIcon, 
  ClipboardList, 
  Settings, 
  CreditCard,
  LogOut
} from 'lucide-react';

const navigation = [
  { name: 'الرئيسية والإحصائيات', href: '/', icon: LayoutDashboard },
  { name: 'إدارة الطلبات', href: '/orders', icon: ClipboardList },
  { name: 'المنتجات والسبح', href: '/products', icon: ShoppingBag },
  { name: 'الأقسام والتصنيفات', href: '/categories', icon: Layers },
  { name: 'البانرات الإعلانية', href: '/banners', icon: ImageIcon },
  { name: 'إعدادات المتجر والحساب البنكي', href: '/settings', icon: Settings },
];

export function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="fixed inset-y-0 right-0 z-50 w-64 bg-slate-900 text-white flex flex-col border-l border-slate-800">
      {/* Brand Header */}
      <div className="h-16 flex items-center gap-3 px-6 border-b border-slate-800 bg-slate-950/40">
        <div className="w-10 h-10 rounded-xl bg-teal-600 flex items-center justify-center font-bold text-white shadow-lg shadow-teal-500/20">
          <ShoppingBag className="w-5 h-5" />
        </div>
        <div>
          <h1 className="font-bold text-base leading-tight">متجر السبح</h1>
          <span className="text-xs text-teal-400 font-medium">لوحة تحكم الإدارة</span>
        </div>
      </div>

      {/* Navigation Items */}
      <nav className="flex-1 px-3 py-6 space-y-1.5 overflow-y-auto">
        {navigation.map((item) => {
          const isActive = pathname === item.href;
          const Icon = item.icon;
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-all duration-150 ${
                isActive
                  ? 'bg-teal-600 text-white shadow-md shadow-teal-600/30 font-semibold'
                  : 'text-slate-400 hover:text-white hover:bg-slate-800/60'
              }`}
            >
              <Icon className={`w-5 h-5 ${isActive ? 'text-white' : 'text-slate-400'}`} />
              <span>{item.name}</span>
            </Link>
          );
        })}
      </nav>

      {/* Footer Info */}
      <div className="p-4 border-t border-slate-800/80 bg-slate-950/20">
        <div className="flex items-center gap-3 p-2 rounded-lg bg-slate-800/40 text-xs text-slate-400">
          <div className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></div>
          <span>متصل بـ Supabase Cloud</span>
        </div>
      </div>
    </aside>
  );
}
