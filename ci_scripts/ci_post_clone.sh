#!/bin/sh
#
# Xcode Cloud runs this automatically right after cloning the repo, before
# resolving packages or building. It regenerates ios/Secrets.swift (which is
# gitignored and therefore absent from the clone) from secret environment
# variables configured on the Xcode Cloud workflow:
#
#   SUPABASE_URL        e.g. https://xxxx.supabase.co
#   SUPABASE_ANON_KEY   the Supabase anon (public client) key
#
# Without this file the app fails to compile (Analytics.swift / FeedbackView.swift /
# SettingsView.swift reference Secrets.supabaseEnabled, .supabaseURL and .supabaseAnonKey).
set -e

SECRETS_PATH="$CI_PRIMARY_REPOSITORY_PATH/ios/Secrets.swift"

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
  echo "warning: SUPABASE_URL / SUPABASE_ANON_KEY not set — generating empty Secrets (analytics/feedback will be inert)."
fi

cat > "$SECRETS_PATH" <<EOF
import Foundation

enum Secrets {
    /// Master switch for the Supabase backend (analytics upload + feedback).
    /// On: anonymous events and submitted feedback are uploaded. Note content
    /// is never sent. Keep in sync with ios/ios/Secrets.swift, PRIVACY.md,
    /// PrivacyInfo.xcprivacy, and the App Store privacy questionnaire.
    static let supabaseEnabled = true

    static let supabaseURL = "${SUPABASE_URL}"
    static let supabaseAnonKey = "${SUPABASE_ANON_KEY}"
}
EOF

echo "Generated $SECRETS_PATH"
