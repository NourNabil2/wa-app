export interface Category {
  id: string;
  name_ar: string;
  name_en: string;
  image_url: string | null;
  sort_order: number;
  created_at: string;
}

export interface Product {
  id: string;
  name_ar: string;
  name_en: string;
  description_ar: string | null;
  description_en: string | null;
  price: number;
  original_price: number | null;
  stock: number;
  images: string[];
  category_id: string | null;
  category?: Category;
  is_available: boolean;
  is_featured: boolean;
  is_new: boolean;
  rating: number;
  review_count: number;
  created_at: string;
}

export interface OrderItem {
  id: string;
  order_id: string;
  product_id: string | null;
  product_name: string;
  product_image: string | null;
  quantity: number;
  unit_price: number;
  total_price: number;
}

export interface BankTransfer {
  id: string;
  order_id: string;
  receipt_url: string;
  sender_name: string | null;
  bank_name: string | null;
  verified: boolean;
  verified_at: string | null;
  created_at: string;
}

export interface Order {
  id: string;
  order_number: number;
  customer_name: string;
  customer_phone: string;
  customer_address: string;
  city: string;
  subtotal: number;
  delivery_fee: number;
  total_price: number;
  payment_method: 'cod' | 'bank_transfer';
  payment_status: 'pending' | 'confirmed' | 'failed' | 'refunded';
  order_status: 'new' | 'processing' | 'shipped' | 'delivered' | 'cancelled';
  notes: string | null;
  created_at: string;
  order_items?: OrderItem[];
  bank_transfers?: BankTransfer[];
}

export interface Banner {
  id: string;
  title_ar: string | null;
  title_en: string | null;
  image_url: string;
  link_url: string | null;
  is_active: boolean;
  sort_order: number;
  created_at: string;
}

export interface StoreSettings {
  id: string;
  store_name: string;
  bank_name: string;
  bank_account_name: string;
  bank_account_number: string;
  bank_iban: string;
  delivery_fee: number;
  free_delivery_threshold: number;
  support_phone: string;
  updated_at: string;
}
