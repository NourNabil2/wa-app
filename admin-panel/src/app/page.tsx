'use client';

import { useEffect, useState } from 'react';
import { Header } from '@/components/Header';
import { supabase } from '@/lib/supabase';
import { Order, Product } from '@/types/database';
import { 
  ShoppingBag, 
  DollarSign, 
  Clock, 
  CheckCircle2, 
  ArrowUpRight, 
  Plus, 
  Eye, 
  FileCheck2 
} from 'lucide-react';
import Link from 'next/link';

export default function DashboardPage() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [totalProducts, setTotalProducts] = useState<number>(0);
  const [loading, setLoading] = useState<boolean>(true);

  useEffect(() => {
    fetchDashboardData();
  }, []);

  async function fetchDashboardData() {
    setLoading(true);
    try {
      // 1. Fetch Orders with order items and bank transfers
      const { data: ordersData } = await supabase
        .from('orders')
        .select('*, order_items(*), bank_transfers(*)')
        .order('created_at', { ascending: false });

      if (ordersData) {
        setOrders(ordersData as Order[]);
      }

      // 2. Fetch Products Count
      const { count } = await supabase
        .from('products')
        .select('*', { count: 'exact', head: true });

      setTotalProducts(count || 0);
    } catch (err) {
      console.error('Error fetching dashboard data:', err);
    } finally {
      setLoading(false);
    }
  }

  // Calculate stats
  const totalRevenue = orders
    .filter(o => o.payment_status === 'confirmed' || o.order_status === 'delivered')
    .reduce((sum, o) => sum + Number(o.total_price || 0), 0);

  const pendingTransfersCount = orders.filter(
    o => o.payment_method === 'bank_transfer' && o.payment_status === 'pending'
  ).length;

  const newOrdersCount = orders.filter(o => o.order_status === 'new').length;

  return (
    <div>
      <Header 
        title="الرئيسية والإحصائيات" 
        subtitle="نظرة عامة على المبيعات، الطلبات، والتحويلات البنكية المعلقة" 
      />

      <div className="p-8 max-w-7xl mx-auto space-y-8">
        {/* Quick Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
          {/* Revenue */}
          <div className="bg-white p-6 rounded-2xl border border-slate-200/80 shadow-sm flex items-center justify-between">
            <div>
              <p className="text-xs font-semibold text-slate-500">إجمالي المبيعات المؤكدة</p>
              <h3 className="text-2xl font-black text-slate-900 mt-2">
                {totalRevenue.toLocaleString('ar-SA')} <span className="text-xs font-normal text-slate-500">ر.س</span>
              </h3>
            </div>
            <div className="w-12 h-12 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <DollarSign className="w-6 h-6" />
            </div>
          </div>

          {/* Total Orders */}
          <div className="bg-white p-6 rounded-2xl border border-slate-200/80 shadow-sm flex items-center justify-between">
            <div>
              <p className="text-xs font-semibold text-slate-500">إجمالي الطلبات</p>
              <h3 className="text-2xl font-black text-slate-900 mt-2">
                {orders.length}
              </h3>
            </div>
            <div className="w-12 h-12 rounded-xl bg-teal-50 text-teal-600 flex items-center justify-center">
              <ShoppingBag className="w-6 h-6" />
            </div>
          </div>

          {/* Pending Bank Transfers */}
          <div className="bg-white p-6 rounded-2xl border border-amber-200/90 shadow-sm flex items-center justify-between bg-amber-50/20">
            <div>
              <p className="text-xs font-semibold text-amber-700">تحويلات بنكية بانتظار التحقق</p>
              <h3 className="text-2xl font-black text-amber-600 mt-2">
                {pendingTransfersCount}
              </h3>
            </div>
            <div className="w-12 h-12 rounded-xl bg-amber-100 text-amber-700 flex items-center justify-center">
              <FileCheck2 className="w-6 h-6" />
            </div>
          </div>

          {/* Total Products */}
          <div className="bg-white p-6 rounded-2xl border border-slate-200/80 shadow-sm flex items-center justify-between">
            <div>
              <p className="text-xs font-semibold text-slate-500">المنتجات المعروضة</p>
              <h3 className="text-2xl font-black text-slate-900 mt-2">
                {totalProducts}
              </h3>
            </div>
            <div className="w-12 h-12 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center">
              <Clock className="w-6 h-6" />
            </div>
          </div>
        </div>

        {/* Action Bar */}
        <div className="flex items-center justify-between bg-gradient-to-r from-teal-800 to-teal-950 p-6 rounded-2xl text-white shadow-md">
          <div>
            <h3 className="text-lg font-bold">إدارة المتجر والمنتجات</h3>
            <p className="text-xs text-teal-200 mt-1">أضف سبح ومنتجات جديدة بروابط وصور تظهر فورياً في تطبيق الموبايل</p>
          </div>
          <div className="flex items-center gap-3">
            <Link 
              href="/products" 
              className="flex items-center gap-2 bg-white text-teal-900 hover:bg-teal-50 px-5 py-2.5 rounded-xl font-bold text-sm transition-all shadow-sm"
            >
              <Plus className="w-4 h-4" />
              <span>إضافة منتج جديد</span>
            </Link>
            <Link 
              href="/orders" 
              className="flex items-center gap-2 bg-teal-700/60 hover:bg-teal-700 text-white px-5 py-2.5 rounded-xl font-bold text-sm border border-teal-500/30 transition-all"
            >
              <span>عرض جميع الطلبات ({orders.length})</span>
            </Link>
          </div>
        </div>

        {/* Recent Orders Section */}
        <div className="bg-white rounded-2xl border border-slate-200/80 shadow-sm overflow-hidden">
          <div className="p-6 border-b border-slate-100 flex items-center justify-between">
            <h3 className="font-bold text-slate-800 text-base">أحدث الطلبات الواردة</h3>
            <Link href="/orders" className="text-xs font-bold text-teal-600 hover:text-teal-700 flex items-center gap-1">
              <span>عرض الكل</span>
              <ArrowUpRight className="w-3.5 h-3.5" />
            </Link>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-right text-sm">
              <thead className="bg-slate-50/80 text-slate-500 text-xs font-semibold border-b border-slate-100">
                <tr>
                  <th className="py-3.5 px-6">رقم الطلب</th>
                  <th className="py-3.5 px-6">العميل</th>
                  <th className="py-3.5 px-6">طريقة الدفع</th>
                  <th className="py-3.5 px-6">حالة الدفع</th>
                  <th className="py-3.5 px-6">حالة الطلب</th>
                  <th className="py-3.5 px-6">المبلغ الإجمالي</th>
                  <th className="py-3.5 px-6">التاريخ</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 text-slate-700">
                {orders.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="py-12 text-center text-slate-400">
                      {loading ? 'جاري تحميل البيانات من سوبابيز...' : 'لا توجد طلبات واردة حتى الآن'}
                    </td>
                  </tr>
                ) : (
                  orders.slice(0, 5).map((order) => (
                    <tr key={order.id} className="hover:bg-slate-50/60 transition-colors">
                      <td className="py-4 px-6 font-bold text-slate-900">
                        #{order.order_number || order.id.slice(0, 6)}
                      </td>
                      <td className="py-4 px-6">
                        <div className="font-medium text-slate-900">{order.customer_name}</div>
                        <div className="text-xs text-slate-400 mt-0.5">{order.customer_phone} - {order.city}</div>
                      </td>
                      <td className="py-4 px-6">
                        {order.payment_method === 'cod' ? (
                          <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold bg-blue-50 text-blue-700 border border-blue-200">
                            دفع عند الاستلام
                          </span>
                        ) : (
                          <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold bg-amber-50 text-amber-700 border border-amber-200">
                            تحويل بنكي
                          </span>
                        )}
                      </td>
                      <td className="py-4 px-6">
                        {order.payment_status === 'confirmed' ? (
                          <span className="text-emerald-600 font-semibold text-xs flex items-center gap-1">
                            <CheckCircle2 className="w-3.5 h-3.5" />
                            <span>تم الدفع</span>
                          </span>
                        ) : (
                          <span className="text-amber-600 font-semibold text-xs flex items-center gap-1">
                            <Clock className="w-3.5 h-3.5" />
                            <span>قيد الانتظار</span>
                          </span>
                        )}
                      </td>
                      <td className="py-4 px-6">
                        <span className={`inline-block px-2.5 py-1 rounded-lg text-xs font-bold ${
                          order.order_status === 'new' ? 'bg-emerald-50 text-emerald-700' :
                          order.order_status === 'processing' ? 'bg-indigo-50 text-indigo-700' :
                          order.order_status === 'shipped' ? 'bg-purple-50 text-purple-700' :
                          order.order_status === 'delivered' ? 'bg-teal-50 text-teal-700' :
                          'bg-slate-100 text-slate-600'
                        }`}>
                          {order.order_status === 'new' ? 'طلب جديد' :
                           order.order_status === 'processing' ? 'جاري التجهيز' :
                           order.order_status === 'shipped' ? 'تم الشحن' :
                           order.order_status === 'delivered' ? 'تم التسليم' : 'ملغي'}
                        </span>
                      </td>
                      <td className="py-4 px-6 font-bold text-slate-900">
                        {Number(order.total_price).toFixed(2)} ر.س
                      </td>
                      <td className="py-4 px-6 text-xs text-slate-400">
                        {new Date(order.created_at).toLocaleDateString('ar-SA')}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}
