const fs = require('fs');
const path = require('path');
const ws = require('ws');
const { createClient } = require('@supabase/supabase-js');

// Project credentials
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://mtoudbilmsrbeqpthehr.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im10b3VkYmlsbXNyYmVxcHRoZWhyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMwMDc1OTgsImV4cCI6MjEwODU4MzU5OH0.BMVtQHdAsC8Aa22rTt7QkVNRyuf6QZovDpE_el_Sk6g';

const supabase = createClient(supabaseUrl, supabaseKey, {
  realtime: {
    transport: ws,
  },
});

const rosaryNames = [
  'سبحة كهرمان بلطيقي طبيعي برائحة مميزة',
  'سبحة كوك تركي معرق بالفضة الخالصة',
  'سبحة يسر بحري مطعمة بالمرجان الطبيعي',
  'سبحة أبنوس أسود ملكي ناعم الملمس',
  'سبحة عقيق يماني كبدي أصلي',
  'سبحة فيروز نيشابوري أزرق ملكي',
  'سبحة سندلوس ألماني قديم شفاف',
  'سبحة مستكة عثمانية معطرة فاخرة',
  'سبحة خشب الصندل العطري الطبيعي',
  'سبحة حجر اللازورد الأفغاني الفاخر',
  'سبحة عين النمر البني الذهبي',
  'سبحة عاج طبيعي منقوش يدوياً',
  'سبحة مرجان تونسي أحمر طبيعي',
  'سبحة كوك مصري أصلي خفيف الوزن',
  'سبحة يسر حجازي مطعم بالفضة والأحجار',
  'سبحة كهرمان بولندي أصفر ليموني',
];

async function seed() {
  console.log('🚀 Starting Rosary Products Upload to Supabase...');

  // 1. Fetch categories
  const { data: categories, error: catErr } = await supabase.from('categories').select('*');
  if (catErr || !categories || categories.length === 0) {
    console.error('❌ Categories table not found or empty. Please run supabase_schema.sql first in Supabase SQL Editor!');
    return;
  }

  console.log(`✅ Found ${categories.length} categories.`);

  const imagesDir = path.resolve(__dirname, '../../assets/images');
  const files = fs.readdirSync(imagesDir).filter(f => f.startsWith('rosary_') && f.endsWith('.jpeg'));

  // Sort files numerically: rosary_1, rosary_2, ...
  files.sort((a, b) => {
    const numA = parseInt(a.replace('rosary_', '').replace('.jpeg', ''));
    const numB = parseInt(b.replace('rosary_', '').replace('.jpeg', ''));
    return numA - numB;
  });

  console.log(`📦 Found ${files.length} rosary image files to process.`);

  let successCount = 0;

  for (let i = 0; i < files.length; i++) {
    const fileName = files[i];
    const filePath = path.join(imagesDir, fileName);
    const fileBuffer = fs.readFileSync(filePath);

    // Storage destination
    const storagePath = `rosaries/${fileName}`;

    console.log(`[${i + 1}/${files.length}] Uploading ${fileName}...`);

    // Upload to 'products' bucket
    const { error: uploadErr } = await supabase.storage
      .from('products')
      .upload(storagePath, fileBuffer, {
        contentType: 'image/jpeg',
        upsert: true,
      });

    if (uploadErr) {
      console.warn(`  ⚠️ Upload warning for ${fileName}:`, uploadErr.message);
    }

    // Get public URL
    const { data: urlData } = supabase.storage.from('products').getPublicUrl(storagePath);
    const imageUrl = urlData.publicUrl;

    // Pick a name and category
    const nameAr = rosaryNames[i % rosaryNames.length] + ` (#${i + 1})`;
    const nameEn = `Luxury Rosary #${i + 1}`;
    const category = categories[i % categories.length];
    const basePrice = 90 + ((i * 17) % 260); // prices between 90 and 350 SAR
    const originalPrice = basePrice + 50;

    // Insert Product
    const { error: insertErr } = await supabase.from('products').insert([{
      name_ar: nameAr,
      name_en: nameEn,
      description_ar: `سبحة يدوية الصنع من خامات طبيعية ممتازة، خيط متين وشكة فاخرة مع كركوشة أنيقة ملائمة للهدايا والاستخدام اليومي.`,
      description_en: `Handcrafted premium luxury rosary made from high-grade natural materials with durable thread and elegant tassel.`,
      price: basePrice,
      original_price: originalPrice,
      stock: 10 + (i % 15),
      images: [imageUrl],
      category_id: category.id,
      is_available: true,
      is_featured: (i % 3 === 0),
      is_new: true,
      rating: 4.8 + ((i % 3) * 0.1),
      review_count: 5 + (i * 2),
    }]);

    if (insertErr) {
      console.error(`  ❌ Failed to insert product #${i + 1}:`, insertErr.message);
    } else {
      successCount++;
    }
  }

  console.log(`\n🎉 DONE! Successfully seeded ${successCount} rosary products into Supabase!`);
}

seed().catch(err => {
  console.error('Fatal error:', err);
});
