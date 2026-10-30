# VoteWala website on Cloud Run: nginx serving the Flutter web build.
# Built by .github/workflows/deploy-cloud-run.yml after `flutter build web`.
FROM nginx:1.27-alpine
COPY hosting/nginx.conf /etc/nginx/conf.d/default.conf
COPY build/web /usr/share/nginx/html
EXPOSE 8080
