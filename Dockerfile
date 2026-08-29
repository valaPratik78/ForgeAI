# Use the official Nginx image to serve the web app
FROM nginx:alpine

# The build stage is typically done before or via multi-stage builds.
# Assuming the Flutter web app is already built in the 'build/web' folder.
# To build locally, run `flutter build web` before building the docker image.
# If you want a multi-stage build, uncomment the section below and comment out the simple COPY line.

# --- MULTI-STAGE BUILD (Optional) ---
# FROM dart:stable AS build
# WORKDIR /app
# RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
# ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"
# RUN flutter channel stable && flutter upgrade
# COPY . .
# RUN flutter pub get
# RUN flutter build web
# ------------------------------------

# Copy the built app to Nginx's html folder
# (Change to COPY --from=build /app/build/web /usr/share/nginx/html if using multi-stage)
COPY build/web /usr/share/nginx/html

# Expose port 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
