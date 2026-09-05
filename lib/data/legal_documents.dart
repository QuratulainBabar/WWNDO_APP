/// Shared Terms & Conditions and Privacy Policy copy for WWNGO.
class LegalSection {
  const LegalSection({
    required this.heading,
    this.body,
    this.bullets,
  });

  final String heading;
  final String? body;
  final List<String>? bullets;
}

abstract final class LegalDocuments {
  static const lastUpdated = 'September 4, 2026';

  static const termsTitle = 'Terms & Conditions';
  static const privacyTitle = 'Privacy Policy';

  static const termsSections = <LegalSection>[
    LegalSection(
      heading: '1. Agreement to these Terms',
      body:
          'These Terms & Conditions (“Terms”) govern your use of the WWNGO mobile application and related services (the “Platform”). WWNGO is a peer-to-peer marketplace that connects Senders who need a parcel moved, Travelers who are already going that way, and Receivers who accept the parcel at destination. By creating an account and checking “I agree to the Terms and Privacy Policy,” you enter a binding agreement with WWNGO. If you do not agree, do not register or use the Platform.',
    ),
    LegalSection(
      heading: '2. What WWNGO is — and is not',
      body:
          'WWNGO facilitates matching, in-app chat, meetup coordination, identity checks, wallet payments, escrow, NFC handoff confirmation, tracking, ratings, and dispute review. WWNGO is not a courier, postal operator, freight forwarder, customs broker, insurer, or employer of Travelers. Delivery is performed by independent users. WWNGO does not take possession of parcels except as needed to operate the Platform (for example storing photos you upload).',
    ),
    LegalSection(
      heading: '3. Eligibility and accounts',
      bullets: [
        'You must be at least 18 years old and able to form a binding contract.',
        'You must provide accurate name, email, phone, country, and password, and keep them up to date.',
        'One person may use a single WWNGO account as Sender, Traveler, and/or Receiver. These Terms apply to every role you use.',
        'Email and phone verification, and identity verification (KYC) through our partner Sumsub, are required before posting deliveries, listing trips, bidding, accepting parcels, or moving money.',
        'You are responsible for activity on your account. Do not share login credentials. Notify support@wwngo.com if you suspect unauthorized access.',
      ],
    ),
    LegalSection(
      heading: '4. Sender responsibilities',
      body:
          'When you act as a Sender you post a delivery request (city-to-city or country-to-country), describe the parcel, set a budget, add photos, and name a Receiver. You agree to:',
      bullets: [
        'Provide truthful parcel category, size, weight, contents description, route, travel date, and meetup preferences.',
        'Only send items that are legal to possess and transport on the chosen route, including customs and airline rules for international trips.',
        'Never list prohibited, dangerous, or illegal goods (see Section 10).',
        'Fund escrow for the agreed traveler payout when you accept a bid or counter-offer, and pay your Sender platform fee at Pay Now (\$2 documents / \$4 objects, or \$3 / \$6 when you cover the receiver\'s fee). Traveler and Receiver platform fees are also collected at Pay Now (wallet first, then card).',
        'Meet the Traveler at the agreed origin meetup location and complete NFC Checkpoint 1 (Sender ↔ Traveler) to confirm handoff.',
        'Communicate only through WWNGO chat for the delivery, and honor cancellations and timers described in the app.',
      ],
    ),
    LegalSection(
      heading: '5. Traveler responsibilities',
      body:
          'When you act as a Traveler you list a trip, review matching parcel requests, accept or counter offers, and carry the parcel on your journey. You agree to:',
      bullets: [
        'Post accurate origin, destination, travel date, and capacity, and only accept parcels you can legally and safely carry.',
        'Pay applicable Traveler platform fees (\$2 for documents, \$4 for objects) from your wallet (or card if needed) when the Sender completes Pay Now.',
        'Confirm or propose meetup locations, complete NFC Checkpoint 1 with the Sender, keep the parcel secure in transit, and complete NFC Checkpoint 2 (Traveler ↔ Receiver) at destination.',
        'Not open, use, swap, or abandon a parcel, and not subcontract the delivery outside WWNGO.',
        'Update shipment status in good faith (for example starting transit) and respond promptly in chat.',
        'Comply with airline, border, and customs declarations. You are responsible for what you physically carry.',
      ],
    ),
    LegalSection(
      heading: '6. Receiver responsibilities',
      body:
          'When you act as a Receiver you are named on a delivery, accept the incoming request, and take the parcel at destination. You agree to:',
      bullets: [
        'Review parcel details before accepting. Accepting is consent only — a Receiver platform fee (\$2 for documents, \$3 for objects) is charged at sender Pay Now unless the sender covers it.',
        'Be available at the destination meetup, verify the parcel, and complete NFC Checkpoint 2 (Traveler ↔ Receiver) to confirm delivery.',
        'Raise a dispute in-app promptly if the parcel is missing, damaged, or not as described, instead of completing NFC confirmation if you do not accept the goods.',
        'Keep contact details accurate so the Sender and Traveler can coordinate.',
      ],
    ),
    LegalSection(
      heading: '7. Matching, bids, and booking',
      body:
          'Senders may discover travelers and send requests. Travelers may receive matching requests, accept, decline, or send a counter-offer. A booking is created only when the Sender accepts a price, required KYC and verification are complete, escrow is successfully funded, and platform fees are collected as displayed. Selection of a Traveler locks the booking. If a payment window or accept timer expires, the booking may auto-cancel and escrow principal is refunded according to Section 12.',
    ),
    LegalSection(
      heading: '8. Meetup locations and chat',
      body:
          'Parties coordinate a public, appropriate meetup using in-app location tools. A meetup is confirmed when the required parties accept it in the app. Chat between Sender–Traveler, Sender–Receiver, and Traveler–Receiver unlocks according to delivery status. Do not share payment details off-platform or move the deal outside WWNGO. Off-platform payments void escrow protection.',
    ),
    LegalSection(
      heading: '9. NFC checkpoints and delivery confirmation',
      bullets: [
        'NFC Checkpoint 1 (Sender ↔ Traveler) confirms the Sender handed the parcel to the Traveler.',
        'NFC Checkpoint 2 (Traveler ↔ Receiver) confirms the Receiver received the parcel. Both parties must complete their tap. Successful Checkpoint 2 marks the shipment Delivered and releases escrow to the Traveler (unless frozen by a dispute).',
        'NFC is a confirmation tool, not a guarantee of parcel condition. Photos, chat, tracking, and dispute records may still be used in a review.',
        'Misusing NFC (confirming without a real handoff, coercing a tap, or spoofing devices) is grounds for suspension and escrow freeze.',
      ],
    ),
    LegalSection(
      heading: '10. Prohibited items and zero-tolerance conduct',
      body:
          'You must not send, carry, or request: illegal drugs, weapons, explosives, hazardous materials, stolen goods, counterfeit items, cash or bearer instruments beyond what local law allows, live animals, human remains, or any item banned by the carrier, airline, or destination country. Fraud, fake identity, fake photos, harassment, rating manipulation, and attempts to bypass escrow are forbidden. WWNGO may suspend accounts, freeze escrow, and report illegal activity to authorities.',
    ),
    LegalSection(
      heading: '11. Payments, wallets, and escrow',
      bullets: [
        'You have one WWNGO wallet shared across Sender, Traveler, and Receiver activity. Top up with Stripe and withdraw via Stripe Connect once a payout account is linked and ready. Transaction history records which role each entry relates to.',
        'When a Sender accepts a Traveler, the agreed payout is moved from the Sender’s available balance into escrow (card payment may cover a shortfall). Escrow is not withdrawable by any party until release, refund, or a dispute decision.',
        'Platform fees (Sender, Traveler, and/or Receiver, including document vs. object rates and optional Sender-covers-Receiver-fee) are disclosed before you confirm and are charged as shown.',
        'Escrow is released to the Traveler after NFC Checkpoint 2 / Delivered, unless frozen. WWNGO is not a bank; wallet balances are Platform records used to settle marketplace transactions.',
      ],
    ),
    LegalSection(
      heading: '12. Cancellations and refunds',
      body:
          'Booked deliveries may be cancelled before the trip is in transit or delivered, subject to in-app rules. Escrow principal is refunded to the Sender. Platform fees are refunded to the paying parties if cancellation is more than 24 hours before travel; within 24 hours, platform fees are generally non-refundable. Posted deliveries that are not yet booked may be cancelled under the posting rules in the app. Auto-cancel (for example unpaid Receiver windows or expired accept timers) refunds escrow principal as stated in the product. Top-ups and completed payouts are not reversed except as required by law or a formal dispute outcome.',
    ),
    LegalSection(
      heading: '13. Tracking, photos, and reviews',
      body:
          'Status updates, parcel photos, and GPS or meetup data you provide are used to operate the delivery. After delivery, parties may leave reviews. Reviews must be honest and about the transaction. WWNGO may hide or remove abusive or fake reviews.',
    ),
    LegalSection(
      heading: '14. Disputes',
      body:
          'If something goes wrong (damage, non-delivery, wrong item, NFC dispute), file a dispute in the app. Filing a dispute freezes escrow while WWNGO reviews delivery records, photos, chat, NFC checkpoints, and identity data. Do not complete NFC Checkpoint 2 if you intend to dispute receipt. WWNGO’s decision on escrow (release, refund, or split) is final as between the parties on the Platform, without limiting any rights you may have against another user in a court of competent jurisdiction. Chargebacks or off-platform claims may still result in account action.',
    ),
    LegalSection(
      heading: '15. Limitation of liability',
      body:
          'To the maximum extent permitted by law, WWNGO is not liable for loss, delay, damage, seizure, or customs issues caused by users, carriers, or governments; for the acts of Senders, Travelers, or Receivers; or for indirect, incidental, or consequential damages. Our total liability to you for a claim relating to the Platform is limited to the greater of (a) the platform fees you paid to WWNGO for the delivery in dispute in the 12 months before the claim, or (b) USD 50. Nothing in these Terms excludes liability that cannot legally be excluded (including for fraud or death/personal injury caused by negligence where such exclusion is forbidden).',
    ),
    LegalSection(
      heading: '16. Changes, suspension, and contact',
      body:
          'We may update these Terms. Continued use after an in-app notice constitutes acceptance of the revised Terms. We may suspend or terminate accounts that violate these Terms. Questions: support@wwngo.com. These Terms are the entire agreement for your use of the Platform and are governed by the laws applicable to WWNGO’s place of establishment, without prejudice to mandatory consumer protections in your country of residence.',
    ),
  ];

