'use client';

import { useEffect, useState } from 'react';
import { Header } from '@/components/Header';
import { supabase, uploadImage } from '@/lib/supabase';
import { Banner } from '@/types/database';
import { Plus, Trash2, X, Loader2, UploadCloud, Image as ImageIcon } from 'lucide-react';

export default function BannersPage() {
  const [banners, setBanners] = useState<Banner[]>([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Form
  const [titleAr, setTitleAr] = useState('');
  const [linkUrl, setLinkUrl] = useState('');
  const [imageFile, setImageFile] = useState<File | null>(null);

  useEffect(() => {
    fetchBanners();
  }, []);

  async function fetchBanners() {
    setLoading(true);
    try {
      const { data } = await supabase.from('banners').select('*').order('sort_order', { ascending: true });
      if (data) setBanners(data as Banner[]);
    } finally {
      setLoading(false);
    }
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!imageFile) {
      alert('يرجى اختيار صورة للبانر');
      return;
    }

    setIsSubmitting(true);
    try {
      const uploadedUrl = await uploadImage(imageFile, 'banners');

      const { error } = await supabase.from('banners').insert([{
        title_ar: titleAr,
        link_url: linkUrl || null,
        image_url: uploadedUrl,
        is_active: true,
        sort_order: banners.length + 1
      }]);

      if (error) throw error;
      setIsModalOpen(false);
      setImageFile(null);
      setTitleAr('');
      setLinkUrl('');
      fetchBanners();
    } catch (err: any) {
      alert('خطأ أثناء رفع البانر: ' + err.message);
    } finally {
      setIsSubmitting(false);
    }
  }

  async function handleDelete(id: string) {
    if (!confirm('هل تريد حذف هذا البانر الإعلاني؟')) return;
    try {
      const { error } = await supabase.from('banners').delete().eq('id', id);
      if (error) throw error;
      setBanners(banners.filter(b => b.id !== id));
    } catch (err: any) {
      alert('خطأ: ' + err.message);
    }
  }

  async function toggleActive(id: string, current: boolean) {
    try {
      const { error } = await supabase.from('banners').update({ is_active: !current }).eq('id', id);
      if (error) throw error;
      setBanners(banners.map(b => b.id === id ? { ...b, is_active: !current } : b));
    } catch (err: any) {
      alert('خطأ: ' + err.message);
    }
  }

  return (
    <div>
      <Header 
        title="البانرات الإعلانية (Carousel)" 
        subtitle="إدارة البانرات والعروض الترويجية التي تظهر في شريط الصفحة الرئيسية للتطبيق" 
      />

      <div className="p-8 max-w-7xl mx-auto space-y-6">
        <div className="flex justify-between items-center bg-white p-4 rounded-2xl border border-slate-200/80 shadow-sm">
          <p className="text-xs text-slate-500 font-medium">البانرات النشطة: {banners.filter(b => b.is_active).length}</p>
          <button 
            onClick={() => setIsModalOpen(true)}
            className="flex items-center gap-2 bg-teal-600 hover:bg-teal-700 text-white px-5 py-2.5 rounded-xl font-bold text-sm shadow-md shadow-teal-600/20"
          >
            <Plus className="w-4 h-4" />
            <span>إضافة بانر جديد</span>
          </button>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {banners.map(b => (
            <div key={b.id} className="bg-white rounded-2xl border border-slate-200/80 shadow-sm overflow-hidden flex flex-col">
              <div className="h-44 bg-slate-100 overflow-hidden relative">
                <img src={b.image_url} alt={b.title_ar || 'بانر'} className="w-full h-full object-cover" />
                <button
                  onClick={() => toggleActive(b.id, b.is_active)}
                  className={`absolute top-3 right-3 px-2.5 py-1 rounded-full text-xs font-bold ${
                    b.is_active ? 'bg-emerald-600 text-white shadow-sm' : 'bg-slate-700 text-white'
                  }`}
                >
                  {b.is_active ? 'مفعل' : 'معطل'}
                </button>
              </div>
              <div className="p-4 flex items-center justify-between">
                <div>
                  <h4 className="font-bold text-slate-800 text-sm">{b.title_ar || 'بدون عنوان'}</h4>
                  {b.link_url && <p className="text-xs text-slate-400 font-mono mt-0.5">{b.link_url}</p>}
                </div>
                <button
                  onClick={() => handleDelete(b.id)}
                  className="p-2 rounded-xl bg-red-50 hover:bg-red-100 text-red-600 transition-colors"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>

      {isModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-md w-full p-6 shadow-2xl relative">
            <button onClick={() => setIsModalOpen(false)} className="absolute left-6 top-6 text-slate-400 hover:text-slate-600">
              <X className="w-6 h-6" />
            </button>
            <h3 className="text-lg font-bold text-slate-900 mb-5">إضافة بانر جديد</h3>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">عنوان البانر (اختياري)</label>
                <input 
                  type="text" 
                  value={titleAr} 
                  onChange={e => setTitleAr(e.target.value)} 
                  placeholder="مثال: خصم 20% بمناسبة اليوم الوطني"
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-sm focus:outline-none focus:border-teal-500" 
                />
              </div>
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">رابط عند الضغط (اختياري)</label>
                <input 
                  type="text" 
                  value={linkUrl} 
                  onChange={e => setLinkUrl(e.target.value)} 
                  placeholder="https://..."
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-sm focus:outline-none focus:border-teal-500 font-mono" 
                />
              </div>
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">صورة البانر العريضة *</label>
                <input 
                  type="file" 
                  required
                  accept="image/*"
                  onChange={e => setImageFile(e.target.files?.[0] || null)}
                  className="w-full text-xs text-slate-500 file:ml-4 file:py-2 file:px-4 file:rounded-xl file:border-0 file:text-xs file:font-semibold file:bg-teal-50 file:text-teal-700 hover:file:bg-teal-100" 
                />
              </div>
              <div className="pt-3 flex justify-end gap-2">
                <button type="button" onClick={() => setIsModalOpen(false)} className="px-4 py-2 text-xs font-bold text-slate-600">إلغاء</button>
                <button 
                  type="submit" 
                  disabled={isSubmitting}
                  className="bg-teal-600 hover:bg-teal-700 text-white px-5 py-2 rounded-xl text-xs font-bold flex items-center gap-1.5 shadow-md shadow-teal-600/20"
                >
                  {isSubmitting && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
                  <span>رفع وحفظ</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
