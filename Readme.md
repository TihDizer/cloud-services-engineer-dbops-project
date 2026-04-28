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
## Create db and user
```sql
CREATE DATABASE store ENCODING = 'UTF8';
CREATE ROLE migration_service_user WITH LOGIN PASSWORD '<secret password>';
GRANT CONNECT ON DATABASE store TO migration_service_user;
```
## Grant privileges for new user
```psql
\store=# c store
```
```sql
GRANT USAGE, CREATE ON SCHEMA public TO migration_service_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO migration_service_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO migration_service_user;
```
## Step 10 (before indeces)
```psql
store=# \timing
```
```sql
SELECT o.date_created, SUM(op.quantity)
FROM orders AS o
JOIN order_product AS op ON o.id = op.order_id
WHERE o.status = 'shipped' AND o.date_created > NOW() - INTERVAL '7 DAY'
GROUP BY o.date_created;
```
```psql
 date_created |  sum
--------------+--------
 2026-04-21   | 935895
 2026-04-22   | 939741
 2026-04-23   | 943377
 2026-04-24   | 931710
 2026-04-25   | 937651
 2026-04-26   | 951191
 2026-04-27   | 816515
(7 rows)

Time: 708.328 ms
```
## EXPLAIN(ANALYZE)
```psql
 Finalize GroupAggregate  (cost=266259.39..266282.44 rows=91 width=12) (actual time=847.770..853.687 rows=7 loops=1)
   Group Key: o.date_created
   ->  Gather Merge  (cost=266259.39..266280.62 rows=182 width=12) (actual time=847.760..853.675 rows=21 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Sort  (cost=265259.36..265259.59 rows=91 width=12) (actual time=835.667..835.669 rows=7 loops=3)
               Sort Key: o.date_created
               Sort Method: quicksort  Memory: 25kB
               Worker 0:  Sort Method: quicksort  Memory: 25kB
               Worker 1:  Sort Method: quicksort  Memory: 25kB
               ->  Partial HashAggregate  (cost=265255.49..265256.40 rows=91 width=12) (actual time=835.649..835.652 rows=7 loops=3)
                     Group Key: o.date_created
                     Batches: 1  Memory Usage: 24kB
                     Worker 0:  Batches: 1  Memory Usage: 24kB
                     Worker 1:  Batches: 1  Memory Usage: 24kB
                     ->  Parallel Hash Join  (cost=148405.47..264704.64 rows=110171 width=8) (actual time=302.006..827.766 rows=84529 loops=3)
                           Hash Cond: (op.order_id = o.id)
                           ->  Parallel Seq Scan on order_product op  (cost=0.00..105361.67 rows=4166667 width=12) (actual time=0.390..156.709 rows=3333333 loops=3)
                           ->  Parallel Hash  (cost=147028.33..147028.33 rows=110171 width=12) (actual time=300.448..300.448 rows=84529 loops=3)
                                 Buckets: 524288  Batches: 1  Memory Usage: 16032kB
                                 ->  Parallel Seq Scan on orders o  (cost=0.00..147028.33 rows=110171 width=12) (actual time=5.904..281.074 rows=84529 loops=3)
                                       Filter: (((status)::text = 'shipped'::text) AND (date_created > (now() - '7 days'::interval)))
                                       Rows Removed by Filter: 3248805
 Planning Time: 0.317 ms
 JIT:
   Functions: 54
   Options: Inlining false, Optimization false, Expressions true, Deforming true
   Timing: Generation 1.973 ms, Inlining 0.000 ms, Optimization 0.881 ms, Emission 16.867 ms, Total 19.721 ms
 Execution Time: 854.478 ms
```
## Step 11 (after indeces)
```psql
store=# \timing
```
```sql
SELECT o.date_created, SUM(op.quantity)
FROM orders AS o
JOIN order_product AS op ON o.id = op.order_id
WHERE o.status = 'shipped' AND o.date_created > NOW() - INTERVAL '7 DAY'
GROUP BY o.date_created;
```
```psql
 date_created |  sum
--------------+--------
 2026-04-21   | 935895
 2026-04-22   | 939741
 2026-04-23   | 943377
 2026-04-24   | 931710
 2026-04-25   | 937651
 2026-04-26   | 951191
 2026-04-27   | 816515
(7 rows)

Time: 548.223 ms
```

Время уменьшилось примерно на 30 процентов после добавления индексов

## EXPLAIN(ANALYZE)
```psql
Finalize GroupAggregate  (cost=188752.11..188775.17 rows=91 width=12) (actual time=686.105..693.331 rows=7 loops=1)
   Group Key: o.date_created
   ->  Gather Merge  (cost=188752.11..188773.35 rows=182 width=12) (actual time=686.095..693.320 rows=21 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Sort  (cost=187752.09..187752.32 rows=91 width=12) (actual time=673.190..673.192 rows=7 loops=3)
               Sort Key: o.date_created
               Sort Method: quicksort  Memory: 25kB
               Worker 0:  Sort Method: quicksort  Memory: 25kB
               Worker 1:  Sort Method: quicksort  Memory: 25kB
               ->  Partial HashAggregate  (cost=187748.22..187749.13 rows=91 width=12) (actual time=673.167..673.170 rows=7 loops=3)
                     Group Key: o.date_created
                     Batches: 1  Memory Usage: 24kB
                     Worker 0:  Batches: 1  Memory Usage: 24kB
                     Worker 1:  Batches: 1  Memory Usage: 24kB
                     ->  Parallel Hash Join  (cost=70898.20..187197.36 rows=110171 width=8) (actual time=145.578..665.432 rows=84529 loops=3)
                           Hash Cond: (op.order_id = o.id)
                           ->  Parallel Seq Scan on order_product op  (cost=0.00..105361.67 rows=4166667 width=12) (actual time=0.018..154.725 rows=3333333 loops=3)
                           ->  Parallel Hash  (cost=69521.06..69521.06 rows=110171 width=12) (actual time=144.385..144.386 rows=84529 loops=3)
                                 Buckets: 524288  Batches: 1  Memory Usage: 16032kB
                                 ->  Parallel Bitmap Heap Scan on orders o  (cost=3622.64..69521.06 rows=110171 width=12) (actual time=27.152..126.727 rows=84529 loops=3)
                                       Recheck Cond: (((status)::text = 'shipped'::text) AND (date_created > (now() - '7 days'::interval)))
                                       Heap Blocks: exact=25645
                                       ->  Bitmap Index Scan on orders_status_date_idx  (cost=0.00..3556.54 rows=264410 width=0) (actual time=26.336..26.336 rows=253586 loops=1)
                                             Index Cond: (((status)::text = 'shipped'::text) AND (date_created > (now() - '7 days'::interval)))
 Planning Time: 0.235 ms
 JIT:
   Functions: 57
   Options: Inlining false, Optimization false, Expressions true, Deforming true
   Timing: Generation 1.974 ms, Inlining 0.000 ms, Optimization 1.436 ms, Emission 18.039 ms, Total 21.449 ms
 Execution Time: 693.939 ms
```

## Compare
C индексами намного меньше строк обрабатывается
```psql
->  Bitmap Index Scan on orders_status_date_idx
  (cost=0.00..3556.54 rows=264410 width=0)
  (actual time=26.336..26.336 rows=253586 loops=1)
```
Без индексов
```psql
->  Parallel Seq Scan on orders o
  (cost=0.00..147028.33 rows=110171 width=12)
  (actual time=5.904..281.074 rows=84529 loops=3)
      Filter: (((status)::text = 'shipped'::text) AND (date_created > (now() - '7 days'::interval)))
      Rows Removed by Filter: 3248805
```
