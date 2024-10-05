# Use Node.js 18.19.1 with Alpine 3.18 as the base image
FROM node:18.19.1-alpine3.18 AS base

FROM base AS builder

ENV SHARP_FORCE_GLOBAL_LIBVIPS=1

ENV npm_package_config_libvips=8.14.3

# Update and upgrade APK packages
RUN apk update && apk upgrade

# Install dependencies for building libvips and sharp
RUN apk add --no-cache \
  build-base \
  meson \
  ninja \
  zlib-dev \
  expat-dev \
  jpeg-dev \
  tiff-dev \
  glib-dev \
  libjpeg-turbo-dev \
  libheif \
  libheif-dev \
  libexif-dev \
  lcms2-dev \
  fftw-dev \
  libpng-dev \
  libwebp-dev \
  libarchive-dev \
  gobject-introspection-dev  # Add this line to install gobject-introspection

# Verify the installation of libheif
RUN apk info | grep libheif

# Set libvips version and download URL
ARG VIPS_VERSION=8.14.3
ARG VIPS_URL=https://github.com/libvips/libvips/releases/download

# Download and build libvips from source
RUN wget ${VIPS_URL}/v${VIPS_VERSION}/vips-${VIPS_VERSION}.tar.xz \
  && tar xf vips-${VIPS_VERSION}.tar.xz \
  && cd vips-${VIPS_VERSION} \
  && meson setup build \
  && meson compile -C build \
  && meson install -C build

# Verify libvips installation
RUN vips --version && echo "Vips Successfully Installed"

# Set the working directory in the container
WORKDIR /app

# Copy package.json and package-lock.json to the container
COPY package*.json ./

# Install npm dependencies, including sharp
RUN npm install --arch=x64 --platform=linux --unsafe-perm sharp

# Copy the rest of the application code to the container
COPY . .

# Expose port 3000 for Express.js
EXPOSE 3000

# Command to run the Express.js app
CMD ["npm", "start"]
