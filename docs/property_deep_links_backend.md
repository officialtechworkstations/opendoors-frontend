# Property share links: backend handoff

The mobile app is configured for `https://links.opendoorsapp.com/properties/{id}`.
Use the property's existing API ID as `{id}`. Links for any other host or path
will open in a browser, not in the app. This hostname and path are now part of
the app configuration; coordinate a frontend release before publishing links.

## Property page and API

- Return an absolute `share_url` in `u_property_details.php`, either inside
  `propetydetails` or at the response root. Example:
  `"share_url": "https://links.opendoorsapp.com/properties/42"`.
- Serve a public HTML page at that URL. It must work for recipients who do not
  have the app installed. Include server-rendered `og:title`, `og:description`,
  `og:image` (an absolute HTTPS URL for the actual property image), and
  `og:url`. A JavaScript-only page will not reliably generate previews.
- Return a useful unavailable page for unpublished/deleted properties; do not
  expose private listing details through share metadata.

## Domain verification files

Serve both files directly over HTTPS, with no redirects:

`https://links.opendoorsapp.com/.well-known/apple-app-site-association`

```json
{
  "applinks": {
    "details": [{
      "appIDs": ["24QSYQPJLT.opendoorsapp.com"],
      "components": [{"/": "/properties/*"}]
    }]
  }
}
```

The file has no `.json` extension and should be served as `application/json`.

`https://links.opendoorsapp.com/.well-known/assetlinks.json`

```json
[{ 
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.opendoors.appnew",
    "sha256_cert_fingerprints": ["REPLACE_WITH_PLAY_APP_SIGNING_SHA256"]
  }
}]
```

Use the **Play App Signing** certificate fingerprint for production. Add a
separate statement/fingerprint for any independently signed test build.

## Verification

1. Check both `.well-known` URLs return HTTP 200 and the JSON directly.
2. Inspect a property page's raw HTML to confirm its Open Graph image and URL.
3. On an installed app build, tap a property link from Notes or a message on
   iOS and from a message on Android. Test both cold and warm launches.
4. Test the same link without the app installed; it should display the web page.

Reel links are not included in this contract. Their app-opening route needs a
separate agreed URL and frontend handling.
