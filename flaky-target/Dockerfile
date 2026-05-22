FROM node:20-alpine

WORKDIR /app
COPY server.js ./

ENV PORT=80
EXPOSE 80

HEALTHCHECK --interval=2s --timeout=3s --retries=10 \
  CMD wget --spider -q http://localhost/state || exit 1

CMD ["node", "server.js"]
