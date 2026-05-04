# --- Auth ---
# Use a strong random value (>=32 chars). Rotate via deploy, not commits.
JWT_SECRET=change-me-min-32-chars-please-use-openssl-rand-base64-32
JWT_EXPIRATION=8h
JWT_REFRESH_EXPIRATION=7d
