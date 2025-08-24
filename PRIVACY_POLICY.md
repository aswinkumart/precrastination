Privacy Policy

This Privacy Policy explains how the precrastination app collects, uses, and shares information.

Data Collection
- The app may collect summary requests and book titles (not personal data) when generating summaries via a third-party AI service.
- The app does not store personal user identifiers unless explicitly enabled by the user.

Third-Party Services
- Anthropic (LLM API): Used to generate short summaries. API requests may include book titles and user prompts. Do not embed API keys in the shipped app. Use a backend proxy or Xcode environment variables during development.
- Google Books API: Used to fetch book cover thumbnails. Thumbnail URLs are cached locally.
- Alamofire & Kingfisher: Networking and image utilities included under MIT.

Data Sharing
- We do not share personal data with third parties except to provide the AI-generated summary service and cover images when you request them.

Security
- API keys should be stored securely and not embedded in client binaries. Remove keys from source before publishing.

Contact
- For privacy questions, contact: privacy@yourdomain.example

Updates
- We may update this policy; the app will include a versioned policy file in the repository.
