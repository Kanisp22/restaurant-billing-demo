FROM node:18-slim

WORKDIR /usr/src/app

ARG BUILD_ID=unknown

COPY package*.json ./
RUN npm ci --omit=dev

COPY src ./src

ENV NODE_ENV=production
ENV PORT=3000
ENV BUILD_ID=$BUILD_ID
EXPOSE 3000

CMD ["node", "src/index.js"]

