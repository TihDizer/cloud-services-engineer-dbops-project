# dbops-project
## Installed software
- [nix (single-user)](https://nixos.org/download/)
```bash
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --no-daemon
```
- docker
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh ./get-docker.sh
```
## Nix develop (for psql and run docker)
```bash
nix develop --experimental-features 'nix-command flakes'
```
or pure psql
```bash
sudo apt-get install -y postgresql-client
```
and
```bash
sudo docker compose up --detach
```
## Step 10 (before indeces)
```psql
db=> \timing
```
```SQL
SELECT o.date_created, SUM(op.quantity)
FROM orders AS o
JOIN order_product AS op ON o.id = op.order_id
WHERE o.status = 'shipped' AND o.date_created > NOW() - INTERVAL '7 DAY'
GROUP BY o.date_created;
```
```psql
 date_created |  sum
--------------+--------
 2026-04-21   | 951720
 2026-04-22   | 946816
 2026-04-23   | 941349
 2026-04-24   | 960466
 2026-04-25   | 951640
 2026-04-26   | 947010
 2026-04-27   | 638924
(7 rows)

Time: 35378.667 ms (00:35.379)
```
## Step 11 (after indeces)
```psql
db=> \timing
```
```SQL

```
