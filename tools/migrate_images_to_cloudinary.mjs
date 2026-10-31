#!/usr/bin/env node

/**
 * سكريبت نقل الصور من ImgBB إلى Cloudinary
 * ----------------------------------------------------
 * يقوم هذا السكريبت بفحص جميع مجموعات ومستندات Firestore،
 * والبحث عن أي روابط صور تتبع ImgBB (i.ibb.co)،
 * ورفعها مباشرة إلى حساب Cloudinary مع آلية إعادة محاولة ذكية
 * لتجاوز قيود واختناقات سيرفر ImgBB، ثم تحديث الروابط في Firestore.
 *
 * الاستخدام:
 *   node tools/migrate_images_to_cloudinary.mjs --dry-run   (فحص ومعاينة الروابط دون تعديل)
 *   node tools/migrate_images_to_cloudinary.mjs             (تنفيذ النقل الفعلي والتحديث)
 */

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import admin from 'firebase-admin';

const CLOUDINARY_CONFIG = {
  cloudName: process.env.CLOUDINARY_CLOUD_NAME || 'ygfhtwug',
  apiKey: process.env.CLOUDINARY_API_KEY || '686447129682517',
  apiSecret: process.env.CLOUDINARY_API_SECRET || 'OjJA1hedgYv_idsy5jGpFoD6V3s',
  folder: 'qarity_migrated',
};

function getServiceAccountPath() {
  const root = process.cwd();
  const files = fs.readdirSync(root);
  const match = files.find(
    (f) => f.startsWith('abudshisha-firebase-adminsdk') && f.endsWith('.json')
  );
  if (match) return path.join(root, match);
  if (fs.existsSync(path.join(root, 'serviceAccountKey.json'))) {
    return path.join(root, 'serviceAccountKey.json');
  }
  return null;
}

const TARGET_COLLECTIONS = [
  'news',
  'market_products',
  'shops',
  'obituaries',
  'occasions',
  'forum_posts',
  'lost_items',
  'village_ads',
  'users',
  'service_providers',
  'medical_center_clinics',
  'village_clinics',
  'pharmacies',
  'optical_shops',
  'lawyers',
  'legal_consultations',
  'agriculture_content',
  'agriculture_consultations',
  'emergency_contacts',
  'village_info',
  'promos',
];

function isImgBbUrl(val) {
  if (typeof val !== 'string') return false;
  return val.includes('i.ibb.co') || val.includes('ibb.co/');
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function fetchWithRetry(url, retries = 3) {
  for (let i = 1; i <= retries; i++) {
    try {
      const res = await fetch(url, {
        headers: {
          'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          Accept: 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
        },
      });
      if (res.ok) {
        const buffer = await res.arrayBuffer();
        const mime = res.headers.get('content-type') || 'image/jpeg';
        return `data:${mime};base64,${Buffer.from(buffer).toString('base64')}`;
      }
    } catch (_) {}
    if (i < retries) await sleep(2000 * i);
  }
  return null;
}

async function uploadToCloudinary(filePayload) {
  const timestamp = Math.round(Date.now() / 1000);
  const folder = CLOUDINARY_CONFIG.folder;

  const strToSign = `folder=${folder}&timestamp=${timestamp}${CLOUDINARY_CONFIG.apiSecret}`;
  const signature = crypto.createHash('sha1').update(strToSign).digest('hex');

  const body = new URLSearchParams();
  body.append('file', filePayload);
  body.append('api_key', CLOUDINARY_CONFIG.apiKey);
  body.append('timestamp', timestamp.toString());
  body.append('folder', folder);
  body.append('signature', signature);

  const res = await fetch(
    `https://api.cloudinary.com/v1_1/${CLOUDINARY_CONFIG.cloudName}/image/upload`,
    {
      method: 'POST',
      body,
    }
  );

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`HTTP ${res.status}: ${errText}`);
  }

  const data = await res.json();
  return data.secure_url;
}

async function smartMigrateImage(oldUrl) {
  // محاولة الرفع المباشر عبر السيرفر
  try {
    return await uploadToCloudinary(oldUrl);
  } catch (directErr) {
    // إذا فشل سيرفر ImgBB أو أعطى Timeout لكلاوديناري، نحاول السحب المحلي كـ Base64
    const base64Data = await fetchWithRetry(oldUrl, 3);
    if (base64Data) {
      return await uploadToCloudinary(base64Data);
    }
    throw directErr;
  }
}

