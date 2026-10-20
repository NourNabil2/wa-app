'use client';

import { useEffect, useState } from 'react';
import { Header } from '@/components/Header';
import { supabase, uploadImage } from '@/lib/supabase';
import { Product, Category } from '@/types/database';
import { 
  Plus, 
  Search, 
  Trash2, 
  Edit3, 
  Image as ImageIcon, 
  Check, 
  X, 
  Loader2,
  UploadCloud 
} from 'lucide-react';

export default function ProductsPage() {
  const [products, setProducts] = useState<Product[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [searchQuery, setSearchQuery] = useState<string>('');
  
  // Modal State
  const [isModalOpen, setIsModalOpen] = useState<boolean>(false);
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);

  // Form State
  const [nameAr, setNameAr] = useState('');
  const [nameEn, setNameEn] = useState('');
  const [price, setPrice] = useState('');
  const [originalPrice, setOriginalPrice] = useState('');
  const [stock, setStock] = useState('15');
  const [categoryId, setCategoryId] = useState('');
  const [descriptionAr, setDescriptionAr] = useState('');
  const [imageUrl, setImageUrl] = useState('');
  const [imageFiles, setImageFiles] = useState<File[]>([]);
  const [isFeatured, setIsFeatured] = useState(false);
  const [isAvailable, setIsAvailable] = useState(true);

  useEffect(() => {
    fetchData();
  }, []);

  async function fetchData() {
    setLoading(true);
    try {
      const [{ data: productsData }, { data: categoriesData }] = await Promise.all([
        supabase.from('products').select('*, category:categories(*)').order('created_at', { ascending: false }),
        supabase.from('categories').select('*').order('sort_order', { ascending: true })
      ]);

      if (productsData) setProducts(productsData as Product[]);
      if (categoriesData) setCategories(categoriesData as Category[]);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  }

  function openAddModal() {
    setEditingProduct(null);
    setNameAr('');
    setNameEn('');
    setPrice('');
    setOriginalPrice('');
    setStock('15');
    setCategoryId(categories[0]?.id || '');
    setDescriptionAr('');
    setImageUrl('');
    setImageFiles([]);
    setIsFeatured(false);
    setIsAvailable(true);
    setIsModalOpen(true);
  }

  function openEditModal(prod: Product) {
    setEditingProduct(prod);
    setNameAr(prod.name_ar);
    setNameEn(prod.name_en || '');
    setPrice(prod.price.toString());
    setOriginalPrice(prod.original_price?.toString() || '');
    setStock(prod.stock.toString());
    setCategoryId(prod.category_id || '');
    setDescriptionAr(prod.description_ar || '');
    setImageUrl(prod.images?.[0] || '');
    setImageFiles([]);
    setIsFeatured(prod.is_featured);
    setIsAvailable(prod.is_available);
    setIsModalOpen(true);
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!nameAr || !price) {
      alert('يرجى ملء اسم المنتج والسعر');
      return;
    }

    setIsSubmitting(true);
    try {
      let finalImages: string[] = editingProduct?.images || [];

      // If user uploaded new files
      if (imageFiles.length > 0) {
        for (const file of imageFiles) {
          const uploadedUrl = await uploadImage(file, 'products');
          finalImages.push(uploadedUrl);
        }
      } else if (imageUrl && !finalImages.includes(imageUrl)) {
        finalImages = [imageUrl, ...finalImages];
      }

      const payload = {
        name_ar: nameAr,
        name_en: nameEn || nameAr,
        price: parseFloat(price),
        original_price: originalPrice ? parseFloat(originalPrice) : null,
        stock: parseInt(stock) || 10,
        category_id: categoryId || null,
        description_ar: descriptionAr,
        images: finalImages,
        is_featured: isFeatured,
        is_available: isAvailable,
        updated_at: new Date().toISOString()
      };

      if (editingProduct) {
        const { error } = await supabase.from('products').update(payload).eq('id', editingProduct.id);
        if (error) throw error;
      } else {
        const { error } = await supabase.from('products').insert([payload]);
        if (error) throw error;
      }

      setIsModalOpen(false);
      fetchData();
    } catch (err: any) {
      alert('حدث خطأ أثناء حفظ المنتج: ' + err.message);
    } finally {
      setIsSubmitting(false);
    }
  }

  async function handleDelete(id: string) {
    if (!confirm('هل أنت متأكد من حذف هذا المنتج نهائياً؟')) return;
    try {
      const { error } = await supabase.from('products').delete().eq('id', id);
      if (error) throw error;
      setProducts(products.filter(p => p.id !== id));
    } catch (err: any) {
      alert('حدث خطأ أثناء الحذف: ' + err.message);
    }
  }

  const filteredProducts = products.filter(p => 
    p.name_ar.toLowerCase().includes(searchQuery.toLowerCase()) ||
    (p.name_en && p.name_en.toLowerCase().includes(searchQuery.toLowerCase()))
  );

  return (
    <div>
      <Header 
        title="إدارة المنتجات والسبح" 
        subtitle="إضافة وتعديل السبح، الأسعار، الصور، وتحديد الكميات المتوفرة" 
      />

      <div className="p-8 max-w-7xl mx-auto space-y-6">
        {/* Controls Bar */}
        <div className="flex flex-col sm:flex-row items-center justify-between gap-4 bg-white p-4 rounded-2xl border border-slate-200/80 shadow-sm">
          <div className="relative w-full sm:w-96">
            <Search className="w-4 h-4 text-slate-400 absolute right-3.5 top-3" />
            <input 
              type="text"
              placeholder="البحث باسم المنتج أو السبحة..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-4 pr-10 py-2 rounded-xl bg-slate-50 border border-slate-200 text-sm focus:outline-none focus:border-teal-500 transition-colors"
            />
          </div>

          <button 
            onClick={openAddModal}
            className="flex items-center gap-2 bg-teal-600 hover:bg-teal-700 text-white px-5 py-2.5 rounded-xl font-bold text-sm shadow-md shadow-teal-600/20 transition-all w-full sm:w-auto justify-center"
          >
            <Plus className="w-4 h-4" />
            <span>إضافة سبحة / منتج جديد</span>
          </button>
        </div>

        {/* Products Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {filteredProducts.map((product) => {
            const firstImg = product.images?.[0] || '/placeholder.png';
            return (
              <div key={product.id} className="bg-white rounded-2xl border border-slate-200/80 shadow-sm overflow-hidden flex flex-col group hover:shadow-md transition-shadow">
                {/* Image Box */}
                <div className="relative aspect-square bg-slate-100 overflow-hidden flex items-center justify-center">
                  {product.images?.[0] ? (
                    <img 
                      src={firstImg} 
                      alt={product.name_ar} 
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                    />
                  ) : (
                    <div className="text-slate-300 flex flex-col items-center">
                      <ImageIcon className="w-10 h-10" />
                      <span className="text-xs mt-1">بدون صورة</span>
                    </div>
                  )}

                  {/* Stock Tag */}
                  <span className={`absolute top-3 right-3 px-2.5 py-1 rounded-full text-xs font-bold ${
                    product.stock > 0 ? 'bg-white/90 text-slate-700 shadow-sm' : 'bg-red-500 text-white'
                  }`}>
                    {product.stock > 0 ? `المتوفر: ${product.stock}` : 'نفذت الكمية'}
                  </span>

                  {/* Status Toggle */}
                  <span className={`absolute top-3 left-3 px-2 py-0.5 rounded-md text-[10px] font-bold ${
                    product.is_available ? 'bg-emerald-500 text-white' : 'bg-slate-500 text-white'
                  }`}>
                    {product.is_available ? 'معروض' : 'مخفي'}
                  </span>
                </div>

                {/* Details */}
                <div className="p-4 flex-1 flex flex-col justify-between">
                  <div>
                    <span className="text-[11px] font-semibold text-teal-600">
                      {product.category?.name_ar || 'قسم عام'}
                    </span>
                    <h4 className="font-bold text-slate-900 text-base mt-1 line-clamp-1">{product.name_ar}</h4>
                    {product.name_en && (
                      <p className="text-xs text-slate-400 font-sans mt-0.5 line-clamp-1">{product.name_en}</p>
                    )}
                  </div>

                  <div className="pt-4 mt-4 border-t border-slate-100 flex items-center justify-between">
                    <div>
                      <span className="text-base font-black text-slate-900">{product.price} ر.س</span>
                      {product.original_price && (
                        <span className="text-xs text-slate-400 line-through mr-2 font-medium">
                          {product.original_price} ر.س
                        </span>
                      )}
                    </div>

                    <div className="flex items-center gap-1.5">
                      <button 
                        onClick={() => openEditModal(product)}
                        className="p-2 rounded-lg bg-slate-50 hover:bg-slate-100 text-slate-600 transition-colors"
                        title="تعديل"
                      >
                        <Edit3 className="w-4 h-4" />
                      </button>
                      <button 
                        onClick={() => handleDelete(product.id)}
                        className="p-2 rounded-lg bg-red-50 hover:bg-red-100 text-red-600 transition-colors"
                        title="حذف"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Modal: Add / Edit Product */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4 overflow-y-auto">
          <div className="bg-white rounded-3xl max-w-2xl w-full p-6 shadow-2xl relative my-8">
            <button 
              onClick={() => setIsModalOpen(false)}
              className="absolute left-6 top-6 text-slate-400 hover:text-slate-600"
            >
              <X className="w-6 h-6" />
            </button>

            <h3 className="text-xl font-bold text-slate-900 mb-6">
              {editingProduct ? 'تعديل بيانات المنتج' : 'إضافة سبحة / منتج جديد'}
            </h3>

            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1.5">اسم المنتج بالعربي *</label>
                  <input 
                    type="text" 
                    required 
                    value={nameAr} 
                    onChange={e => setNameAr(e.target.value)}
                    placeholder="مثال: سبحة كوك إسلامية فاخرة"
                    className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-sm focus:outline-none focus:border-teal-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1.5">اسم المنتج بالإنجليزي</label>
                  <input 
                    type="text" 
                    value={nameEn} 
                    onChange={e => setNameEn(e.target.value)}
                    placeholder="e.g. Premium Kuka Rosary"
                    className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-sm focus:outline-none focus:border-teal-500 font-sans"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1.5">السعر الحالي (ر.س) *</label>
                  <input 
                    type="number" 
                    step="0.01" 
                    required 
                    value={price} 
                    onChange={e => setPrice(e.target.value)}
                    placeholder="99.00"
                    className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-sm focus:outline-none focus:border-teal-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1.5">السعر قبل الخصم (اختياري)</label>
                  <input 
                    type="number" 
                    step="0.01" 
                    value={originalPrice} 
                    onChange={e => setOriginalPrice(e.target.value)}
                    placeholder="140.00"
                    className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-sm focus:outline-none focus:border-teal-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1.5">الكمية المتوفرة (المخزون)</label>
                  <input 
                    type="number" 
                    required 
                    value={stock} 
                    onChange={e => setStock(e.target.value)}
                    className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-sm focus:outline-none focus:border-teal-500"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1.5">القسم / التصنيف</label>
                <select 
                  value={categoryId} 
                  onChange={e => setCategoryId(e.target.value)}
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-sm focus:outline-none focus:border-teal-500 bg-white"
                >
                  <option value="">اختر قسماً</option>
                  {categories.map(c => (
                    <option key={c.id} value={c.id}>{c.name_ar}</option>
                  ))}
                </select>
              </div>

              {/* Upload image */}
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1.5">رفع صور المنتج (مباشرة إلى Supabase)</label>
                <div className="border-2 border-dashed border-slate-200 rounded-2xl p-4 text-center hover:bg-slate-50 transition-colors">
                  <input 
                    type="file" 
                    multiple 
                    accept="image/*"
                    onChange={e => setImageFiles(Array.from(e.target.files || []))}
                    className="hidden"
                    id="product-images-input"
                  />
                  <label htmlFor="product-images-input" className="cursor-pointer flex flex-col items-center">
                    <UploadCloud className="w-8 h-8 text-teal-600 mb-2" />
                    <span className="text-sm font-semibold text-slate-700">اضغط لرفع صور من جهازك</span>
                    <span className="text-xs text-slate-400 mt-1">PNG, JPG, WEBP تصل إلى 5 ميجابايت</span>
                  </label>
                </div>
                {imageFiles.length > 0 && (
                  <p className="text-xs text-teal-600 font-semibold mt-2">
                    تم اختيار {imageFiles.length} صورة جاهزة للرفع
                  </p>
                )}
              </div>

              {/* Toggle Options */}
              <div className="flex items-center gap-6 pt-2">
                <label className="flex items-center gap-2 cursor-pointer">
                  <input 
                    type="checkbox" 
                    checked={isAvailable} 
                    onChange={e => setIsAvailable(e.target.checked)}
                    className="w-4 h-4 text-teal-600 rounded"
                  />
                  <span className="text-xs font-bold text-slate-700">متاح للبيع في التطبيق</span>
                </label>
                <label className="flex items-center gap-2 cursor-pointer">
                  <input 
                    type="checkbox" 
                    checked={isFeatured} 
                    onChange={e => setIsFeatured(e.target.checked)}
                    className="w-4 h-4 text-teal-600 rounded"
                  />
                  <span className="text-xs font-bold text-slate-700">عرض في القسم المميز</span>
                </label>
              </div>

              <div className="pt-4 border-t border-slate-100 flex items-center justify-end gap-3">
                <button 
                  type="button" 
                  onClick={() => setIsModalOpen(false)}
                  className="px-5 py-2.5 rounded-xl border border-slate-200 text-sm font-bold text-slate-600 hover:bg-slate-50"
                >
                  إلغاء
                </button>
                <button 
                  type="submit" 
                  disabled={isSubmitting}
                  className="flex items-center gap-2 bg-teal-600 hover:bg-teal-700 text-white px-6 py-2.5 rounded-xl font-bold text-sm shadow-md shadow-teal-600/20 disabled:opacity-50"
                >
                  {isSubmitting && <Loader2 className="w-4 h-4 animate-spin" />}
                  <span>{editingProduct ? 'تحديث المنتج' : 'حفظ المنتج'}</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
