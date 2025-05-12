# Blockchain Repo for IPBlocks

### How to run

At first, clone the repository.
Make sure [Docker](https://docs.docker.com/engine/install/) is installed.

Next, simply run:
```sh
docker-compose up --build
```

To deploy the smart contract, first, open the container's shell:
```sh
docker exec -it sol-container bash
```

Once inside the container, simply run
```sh
truffle deploy
```

After successful execution, a transaction receipt will be shown in the terminal.

### Tech stack
* **Programming Language**: Solidity
* **Compilation, deploying, and testing**: Truffle
* **Network**: Ganache
