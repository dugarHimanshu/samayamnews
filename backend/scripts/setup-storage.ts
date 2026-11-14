/** Creates the storage buckets: `raw` (private uploads) and `media` (public processed images/PDFs). */
import { MEDIA_BUCKET, RAW_BUCKET, supabaseAdmin } from '../src/services/storage.js'

const storage = supabaseAdmin().storage
const buckets = [
  { name: RAW_BUCKET, public: false, fileSizeLimit: 50 * 1024 * 1024 },
  { name: MEDIA_BUCKET, public: true, fileSizeLimit: 50 * 1024 * 1024 },
]
for (const b of buckets) {
  const { error } = await storage.createBucket(b.name, { public: b.public, fileSizeLimit: b.fileSizeLimit })
  if (error && !/already exists/i.test(error.message)) throw error
  if (error) await storage.updateBucket(b.name, { public: b.public, fileSizeLimit: b.fileSizeLimit })
  console.log(`Bucket "${b.name}" ready (${b.public ? 'public' : 'private'})`)
}
process.exit(0)
