# A Dockerfile for local testing. Should NOT be used in production!
FROM node:alpine
WORKDIR /usr/src/app

COPY package.json package-lock.json /usr/src/app/
RUN npm install

COPY . .
CMD ./node_modules/.bin/serverless offline start