  static const privacySections = <LegalSection>[
    LegalSection(
      heading: '1. Introduction',
      body:
          'This Privacy Policy explains how WWNGO collects, uses, shares, and protects personal data when you use our peer-to-peer parcel marketplace as a Sender, Traveler, and/or Receiver. It applies to first-time registration and all later use of the same account. By creating an account you acknowledge this Policy. For questions, contact privacy@wwngo.com.',
    ),
    LegalSection(
      heading: '2. Data we collect',
      bullets: [
        'Account data: full name, email, phone (with country/dial code), password (stored hashed), country, selected role, and profile details you add.',
        'Verification data: email and phone OTP status; KYC information processed by Sumsub (identity document, selfie, liveness, and verification result). WWNGO stores verification status and references, not your raw ID images, except as our KYC partner’s flow requires.',
        'Delivery data: routes, dates, parcel category/size/weight/description, photos, Receiver contact, meetup addresses, bids and counter-offers, shipment status, NFC checkpoint records, cancellation and dispute records.',
        'Communications: in-app chat messages, attachments, and support emails.',
        'Payments: unified wallet balance and ledger (available and escrow), transaction descriptions with activity role tags, Stripe payment and Connect identifiers. Card numbers are handled by Stripe, not stored on WWNGO servers.',
        'Device and usage: app version, device type, IP address, crash logs, and push-notification tokens (FCM) to deliver alerts.',
      ],
    ),
    LegalSection(
      heading: '3. How we use your data',
      bullets: [
        'Create and secure your account, and let you switch among Sender, Traveler, and Receiver.',
        'Match parcels to trips, display listings, and run bids, timers, and booking locks.',
        'Collect platform fees, hold Sender funds in escrow, release payouts to Travelers after NFC Checkpoint 2, and process refunds on cancellation or dispute.',
        'Enable meetup coordination, chat, tracking, NFC confirmation, reviews, and notifications.',
        'Prevent fraud, enforce these Terms, review disputes, and meet legal obligations.',
        'Improve reliability and customer support. We do not sell your personal data.',
      ],
    ),
    LegalSection(
      heading: '4. Role-specific sharing on a delivery',
      body:
          'To complete a booking, limited profile and delivery information is shown to the other parties on that shipment only — for example names, ratings, route, parcel summary, meetup status, and chat. A Traveler does not receive your full payment card details. A Receiver sees what they need to accept and collect the parcel. After delivery or cancellation, access follows product rules (history, reviews, dispute files).',
    ),
    LegalSection(
      heading: '5. Processors and third parties',
      bullets: [
        'Sumsub — identity verification (KYC).',
        'Stripe — wallet top-up, payment intents, and Connect payouts.',
        'Firebase Cloud Messaging — push notifications.',
        'Email/SMS providers — one-time codes and transactional mail.',
        'Hosting and database providers that process data on our instructions.',
        'Authorities when required by law or to protect users from serious harm.',
      ],
    ),
    LegalSection(
      heading: '6. Retention, security, and international transfer',
      body:
          'We keep account, ledger, delivery, NFC, and dispute records for as long as you have an account and for a reasonable period afterward to complete payouts, handle chargebacks, and meet bookkeeping and legal duties. We use encryption in transit, access controls, and unified wallet accounting. Data may be processed in countries other than yours; we use appropriate safeguards with processors. No method of transmission is 100% secure.',
    ),
    LegalSection(
      heading: '7. Your rights',
      body:
          'Subject to applicable law, you may request access, correction, deletion, restriction, or export of your personal data, and object to certain processing. You may withdraw consent where processing is based on consent (this does not affect prior lawful processing). Some records (escrow, KYC status, completed ledgers) may be retained where we must keep them. Contact privacy@wwngo.com. You may also lodge a complaint with your local data protection authority.',
    ),
    LegalSection(
      heading: '8. Children, changes, and contact',
      body:
          'WWNGO is not directed at children under 18. We do not knowingly collect their data. We may update this Policy and will post the new date in the app. Material changes may be notified in-app or by email. Contact: privacy@wwngo.com (privacy) or support@wwngo.com (general).',
    ),
  ];
}
