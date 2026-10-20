-- ==============================================================================
-- 🚀 SUPABASE SCHEMA FOR WA-APP (PRODUCTS, CATEGORIES, ORDERS & TRANSFERS)
-- ==============================================================================
-- Run this complete script in your Supabase Dashboard: SQL Editor -> New Query -> Run
-- ==============================================================================

-- 1. Enable UUID Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================================================
-- 2. TABLES CREATION
-- ==============================================================================

-- Categories Table
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name_ar TEXT NOT NULL,
    name_en TEXT NOT NULL,
    image_url TEXT,
    sort_order INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Products Table
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name_ar TEXT NOT NULL,
    name_en TEXT NOT NULL,
    description_ar TEXT,
    description_en TEXT,
    price NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    original_price NUMERIC(10, 2),
    stock INT NOT NULL DEFAULT 10,
    images TEXT[] DEFAULT ARRAY[]::TEXT[],
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    is_available BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false,
    is_new BOOLEAN DEFAULT true,
    rating NUMERIC(2, 1) DEFAULT 5.0,
    review_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Promotional Banners Table
CREATE TABLE IF NOT EXISTS public.banners (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title_ar TEXT,
    title_en TEXT,
    image_url TEXT NOT NULL,
    link_url TEXT,
    is_active BOOLEAN DEFAULT true,
    sort_order INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Orders Table
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number BIGSERIAL UNIQUE,
    customer_name TEXT NOT NULL,
    customer_phone TEXT NOT NULL,
    customer_address TEXT NOT NULL,
    city TEXT NOT NULL DEFAULT 'الرياض',
    subtotal NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    delivery_fee NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    total_price NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    payment_method TEXT NOT NULL CHECK (payment_method IN ('cod', 'bank_transfer')),
    payment_status TEXT NOT NULL DEFAULT 'pending' CHECK (payment_status IN ('pending', 'confirmed', 'failed', 'refunded')),
    order_status TEXT NOT NULL DEFAULT 'new' CHECK (order_status IN ('new', 'processing', 'shipped', 'delivered', 'cancelled')),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Order Items Table
CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
    product_name TEXT NOT NULL,
    product_image TEXT,
    quantity INT NOT NULL DEFAULT 1,
    unit_price NUMERIC(10, 2) NOT NULL,
    total_price NUMERIC(10, 2) NOT NULL
);

-- Bank Transfers (Receipts) Table
CREATE TABLE IF NOT EXISTS public.bank_transfers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    receipt_url TEXT NOT NULL,
    sender_name TEXT,
    bank_name TEXT,
    verified BOOLEAN DEFAULT false,
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Store Settings Table (Bank details, shipping fee, etc.)
CREATE TABLE IF NOT EXISTS public.store_settings (
    id TEXT PRIMARY KEY DEFAULT 'main',
    store_name TEXT DEFAULT 'متجر السبح الفاخرة',
    bank_name TEXT DEFAULT 'مصرف الراجحي',
    bank_account_name TEXT DEFAULT 'متجر السبح',
    bank_account_number TEXT DEFAULT '12345678901234',
    bank_iban TEXT DEFAULT 'SA0000000000000000000000',
    delivery_fee NUMERIC(10, 2) DEFAULT 25.00,
    free_delivery_threshold NUMERIC(10, 2) DEFAULT 250.00,
    support_phone TEXT DEFAULT '+966500000000',
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- ==============================================================================
-- 3. STORAGE BUCKETS CREATION
-- ==============================================================================

INSERT INTO storage.buckets (id, name, public)
VALUES 
    ('products', 'products', true),
    ('banners', 'banners', true),
    ('receipts', 'receipts', true)
ON CONFLICT (id) DO NOTHING;

-- ==============================================================================
-- 4. ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

-- Enable RLS on all tables
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.banners ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bank_transfers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.store_settings ENABLE ROW LEVEL SECURITY;

-- 1. Public can READ categories, products, banners, and store settings
CREATE POLICY "Public Read Categories" ON public.categories FOR SELECT USING (true);
CREATE POLICY "Public Read Products" ON public.products FOR SELECT USING (is_available = true OR auth.role() = 'authenticated');
CREATE POLICY "Public Read Banners" ON public.banners FOR SELECT USING (is_active = true OR auth.role() = 'authenticated');
CREATE POLICY "Public Read Store Settings" ON public.store_settings FOR SELECT USING (true);

-- 2. Anyone (including guests) can INSERT orders, order_items, and receipts
CREATE POLICY "Allow Insert Orders" ON public.orders FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow Insert Order Items" ON public.order_items FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow Insert Bank Transfers" ON public.bank_transfers FOR INSERT WITH CHECK (true);

-- 3. Authenticated Admin has FULL access to everything
CREATE POLICY "Admin Full Access Categories" ON public.categories FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Admin Full Access Products" ON public.products FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Admin Full Access Banners" ON public.banners FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Admin Full Access Orders" ON public.orders FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Admin Full Access Order Items" ON public.order_items FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Admin Full Access Bank Transfers" ON public.bank_transfers FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Admin Full Access Store Settings" ON public.store_settings FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 4. Storage Policies: Allow public read of images
CREATE POLICY "Public Access Products Bucket" ON storage.objects FOR SELECT USING (bucket_id = 'products');
CREATE POLICY "Public Access Banners Bucket" ON storage.objects FOR SELECT USING (bucket_id = 'banners');
CREATE POLICY "Public Access Receipts Bucket" ON storage.objects FOR SELECT USING (bucket_id = 'receipts');

-- Allow anyone to upload receipts and allow authenticated users to upload products & banners
CREATE POLICY "Anyone Can Upload Receipts" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'receipts');
CREATE POLICY "Admin Can Upload Products" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'products');
CREATE POLICY "Admin Can Upload Banners" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'banners');
CREATE POLICY "Admin Can Delete Files" ON storage.objects FOR DELETE TO authenticated USING (true);

-- ==============================================================================
-- 5. INITIAL SEED DATA
-- ==============================================================================

-- Seed Categories
INSERT INTO public.categories (name_ar, name_en, sort_order)
VALUES 
    ('سبح كهرمان طبيعي', 'Amber Rosaries', 1),
    ('سبح كوك ومستكة', 'Kuka & Mastic', 2),
    ('سبح خشب الأبنوس والصندل', 'Ebony & Sandalwood', 3),
    ('سبح عقيق وأحجار كريمة', 'Agate & Gemstones', 4),
    ('سبح يسر مكي مطعم بالفضة', 'Yusr with Silver', 5)
ON CONFLICT DO NOTHING;

-- Seed Store Settings
INSERT INTO public.store_settings (id, store_name, bank_name, bank_account_name, bank_account_number, bank_iban, delivery_fee)
VALUES (
    'main',
    'متجر السبح الفاخرة',
    'مصرف الراجحي',
    'مؤسسة السبح الفاخرة للتجارة',
    '23847291038472',
    'SA458000023847291038472',
    25.00
) ON CONFLICT (id) DO NOTHING;
