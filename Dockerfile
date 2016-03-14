FROM node:0.10.36

WORKDIR /usr/src/app
COPY . /usr/src/app
RUN cd /usr/src/app/funnel && npm install
