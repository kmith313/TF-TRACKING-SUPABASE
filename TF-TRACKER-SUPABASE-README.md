# TF-Tracker (Supabase version) - Summary + Comparison

## What this site does
- Login with User ID + password (same IDs as in your Supabase project).
- **Summary** tab: Workshop wise, Division wise, Pending for issue - age wise, Capacity wise. By default: this month (From = 1st of the month, To = today).
- **Comparison** tab: Division wise / Day wise, this year vs the same dates of the previous year. By default: this month.
- Tap any number to see the records behind it (300 at a time, "Load more"). Excel and Print work like before.
- No Kitty tab. No Data / Driver / Admin tabs yet (they come with the "save data" step).

## Put it online (one time)
1. Supabase > SQL Editor > run `supabase-step8-app.sql` (one time).
2. GitHub: create a NEW repository (e.g. `TF-TRACKER-SB`) - do NOT upload over your old working app.
3. Upload every file of the `site` folder (index.html, config.js, sw.js, logo.png, icons ...) to that repository (Add file > Upload files).
4. Settings > Pages > Source: main branch / root > Save. The link appears after 1-2 minutes.
5. Open the link, log in with the ID you already tested (admin1 / je_mau / head1).

`config.js` already contains your project URL and the publishable key (both are public by design; the database rules protect the data).