async function main() {
  const isDryRun = process.argv.includes('--dry-run');

  console.log('='.repeat(65));
  console.log('🚀 أداة ترحيل الصور من ImgBB إلى Cloudinary — مشروع قرية أبوديشيشة');
  console.log('='.repeat(65));
  console.log(
    `الوضع الحالي: ${isDryRun ? '🔍 فحص ومعاينة فقط (Dry-Run)' : '⚡ نقل وتعديل فعلي (Live Migration)'}`
  );
  console.log(`حساب Cloudinary: ${CLOUDINARY_CONFIG.cloudName}`);

  const serviceAccountPath = getServiceAccountPath();
  if (!serviceAccountPath) {
    console.error('❌ لم يتم العثور على ملف Firebase Service Account في المجلد الرئيسي!');
    process.exit(1);
  }

  const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: 'abudshisha',
  });

  const db = admin.firestore();

  const cacheFile = path.join(process.cwd(), 'tools', 'migrated_images_cache.json');
  let cache = {};
  if (fs.existsSync(cacheFile)) {
    try {
      cache = JSON.parse(fs.readFileSync(cacheFile, 'utf8'));
    } catch (_) {}
  }

  let totalDocsScanned = 0;
  let totalImagesFound = 0;
  let totalImagesMigrated = 0;
  let totalDocsUpdated = 0;
  const errors = [];

  for (const colName of TARGET_COLLECTIONS) {
    process.stdout.write(`\n📁 فحص مجموعة: ${colName}... `);
    let snapshot;
    try {
      snapshot = await db.collection(colName).get();
    } catch (e) {
      console.log(`⚠️ تعذر الوصول: ${e.message}`);
      continue;
    }

    console.log(`(${snapshot.docs.length} مستند)`);

    for (const doc of snapshot.docs) {
      totalDocsScanned++;
      const data = doc.data();
      const updates = {};

      for (const [key, value] of Object.entries(data)) {
        if (typeof value === 'string' && isImgBbUrl(value)) {
          totalImagesFound++;

          if (isDryRun) {
            console.log(`   [معاينة] مستند: ${doc.id} | حقل: ${key} -> ${value}`);
          } else {
            let newUrl = cache[value];
            if (!newUrl) {
              process.stdout.write(`   ⬆️ نقل صورة [${doc.id} - ${key}]... `);
              try {
                await sleep(1000);
                newUrl = await smartMigrateImage(value);
                cache[value] = newUrl;
                fs.writeFileSync(cacheFile, JSON.stringify(cache, null, 2), 'utf8');
                console.log(`✅ تم!`);
                updates[key] = newUrl;
                totalImagesMigrated++;
              } catch (err) {
                console.log(`⚠️ تخطي (تعذر من ImgBB): ${err.message.substring(0, 70)}`);
                errors.push({ collection: colName, docId: doc.id, field: key, url: value, error: err.message });
              }
            } else {
              updates[key] = newUrl;
              totalImagesMigrated++;
            }
          }
        } else if (Array.isArray(value)) {
          let arrayChanged = false;
          const newArray = [];

          for (const item of value) {
            if (typeof item === 'string' && isImgBbUrl(item)) {
              totalImagesFound++;
              arrayChanged = true;

              if (isDryRun) {
                console.log(`   [معاينة] مستند: ${doc.id} | مصفوفة: ${key} -> ${item}`);
                newArray.push(item);
              } else {
                let newUrl = cache[item];
                if (!newUrl) {
                  process.stdout.write(`   ⬆️ نقل صورة [${doc.id} - ${key}[]]... `);
                  try {
                    await sleep(1000);
                    newUrl = await smartMigrateImage(item);
                    cache[item] = newUrl;
                    fs.writeFileSync(cacheFile, JSON.stringify(cache, null, 2), 'utf8');
                    console.log(`✅ تم!`);
                    newArray.push(newUrl);
                    totalImagesMigrated++;
                  } catch (err) {
                    console.log(`⚠️ تخطي (تعذر من ImgBB): ${err.message.substring(0, 70)}`);
                    newArray.push(item);
                    errors.push({ collection: colName, docId: doc.id, field: key, url: item, error: err.message });
                  }
                } else {
                  newArray.push(newUrl);
                  totalImagesMigrated++;
                }
              }
            } else {
              newArray.push(item);
            }
          }

          if (arrayChanged && !isDryRun) {
            updates[key] = newArray;
          }
        }
      }

      if (!isDryRun && Object.keys(updates).length > 0) {
        try {
          await db.collection(colName).doc(doc.id).update(updates);
          totalDocsUpdated++;
        } catch (e) {
          console.error(`❌ خطأ أثناء تحديث المستند ${doc.id} في ${colName}:`, e.message);
          errors.push({ collection: colName, docId: doc.id, error: e.message });
        }
      }
    }
  }

  console.log('\n' + '='.repeat(65));
  console.log('📊 ملخص عملية فحص وترحيل الصور:');
  console.log('='.repeat(65));
  console.log(`- إجمالي المستندات المفحوصة: ${totalDocsScanned}`);
  console.log(`- إجمالي صور ImgBB المتبقية والمكتشفة: ${totalImagesFound}`);
  if (!isDryRun) {
    console.log(`- إجمالي الصور المنقولة والمحفوظة في Cloudinary: ${Object.keys(cache).length}`);
    console.log(`- إجمالي مستندات Firestore المحدثة في هذه الجولة: ${totalDocsUpdated}`);
  }
  console.log('='.repeat(65));
}

main().catch((err) => {
  console.error('❌ حدث خطأ غير متوقع:', err);
  process.exit(1);
});
