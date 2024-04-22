# Build stage
FROM node:18 as build-stage
WORKDIR /app
COPY package*.json ./
RUN npm install --legacy-peer-deps
COPY ./ ./
RUN npm run build

# Production stage
FROM nginx:stable-alpine
COPY --from=build-stage /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
