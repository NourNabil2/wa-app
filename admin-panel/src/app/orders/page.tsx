'use client';

import { useEffect, useState } from 'react';
import { Header } from '@/components/Header';
import { supabase } from '@/lib/supabase';
import { Order } from '@/types/database';
import { 
  CheckCircle2, 
  Clock, 
  Eye, 
  Filter, 
  X, 
  ExternalLink, 
  FileText, 
  Phone, 
  MapPin, 
  AlertCircle 
} from 'lucide-react';

export default function OrdersPage() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
  const [receiptModalUrl, setReceiptModalUrl] = useState<string | null>(null);
  const [statusFilter, setStatusFilter] = useState<string>('all');

  useEffect(() => {
    fetchOrders();
  }, []);

  async function fetchOrders() {
    setLoading(true);
    try {
      const { data } = await supabase
        .from('orders')
        .select('*, order_items(*), bank_transfers(*)')
        .order('created_at', { ascending: false });

      if (data) setOrders(data as Order[]);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  }

  async function updateOrderStatus(orderId: string, newStatus: string) {
    try {
      const { error } = await supabase
        .from('orders')
        .update({ order_status: newStatus, updated_at: new Date().toISOString() })
        .eq('id', orderId);

      if (error) throw error;
      setOrders(orders.map(o => o.id === orderId ? { ...o, order_status: newStatus as any } : o));
      if (selectedOrder?.id === orderId) {
        setSelectedOrder({ ...selectedOrder, order_status: newStatus as any });
      }
    } catch (err: any) {
      alert('فشل تحديث حالة الطلب: ' + err.message);
    }
  }

  async function confirmBankPayment(orderId: string) {
    if (!confirm('هل تأكدت من وصول المبلغ في حسابك البنكي وتريد تأكيد الدفع؟')) return;
    try {
      const { error: orderErr } = await supabase
        .from('orders')
        .update({ 
          payment_status: 'confirmed', 
          order_status: 'processing',
          updated_at: new Date().toISOString() 
        })
        .eq('id', orderId);

      if (orderErr) throw orderErr;

      // Update transfer record
      await supabase
        .from('bank_transfers')
        .update({ verified: true, verified_at: new Date().toISOString() })
        .eq('order_id', orderId);

      setOrders(orders.map(o => o.id === orderId ? { 
        ...o, 
        payment_status: 'confirmed', 
        order_status: 'processing' 
      } : o));

      if (selectedOrder?.id === orderId) {
        setSelectedOrder({ 
          ...selectedOrder, 
          payment_status: 'confirmed', 
          order_status: 'processing' 
        });
      }

      alert('تم تأكيد الدفع بنجاح وتحويل الطلب إلى "جاري التجهيز"!');
    } catch (err: any) {
      alert('خطأ أثناء التأكيد: ' + err.message);
    }
  }

  const filteredOrders = orders.filter(o => {
    if (statusFilter === 'all') return true;
    if (statusFilter === 'pending_transfers') {
      return o.payment_method === 'bank_transfer' && o.payment_status === 'pending';
    }
    return o.order_status === statusFilter;
  });

  return (
    <div>
      <Header 
        title="إدارة ومتابعة الطلبات" 
        subtitle="متابعة طلبات الدفع عند الاستلام، التحقق من إيصالات التحويل البنكي، وتحديث حالات الشحن" 
      />

      <div className="p-8 max-w-7xl mx-auto space-y-6">
        {/* Filter Tabs */}
        <div className="flex items-center gap-2 overflow-x-auto pb-2">
          {[
            { id: 'all', label: `جميع الطلبات (${orders.length})` },
            { id: 'pending_transfers', label: 'تحويلات بانتظار التأكيد', alert: true },
            { id: 'new', label: 'طلبات جديدة' },
            { id: 'processing', label: 'جاري التجهيز' },
            { id: 'shipped', label: 'تم الشحن' },
            { id: 'delivered', label: 'تم التسليم' },
          ].map(tab => (
            <button
              key={tab.id}
              onClick={() => setStatusFilter(tab.id)}
              className={`px-4 py-2.5 rounded-xl text-xs font-bold transition-all whitespace-nowrap flex items-center gap-2 ${
                statusFilter === tab.id
                  ? 'bg-teal-600 text-white shadow-sm'
                  : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
              }`}
            >
              {tab.alert && (
                <span className="w-2 h-2 rounded-full bg-amber-500 animate-ping"></span>
              )}
              <span>{tab.label}</span>
            </button>
          ))}
        </div>

        {/* Orders Table */}
        <div className="bg-white rounded-2xl border border-slate-200/80 shadow-sm overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-right text-sm">
              <thead className="bg-slate-50 text-slate-500 text-xs font-semibold border-b border-slate-200">
                <tr>
                  <th className="py-4 px-6">رقم الطلب</th>
                  <th className="py-4 px-6">العميل والتواصل</th>
                  <th className="py-4 px-6">طريقة الدفع</th>
                  <th className="py-4 px-6">إيصال التحويل</th>
                  <th className="py-4 px-6">حالة الطلب</th>
                  <th className="py-4 px-6">الإجمالي</th>
                  <th className="py-4 px-6 text-center">إجراءات</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filteredOrders.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="py-12 text-center text-slate-400">
                      {loading ? 'جاري التحميل...' : 'لا توجد طلبات مطابقة للفلتر المحدد'}
                    </td>
                  </tr>
                ) : (
                  filteredOrders.map(order => {
                    const transfer = order.bank_transfers?.[0];
                    return (
                      <tr key={order.id} className="hover:bg-slate-50/70 transition-colors">
                        <td className="py-4 px-6 font-bold text-slate-900">
                          #{order.order_number || order.id.slice(0, 6)}
                        </td>
                        <td className="py-4 px-6">
                          <div className="font-bold text-slate-900">{order.customer_name}</div>
                          <div className="text-xs text-slate-500 flex items-center gap-1 mt-0.5">
                            <Phone className="w-3 h-3" />
                            <span>{order.customer_phone}</span>
                            <span>• {order.city}</span>
                          </div>
                        </td>
                        <td className="py-4 px-6">
                          {order.payment_method === 'cod' ? (
                            <span className="px-2.5 py-1 rounded-full text-xs font-semibold bg-blue-50 text-blue-700 border border-blue-200">
                              عند الاستلام (COD)
                            </span>
                          ) : (
                            <span className="px-2.5 py-1 rounded-full text-xs font-semibold bg-amber-50 text-amber-700 border border-amber-200">
                              تحويل بنكي
                            </span>
                          )}
                        </td>
                        <td className="py-4 px-6">
                          {order.payment_method === 'bank_transfer' ? (
                            transfer?.receipt_url ? (
                              <button 
                                onClick={() => setReceiptModalUrl(transfer.receipt_url)}
                                className="text-xs font-bold text-teal-600 hover:text-teal-700 underline flex items-center gap-1"
                              >
                                <FileText className="w-3.5 h-3.5" />
                                <span>عرض الإشعار</span>
                              </button>
                            ) : (
                              <span className="text-xs text-amber-600 flex items-center gap-1">
                                <AlertCircle className="w-3 h-3" />
                                <span>لم يرفع إيصال</span>
                              </span>
                            )
                          ) : (
                            <span className="text-xs text-slate-400">—</span>
                          )}
                        </td>
                        <td className="py-4 px-6">
                          <select
                            value={order.order_status}
                            onChange={(e) => updateOrderStatus(order.id, e.target.value)}
                            className="text-xs font-bold px-2.5 py-1 rounded-lg border border-slate-200 bg-white focus:outline-none focus:border-teal-500 cursor-pointer"
                          >
                            <option value="new">طلب جديد</option>
                            <option value="processing">جاري التجهيز</option>
                            <option value="shipped">تم الشحن</option>
                            <option value="delivered">تم التسليم</option>
                            <option value="cancelled">ملغي</option>
                          </select>
                        </td>
                        <td className="py-4 px-6 font-bold text-slate-900">
                          {Number(order.total_price).toFixed(2)} ر.س
                        </td>
                        <td className="py-4 px-6 text-center">
                          <button
                            onClick={() => setSelectedOrder(order)}
                            className="p-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 transition-colors inline-flex items-center gap-1 text-xs font-bold"
                          >
                            <Eye className="w-3.5 h-3.5" />
                            <span>التفاصيل</span>
                          </button>
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {/* Order Details Drawer / Modal */}
      {selectedOrder && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-xl w-full p-6 shadow-2xl relative max-h-[90vh] overflow-y-auto">
            <button 
              onClick={() => setSelectedOrder(null)}
              className="absolute left-6 top-6 text-slate-400 hover:text-slate-600"
            >
              <X className="w-6 h-6" />
            </button>

            <h3 className="text-xl font-bold text-slate-900 mb-1">
              تفاصيل الطلب #{selectedOrder.order_number || selectedOrder.id.slice(0, 6)}
            </h3>
            <p className="text-xs text-slate-400 mb-6">
              تم الإنشاء في {new Date(selectedOrder.created_at).toLocaleString('ar-SA')}
            </p>

            <div className="space-y-4">
              {/* Customer Info */}
              <div className="p-4 rounded-2xl bg-slate-50 border border-slate-100 space-y-1">
                <div className="font-bold text-slate-800">{selectedOrder.customer_name}</div>
                <div className="text-xs text-slate-500">{selectedOrder.customer_phone}</div>
                <div className="text-xs text-slate-500">{selectedOrder.customer_address} - {selectedOrder.city}</div>
              </div>

              {/* Bank Transfer Box */}
              {selectedOrder.payment_method === 'bank_transfer' && (
                <div className="p-4 rounded-2xl bg-amber-50 border border-amber-200">
                  <div className="flex items-center justify-between">
                    <div>
                      <h5 className="font-bold text-amber-900 text-xs">حالة التحويل البنكي</h5>
                      <p className="text-xs text-amber-700 mt-0.5">
                        {selectedOrder.payment_status === 'confirmed' ? 'تم تأكيد وصول الحوالة' : 'بانتظار مراجعة الإشعار وتأكيد الدفع'}
                      </p>
                    </div>
                    {selectedOrder.payment_status !== 'confirmed' && (
                      <button
                        onClick={() => confirmBankPayment(selectedOrder.id)}
                        className="bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold px-3 py-1.5 rounded-lg shadow-sm"
                      >
                        تأكيد استلام المبلغ
                      </button>
                    )}
                  </div>
                  {selectedOrder.bank_transfers?.[0]?.receipt_url && (
                    <div className="mt-3">
                      <button
                        onClick={() => setReceiptModalUrl(selectedOrder.bank_transfers![0].receipt_url)}
                        className="text-xs font-bold text-teal-700 underline flex items-center gap-1"
                      >
                        <ExternalLink className="w-3.5 h-3.5" />
                        <span>فتح صورة إيصال التحويل للمطابقة</span>
                      </button>
                    </div>
                  )}
                </div>
              )}

              {/* Items List */}
              <div>
                <h5 className="text-xs font-bold text-slate-600 mb-2">عناصر الطلب:</h5>
                <div className="divide-y divide-slate-100 border border-slate-100 rounded-xl overflow-hidden">
                  {selectedOrder.order_items?.map((item) => (
                    <div key={item.id} className="p-3 bg-white flex items-center justify-between text-xs">
                      <div>
                        <span className="font-bold text-slate-800">{item.product_name}</span>
                        <span className="text-slate-400 mr-2">x {item.quantity}</span>
                      </div>
                      <span className="font-bold text-slate-900">{item.total_price} ر.س</span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Total Calculation */}
              <div className="p-4 rounded-xl bg-slate-100 text-xs space-y-1.5 font-medium">
                <div className="flex justify-between text-slate-600">
                  <span>المجموع الفرعي:</span>
                  <span>{selectedOrder.subtotal} ر.س</span>
                </div>
                <div className="flex justify-between text-slate-600">
                  <span>رسوم التوصيل:</span>
                  <span>{selectedOrder.delivery_fee} ر.س</span>
                </div>
                <div className="flex justify-between font-black text-slate-900 text-sm pt-2 border-t border-slate-200">
                  <span>الإجمالي النهائي:</span>
                  <span>{selectedOrder.total_price} ر.س</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Receipt Image Preview Modal */}
      {receiptModalUrl && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-md flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-lg w-full p-4 relative">
            <button
              onClick={() => setReceiptModalUrl(null)}
              className="absolute left-4 top-4 p-1.5 rounded-full bg-slate-100 text-slate-600 hover:bg-slate-200"
            >
              <X className="w-5 h-5" />
            </button>
            <h4 className="font-bold text-sm text-slate-800 mb-3 px-2">إشعار التحويل البنكي المرفوع</h4>
            <div className="rounded-2xl overflow-hidden bg-slate-100 max-h-[75vh] flex items-center justify-center">
              <img src={receiptModalUrl} alt="إيصال التحويل" className="w-full h-auto object-contain" />
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
