# Use Node.js 18.19.1 with Alpine 3.18 as the base image
FROM node:18.19.1-alpine3.18 AS base

FROM base AS builder

ENV SHARP_FORCE_GLOBAL_LIBVIPS=1
ENV npm_package_config_libvips=8.14.3

# Update and upgrade APK packages
RUN apk update && apk upgrade

# Install dependencies for building libheif, libvips, and sharp
RUN apk add --no-cache \
  build-base \
  cmake \
  meson \
  ninja \
  zlib-dev \
  expat-dev \
  jpeg-dev \
  tiff-dev \
  glib-dev \
  libjpeg-turbo-dev \
  libexif-dev \
  lcms2-dev \
  fftw-dev \
  libpng-dev \
  libwebp-dev \
  libarchive-dev \
  gobject-introspection-dev \
  aom-dev \
  make

RUN apk add --no-cache \
  x265-dev \
  dav1d-dev \
  libde265-dev \
  aom-dev

# Verify the installation of necessary packages
RUN apk info | grep libheif || true

# Set libheif version and download URL
ARG HEIF_VERSION=1.16.2
ARG HEIF_URL=https://github.com/strukturag/libheif/archive/refs/tags/v${HEIF_VERSION}.tar.gz

# Download and build libheif from source with codec support
RUN wget ${HEIF_URL} \
  && tar -xzf v${HEIF_VERSION}.tar.gz \
  && cd libheif-${HEIF_VERSION} \
  && cmake . -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr \
  -DWITH_EXAMPLES=ON -DWITH_LIBX265=ON -DWITH_AOM=ON -DWITH_DAV1D=ON -DWITH_LIBDE265=ON -DENABLE_PLUGIN_LOADING=NO \
  && make \
  && make install

# Verify libheif installation
RUN heif-convert --version && echo "Libheif Successfully Installed"

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
