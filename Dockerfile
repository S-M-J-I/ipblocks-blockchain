# ethereum start
# start-client
FROM ethereum/solc:stable
FROM node:23-bullseye-slim

RUN apt-get update

RUN npm install -g truffle ganache web3

WORKDIR /sol-container

COPY . .

EXPOSE 8545 8545

CMD ["ganache", "--host", "0.0.0.0", "--accounts", "150", "--deterministic"]