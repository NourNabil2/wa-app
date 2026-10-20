'use client';

import { useEffect, useState } from 'react';
import { Header } from '@/components/Header';
import { supabase } from '@/lib/supabase';
import { StoreSettings } from '@/types/database';
import { Building2, Save, Loader2, CheckCircle2 } from 'lucide-react';

export default function SettingsPage() {
  const [settings, setSettings] = useState<StoreSettings | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [success, setSuccess] = useState(false);

  // Form states
  const [storeName, setStoreName] = useState('');
  const [bankName, setBankName] = useState('');
  const [bankAccountName, setBankAccountName] = useState('');
  const [bankAccountNumber, setBankAccountNumber] = useState('');
  const [bankIban, setBankIban] = useState('');
  const [deliveryFee, setDeliveryFee] = useState('25');
  const [supportPhone, setSupportPhone] = useState('');

  useEffect(() => {
    fetchSettings();
  }, []);

  async function fetchSettings() {
    setLoading(true);
    try {
      const { data } = await supabase.from('store_settings').select('*').eq('id', 'main').single();
      if (data) {
        setSettings(data as StoreSettings);
        setStoreName(data.store_name);
        setBankName(data.bank_name);
        setBankAccountName(data.bank_account_name);
        setBankAccountNumber(data.bank_account_number);
        setBankIban(data.bank_iban);
        setDeliveryFee(data.delivery_fee?.toString() || '25');
        setSupportPhone(data.support_phone || '');
      }
    } finally {
      setLoading(false);
    }
  }

  async function handleSave(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    setSuccess(false);

    try {
      const payload = {
        store_name: storeName,
        bank_name: bankName,
        bank_account_name: bankAccountName,
        bank_account_number: bankAccountNumber,
        bank_iban: bankIban,
        delivery_fee: parseFloat(deliveryFee) || 25,
        support_phone: supportPhone,
        updated_at: new Date().toISOString()
      };

      const { error } = await supabase
        .from('store_settings')
        .upsert({ id: 'main', ...payload });

      if (error) throw error;
      setSuccess(true);
      setTimeout(() => setSuccess(false), 3000);
    } catch (err: any) {
      alert('خطأ أثناء الحفظ: ' + err.message);
    } finally {
      setSaving(false);
    }
  }

  return (
    <div>
      <Header 
        title="إعدادات المتجر والحساب البنكي" 
        subtitle="تحديد بيانات الحساب البنكي التي تظهر للعميل في التطبيق ورسوم التوصيل" 
      />

      <div className="p-8 max-w-4xl mx-auto space-y-6">
        {success && (
          <div className="p-4 rounded-2xl bg-emerald-50 border border-emerald-200 text-emerald-800 text-sm font-bold flex items-center gap-2">
            <CheckCircle2 className="w-5 h-5 text-emerald-600" />
            <span>تم حفظ التعديلات بنجاح وستظهر مباشرة في التطبيق!</span>
          </div>
        )}

        <form onSubmit={handleSave} className="space-y-6">
          {/* Bank Account Details Card */}
          <div className="bg-white p-6 rounded-2xl border border-slate-200/80 shadow-sm space-y-5">
            <div className="flex items-center gap-3 pb-4 border-b border-slate-100">
              <div className="w-10 h-10 rounded-xl bg-amber-50 text-amber-700 flex items-center justify-center font-bold">
                <Building2 className="w-5 h-5" />
              </div>
              <div>
                <h3 className="font-bold text-slate-800 text-base">بيانات الحساب البنكي للتحويل اليدوي</h3>
                <p className="text-xs text-slate-500 mt-0.5">تظهر هذه البيانات للعملاء في التطبيق عند اختيار "التحويل البنكي"</p>
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1.5">اسم البنك</label>
                <input 
                  type="text" 
                  value={bankName} 
                  onChange={e => setBankName(e.target.value)} 
                  placeholder="مثال: مصرف الراجحي"
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-sm focus:outline-none focus:border-teal-500" 
                />
              </div>
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1.5">اسم صاحب الحساب (المستفيد)</label>
                <input 
                  type="text" 
                  value={bankAccountName} 
                  onChange={e => setBankAccountName(e.target.value)} 
                  placeholder="مثال: مؤسسة السبح الفاخرة"
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-sm focus:outline-none focus:border-teal-500" 
                />
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1.5">رقم الحساب</label>
                <input 
                  type="text" 
                  value={bankAccountNumber} 
                  onChange={e => setBankAccountNumber(e.target.value)} 
                  placeholder="123456789012"
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-sm focus:outline-none focus:border-teal-500 font-mono" 
                />
              </div>
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1.5">رقم الآيبان (IBAN)</label>
                <input 
                  type="text" 
                  value={bankIban} 
                  onChange={e => setBankIban(e.target.value)} 
                  placeholder="SA0000000000000000000000"
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-sm focus:outline-none focus:border-teal-500 font-mono" 
                />
              </div>
            </div>
          </div>

          {/* Delivery & General Settings */}
          <div className="bg-white p-6 rounded-2xl border border-slate-200/80 shadow-sm space-y-4">
            <h3 className="font-bold text-slate-800 text-base pb-3 border-b border-slate-100">إعدادات المتجر والتوصيل</h3>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1.5">اسم المتجر</label>
                <input 
                  type="text" 
                  value={storeName} 
                  onChange={e => setStoreName(e.target.value)} 
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-sm focus:outline-none focus:border-teal-500" 
                />
              </div>
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1.5">رسوم التوصيل (ر.س)</label>
                <input 
                  type="number" 
                  value={deliveryFee} 
                  onChange={e => setDeliveryFee(e.target.value)} 
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-sm focus:outline-none focus:border-teal-500" 
                />
              </div>
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1.5">رقم هاتف الدعم / الواتساب</label>
                <input 
                  type="text" 
                  value={supportPhone} 
                  onChange={e => setSupportPhone(e.target.value)} 
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-sm focus:outline-none focus:border-teal-500 font-mono" 
                />
              </div>
            </div>
          </div>

          <div className="flex justify-end">
            <button
              type="submit"
              disabled={saving}
              className="flex items-center gap-2 bg-teal-600 hover:bg-teal-700 text-white px-8 py-3 rounded-xl font-bold text-sm shadow-md shadow-teal-600/20 disabled:opacity-50 transition-all"
            >
              {saving ? <Loader2 className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />}
              <span>حفظ الإعدادات</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
