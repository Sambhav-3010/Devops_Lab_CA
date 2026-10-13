FROM node:20-alpine

ENV NODE_ENV=production
ENV PORT=8000

WORKDIR /app

COPY package.json ./
RUN npm config set fetch-retries 5 \
    && npm config set fetch-retry-factor 2 \
    && npm config set fetch-retry-mintimeout 1000 \
    && npm config set fetch-retry-maxtimeout 120000 \
    && npm install --omit=dev --no-audit --no-fund \
    && npm cache clean --force
COPY server.js ./

USER node
EXPOSE 8000

CMD ["node", "server.js"]
