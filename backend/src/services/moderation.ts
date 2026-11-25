import { and, desc, eq, ilike, inArray, isNull, or, sql } from 'drizzle-orm'
import { db } from '../db/client.js'
import { articleStats, articles, media, profiles, submissionEvents, submissions } from '../db/schema.js'
import { type AuthUser, forgetUser } from '../lib/auth.js'
import { invalidate } from '../lib/cache.js'
import { decodeCursor, encodeCursor } from '../lib/cursor.js'
import { badRequest, notFound } from '../lib/errors.js'
import { toArticleDtos } from './articles.js'
import { supabaseAdmin } from './storage.js'

// ------------------------------------------------------------------ news list + permanent delete

/** Every article (live and unpublished), newest first, for the admin News List. */
export async function adminArticles(params: { q?: string; cursor?: string; limit: number }) {
  const pos = decodeCursor<{ t: string; i: string }>(params.cursor)
  const rows = await db
    .select({ article: articles, cover: { variants: media.variants, status: media.status }, likes: articleStats.likes, comments: articleStats.comments })
    .from(articles)
    .leftJoin(media, eq(media.id, articles.coverMediaId))
    .leftJoin(articleStats, eq(articleStats.articleId, articles.id))
    .where(
      and(
        params.q ? or(ilike(articles.title, `%${params.q}%`), ilike(articles.authorName, `%${params.q}%`)) : undefined,
        pos ? sql`(${articles.publishedAt}, ${articles.id}) < (${pos.t}::timestamptz, ${pos.i}::uuid)` : undefined,
      ),
    )
    .orderBy(desc(articles.publishedAt), desc(articles.id))
    .limit(params.limit + 1)
  const slice = rows.slice(0, params.limit)
  const dtos = await toArticleDtos(slice, { withBody: false })
  const last = slice.at(-1)
  return {
    items: dtos.map((d, i) => ({ ...d, status: slice[i]!.article.status })),
    nextCursor: rows.length > params.limit && last ? encodeCursor({ t: last.article.publishedAt.toISOString(), i: last.article.id }) : null,
  }
}

/**
 * Permanently removes a published article: likes, bookmarks, comments, stats and revisions go
 * with it (FK cascades); follow-ups that linked to it lose the link. Readers stop seeing it
 * immediately on this instance and within the CDN's short cache window everywhere else.
 */
export async function deleteArticle(admin: AuthUser, id: string) {
  await db.transaction(async (tx) => {
    const [a] = await tx.select({ id: articles.id, submissionId: articles.submissionId, title: articles.title }).from(articles).where(eq(articles.id, id)).for('update')
    if (!a) throw notFound('Article not found')
    await tx.update(articles).set({ relatedArticleId: null, relatedAnchor: null }).where(eq(articles.relatedArticleId, id))
    await tx.delete(articles).where(eq(articles.id, id))
    if (a.submissionId) {
      await tx.insert(submissionEvents).values({ submissionId: a.submissionId, actorId: admin.id, type: 'rejected', payload: { reason: 'Deleted by admin after publishing', deletedArticleId: id } })
    }
  })
  invalidate('feed:')
}

// ------------------------------------------------------------------ remove reporter / freelancer

export const REMOVABLE_ROLES = ['employee', 'freelancer'] as const

/** Reporters and freelancers (active ones first), for the admin list with a Remove button. */
export async function contributors() {
  return db
    .select({ id: profiles.id, email: profiles.email, fullName: profiles.fullName, role: profiles.role, homeDistrictId: profiles.homeDistrictId, createdAt: profiles.createdAt })
    .from(profiles)
    .where(and(inArray(profiles.role, [...REMOVABLE_ROLES]), isNull(profiles.deletedAt), isNull(profiles.disabledAt)))
    .orderBy(profiles.fullName)
}

/**
 * Removes a reporter/freelancer: blocks sign-in (Supabase ban + disabled flag checked on every
 * request), drops their newsroom role and withdraws stories still waiting for review.
 * Articles they already published stay in the app.
 */
export async function removeContributor(admin: AuthUser, userId: string) {
  if (userId === admin.id) throw badRequest('You cannot remove yourself')
  const [p] = await db.select().from(profiles).where(eq(profiles.id, userId)).limit(1)
  if (!p || p.deletedAt) throw notFound('User not found')
  if (!REMOVABLE_ROLES.includes(p.role as (typeof REMOVABLE_ROLES)[number]) && !p.disabledAt) {
    throw badRequest('Only reporters and freelancers can be removed here')
  }
  await db.transaction(async (tx) => {
    await tx.update(profiles).set({ disabledAt: new Date(), role: 'reader' }).where(eq(profiles.id, userId))
    const open = await tx
      .update(submissions)
      .set({ status: 'rejected', claimedBy: null, claimExpiresAt: null })
      .where(and(eq(submissions.submitterId, userId), inArray(submissions.status, ['pending', 'in_review'])))
      .returning({ id: submissions.id })
    if (open.length) {
      await tx.insert(submissionEvents).values(open.map((s) => ({ submissionId: s.id, actorId: admin.id, type: 'rejected' as const, payload: { reason: 'Reporter account removed' } })))
    }
  })
  forgetUser(userId)
  // Also stop new sign-ins and token refreshes at the auth server (~100 years).
  const { error } = await supabaseAdmin().auth.admin.updateUserById(userId, { ban_duration: '876000h' })
  if (error) throw new Error(`Account disabled, but sign-in block failed: ${error.message}`)
}
