# DeepAPI Brand Application

The assets in this directory are the repository source of truth. `deploy.sh`
installs the SVG and PNG logo files to `/var/www/deepapi-brand`, installs the
pricing page to `/var/www/deepapi-site`, and Nginx exposes stable public paths:

| Purpose | Public path | Asset |
| --- | --- | --- |
| Primary photographic logo | `/brand/deepapi-logo.png` | `deepapi-logo.png` |
| Primary horizontal logo | `/brand/deepapi-logo.svg` | `deepapi-logo.svg` |
| Square app/header icon | `/brand/deepapi-icon.svg` | `deepapi-icon.svg` |
| Browser favicon | `/favicon.svg` | `favicon.svg` |
| one-api fallback logo | `/logo.png` | `deepapi-logo.png` |
| Legacy browser favicon | `/favicon.ico` | `favicon.svg` |
| Pricing page | `/pricing/` | `static/pricing/index.html` |

The fallback routes override the fixed one-api image's bundled icon URLs. They
do not modify the image itself.

## One-API Admin Settings

The pinned one-api frontend supports custom system name, logo, footer,
homepage, and About content. After an operator deploys the repository changes,
sign in as an administrator and open **Settings > System Settings**:

1. Set **System Name** to `DeepAPI`.
2. Set **Logo Image URL** to
   `https://deepapi.click/brand/deepapi-logo.png`.
3. Replace any old product name, logo, or misleading partnership copy in
   **Homepage Content**, **About System**, and **Footer**.
4. Link public pricing calls to action to `https://deepapi.click/pricing/`.
5. Use the SVG horizontal logo only in custom dark-background HTML where its
   4:1 aspect ratio has enough width:
   `https://deepapi.click/brand/deepapi-logo.svg`.
6. Reload in a private browser window so stale local storage and cached icons
   do not hide the change.

The one-api frontend uses its configured Logo URL for both visible UI logos and
the runtime favicon. The dedicated favicon routes remain useful during initial
page load and as browser fallbacks.

## Asset And Accessibility Notes

- `deepapi-logo.png` is the current visible product logo requested for the live
  site. It has a white background and works best in light containers or white
  pills on dark pages.
- `deepapi-logo.svg` is a 640x160 horizontal asset with a 4:1 aspect ratio. Use
  it at 120px wide or larger and keep its aspect ratio.
- `deepapi-icon.svg` is a 128x128 square asset for headers, app tiles, and
  avatars. Use it at 32px or larger where practical.
- `favicon.svg` is a simplified 64x64 square asset designed to remain distinct
  at browser-tab sizes.
- The horizontal logo and square icon include their own Night background, so
  they remain consistent when placed on light or dark surrounding backgrounds.
- The logo and icon include SVG `title` and `desc` metadata. When used through
  an HTML `img` element, also provide meaningful alt text such as
  `alt="DeepAPI"`. Use empty alt text only when the image is decorative.
- If an asset is copied inline more than once on one page, give each copy
  unique `title` and `desc` IDs so `aria-labelledby` references remain valid.
- The favicon intentionally has no image role or accessible label because
  browser favicons are decorative.

## Verification

Run after an operator deploys the repository:

```bash
nginx -t
curl -fsSI https://deepapi.click/brand/deepapi-logo.svg
curl -fsSI https://deepapi.click/brand/deepapi-logo.png
curl -fsSI https://deepapi.click/brand/deepapi-icon.svg
curl -fsSI https://deepapi.click/favicon.svg
curl -fsSI https://deepapi.click/favicon.ico
curl -fsSI https://deepapi.click/logo.png
curl -fsSI https://deepapi.click/pricing/
```

Then verify visually in a private browser window:

- browser tab shows the DeepAPI route icon;
- login page and header show the square DeepAPI icon;
- `/pricing/` shows the pricing table with the photographic DeepAPI logo;
- page title and visible product name say `DeepAPI`;
- homepage, About, and footer contain no old logo or endorsement language;
- icon remains recognizable at 16px, 32px, and 128px;
- horizontal logo remains legible with light and dark surrounding backgrounds.

## Current Boundary

The repository installs and serves the assets and overrides one-api's fallback
icon URLs. The one-api settings are stored in its database, so this repository
cannot guarantee the live **System Name**, **Logo**, **Homepage Content**,
**About System**, or **Footer** values until an operator applies and verifies
them.
