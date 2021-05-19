# GambleBoard

A decentralized betting platform on the Ethereum blockchain! 

Implements the [Arbitration](https://github.com/ethereum/EIPs/issues/792) and [Evidence](https://github.com/ethereum/EIPs/issues/1497) standards and uses [The Graph Protocol](https://thegraph.com/) for indexing.

[Requirements](https://github.com/LauriTahvanainen/GambleBoard/edit/main/documentation/requirements.md)

## Running

Deploying the project locally:

#### Dependencies

Install:

- [Ganache](https://github.com/trufflesuite/ganache-cli)/[Ganache-Cli](https://github.com/trufflesuite/ganache-cli)
- [npm](https://www.npmjs.com/get-npm)
- [yarn](https://yarnpkg.com/getting-started/install) (e.g. with npm)
- [Graph CLI](https://github.com/graphprotocol/graph-cli)
- [Graph TypeScript Library](https://github.com/graphprotocol/graph-ts)
- [Graph Node](https://github.com/graphprotocol/graph-node)
	- [Rust](https://www.rust-lang.org/en-US/install.html) (latest stable)
	- [PostgreSQL](https://www.postgresql.org/download/)
	- [IPFS](https://docs.ipfs.io/install/)

#### Front end

The front end repository can be found [here](https://github.com/LauriTahvanainen/GambleBoard-frontend)

For using the centralized arbitrator with a browser, you can use the [Centralized arbitrator dashboard](https://github.com/LauriTahvanainen/centralized-arbitrator-dashboard)

You should start the user interface when you have the blockchain and the graph node running.

#### Contract

Use for example the [Remix IDE](https://remix.ethereum.org) to edit and deploy the contracts to the Ganache blockchain. Use port 8545. First deploy the [Centralized Auto Appealable Arbitrator](https://github.com/LauriTahvanainen/GambleBoard/blob/main/src/contracts/test/AutoAppealableArbitrator.sol). Copy the address of the arbitrator and give it as a parameter to the [GambleBoard.sol](https://github.com/LauriTahvanainen/GambleBoard/blob/main/src/contracts/GambleBoard.sol) when deploying it. arbitratorExtraData can be 0x00. To use the hard coded (TODO: ADD A GLOBAL SETTINGS FILE) addresses in the code, use the memonic in [here](https://github.com/LauriTahvanainen/GambleBoard/blob/main/TestInput/Input.txt) to create the Ganache chain account. Import the first account to metamask. Deploy first the centralized arbitrator, and then the GambleBoard contract. You can also replace the hardcoded  addresses; in the [`subgraph.yaml file`](https://github.com/LauriTahvanainen/GambleBoard/blob/main/subgraph.yaml) and in the [front-end](https://github.com/LauriTahvanainen/GambleBoard-Frontend).

#### Local Graph Node Deployment Steps

1. IPFS: run `ipfs init` followed by `ipfs daemon`. This starts the IPFS service. It listens on port 5001.
For the evidence to be able to be sent locally, the IPFS config file should start with:
```
 API": {
		"HTTPHeaders": {
			"Access-Control-Allow-Methods": [
				"GET",
				"PUT",
				"POST"
			],
			"Access-Control-Allow-Origin": [
				"http://localhost:3000",
				"http://localhost:3001",
				"http://127.0.0.1:5001",
				"https://webui.ipfs.io"
			]
		}
	}
```
Otherwise the client will complain about a CORS error.

2. (NOTICE: The node documentation tells you to do it this way, but when you install PostgreSQL, it creates a default databasecluster. You could use that and run `createdb graph-node` on that skipping the first two commands. Remembre to use the same database user for every command) PostgreSQL: In the folder where you want to save the database run `initdb -D .postgres` followed by `pg_ctl -D .postgres -l logfile start` and `createdb graph-node`. This starts the PostgreSQL service that listens on port 5432 and initializes a PostgreSQL database named graph-node
3. If using Ubuntu, you may need to install additional packages:
   - `sudo apt-get install -y clang libpq-dev libssl-dev pkg-config`
4. clone https://github.com/graphprotocol/graph-node to own folder, and run `cargo build` in the folder. Some depencencies might need to be installed.
5. In the graph-node folder run:

```
cargo run -p graph-node --release -- 
  --postgres-url postgresql://USERNAME[:PASSWORD]@localhost:5432/graph-node 
  --ethereum-rpc [URL] 
  --ipfs 127.0.0.1:5001
```

For example:

```
cargo run -p graph-node --release -- --postgres-url postgresql://postgres:[PASSWORD]@localhost:5432/graph-node --ethereum-rpc ganache:http://127.0.0.1:8545 --ipfs 127.0.0.1:5001 --debug
```

Try your OS username as `USERNAME` and `PASSWORD` or the Postgres user depending on with which user you initialized the database. For details on setting
the connection string, check the [Postgres documentation](https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING).
`graph-node` uses a few Postgres extensions. If the Postgres user with which
you run `graph-node` is a superuser, `graph-node` will enable these
extensions when it initalizes the database. If the Postgres user is not a
superuser, you will need to create the extensions manually since only
superusers are allowed to do that. To create them you need to connect as a
superuser, which in many installations is the `postgres` user:

```bash
    psql -q -X -U <SUPERUSER> graph-node <<EOF
create extension pg_trgm;
create extension pg_stat_statements;
create extension btree_gist;
create extension postgres_fdw;
grant usage on foreign data wrapper postgres_fdw to <USERNAME>;
EOF

```

This will also spin up a GraphiQL interface at `http://127.0.0.1:8000/`.

6. Inside the GambleBoard folder, install dependencies: `yarn`
7. Generate mapping code from the contract ABI and the definitions in the subgraph.yaml file: `yarn codegen`

8. deploy the subgraph to the local node:

```
yarn create-local

yarn deploy-local
```

If the deploy succeeds it will print the links to the endpoints of the subgraph. Accessing the Queries link, you can query the subgraph from the browser. For example: `http://localhost:8000/subgraphs/name/LauriTahvanainen/GambleBoard`

Now everything should be running locally and you can start the front-end. [More information on the graph-node](https://github.com/graphprotocol/graph-node/blob/master/docs/getting-started.md)

### Changes to the contract/subgraph mappings.

Steps to do when updating the `contract/mapping.ts/schema.graphql` (not all might be necessary):

1. Update contract ABI in `abis/GambleBoard.json` (ABI can be copied from Remix when you compile a contract)
2. Deploy new contract
3. Copy and paste the new contract address to `subgraph.yaml` and front-end
4. Run:

```
yarn deploy-local
```
5. Fix possible errors; Repeat step 4 until the subgraph is deployed.

You might also need to remove the subgraph with `yarn remove-local` and re-deploy it

Or even re-create the graph-node database.

## Resources

- [Solidity](https://buildmedia.readthedocs.org/media/pdf/solidity/develop/solidity.pdf)
- [The Graph](https://thegraph.com/docs/introduction)
- [GraphQL](https://graphql.org/learn/) and [Queries With The Graph](https://thegraph.com/docs/graphql-api#queries) 
