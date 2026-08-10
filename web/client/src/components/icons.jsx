/**
 * The Material icons the app draws, as inline SVG.
 *
 * The Flutter build gets these from the bundled MaterialIcons font. Loading
 * that font here would mean either shipping a second copy of it or pulling
 * from Google's CDN — and the README's "one outbound dependency" claim is a
 * privacy promise, not a performance note, so the CDN is out. These are drawn
 * on the same 24px grid at the same optical weight instead.
 *
 * Every name below maps to the `Icons.*` constant used at the matching call
 * site, so a reader comparing the two trees can follow it across.
 */

const PATHS = {
  // Dashboard chrome
  notifications_outlined:
    'M12 22a2 2 0 0 0 2-2h-4a2 2 0 0 0 2 2Zm6-6v-5a6 6 0 0 0-4.5-5.8V4.5a1.5 1.5 0 0 0-3 0v.7A6 6 0 0 0 6 11v5l-1.7 1.7a1 1 0 0 0 .7 1.7h14a1 1 0 0 0 .7-1.7L18 16Z',
  settings_outlined:
    'M12 15.5A3.5 3.5 0 1 1 15.5 12 3.5 3.5 0 0 1 12 15.5Zm7.4-2.6.1-.9-.1-.9 1.7-1.3a.5.5 0 0 0 .1-.6l-1.6-2.8a.5.5 0 0 0-.6-.2l-2 .8a7 7 0 0 0-1.5-.9l-.3-2.1a.5.5 0 0 0-.5-.4h-3.2a.5.5 0 0 0-.5.4l-.3 2.1a7 7 0 0 0-1.5.9l-2-.8a.5.5 0 0 0-.6.2L4.5 9.2a.5.5 0 0 0 .1.6l1.7 1.3-.1.9.1.9-1.7 1.3a.5.5 0 0 0-.1.6l1.6 2.8a.5.5 0 0 0 .6.2l2-.8a7 7 0 0 0 1.5.9l.3 2.1a.5.5 0 0 0 .5.4h3.2a.5.5 0 0 0 .5-.4l.3-2.1a7 7 0 0 0 1.5-.9l2 .8a.5.5 0 0 0 .6-.2l1.6-2.8a.5.5 0 0 0-.1-.6Z',
  arrow_back: 'M20 11H7.8l5.6-5.6L12 4l-8 8 8 8 1.4-1.4L7.8 13H20Z',
  chevron_right: 'M9.3 6 8 7.4l4.6 4.6L8 16.6 9.3 18l6-6Z',
  arrow_outward: 'M7 17.3 15.9 8.4H8V6.5h11v11h-1.9V9.7l-8.9 9Z',
  info_outline:
    'M11 17h2v-6h-2ZM12 9a1 1 0 1 0-1-1 1 1 0 0 0 1 1Zm0 13a10 10 0 1 1 10-10 10 10 0 0 1-10 10Zm0-2a8 8 0 1 0-8-8 8 8 0 0 0 8 8Z',

  // Hero states — _ScoreHeader._palette
  rocket_launch:
    'M9.2 15.4 8 14.2a15 15 0 0 1 6-8.7A9.3 9.3 0 0 1 20.4 4a9.3 9.3 0 0 1-1.5 6.4 15 15 0 0 1-8.7 6ZM15.5 10a1.5 1.5 0 1 0-1.5-1.5 1.5 1.5 0 0 0 1.5 1.5ZM6.6 16.1a3.4 3.4 0 0 0-2.4 2.3L3.5 21l2.6-.7a3.4 3.4 0 0 0 2.3-2.4Z',
  verified_user:
    'M12 2 4 5.3v5.5c0 4.8 3.4 9.3 8 10.4 4.6-1.1 8-5.6 8-10.4V5.3Zm-1.2 14-3.5-3.5 1.4-1.4 2.1 2.1 5-5 1.4 1.4Z',
  warning_amber:
    'M12 5.6 19 18H5ZM12 2 1 21h22ZM11 15h2v2h-2Zm0-6h2v5h-2Z',
  priority_high:
    'M12 21a2.2 2.2 0 1 1 2.2-2.2A2.2 2.2 0 0 1 12 21Zm-2-8V3h4v10Z',
  schedule:
    'M12 2a10 10 0 1 0 10 10A10 10 0 0 0 12 2Zm0 18a8 8 0 1 1 8-8 8 8 0 0 1-8 8Zm.5-13H11v6l5.2 3.2.8-1.3-4.5-2.7Z',

  // Modules — module_card.dart
  link: 'M3.9 12A3.1 3.1 0 0 1 7 8.9h4V7H7a5 5 0 0 0 0 10h4v-1.9H7A3.1 3.1 0 0 1 3.9 12ZM8 13h8v-2H8Zm9-6h-4v1.9h4a3.1 3.1 0 0 1 0 6.2h-4V17h4a5 5 0 0 0 0-10Z',
  bug_report:
    'M20 8h-2.8a6 6 0 0 0-1.5-1.7L17 4.4 15.8 3.2l-1.9 1.9a5.6 5.6 0 0 0-3.8 0L8.2 3.2 7 4.4l1.3 1.9A6 6 0 0 0 6.8 8H4v2h2.1v1H4v2h2.1v1H4v2h2.8a6 6 0 0 0 10.4 0H20v-2h-2.1v-1H20v-2h-2.1v-1H20ZM14 16h-4v-2h4Zm0-4h-4v-2h4Z',
  lock_person:
    'M18 8h-1V6a5 5 0 0 0-10 0v2H6a2 2 0 0 0-2 2v10a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V10a2 2 0 0 0-2-2ZM9 6a3 3 0 0 1 6 0v2H9Zm3 6a2.2 2.2 0 1 1-2.2 2.2A2.2 2.2 0 0 1 12 12Zm4.5 8h-9v-.8c0-1.5 3-2.3 4.5-2.3s4.5.8 4.5 2.3Z',
  wifi: 'M12 21 24 6a19 19 0 0 0-24 0Zm0-3.6L4.6 8.2a15.3 15.3 0 0 1 14.8 0Z',

  // Defence tiles — _DefenseGrid
  travel_explore:
    'M12 2a10 10 0 1 0 6 18l-1.5-1.5A8 8 0 1 1 20 12h-2l2.5 4 2.5-4h-1A10 10 0 0 0 12 2Zm-1 4.1v1.6a1.5 1.5 0 0 0-1.5 1.5H8a1.5 1.5 0 0 0-1.5 1.5v1.5A1.5 1.5 0 0 0 8 13.7h3v2.2a6 6 0 0 1 0-11.9Zm2.6 1.2A6 6 0 0 1 17 11h-2.5a1.5 1.5 0 0 0-1.5-1.5V8a1.5 1.5 0 0 0 .6-.7Z',
  image_search:
    'M13 3a7 7 0 0 0-7 7 7 7 0 0 0 1 3.5L3 17.6 4.4 19l3.1-4A7 7 0 1 0 13 3Zm0 2a5 5 0 1 1-5 5 5 5 0 0 1 5-5Zm-.5 1.5v3h-3V11h3v3h1.5v-3h3V9.5h-3v-3Z',
  online_prediction:
    'M12 2a10 10 0 0 1 8.5 15.3L19 15.9A8 8 0 1 0 5 15.9l-1.5 1.4A10 10 0 0 1 12 2Zm0 4a6 6 0 0 1 4.8 9.6l-1.5-1.5A4 4 0 1 0 8.7 14l-1.5 1.6A6 6 0 0 1 12 6Zm-1 5h2v11h-2Z',
  balance:
    'M13 3v1.3l6 2.1-.6 1.9L17 7.9 20 15h-6l3-7.1-4-1.4V19h4v2H7v-2h4V6.5l-4 1.4L10 15H4l3-7.1-1.4.4L5 6.4l6-2.1V3Z',

  // Scan-row module glyphs — _ScanRow._moduleIcons
  android:
    'M6 18a1 1 0 0 0 1 1h1v3.5a1.5 1.5 0 0 0 3 0V19h2v3.5a1.5 1.5 0 0 0 3 0V19h1a1 1 0 0 0 1-1V8H6Zm-2.5-10A1.5 1.5 0 0 0 2 9.5v7a1.5 1.5 0 0 0 3 0v-7A1.5 1.5 0 0 0 3.5 8Zm17 0A1.5 1.5 0 0 0 19 9.5v7a1.5 1.5 0 0 0 3 0v-7A1.5 1.5 0 0 0 20.5 8ZM15.5 4.2l1.3-1.3-.7-.7-1.5 1.5a6.6 6.6 0 0 0-5.2 0L7.9 2.2l-.7.7 1.3 1.3A6 6 0 0 0 6 7h12a6 6 0 0 0-2.5-2.8ZM10 5.5H9v-1h1Zm5 0h-1v-1h1Z',
  mark_email_unread:
    'M18.5 9A3.5 3.5 0 1 1 22 5.5 3.5 3.5 0 0 1 18.5 9ZM4 20a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h9.2a4.5 4.5 0 0 0 .3 4.6L12 9.6 4 5v2.2l8 4.8 4.5-2.7A4.5 4.5 0 0 0 20 10.7V18a2 2 0 0 1-2 2Z',
  shield:
    'M12 2 4 5.3v5.5c0 4.8 3.4 9.3 8 10.4 4.6-1.1 8-5.6 8-10.4V5.3Z',
  security:
    'M12 2 4 5.3v5.5c0 4.8 3.4 9.3 8 10.4 4.6-1.1 8-5.6 8-10.4V5.3Zm0 9.9h6.2c-.5 3.5-2.9 6.7-6.2 7.7v-7.7H5.8V6.6L12 4Z',
  shield_outlined:
    'M12 2 4 5.3v5.5c0 4.8 3.4 9.3 8 10.4 4.6-1.1 8-5.6 8-10.4V5.3Zm6 8.8c0 3.8-2.6 7.4-6 8.4-3.4-1-6-4.6-6-8.4V6.6l6-2.5 6 2.5Z',
  task_alt:
    'M20.5 5.3 19 3.9l-8.6 8.6-3.4-3.4L5.6 10.5l4.8 4.8ZM21 12a9 9 0 1 1-3.6-7.2l1.4-1.4A11 11 0 1 0 23 12Z',
  qr_code_scanner:
    'M3 3h6v2H5v4H3Zm12 0h6v6h-2V5h-4Zm6 12v6h-6v-2h4v-4ZM3 15h2v4h4v2H3Zm4-8h4v4H7Zm6 6h4v4h-4Zm0-6h4v4h-4Zm-6 6h4v4H7Z',
  logout:
    'M17 8.4 15.6 9.8 17.2 11.5H9v2h8.2l-1.6 1.7L17 16.6 21 12.5ZM5 5h7V3H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h7v-2H5Z',
};

/**
 * @param {string} name  key in PATHS, named after the Flutter `Icons.*` constant
 * @param {number} size  matches the `size:` argument at the Dart call site
 */
export function Icon({ name, size = 24, color = 'currentColor', className }) {
  const d = PATHS[name];
  if (!d) return null;
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill={color}
      className={className}
      aria-hidden="true"
      focusable="false"
    >
      <path d={d} />
    </svg>
  );
}

export default Icon;
