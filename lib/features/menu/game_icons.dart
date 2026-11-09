// Logos des jeux du menu, en SVG intégré au code (pas de fichier d'asset à copier).
// Source : src/app/components/MainMenu.tsx (fonctions ChkobbaIcon, DominoIcon, BeloteIcon, LudoIcon, RamiIcon).
// Note : flutter_svg ne dessine pas les éléments <text> ; les chiffres 7, 8 et 9 n'apparaissent donc pas.

const gameIconSvg = <String, String>{
  'Chkobba': r'''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 72 72" width="56" height="56">
  <g transform="rotate(-12 28 36)">
    <rect x="9" y="12" width="35" height="49" rx="7" fill="#1676d2" stroke="#15264d" stroke-width="4"/>
    <path d="M15 19h23M15 54h23" stroke="#fff8e7" stroke-width="2.5" opacity=".8"/>
  </g>
  <g transform="rotate(9 45 36)">
    <rect x="27" y="8" width="36" height="53" rx="7" fill="#fff8e7" stroke="#15264d" stroke-width="4"/>
    <circle cx="46" cy="25" r="5" fill="#ffd653" stroke="#15264d" stroke-width="2.5"/>
    <circle cx="38" cy="38" r="5" fill="#ffd653" stroke="#15264d" stroke-width="2.5"/>
    <circle cx="54" cy="38" r="5" fill="#ffd653" stroke="#15264d" stroke-width="2.5"/>
    <circle cx="46" cy="51" r="5" fill="#ffd653" stroke="#15264d" stroke-width="2.5"/>
  </g>
</svg>''',
  'Domino': r'''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 72 72" width="56" height="56">
  <path d="M17 59V28c0-13 8-21 19-21s19 8 19 21v31" fill="#1676d2" stroke="#15264d" stroke-width="4"/>
  <path d="M24 58V29c0-8 5-14 12-14s12 6 12 14v29" fill="#fff8e7" opacity=".95"/>
  <g transform="rotate(-9 36 38)">
    <rect x="17" y="26" width="40" height="24" rx="6" fill="#fff8e7" stroke="#15264d" stroke-width="4"/>
    <path d="M37 27v22" stroke="#15264d" stroke-width="3"/>
    <circle cx="27" cy="38" r="3.5" fill="#e43f5f"/>
    <circle cx="47" cy="33" r="3.5" fill="#1676d2"/>
    <circle cx="47" cy="43" r="3.5" fill="#1676d2"/>
  </g>
</svg>''',
  'Belote': r'''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 72 72" width="56" height="56">
  <g transform="rotate(-13 27 37)">
    <rect x="9" y="13" width="34" height="48" rx="7" fill="#fff8e7" stroke="#15264d" stroke-width="4"/>
    <path d="M26 45c-10-7-12-13-7-17 4-3 7 0 8 3 2-3 5-6 9-3 5 4 2 11-10 17Z" fill="#e43f5f"/>
  </g>
  <g transform="rotate(11 46 37)">
    <rect x="29" y="11" width="34" height="49" rx="7" fill="#fff8e7" stroke="#15264d" stroke-width="4"/>
    <path d="M46 24c8 7 12 12 6 17-4 3-7 0-7-3-2 4-5 6-9 3-6-5-1-11 10-17Z" fill="#15264d"/>
    <path d="M36 17c5-8 14-9 20 0l-3 5H39Z" fill="#e43f5f" stroke="#15264d" stroke-width="2.5" stroke-linejoin="round"/>
  </g>
</svg>''',
  'Ludo': r'''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 72 72" width="56" height="56">
  <path d="M36 7 43 20 58 14 52 29 65 36 52 43 58 58 43 52 36 65 29 52 14 58 20 43 7 36 20 29 14 14 29 20Z" fill="#fff8e7" stroke="#15264d" stroke-width="3.5" stroke-linejoin="round"/>
  <circle cx="36" cy="36" r="10" fill="#ffd653" stroke="#15264d" stroke-width="3"/>
  <circle cx="36" cy="13" r="6" fill="#e43f5f" stroke="#15264d" stroke-width="3"/>
  <circle cx="59" cy="36" r="6" fill="#49c9a7" stroke="#15264d" stroke-width="3"/>
  <circle cx="36" cy="59" r="6" fill="#1676d2" stroke="#15264d" stroke-width="3"/>
  <circle cx="13" cy="36" r="6" fill="#f49b32" stroke="#15264d" stroke-width="3"/>
</svg>''',
  'Rami': r'''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 72 72" width="56" height="56">
  <g transform="rotate(-18 25 38)">
    <rect x="8" y="14" width="31" height="47" rx="6" fill="#1676d2" stroke="#15264d" stroke-width="4"/>
  </g>
  <g transform="rotate(-2 36 35)">
    <rect x="21" y="9" width="31" height="50" rx="6" fill="#fff8e7" stroke="#15264d" stroke-width="4"/>
    <path d="M36 38c-6-5-7-9-3-11 3-2 5 0 5 2 1-2 3-4 6-2 4 3 1 7-8 11Z" fill="#e43f5f"/>
  </g>
  <g transform="rotate(15 49 37)">
    <rect x="35" y="12" width="30" height="48" rx="6" fill="#ffd653" stroke="#15264d" stroke-width="4"/>
    <circle cx="51" cy="45" r="5" fill="#e43f5f" stroke="#15264d" stroke-width="2"/>
  </g>
</svg>''',
};
