# Blockchain Repo for IPBlocks | [Read the Paper](https://ieeexplore.ieee.org/document/11374961)

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

### Cite this work
```
@inproceedings{ahmmed2025ipblocks,
  title={IPBlocks: A Blockchain Ecosystem for Secure IP Registration and Decentralized Marketplace},
  author={Ahmmed, Sadia and Islam, SM Jishanul and Mustakim, Sahid Hossain and Islam, Ridwan Arefin and Shanto, Subangkar Karmaker and Islam, Salekul},
  booktitle={TENCON 2025-2025 IEEE Region 10 Conference (TENCON)},
  pages={1491--1495},
  year={2025},
  organization={IEEE}
}
```
