'use client';

import { useEffect, useState } from 'react';
import { Header } from '@/components/Header';
import { supabase, uploadImage } from '@/lib/supabase';
import { Category } from '@/types/database';
import { Plus, Trash2, Edit3, X, Loader2, UploadCloud, Layers } from 'lucide-react';

export default function CategoriesPage() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [editingCategory, setEditingCategory] = useState<Category | null>(null);

  // Form
  const [nameAr, setNameAr] = useState('');
  const [nameEn, setNameEn] = useState('');
  const [sortOrder, setSortOrder] = useState('0');
  const [imageFile, setImageFile] = useState<File | null>(null);

  useEffect(() => {
    fetchCategories();
  }, []);

  async function fetchCategories() {
    setLoading(true);
    try {
      const { data } = await supabase.from('categories').select('*').order('sort_order', { ascending: true });
      if (data) setCategories(data as Category[]);
    } finally {
      setLoading(false);
    }
  }

  function openAddModal() {
    setEditingCategory(null);
    setNameAr('');
    setNameEn('');
    setSortOrder((categories.length + 1).toString());
    setImageFile(null);
    setIsModalOpen(true);
  }

  function openEditModal(c: Category) {
    setEditingCategory(c);
    setNameAr(c.name_ar);
    setNameEn(c.name_en || '');
    setSortOrder(c.sort_order.toString());
    setImageFile(null);
    setIsModalOpen(true);
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!nameAr) {
      alert('اسم القسم بالعربي مطلوب');
      return;
    }

    setIsSubmitting(true);
    try {
      let imageUrl = editingCategory?.image_url || null;

      if (imageFile) {
        imageUrl = await uploadImage(imageFile, 'products');
      }

      const payload = {
        name_ar: nameAr,
        name_en: nameEn || nameAr,
        sort_order: parseInt(sortOrder) || 0,
        image_url: imageUrl,
      };

      if (editingCategory) {
        const { error } = await supabase.from('categories').update(payload).eq('id', editingCategory.id);
        if (error) throw error;
      } else {
        const { error } = await supabase.from('categories').insert([payload]);
        if (error) throw error;
      }

      setIsModalOpen(false);
      fetchCategories();
    } catch (err: any) {
      alert('خطأ: ' + err.message);
    } finally {
      setIsSubmitting(false);
    }
  }

  async function handleDelete(id: string) {
    if (!confirm('هل تريد حذف هذا القسم؟')) return;
    try {
      const { error } = await supabase.from('categories').delete().eq('id', id);
      if (error) throw error;
      setCategories(categories.filter(c => c.id !== id));
    } catch (err: any) {
      alert('خطأ أثناء الحذف: ' + err.message);
    }
  }

  return (
    <div>
      <Header 
        title="الأقسام والتصنيفات" 
        subtitle="إدارة تصنيفات السبح التي تظهر في شريط الأقسام الدائري في التطبيق" 
      />

      <div className="p-8 max-w-7xl mx-auto space-y-6">
        <div className="flex justify-between items-center bg-white p-4 rounded-2xl border border-slate-200/80 shadow-sm">
          <p className="text-xs text-slate-500 font-medium">عدد الأقسام الحالية: {categories.length}</p>
          <button 
            onClick={openAddModal}
            className="flex items-center gap-2 bg-teal-600 hover:bg-teal-700 text-white px-5 py-2.5 rounded-xl font-bold text-sm shadow-md shadow-teal-600/20"
          >
            <Plus className="w-4 h-4" />
            <span>إضافة قسم جديد</span>
          </button>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-5">
          {categories.map((c) => (
            <div key={c.id} className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-sm flex flex-col items-center text-center relative group">
              <div className="w-20 h-20 rounded-full bg-slate-100 overflow-hidden mb-3 border border-slate-200 flex items-center justify-center">
                {c.image_url ? (
                  <img src={c.image_url} alt={c.name_ar} className="w-full h-full object-cover" />
                ) : (
                  <Layers className="w-8 h-8 text-teal-600" />
                )}
              </div>

              <h4 className="font-bold text-slate-800 text-sm">{c.name_ar}</h4>
              <p className="text-xs text-slate-400 font-sans mt-0.5">{c.name_en}</p>

              <div className="mt-4 pt-3 border-t border-slate-100 flex items-center gap-2 w-full justify-center">
                <button
                  onClick={() => openEditModal(c)}
                  className="p-1.5 rounded-lg bg-slate-50 hover:bg-slate-100 text-slate-600 text-xs font-semibold flex items-center gap-1"
                >
                  <Edit3 className="w-3.5 h-3.5" />
                  <span>تعديل</span>
                </button>
                <button
                  onClick={() => handleDelete(c.id)}
                  className="p-1.5 rounded-lg bg-red-50 hover:bg-red-100 text-red-600 text-xs font-semibold flex items-center gap-1"
                >
                  <Trash2 className="w-3.5 h-3.5" />
                  <span>حذف</span>
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
            <h3 className="text-lg font-bold text-slate-900 mb-5">
              {editingCategory ? 'تعديل القسم' : 'إضافة قسم جديد'}
            </h3>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">اسم القسم بالعربي *</label>
                <input 
                  type="text" 
                  required 
                  value={nameAr} 
                  onChange={e => setNameAr(e.target.value)} 
                  placeholder="مثال: سبح كوك"
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-sm focus:outline-none focus:border-teal-500" 
                />
              </div>
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">اسم القسم بالإنجليزي</label>
                <input 
                  type="text" 
                  value={nameEn} 
                  onChange={e => setNameEn(e.target.value)} 
                  placeholder="e.g. Kuka Rosaries"
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-sm focus:outline-none focus:border-teal-500 font-sans" 
                />
              </div>
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">صورة القسم (دائرية)</label>
                <input 
                  type="file" 
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
                  <span>حفظ</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
