class AdvertisementItem {
  final String id;
  final String sponsor;
  final String headline;
  final String tag;
  final String description;
  final String ctaText;
  final String imageUrl;

  const AdvertisementItem({
    required this.id,
    required this.sponsor,
    required this.headline,
    required this.tag,
    required this.description,
    required this.ctaText,
    required this.imageUrl,
  });
}

const List<AdvertisementItem> demoAds = [
  AdvertisementItem(
    id: 'ad-01',
    sponsor: 'AURA MOBILITY',
    headline: 'Next-Gen Electric Vehicles Engineered for Indian Roads.',
    tag: 'SPONSORED INNOVATION',
    description: 'Experience ultra-fast charging, seamless connected cockpit, and 650km verified range.',
    ctaText: 'Explore Models',
    imageUrl: 'https://images.unsplash.com/photo-1593941707882-a5bba14938c7?auto=format&fit=crop&w=900&q=80',
  ),
  AdvertisementItem(
    id: 'ad-02',
    sponsor: 'ZENITH WEALTH',
    headline: 'Smart Algorithmic Investing Built for Discerning Investors.',
    tag: 'FINANCIAL ADVISORY',
    description: 'Zero commission index exposure with real-time portfolio rebalancing and tax-loss harvesting.',
    ctaText: 'Start Investing',
    imageUrl: 'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?auto=format&fit=crop&w=900&q=80',
  ),
  AdvertisementItem(
    id: 'ad-03',
    sponsor: 'HORIZON CLOUD',
    headline: 'Enterprise Cloud Infrastructure with Global Edge Performance.',
    tag: 'TECH SOLUTIONS',
    description: 'Deploy in under 30 seconds with 99.999% uptime SLA across 40 worldwide zones.',
    ctaText: 'Get Free Credits',
    imageUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?auto=format&fit=crop&w=900&q=80',
  ),
  AdvertisementItem(
    id: 'ad-04',
    sponsor: 'LUMINA SMART AUDIO',
    headline: 'Immersive Spatial Sound that Adapts to Your Room Acoustics.',
    tag: 'PREMIUM AUDIO',
    description: 'Lossless studio playback with active noise cancellation and 48-hour battery longevity.',
    ctaText: 'Discover Audio',
    imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=900&q=80',
  ),
  AdvertisementItem(
    id: 'ad-05',
    sponsor: 'ORION TRAVEL & RESORTS',
    headline: 'Exclusive Luxury Retreats Crafted in Untamed Destinations.',
    tag: 'CURATED GETAWAYS',
    description: 'Book signature private villas with personalized chef services and complimentary airport transfers.',
    ctaText: 'View Escapes',
    imageUrl: 'https://images.unsplash.com/photo-1571896349842-33c89424de2d?auto=format&fit=crop&w=900&q=80',
  ),
];
