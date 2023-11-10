# chainlink-node

## Initial setup

Configure the items in ``chainlink-sepolia-secrets`` and then run the following:

```bash
mkdir -p ~/.chainlink/sepolia/postgres/
mkdir -p ~/.chainlink/sepolia/secrets/
cp  ./chainlink-sepolia-secrets/* ~/.chainlink/sepolia/secrets/
```

## Start the both the node and postgres

```bash
docker compose up -d
```

## Stop the both the node and postgres

```bash
docker compose down
```

## Connect to the node for admin purposes

note use the user and password defined in ``~/.chainlink/sepolia/secrets/api`` to log in when prompted

```bash
docker exec -it chainlink-sepolia-node /bin/bash
chainlink admin login
```
